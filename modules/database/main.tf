resource "aws_instance" "postgres" {
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
    apt-get install -y postgresql postgresql-contrib

    systemctl enable postgresql
    systemctl start postgresql

    # Enable PostgreSQL CDC settings
    echo "wal_level = logical" >> /etc/postgresql/*/main/postgresql.conf
    echo "max_wal_senders = 10" >> /etc/postgresql/*/main/postgresql.conf
    echo "max_replication_slots = 10" >> /etc/postgresql/*/main/postgresql.conf

    # Allow PostgreSQL to listen on all interfaces inside the VPC
    echo "listen_addresses = '*'" >> /etc/postgresql/*/main/postgresql.conf

    # Allow VPC internal access
    echo "host all all 10.0.0.0/16 md5" >> /etc/postgresql/*/main/pg_hba.conf
    echo "host replication debezium 10.0.0.0/16 md5" >> /etc/postgresql/*/main/pg_hba.conf

    systemctl restart postgresql

    sudo -u postgres psql <<SQL
    CREATE USER debezium WITH PASSWORD 'debezium_password' REPLICATION LOGIN;
    CREATE DATABASE ordersdb;
SQL

    sudo -u postgres psql -d ordersdb <<SQL
    CREATE TABLE IF NOT EXISTS orders (
      id SERIAL PRIMARY KEY,
      customer_name TEXT NOT NULL,
      amount NUMERIC(10,2) NOT NULL,
      status TEXT NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    ALTER TABLE orders REPLICA IDENTITY FULL;

    INSERT INTO orders (customer_name, amount, status)
    VALUES
      ('Gal Azulay', 199.90, 'created'),
      ('Test Customer', 349.50, 'created');
SQL

  EOF

  tags = {
    Name = "${var.name_prefix}-postgres-ec2"
    Role = "cdc-source-database"
  }
}