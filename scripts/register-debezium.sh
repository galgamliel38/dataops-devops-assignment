#!/bin/bash
# ============================================================
# register-debezium.sh
# Registers the Debezium PostgreSQL CDC connector via REST API
# Usage: ./register-debezium.sh <KAFKA_PUBLIC_IP> <DB_PRIVATE_IP>
# ============================================================

set -euo pipefail

KAFKA_HOST=${1:?Usage: $0 <KAFKA_PUBLIC_IP> <DB_PRIVATE_IP>}
DB_PRIVATE_IP=${2:?Usage: $0 <KAFKA_PUBLIC_IP> <DB_PRIVATE_IP>}
CONNECT_URL="http://${KAFKA_HOST}:8083"

echo "⏳ Waiting for Kafka Connect to be ready..."
for i in $(seq 1 20); do
  if curl -sf "${CONNECT_URL}/connectors" > /dev/null 2>&1; then
    echo "✅ Kafka Connect is ready"
    break
  fi
  echo "   attempt $i/20..."
  sleep 10
done

# Inject the DB private IP into the connector config
CONNECTOR_JSON=$(sed "s/REPLACE_WITH_DB_PRIVATE_IP/${DB_PRIVATE_IP}/g" \
  "$(dirname "$0")/../connectors/debezium-postgres.json")

echo "🚀 Registering Debezium connector..."
curl -sf -X POST "${CONNECT_URL}/connectors" \
  -H "Content-Type: application/json" \
  --data "$CONNECTOR_JSON" | jq .

echo ""
echo "✅ Debezium connector registered. Check status:"
echo "   curl ${CONNECT_URL}/connectors/postgres-orders-cdc/status | jq ."
