# ============================================================
# Database Module
# Provisions EC2 with PostgreSQL configured as CDC source
# ============================================================

resource "aws_instance" "postgres" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail
    exec > /var/log/user-data.log 2>&1

    # ── Install PostgreSQL ────────────────────────────────────
    apt-get update -y
    apt-get install -y postgresql postgresql-contrib

    systemctl enable postgresql
    systemctl start postgresql

    # ── CDC configuration (logical replication) ───────────────
    # wal_level=logical is required for Debezium CDC
    PG_CONF=$(find /etc/postgresql -name "postgresql.conf" | head -1)
    PG_HBA=$(find /etc/postgresql -name "pg_hba.conf" | head -1)

    echo "wal_level = logical"           >> "$PG_CONF"
    echo "max_wal_senders = 10"          >> "$PG_CONF"
    echo "max_replication_slots = 10"    >> "$PG_CONF"
    echo "listen_addresses = '*'"        >> "$PG_CONF"

    # Allow VPC internal access (Kafka Connect / Debezium)
    echo "host all             all          10.0.0.0/16  md5"       >> "$PG_HBA"
    echo "host replication     debezium     10.0.0.0/16  md5"       >> "$PG_HBA"

    systemctl restart postgresql

    # ── Create Debezium user, database and orders table ───────
    sudo -u postgres psql <<SQL
      CREATE USER debezium WITH PASSWORD 'debezium_password' REPLICATION LOGIN;
      CREATE DATABASE ordersdb;
      GRANT ALL PRIVILEGES ON DATABASE ordersdb TO debezium;
SQL

    sudo -u postgres psql -d ordersdb <<SQL
      -- Grant schema usage to debezium
      GRANT USAGE ON SCHEMA public TO debezium;
      GRANT SELECT ON ALL TABLES IN SCHEMA public TO debezium;
      ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO debezium;

      -- Orders table: matches required Iceberg schema + CDC metadata columns
      CREATE TABLE IF NOT EXISTS orders (
        id            SERIAL PRIMARY KEY,
        customer_name TEXT           NOT NULL,
        amount        NUMERIC(10,2)  NOT NULL,
        status        TEXT           NOT NULL,
        created_at    TIMESTAMP      DEFAULT CURRENT_TIMESTAMP
      );

      -- REPLICA IDENTITY FULL ensures UPDATE/DELETE events carry full row data
      ALTER TABLE orders REPLICA IDENTITY FULL;

      -- Seed data for initial testing
      INSERT INTO orders (customer_name, amount, status) VALUES
        ('Gal Gamliel',    199.90, 'created'),
        ('Test Customer',  349.50, 'created'),
        ('Alice Cohen',    750.00, 'pending');
SQL

    echo "✅ PostgreSQL CDC setup complete!" >> /var/log/user-data.log
  EOF

  root_block_device {
    volume_size = 20
    volume_type = "gp3"

    tags = {
      Name = "${var.name_prefix}-postgres-root-volume"
    }
  }

  tags = {
    Name = "${var.name_prefix}-postgres-ec2"
    Role = "cdc-source-database"
  }
}
