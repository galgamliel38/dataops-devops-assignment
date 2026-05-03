# DataOps DevOps Assignment

## Overview

End-to-end CDC data pipeline infrastructure:

```
PostgreSQL (CDC) → Kafka Connect → AWS S3 Tables (Iceberg)
```

Changes in the `orders` table are captured by **Debezium**, streamed through **Kafka**, and written to an **Iceberg** table in **AWS S3 Tables**.

---

## Architecture

```
┌─────────────────────────┐        ┌──────────────────────────────────────┐
│  EC2: PostgreSQL        │        │  Local Docker (WSL2)                 │
│  AWS eu-west-1          │  CDC   │                                      │
│  - ordersdb             │──────▶ │  - Kafka Broker (KRaft)              │
│  - wal_level=logical    │        │  - Schema Registry                   │
│  - orders table         │        │  - Kafka Connect                     │
│  - pgoutput plugin      │        │    ├── Debezium PostgreSQL Source    │
│  - publication: dbz_pub │        │    └── Iceberg Sink (tabular-io)    │
│                         │        │                                      │
│  t3.micro               │        │  REST API: localhost:8083            │
└─────────────────────────┘        └──────────────┬───────────────────────┘
                                                  │ writes
                                                  ▼
                                   ┌──────────────────────────────┐
                                   │  AWS S3 Tables (Iceberg)     │
                                   │  namespace: cdc              │
                                   │  table:     orders           │
                                   │  cols: id, customer_name,    │
                                   │    amount, status,           │
                                   │    created_at, __op,         │
                                   │    __source_ts_ms            │
                                   └──────────────────────────────┘
```

### Design Decision — Local Kafka

Confluent Platform requires ~4GB RAM. AWS Free Tier instances (t3.micro/t3.small) do not provide enough memory to run Broker + Schema Registry + Connect + Control Center simultaneously.

Following the interviewer's suggestion, Kafka and Kafka Connect run locally via Docker (WSL2) while PostgreSQL and S3 Tables remain on AWS. This matches option 2 from the interviewer: *"run locally with connectivity to SQL and S3 Tables on AWS"*.

### Terraform Module Structure

```
├── bootstrap/                   # Run ONCE — creates S3 state bucket
├── main.tf                      # Root — wires all modules
├── providers.tf                 # AWS provider + S3 backend
├── variables.tf
├── outputs.tf
├── modules/
│   ├── networking/              # VPC, subnet, IGW, security groups
│   ├── database/                # PostgreSQL EC2 (CDC source)
│   ├── kafka/                   # EC2 + IAM role (Confluent commented out)
│   └── s3tables/                # S3 Table Bucket + Iceberg table
├── connectors/
│   ├── debezium-postgres.json
│   └── iceberg-sink.json
├── local-setup/
│   └── docker-compose.yml       # Local Kafka stack
└── scripts/
    ├── register-debezium.sh
    ├── register-iceberg.sh
    └── test-cdc.sql
```

---

## Deploy from Scratch

### Prerequisites

- Terraform >= 1.10.0
- AWS CLI configured (`aws configure`)
- Docker + WSL2 (Windows) or Docker Desktop (Mac/Linux)
- An existing EC2 Key Pair in the target region

### Step 1 — Create Terraform state bucket (bootstrap)

```bash
cd bootstrap/
terraform init
terraform apply
# Output: state_bucket_name = "dataops-devops-tfstate-ACCOUNTID"
```

Copy the bucket name into `providers.tf` → `backend "s3" { bucket = "..." }`.

### Step 2 — Create `terraform.tfvars`

```hcl
aws_region             = "eu-west-1"
my_ip_cidr             = "YOUR_PUBLIC_IP/32"
ec2_key_name           = "YOUR_KEY_PAIR_NAME"
database_instance_type = "t3.micro"
kafka_instance_type    = "t3.small"
```

### Step 3 — Deploy AWS infrastructure

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

**Expected outputs:**
```
database_public_ip         = "x.x.x.x"
database_private_ip        = "10.0.1.x"
kafka_public_ip            = "x.x.x.x"
s3tables_table_bucket_name = "dataops-devops-home-assignment-table-bucket"
orders_iceberg_table_arn   = "arn:aws:s3tables:..."
```

### Step 4 — Set up PostgreSQL (CDC source)

SSH into the database instance and run:

