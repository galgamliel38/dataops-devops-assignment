#!/bin/bash

KAFKA_HOST=$1

curl -X POST http://$KAFKA_HOST:8083/connectors \
  -H "Content-Type: application/json" \
  --data @../connectors/debezium-postgres.json