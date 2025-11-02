#!/bin/bash

# Complete Oracle Sharding Setup Script
# This script sets up the sharding infrastructure for the bank transaction system
# Usage: ./scripts/setup-sharding.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SQL_DIR="$PROJECT_DIR/sql/sharding"

# Load environment variables
if [ -f "$PROJECT_DIR/.env" ]; then
    export $(cat "$PROJECT_DIR/.env" | grep -v '^#' | xargs)
else
    export ORACLE_PWD=${ORACLE_PWD:-"tuPDqNJWLr7QcA"}
    export BANK_APP_PASSWORD=${BANK_APP_PASSWORD:-"BankAppPass123"}
    export SHARD_CATALOG_PASSWORD=${SHARD_CATALOG_PASSWORD:-"CatalogPass123"}
fi

echo "========================================="
echo "Oracle Sharding Setup for Bank System"
echo "========================================="
echo ""

# Check if Docker containers are running
echo "Checking Docker containers..."
if ! docker ps | grep -q oracle-catalog; then
    echo "❌ Catalog container is not running!"
    echo "Please start containers first: docker-compose -f docker-compose-sharding.yml up -d"
    exit 1
fi

if ! docker ps | grep -q oracle-shard1; then
    echo "❌ Shard containers are not running!"
    echo "Please start containers first: docker-compose -f docker-compose-sharding.yml up -d"
    exit 1
fi

echo "✅ Containers are running"
echo ""

# Wait for databases to be ready
echo "Waiting for databases to initialize (this may take a few minutes)..."
sleep 30

# Function to wait for database ready
wait_for_db() {
    local container=$1
    local max_attempts=60
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if docker exec $container sqlplus -s /nolog <<EOF > /dev/null 2>&1
connect sys/${ORACLE_PWD}@FREEPDB1 as sysdba
SELECT 'READY' FROM DUAL;
EXIT;
EOF
        then
            return 0
        fi
        echo "Waiting for $container to be ready... (attempt $attempt/$max_attempts)"
        sleep 10
        attempt=$((attempt + 1))
    done
    
    echo "❌ $container did not become ready in time"
    return 1
}

echo "Checking database readiness..."
wait_for_db oracle-catalog || exit 1
wait_for_db oracle-shard1 || exit 1
wait_for_db oracle-shard2 || exit 1
wait_for_db oracle-shard3 || exit 1

echo "✅ All databases are ready"
echo ""

# Setup Catalog Database
echo "========================================="
echo "Step 1: Setting up Catalog Database"
echo "========================================="

echo "Enabling sharding..."
docker exec -i oracle-catalog sqlplus sys/${ORACLE_PWD}@FREEPDB1 as sysdba < "$SQL_DIR/01-enable-sharding.sql"

echo "Creating shard catalog user..."
docker exec -i oracle-catalog sqlplus sys/${ORACLE_PWD}@FREEPDB1 as sysdba < "$SQL_DIR/02-create-shard-catalog-user.sql"

echo "Creating bank app user..."
docker exec -i oracle-catalog sqlplus sys/${ORACLE_PWD}@FREEPDB1 as sysdba < "$SQL_DIR/03-create-bank-app-user.sql"

echo "✅ Catalog database setup complete"
echo ""

# Setup Shard Databases
for shard_num in 1 2 3; do
    echo "========================================="
    echo "Step $((shard_num + 1)): Setting up Shard $shard_num"
    echo "========================================="
    
    echo "Enabling sharding on shard $shard_num..."
    docker exec -i oracle-shard$shard_num sqlplus sys/${ORACLE_PWD}@FREEPDB1 as sysdba < "$SQL_DIR/01-enable-sharding.sql"
    
    echo "Creating bank app user on shard $shard_num..."
    docker exec -i oracle-shard$shard_num sqlplus sys/${ORACLE_PWD}@FREEPDB1 as sysdba < "$SQL_DIR/03-create-bank-app-user.sql"
    
    echo "✅ Shard $shard_num setup complete"
    echo ""
done

# Create Sharded Tables on Catalog
echo "========================================="
echo "Step 5: Creating Sharded Tables"
echo "========================================="

echo "Creating sharded tables on catalog..."
docker exec -i oracle-catalog sqlplus bank_app/${BANK_APP_PASSWORD}@FREEPDB1 < "$SQL_DIR/04-create-sharded-tables.sql"

echo "✅ Sharded tables created"
echo ""

# Insert Sample Data
echo "========================================="
echo "Step 6: Inserting Sample Data"
echo "========================================="

echo "Inserting sample data..."
docker exec -i oracle-catalog sqlplus bank_app/${BANK_APP_PASSWORD}@FREEPDB1 < "$SQL_DIR/05-insert-sample-data.sql"

echo "✅ Sample data inserted"
echo ""

# Create Procedures
echo "========================================="
echo "Step 7: Creating Stored Procedures"
echo "========================================="

echo "Creating procedures..."
docker exec -i oracle-catalog sqlplus bank_app/${BANK_APP_PASSWORD}@FREEPDB1 < "$SQL_DIR/06-create-procedures.sql"

echo "✅ Procedures created"
echo ""

echo "========================================="
echo "✅ Sharding Setup Complete!"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Run use case demonstrations:"
echo "   docker exec -it oracle-catalog sqlplus bank_app/${BANK_APP_PASSWORD}@FREEPDB1 < sql/sharding/07-use-cases.sql"
echo ""
echo "2. Test queries:"
echo "   docker exec -it oracle-catalog sqlplus bank_app/${BANK_APP_PASSWORD}@FREEPDB1"
echo ""
echo "3. Access web interface:"
echo "   Catalog: https://localhost:5500/em"
echo "   Shard 1:  https://localhost:5501/em"
echo "   Shard 2:  https://localhost:5502/em"
echo "   Shard 3:  https://localhost:5503/em"
echo ""