```bash
sudo apt-get install -y postgresql
sudo -u postgres psql -c "ALTER SYSTEM SET wal_level = logical;"
sudo systemctl restart postgresql
sudo -u postgres psql -c "CREATE USER debezium WITH PASSWORD 'debezium_password' REPLICATION LOGIN SUPERUSER;"
sudo -u postgres psql -c "CREATE DATABASE ordersdb;"
sudo -u postgres psql -d ordersdb -c "
  CREATE TABLE orders (
    id            SERIAL PRIMARY KEY,
    customer_name TEXT NOT NULL,
    amount        NUMERIC(10,2) NOT NULL,
    status        TEXT NOT NULL,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );
  ALTER TABLE orders REPLICA IDENTITY FULL;
  CREATE PUBLICATION dbz_publication FOR TABLE orders;
  INSERT INTO orders (customer_name, amount, status) VALUES
    ('Gal Gamliel', 199.90, 'created'),
    ('Test Customer', 349.50, 'created'),
    ('Alice Cohen', 750.00, 'pending');
"
```

Also open PostgreSQL to external connections:

```bash
PG_CONF=$(find /etc/postgresql -name "postgresql.conf")
echo "listen_addresses = '*'" | sudo tee -a $PG_CONF
echo "host all all 0.0.0.0/0 md5" | sudo tee -a /etc/postgresql/*/main/pg_hba.conf
sudo systemctl restart postgresql
```

### Step 5 — Start local Kafka stack (Docker)

```bash
cd local-setup/
docker-compose up -d

# Install connectors inside the container
docker exec kafka-connect confluent-hub install --no-prompt debezium/debezium-connector-postgresql:2.5.4

# Install Iceberg connector
docker exec kafka-connect bash -c "
  curl -sL 'https://github.com/databricks/iceberg-kafka-connect/releases/download/v0.6.19/iceberg-kafka-connect-runtime-0.6.19.zip' -o /tmp/iceberg.zip
  mkdir -p /usr/share/confluent-hub-components/iceberg-kafka-connect
  cd /usr/share/confluent-hub-components/iceberg-kafka-connect
  jar xf /tmp/iceberg.zip
  echo 'plugin.path=/usr/share/java,/usr/share/confluent-hub-components,/usr/share/confluent-hub-components/iceberg-kafka-connect/iceberg-kafka-connect-runtime-0.6.19' >> /etc/kafka/connect-distributed.properties
"
docker restart kafka-connect
sleep 30
```

---

## Testing the CDC Flow End-to-End

### Step 1 — Register Debezium connector

Replace `DB_PUBLIC_IP` with the database EC2 public IP:

```bash
curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d @connectors/debezium-postgres.json

# Verify RUNNING:
curl http://localhost:8083/connectors/postgres-orders-cdc/status | jq .tasks[0].state
```

### Step 2 — Register Iceberg Sink connector

```bash
curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d @connectors/iceberg-sink.json

# Verify RUNNING:
curl http://localhost:8083/connectors/iceberg-orders-sink/status | jq .tasks[0].state
```

### Step 3 — Trigger CDC events

```bash
psql -h <DB_PUBLIC_IP> -U debezium -d ordersdb -f scripts/test-cdc.sql
```

### Step 4 — Verify data in Kafka topic

```bash
docker exec kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic cdc.public.orders \
  --from-beginning \
  --max-messages 10
```

You will see messages with `__op: "r"` (snapshot), `__op: "c"` (insert), `__op: "u"` (update), `__op: "d"` (delete).

### Step 5 — Verify data in S3 Tables via Athena

```sql
SELECT id, customer_name, amount, status, __op, __source_ts_ms
FROM "cdc"."orders"
ORDER BY __source_ts_ms DESC
LIMIT 10;
```

---

## Security Design Decisions

| Decision | Rationale |
|----------|-----------|
| IAM Role on Kafka EC2 | No hardcoded AWS credentials |
| Security groups with `/32` CIDR | SSH restricted to operator IP only |
| PostgreSQL port 5432 restricted | Only accessible from allowed IPs |
| S3 state bucket with versioning + encryption | State file protected and recoverable |
| `use_lockfile = true` | Native S3 locking, no DynamoDB needed |
| Debezium SUPERUSER | Required to create PostgreSQL publications for CDC |

---

## Screenshots

See `screenshots/` directory:
- `01-terraform-apply-outputs.png`
- `02-ec2-instances.png`
- `03-security-group.png`
- `04-connectors-running.png`
- `05-kafka-cdc-messages-topic.png`
- `06-postgres-insert-and-select.png`
- `07-connectors-running.png`
- `08-kafka-cdc-messages-final.png`
---

## Tear Down

```bash
terraform destroy
cd bootstrap/ && terraform destroy
```
