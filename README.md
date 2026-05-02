# DataOps DevOps Assignment

## Overview

End-to-end data pipeline infrastructure on AWS, fully provisioned via Terraform:

```
PostgreSQL (CDC) → Confluent Platform (Kafka) → AWS S3 Tables (Iceberg)
```

Changes in the `orders` table are captured by **Debezium**, streamed through **Kafka**, and written to an **Iceberg** table in **AWS S3 Tables** via the Iceberg Kafka Connect Sink connector.

---

## Architecture

```
┌─────────────────────────┐        ┌──────────────────────────────────────────┐
│  EC2: PostgreSQL (CDC)  │        │  EC2: Confluent Platform                 │
│                         │  CDC   │                                          │
│  - ordersdb             │──────▶ │  - Kafka Broker (KRaft)                  │
│  - wal_level=logical    │        │  - Schema Registry                       │
│  - Debezium user        │        │  - Kafka Connect                         │
│  - orders table         │        │    ├── Debezium PostgreSQL Source         │
│                         │        │    └── Iceberg Sink (tabular-io)         │
│  t3.micro               │        │  - Control Center (UI: port 9021)        │
└─────────────────────────┘        │                                          │
                                   │  t3.xlarge                               │
                                   └──────────────┬───────────────────────────┘
                                                  │ writes
                                                  ▼
                                   ┌──────────────────────────────┐
                                   │  AWS S3 Tables (Iceberg)     │
                                   │  namespace: cdc              │
                                   │  table:     orders           │
                                   │  schema: id, customer_name,  │
                                   │    amount, status,           │
                                   │    created_at, __op,         │
                                   │    __source_ts_ms            │
                                   └──────────────────────────────┘
```

### Terraform Module Structure

```
├── bootstrap/                      # Run ONCE to create the S3 state bucket
│   └── main.tf
├── main.tf                         # Root — wires all modules
├── providers.tf                    # AWS provider + S3 backend
├── variables.tf
├── outputs.tf
├── modules/
│   ├── networking/                 # VPC, subnet, IGW, security groups
│   ├── database/                   # PostgreSQL EC2 (CDC source)
│   ├── kafka/                      # Confluent EC2 + IAM role
│   └── s3tables/                   # S3 Table Bucket + Iceberg table (with schema)
├── connectors/
│   ├── debezium-postgres.json      # Debezium CDC source config
│   └── iceberg-sink.json           # Iceberg Sink connector config
└── scripts/
    ├── register-debezium.sh
    ├── register-iceberg.sh
    └── test-cdc.sql
```

---

## Deploy from Scratch

### Step 1 — Create the Terraform state bucket (bootstrap)

This runs once and creates the S3 bucket used for remote state.

```bash
cd bootstrap/
terraform init
terraform apply
# Output: state_bucket_name = "dataops-devops-tfstate-123456789012"
```

Copy the output bucket name into `providers.tf`:

```hcl
backend "s3" {
  bucket = "dataops-devops-tfstate-123456789012"   # ← paste here
  ...
}
```

### Step 2 — Create `terraform.tfvars`

```hcl
aws_region             = "eu-west-1"
my_ip_cidr             = "YOUR_PUBLIC_IP/32"
ec2_key_name           = "YOUR_KEY_PAIR_NAME"
database_instance_type = "t3.micro"
kafka_instance_type    = "t3.xlarge"
```

### Step 3 — Deploy

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

**Expected outputs after apply:**

```
database_private_ip        = "10.0.1.x"
database_public_ip         = "x.x.x.x"
kafka_public_ip            = "x.x.x.x"
control_center_url         = "http://x.x.x.x:9021"
kafka_connect_url          = "http://x.x.x.x:8083"
s3tables_table_bucket_name = "dataops-devops-home-assignment-table-bucket"
orders_iceberg_table_arn   = "arn:aws:s3tables:..."
```

---

## Testing the CDC Flow End-to-End

### Step 1 — Wait for Confluent to finish starting (~8 min)

```bash
ssh -i YOUR_KEY.pem ubuntu@<kafka_public_ip>
sudo tail -f /var/log/user-data.log
# Wait for: ✅ Confluent Platform setup complete!
```

### Step 2 — Register Debezium connector

```bash
./scripts/register-debezium.sh <kafka_public_ip> <db_private_ip>

# Verify RUNNING:
curl http://<kafka_public_ip>:8083/connectors/postgres-orders-cdc/status | jq .
```

### Step 3 — Register Iceberg Sink connector

```bash
./scripts/register-iceberg.sh <kafka_public_ip> eu-west-1

# Verify RUNNING:
curl http://<kafka_public_ip>:8083/connectors/iceberg-orders-sink/status | jq .
```

### Step 4 — Trigger CDC events

```bash
psql -h <db_public_ip> -U debezium -d ordersdb -f scripts/test-cdc.sql
```

This produces INSERT (op=c), UPDATE (op=u), and DELETE (op=d) events on `cdc.orders`.

### Step 5 — Verify in Confluent Control Center

Open `http://<kafka_public_ip>:9021` → Topics → cdc.orders → Messages.
**Take a screenshot** — required deliverable.

### Step 6 — Verify data in S3 Tables via Athena

```sql
SELECT id, customer_name, amount, status, __op, __source_ts_ms
FROM "cdc"."orders"
ORDER BY __source_ts_ms DESC
LIMIT 20;
```

**Take a screenshot of results** — required deliverable.

---

## Security Design Decisions

| Decision | Rationale |
|----------|-----------|
| IAM Role on Kafka EC2 | No hardcoded AWS credentials; Iceberg connector uses instance profile to call S3 Tables APIs |
| Security groups with `/32` CIDR | SSH and UI restricted to operator IP only |
| PostgreSQL port 5432 only from Kafka SG | Database not reachable from internet |
| Kafka broker port 9092 open within VPC CIDR | Allows Debezium (on DB EC2) to reach Kafka across internal network |
| S3 state bucket versioning + encryption | State file protected and recoverable |
| `use_lockfile = true` in backend | Native S3 locking, no DynamoDB needed |
| No NAT Gateway | Cost reduction; both instances have public IPs (acceptable for assignment scope) |

---

## Bonus: Schema Evolution

With `iceberg.tables.evolve-schema-enabled: true` in the Iceberg Sink, the table automatically evolves when you add columns:

```sql
ALTER TABLE orders ADD COLUMN discount NUMERIC(5,2) DEFAULT 0.00;

INSERT INTO orders (customer_name, amount, status, discount)
VALUES ('Schema Test', 299.00, 'created', 15.00);
```

Query in Athena — the `discount` column appears automatically in the Iceberg table.

---

## Tear Down

```bash
terraform destroy
cd bootstrap/ && terraform destroy   # only if you also want to remove the state bucket
```

---

## Screenshots

See `screenshots/` directory:
- `01-terraform-apply-outputs.png`
- `02-ec2-instances.png`
- `03-security-group.png`
