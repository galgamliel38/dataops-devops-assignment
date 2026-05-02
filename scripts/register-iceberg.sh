#!/bin/bash
# ============================================================
# register-iceberg.sh
# Registers the Iceberg Sink connector via REST API
# Usage: ./register-iceberg.sh <KAFKA_PUBLIC_IP> <AWS_REGION>
# ============================================================

set -euo pipefail

KAFKA_HOST=${1:?Usage: $0 <KAFKA_PUBLIC_IP> <AWS_REGION>}
AWS_REGION=${2:?Usage: $0 <KAFKA_PUBLIC_IP> <AWS_REGION>}
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

CONNECTOR_JSON=$(sed "s/REPLACE_WITH_AWS_REGION/${AWS_REGION}/g" \
  "$(dirname "$0")/../connectors/iceberg-sink.json")

echo "🚀 Registering Iceberg Sink connector..."
curl -sf -X POST "${CONNECT_URL}/connectors" \
  -H "Content-Type: application/json" \
  --data "$CONNECTOR_JSON" | jq .

echo ""
echo "✅ Iceberg Sink connector registered. Check status:"
echo "   curl ${CONNECT_URL}/connectors/iceberg-orders-sink/status | jq ."
