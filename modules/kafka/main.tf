# ============================================================
# Kafka Module
# Provisions EC2 instance with Confluent Platform Community Edition
# Services: Kafka Broker (KRaft), Schema Registry, Kafka Connect, Control Center
# ============================================================

# ----------------------------------------------------------
# IAM Role – allows the Kafka EC2 to call AWS APIs
# (S3 Tables / Iceberg writes, no hardcoded credentials needed)
# ----------------------------------------------------------
resource "aws_iam_role" "kafka_ec2" {
  name = "${var.name_prefix}-kafka-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "${var.name_prefix}-kafka-ec2-role"
  }
}

# S3 Tables full access (needed by Iceberg Sink Connector)
resource "aws_iam_role_policy" "kafka_s3tables" {
  name = "${var.name_prefix}-kafka-s3tables-policy"
  role = aws_iam_role.kafka_ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3TablesAccess"
        Effect = "Allow"
        Action = [
          "s3tables:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "S3BucketAccessForIceberg"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = "*"
      },
      {
        Sid    = "GlueForIcebergCatalog"
        Effect = "Allow"
        Action = [
          "glue:*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "kafka_ec2" {
  name = "${var.name_prefix}-kafka-ec2-profile"
  role = aws_iam_role.kafka_ec2.name
}

# ----------------------------------------------------------
# EC2 Instance – Confluent Platform
# ----------------------------------------------------------
resource "aws_instance" "kafka" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  # Attach IAM role so Iceberg connector can write to S3 Tables without hardcoded keys
  iam_instance_profile = aws_iam_instance_profile.kafka_ec2.name

  # user_data runs on first boot; sets up the entire Confluent stack
  user_data = <<-EOF
  #!/bin/bash
    set -euxo pipefail
    exec > /var/log/user-data.log 2>&1

    # ── System packages ──────────────────────────────────────
    apt-get update -y
    apt-get install -y curl gnupg software-properties-common openjdk-17-jdk wget

    # ── Confluent Platform Community Edition ─────────────────
    curl -fsSL https://packages.confluent.io/deb/8.0/archive.key \
      | gpg --dearmor -o /usr/share/keyrings/confluent-archive-keyring.gpg

    echo "deb [signed-by=/usr/share/keyrings/confluent-archive-keyring.gpg] \
https://packages.confluent.io/deb/8.0 stable main" \
      > /etc/apt/sources.list.d/confluent.list

   apt-get install -y \
    confluent-platform \
    confluent-hub-client
    # confluent-control-center intentionally excluded — too memory-heavy for Free Tier

    # ── Connectors ───────────────────────────────────────────
    # Debezium PostgreSQL CDC source
    confluent-hub install --no-prompt debezium/debezium-connector-postgresql:2.5.4

    # Iceberg Sink (tabular / Apache Iceberg)
    mkdir -p /usr/share/confluent-hub-components/iceberg-kafka-connect
    wget -q -O /tmp/iceberg-kafka-connect.tar.gz \
      "https://github.com/tabular-io/iceberg-kafka-connect/releases/download/v0.6.19/iceberg-kafka-connect-runtime-0.6.19.tar.gz"
    tar -xzf /tmp/iceberg-kafka-connect.tar.gz \
      -C /usr/share/confluent-hub-components/iceberg-kafka-connect --strip-components=1

    # ── Detect this instance's private IP (used in advertised.listeners) ─
    PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
    PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
    AWS_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)

    # ── KRaft Kafka Broker ───────────────────────────────────
    CLUSTER_ID=$(kafka-storage random-uuid)

    cat > /etc/kafka/kraft/server.properties <<CONFIG
# KRaft single-node config (no ZooKeeper)
process.roles=broker,controller
node.id=1
controller.quorum.voters=1@localhost:9093

# Listeners
listeners=PLAINTEXT://0.0.0.0:9092,CONTROLLER://localhost:9093
# advertised.listeners must use the private IP so Debezium (other EC2) can reach Kafka
advertised.listeners=PLAINTEXT://$${PRIVATE_IP}:9092
controller.listener.names=CONTROLLER
listener.security.protocol.map=CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT

# Storage
log.dirs=/var/lib/kafka/data

# Single-node replication factors
offsets.topic.replication.factor=1
transaction.state.log.replication.factor=1
transaction.state.log.min.isr=1
group.initial.rebalance.delay.ms=0

# Retention
log.retention.hours=168
CONFIG

    kafka-storage format \
      -t "$CLUSTER_ID" \
      -c /etc/kafka/kraft/server.properties \
      --ignore-formatted

    systemctl enable confluent-kafka
    systemctl start confluent-kafka
    sleep 30

    # ── Schema Registry ──────────────────────────────────────
    cat > /etc/schema-registry/schema-registry.properties <<CONFIG
listeners=http://0.0.0.0:8081
kafkastore.bootstrap.servers=PLAINTEXT://localhost:9092
host.name=$${PRIVATE_IP}
CONFIG

    systemctl enable confluent-schema-registry
    systemctl start confluent-schema-registry
    sleep 10

    # ── Kafka Connect ─────────────────────────────────────────
    cat > /etc/kafka/connect-distributed.properties <<CONFIG
bootstrap.servers=$${PRIVATE_IP}:9092
group.id=connect-cluster

# JSON converters (Debezium will produce JSON; Iceberg sink reads JSON)
key.converter=org.apache.kafka.connect.json.JsonConverter
value.converter=org.apache.kafka.connect.json.JsonConverter
key.converter.schemas.enable=true
value.converter.schemas.enable=true

# Internal topics
offset.storage.topic=connect-offsets
offset.storage.replication.factor=1
config.storage.topic=connect-configs
config.storage.replication.factor=1
status.storage.topic=connect-status
status.storage.replication.factor=1

# Plugin directories (includes iceberg connector)
plugin.path=/usr/share/java,/usr/share/confluent-hub-components

# REST API
rest.host.name=0.0.0.0
rest.port=8083
rest.advertised.host.name=$${PRIVATE_IP}
rest.advertised.port=8083

# Schema Registry integration
key.converter.schema.registry.url=http://localhost:8081
value.converter.schema.registry.url=http://localhost:8081
CONFIG

    systemctl enable confluent-kafka-connect
    systemctl start confluent-kafka-connect
    sleep 20

    # ── Control Center ────────────────────────────────────────
    cat > /etc/confluent-control-center/control-center-production.properties <<CONFIG
bootstrap.servers=$${PRIVATE_IP}:9092
confluent.controlcenter.data.dir=/var/lib/confluent-control-center
confluent.controlcenter.id=1
confluent.controlcenter.connect.connect-default.cluster=http://localhost:8083
confluent.controlcenter.schema.registry.url=http://localhost:8081
confluent.controlcenter.streams.num.stream.threads=2
confluent.controlcenter.internal.topics.replication=1
confluent.controlcenter.command.topic.replication=1
confluent.metrics.topic.replication=1
confluent.monitoring.interceptor.topic.replication=1
listeners=http://0.0.0.0:9021
CONFIG

    systemctl enable confluent-control-center
    systemctl start confluent-control-center
    sleep 30

    # ── Create cdc.orders topic ───────────────────────────────
    kafka-topics --bootstrap-server localhost:9092 \
      --create \
      --if-not-exists \
      --topic cdc.orders \
      --partitions 1 \
      --replication-factor 1

    echo "✅ Confluent Platform setup complete!" >> /var/log/user-data.log
  EOF

  root_block_device {
    volume_size = 30
    volume_type = "gp3"

    tags = {
      Name = "${var.name_prefix}-kafka-root-volume"
    }
  }

  tags = {
    Name = "${var.name_prefix}-kafka-ec2"
    Role = "confluent-platform"
  }
}
