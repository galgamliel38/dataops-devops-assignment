# DataOps DevOps Assignment

## Overview

This project provisions a DataOps infrastructure on AWS using Terraform.

The goal is to demonstrate an end-to-end data pipeline:

```text
PostgreSQL (CDC Source) → Kafka / Confluent → AWS S3 Tables (Iceberg)

The infrastructure is fully defined as code and organized into Terraform modules.

Architecture

The project includes:

AWS VPC and networking
EC2 instance for PostgreSQL
EC2 instance for Kafka / Confluent
Security Groups with restricted access
S3 Tables bucket and Iceberg table
Connector configuration files
Test scripts
Screenshots of the deployed infrastructure

Project Structure.
├── connectors
├── modules
│   ├── networking
│   ├── database
│   ├── kafka
│   └── s3tables
├── scripts
├── screenshots
├── main.tf
├── providers.tf
├── variables.tf
├── outputs.tf
└── README.md

Terraform Modules
networking

Creates:

VPC
Public subnet
Internet Gateway
Route Table
Security Groups
database

Creates a PostgreSQL EC2 instance and configures it as a CDC source.

Includes:

PostgreSQL installation
ordersdb database
orders table
Debezium user
Logical replication settings
kafka

Creates a Kafka / Confluent EC2 instance.

Includes:

Kafka Broker
Schema Registry
Kafka Connect
Control Center
Kafka topic: cdc.orders
s3tables

Creates the S3 Tables target layer.

Includes:

S3 Tables bucket
Namespace: cdc
Iceberg table: orders

Security

Security Groups are configured with limited inbound access.

Administrative access and UI access are restricted to a specific public IP using /32.

No AWS credentials are stored in the repository.

The following files are intentionally excluded from Git:
terraform.tfvars
terraform.tfstate
terraform.tfstate.backup
*.pem
.terraform/

How to Deploy
Prerequisites
Terraform installed
AWS CLI configured
AWS credentials available locally
Existing EC2 Key Pair
Valid public IP configured in terraform.tfvars
Commands
terraform init
terraform validate
terraform plan
terraform apply

To destroy the infrastructure:
terraform destroy

CDC Flow

Expected flow:
PostgreSQL orders table
        ↓
Debezium PostgreSQL Connector
        ↓
Kafka topic: cdc.orders
        ↓
Iceberg Sink Connector
        ↓
AWS S3 Tables / Iceberg orders table

Connector configuration files are located under:
connectors/

Test SQL script is located under:
scripts/test-cdc.sql

Screenshots
Terraform Apply Outputs
EC2 Instances
Security Group Rules

Cost Considerations

To reduce costs:

Used small EC2 instance types
Used a single AWS region
Avoided NAT Gateway
Destroyed infrastructure after testing

Notes

Confluent Control Center may take additional time to become available on small EC2 instances such as t3.micro.

For a production-grade setup, I would improve the architecture by adding:

Private subnets
IAM roles for EC2
Remote Terraform state in S3 with locking
CloudWatch alarms
Larger Kafka instance type
More complete connector validation
Dedicated IAM user/role instead of root credentials