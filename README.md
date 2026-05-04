DataOps DevOps Assignment – End-to-End CDC Pipeline
Overview
This project implements an end-to-end CDC (Change Data Capture) pipeline:

PostgreSQL → Debezium → Kafka → Iceberg Sink Connector → AWS S3 Tables

The platform is executed locally using WSL and Docker, while PostgreSQL and S3 Tables are hosted on AWS.

Architecture
PostgreSQL on AWS EC2
↓
Debezium PostgreSQL Connector
↓
Kafka Topic: cdc.public.orders
↓
Iceberg Sink Connector
↓
AWS S3 Tables

Technologies Used
Terraform
AWS EC2
AWS S3 Tables
PostgreSQL
Docker / Docker Compose
Apache Kafka
Kafka Connect
Debezium
Iceberg Sink Connector
WSL2
Project Structure
.
├── docker-compose.yml
├── debezium.json
├── connectors/
│   └── iceberg-sink.json
├── scripts/
├── modules/
│   ├── database/
│   ├── kafka/
│   ├── networking/
│   └── s3tables/
├── screenshots/
└── README.md


Prerequisites

Before running the project, make sure you have:

WSL2
Docker
Docker Compose
PostgreSQL client (psql)
AWS infrastructure created with Terraform
AWS credentials available locally for the Iceberg connector

Do not commit real AWS credentials to Git.

AWS Infrastructure

Terraform provisions:

PostgreSQL EC2 instance
Networking and security groups
S3 Tables bucket
Iceberg table
IAM role configuration

Run from the project root:

terraform init
terraform apply

After apply, note the PostgreSQL public IP and update it inside:

debezium.json

Example:

"database.hostname": "POSTGRES_PUBLIC_IP"
PostgreSQL Configuration

PostgreSQL must be configured for logical replication.

On the PostgreSQL EC2 instance, edit:

sudo nano /etc/postgresql/14/main/postgresql.conf

Set:

listen_addresses = '*'
wal_level = logical
max_replication_slots = 10
max_wal_senders = 10

Then edit:

sudo nano /etc/postgresql/14/main/pg_hba.conf

Add:

host    all             all             0.0.0.0/0               md5

Restart PostgreSQL:

sudo systemctl restart postgresql

Create the orders table:

sudo -u postgres psql
CREATE TABLE public.orders (
    id SERIAL PRIMARY KEY,
    customer_name TEXT,
    amount NUMERIC,
    status TEXT,
    created_at TIMESTAMP
);
Local Runtime Setup

The Kafka platform runs locally in WSL.

Start the stack:

sudo docker-compose up -d

Verify containers:

sudo docker ps

Expected containers:

galga_zookeeper_1
galga_kafka_1
galga_connect_1
Verify Kafka Connect
curl localhost:8083/connectors

At first, the result can be empty:

[]
Register Debezium Connector
curl -X POST http://localhost:8083/connectors \
-H "Content-Type: application/json" \
--data @debezium.json

Check status:

curl localhost:8083/connectors/postgres-connector/status | jq .

Expected:

"state": "RUNNING"
Verify Iceberg Plugin
curl localhost:8083/connector-plugins | grep -i iceberg

Expected class:

io.tabular.iceberg.connect.IcebergSinkConnector
Register Iceberg Sink Connector
curl -X POST http://localhost:8083/connectors \
-H "Content-Type: application/json" \
--data @connectors/iceberg-sink.json

Check status:

curl localhost:8083/connectors/iceberg-orders-sink/status | jq .

Expected connector state:

"state": "RUNNING"
Insert Test Data

On the PostgreSQL EC2 instance:

sudo -u postgres psql
INSERT INTO public.orders (customer_name, amount, status, created_at)
VALUES ('FINAL_SUCCESS', 999, 'created', NOW());
Verify CDC Events in Kafka

From WSL:

sudo docker exec -it galga_kafka_1 kafka-console-consumer \
--bootstrap-server localhost:9092 \
--topic cdc.public.orders \
--from-beginning \
--timeout-ms 10000

Expected output should include:

FINAL_SUCCESS

or:

LIVE_TEST_AFTER_RESTART

The Debezium event includes:

"op": "c"

Where:

c = create / insert
u = update
d = delete
r = snapshot read
Validation Screenshots

Screenshots are included under the screenshots/ directory.

Recommended screenshots:

debezium-connector-running.png
iceberg-connector-running.png
iceberg-plugin-loaded.png
kafka-topic-list.png
kafka-cdc-events-debezium.png
postgres-insert-success.png
Security Notes

AWS credentials are not hardcoded in the source code.

For local execution, credentials can be passed into the Kafka Connect container using environment variables.

The .env file should not be committed to Git.

Example .gitignore entry:

.env

In a production environment, the preferred approach would be IAM Roles instead of static access keys.

Key Learnings

This project demonstrates:

CDC using Debezium
PostgreSQL logical replication
Kafka as a streaming buffer
Kafka Connect plugin management
Iceberg Sink Connector setup
S3 Tables integration
Debugging networking, replication, credentials, and connector issues
Final Result

The project successfully validates a CDC flow from PostgreSQL into Kafka and runs the Iceberg Sink Connector for writing into AWS S3 Tables.

Validated flow:

PostgreSQL → Debezium → Kafka → Iceberg → S3 Tables
