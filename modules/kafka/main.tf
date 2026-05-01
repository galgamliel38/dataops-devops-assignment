resource "aws_instance" "kafka" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    set -e

    apt-get update -y
    apt-get install -y curl gnupg software-properties-common openjdk-17-jdk

    curl -fsSL https://packages.confluent.io/deb/8.0/archive.key | gpg --dearmor -o /usr/share/keyrings/confluent-archive-keyring.gpg

    echo "deb [signed-by=/usr/share/keyrings/confluent-archive-keyring.gpg] https://packages.confluent.io/deb/8.0 stable main" > /etc/apt/sources.list.d/confluent.list
    echo "deb [signed-by=/usr/share/keyrings/confluent-archive-keyring.gpg] https://packages.confluent.io/clients/deb $(lsb_release -cs) main" >> /etc/apt/sources.list.d/confluent.list

    apt-get update -y
    apt-get install -y confluent-platform confluent-control-center confluent-hub-client
    
    # Install Debezium PostgreSQL connector
    confluent-hub install --no-prompt debezium/debezium-connector-postgresql:latest

    # Prepare directory for custom Iceberg connector
    mkdir -p /usr/share/confluent-hub-components/iceberg-kafka-connect

    # Basic single-node Kafka KRaft configuration
    CLUSTER_ID=$(kafka-storage random-uuid)

    cat > /etc/kafka/kraft/server.properties <<CONFIG
process.roles=broker,controller
node.id=1
controller.quorum.voters=1@localhost:9093
listeners=PLAINTEXT://0.0.0.0:9092,CONTROLLER://localhost:9093
advertised.listeners=PLAINTEXT://localhost:9092
controller.listener.names=CONTROLLER
listener.security.protocol.map=CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT
log.dirs=/var/lib/kafka/data
offsets.topic.replication.factor=1
transaction.state.log.replication.factor=1
transaction.state.log.min.isr=1
group.initial.rebalance.delay.ms=0
CONFIG

    kafka-storage format -t "$CLUSTER_ID" -c /etc/kafka/kraft/server.properties --ignore-formatted

    systemctl enable confluent-kafka
    systemctl start confluent-kafka

    sleep 30

    # Schema Registry
    cat > /etc/schema-registry/schema-registry.properties <<CONFIG
listeners=http://0.0.0.0:8081
kafkastore.bootstrap.servers=PLAINTEXT://localhost:9092
host.name=localhost
CONFIG

    systemctl enable confluent-schema-registry
    systemctl start confluent-schema-registry

    # Kafka Connect
    cat > /etc/kafka/connect-distributed.properties <<CONFIG
bootstrap.servers=localhost:9092
group.id=connect-cluster
key.converter=org.apache.kafka.connect.json.JsonConverter
value.converter=org.apache.kafka.connect.json.JsonConverter
key.converter.schemas.enable=false
value.converter.schemas.enable=false
offset.storage.topic=connect-offsets
offset.storage.replication.factor=1
config.storage.topic=connect-configs
config.storage.replication.factor=1
status.storage.topic=connect-status
status.storage.replication.factor=1
plugin.path=/usr/share/java,/usr/share/confluent-hub-components
rest.host.name=0.0.0.0
rest.port=8083
CONFIG

    systemctl enable confluent-kafka-connect
    systemctl start confluent-kafka-connect

    # Control Center
    cat > /etc/confluent-control-center/control-center-production.properties <<CONFIG
bootstrap.servers=localhost:9092
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

    sleep 20

    kafka-topics --bootstrap-server localhost:9092 \
      --create \
      --if-not-exists \
      --topic cdc.orders \
      --partitions 1 \
      --replication-factor 1

  EOF

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.name_prefix}-kafka-ec2"
    Role = "confluent-platform"
  }
}