#!/bin/bash

# Test Oracle Sharding Setup
# Usage: ./scripts/test-sharding.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Load environment variables
if [ -f "$PROJECT_DIR/.env" ]; then
    export $(cat "$PROJECT_DIR/.env" | grep -v '^#' | xargs)
else
    export ORACLE_PWD=${ORACLE_PWD:-"tuPDqNJWLr7QcA"}
    export BANK_APP_PASSWORD=${BANK_APP_PASSWORD:-"BankAppPass123"}
fi

echo "========================================="
echo "Oracle Sharding Test"
echo "========================================="
echo ""

# Test 1: Check containers
echo "Test 1: Checking containers..."
if docker ps | grep -q oracle-catalog && \
   docker ps | grep -q oracle-shard1 && \
   docker ps | grep -q oracle-shard2 && \
   docker ps | grep -q oracle-shard3; then
    echo "✅ All containers are running"
else
    echo "❌ Some containers are not running"
    docker ps | grep oracle-
    exit 1
fi
echo ""

# Test 2: Check database connections
echo "Test 2: Testing database connections..."

test_connection() {
    local container=$1
    if docker exec $container sqlplus -s /nolog <<EOF > /dev/null 2>&1
connect sys/${ORACLE_PWD}@freepdb1 as sysdba
SELECT 'CONNECTED' FROM DUAL;
EXIT;
EOF
    then
        echo "✅ $container: Connected"
        return 0
    else
        echo "❌ $container: Connection failed"
        return 1
    fi
}

test_connection oracle-catalog
test_connection oracle-shard1
test_connection oracle-shard2
test_connection oracle-shard3
echo ""

# Test 3: Check sharded tables exist
echo "Test 3: Checking sharded tables..."
if docker exec oracle-catalog sqlplus -s bank_app/${BANK_APP_PASSWORD}@freepdb1 <<EOF | grep -q "USERS\|ACCOUNTS\|TRANSACTIONS"
SELECT table_name FROM user_tables WHERE table_name IN ('USERS', 'ACCOUNTS', 'TRANSACTIONS');
EXIT;
EOF
then
    echo "✅ Sharded tables exist"
else
    echo "❌ Sharded tables not found"
    exit 1
fi
echo ""

# Test 4: Test queries
echo "Test 4: Testing sharded queries..."

echo "Querying accounts table..."
docker exec -i oracle-catalog sqlplus bank_app/${BANK_APP_PASSWORD}@freepdb1 <<'EOF'
SET PAGESIZE 20
SELECT COUNT(*) AS account_count FROM accounts;
SELECT region, COUNT(*) AS count, SUM(balance) AS total_balance 
FROM accounts 
GROUP BY region;
EXIT;
EOF

echo ""
echo "========================================="
echo "✅ All tests passed!"
echo "========================================="

