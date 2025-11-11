#!/bin/bash

# Run Use Case Demonstrations
# Usage: ./scripts/run-use-cases.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SQL_FILE="$PROJECT_DIR/sql/sharding/07-use-cases.sql"

# Load environment variables
if [ -f "$PROJECT_DIR/.env" ]; then
    export $(cat "$PROJECT_DIR/.env" | grep -v '^#' | xargs)
else
    export BANK_APP_PASSWORD=${BANK_APP_PASSWORD:-"BankAppPass123"}
fi

echo "========================================="
echo "Running Oracle Sharding Use Cases"
echo "========================================="
echo ""

if [ ! -f "$SQL_FILE" ]; then
    echo "❌ Use cases file not found: $SQL_FILE"
    exit 1
fi

echo "Executing use case demonstrations..."
echo ""

docker exec -i oracle-catalog sqlplus bank_app/${BANK_APP_PASSWORD}@freepdb1 < "$SQL_FILE"

echo ""
echo "========================================="
echo "✅ Use cases executed!"
echo "========================================="

