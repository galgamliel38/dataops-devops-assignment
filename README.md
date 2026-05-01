# DataOps DevOps Engineer Home Assignment

## Overview

This repository contains an end-to-end AWS data pipeline provisioned with Terraform.

Expected flow:

PostgreSQL (CDC Source) → Confluent Platform Kafka → AWS S3 Tables (Iceberg)

The goal of this assignment is to demonstrate infrastructure provisioning, data integration, CDC streaming, and modern table storage on AWS.

---

# Architecture

## Infrastructure

Provisioned entirely with Terraform:

- VPC
- Public subnet
- Internet gateway
- Route table
- Security groups
- EC2 instance for PostgreSQL
- EC2 instance for Confluent Platform
- AWS S3 Tables bucket / namespace / Iceberg table

## Compute

### PostgreSQL EC2

Used as transactional source database.

Includes:

- ordersdb database
- orders table
- logical replication enabled
- Debezium user

### Kafka EC2

Confluent Platform components:

- Kafka Broker
- Schema Registry
- Kafka Connect
- Control Center

Kafka Topic:

cdc.orders

---

# Terraform Structure

```text
modules/
├── networking
├── database
├── kafka
└── s3tables