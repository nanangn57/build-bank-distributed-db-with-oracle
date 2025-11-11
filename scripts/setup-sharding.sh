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
connect sys/${ORACLE_PWD}@freepdb1 as sysdba
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
docker exec -i oracle-catalog sqlplus sys/${ORACLE_PWD}@freepdb1 as sysdba < "$SQL_DIR/01-enable-sharding.sql"

echo "Creating shard catalog user..."
docker exec -i oracle-catalog sqlplus sys/${ORACLE_PWD}@freepdb1 as sysdba < "$SQL_DIR/02-create-shard-catalog-user.sql"

echo "Creating bank app user..."
docker exec -i oracle-catalog sqlplus sys/${ORACLE_PWD}@freepdb1 as sysdba < "$SQL_DIR/03-create-bank-app-user.sql"

echo "✅ Catalog database setup complete"
echo ""

# Setup Shard Databases
for shard_num in 1 2 3; do
    echo "========================================="
    echo "Step $((shard_num + 1)): Setting up Shard $shard_num"
    echo "========================================="
    
    echo "Enabling sharding on shard $shard_num..."
    docker exec -i oracle-shard$shard_num sqlplus sys/${ORACLE_PWD}@freepdb1 as sysdba < "$SQL_DIR/01-enable-sharding.sql"
    
    echo "Creating bank app user on shard $shard_num..."
    docker exec -i oracle-shard$shard_num sqlplus sys/${ORACLE_PWD}@freepdb1 as sysdba < "$SQL_DIR/03-create-bank-app-user.sql"
    
    echo "✅ Shard $shard_num setup complete"
    echo ""
done

# Create Catalog Metadata (Catalog should only have metadata, not application data)
echo "========================================="
echo "Step 5: Creating Catalog Metadata"
echo "========================================="

echo "Creating metadata tables on catalog..."
docker exec -i oracle-catalog sqlplus bank_app/${BANK_APP_PASSWORD}@freepdb1 < "$SQL_DIR/09-create-catalog-metadata.sql"

echo "Ensuring bank_app has CREATE DATABASE LINK privilege on catalog..."
docker exec -i oracle-catalog sqlplus sys/${ORACLE_PWD}@freepdb1 as sysdba <<'EOF'
GRANT CREATE DATABASE LINK TO bank_app;
EXIT;
EOF

echo "Creating database links to shards..."
docker exec -i oracle-catalog sqlplus bank_app/${BANK_APP_PASSWORD}@freepdb1 < "$SQL_DIR/10-create-catalog-database-links.sql"

echo "✅ Catalog metadata and database links created"
echo ""

# Create Sharded Tables on Each Shard
echo "========================================="
echo "Step 6: Creating Sharded Tables on Shards"
echo "========================================="

echo "Creating sharded tables on each shard..."
for shard_num in 1 2 3; do
    echo "Creating tables on shard $shard_num..."
    docker exec -i oracle-shard$shard_num sqlplus bank_app/${BANK_APP_PASSWORD}@freepdb1 < "$SQL_DIR/04-create-sharded-tables.sql"
    echo "✅ Tables created on shard $shard_num"
done

echo ""

# Create Procedures on Each Shard
echo "========================================="
echo "Step 7: Creating Stored Procedures on Shards"
echo "========================================="

echo "Creating procedures on each shard..."
for shard_num in 1 2 3; do
    echo "Creating procedures on shard $shard_num..."
    docker exec -i oracle-shard$shard_num sqlplus bank_app/${BANK_APP_PASSWORD}@freepdb1 < "$SQL_DIR/06-create-procedures.sql"
    echo "✅ Procedures created on shard $shard_num"
done

echo ""

# Insert Sample Data on Correct Shards
echo "========================================="
echo "Step 8: Inserting Sample Data on Shards"
echo "========================================="

echo "Inserting NA region data on Shard 1..."
docker exec -i oracle-shard1 sqlplus bank_app/${BANK_APP_PASSWORD}@freepdb1 < "$SQL_DIR/05-insert-sample-data-na.sql"

echo "Inserting EU region data on Shard 2..."
docker exec -i oracle-shard2 sqlplus bank_app/${BANK_APP_PASSWORD}@freepdb1 < "$SQL_DIR/05-insert-sample-data-eu.sql"

echo "Inserting APAC region data on Shard 3..."
docker exec -i oracle-shard3 sqlplus bank_app/${BANK_APP_PASSWORD}@freepdb1 < "$SQL_DIR/05-insert-sample-data-apac.sql"

echo "✅ Sample data inserted on all shards"
echo ""

echo "========================================="
echo "Step 9: Creating Catalog Views"
echo "========================================="

echo "Creating union views for cross-shard queries..."
docker exec -i oracle-catalog sqlplus bank_app/${BANK_APP_PASSWORD}@freepdb1 < "$SQL_DIR/11-create-catalog-union-views.sql"

echo "Creating dashboard views for statistics..."
docker exec -i oracle-catalog sqlplus bank_app/${BANK_APP_PASSWORD}@freepdb1 < "$SQL_DIR/08-create-dashboard-views.sql"

echo "✅ Catalog views created"
echo ""

echo "========================================="
echo "✅ Sharding Setup Complete!"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Query all shards via catalog (UNION ALL views):"
echo "   docker exec -it oracle-catalog sqlplus bank_app/${BANK_APP_PASSWORD}@freepdb1"
echo "   SELECT * FROM users_all;              # All users from all shards"
echo "   SELECT * FROM accounts_all;           # All accounts from all shards"
echo "   SELECT * FROM transactions_all;       # All transactions from all shards"
echo "   SELECT * FROM account_summary_all;    # Accounts with user details"
echo "   SELECT * FROM regional_stats;        # Aggregated stats by region"
echo ""
echo "2. Run example catalog queries:"
echo "   docker exec -i oracle-catalog sqlplus bank_app/${BANK_APP_PASSWORD}@freepdb1 < sql/sharding/12-example-catalog-queries.sql"
echo ""
echo "3. Query data on specific shards (direct access):"
echo "   docker exec -it oracle-shard1 sqlplus bank_app/${BANK_APP_PASSWORD}@freepdb1  # NA region data"
echo "   docker exec -it oracle-shard2 sqlplus bank_app/${BANK_APP_PASSWORD}@freepdb1  # EU region data"
echo "   docker exec -it oracle-shard3 sqlplus bank_app/${BANK_APP_PASSWORD}@freepdb1  # APAC region data"
echo ""
echo "4. View catalog metadata:"
echo "   SELECT * FROM shard_routing_view;"
echo ""
echo "5. Access web interface:"
echo "   Catalog: https://localhost:5500/em  (metadata + union views)"
echo "   Shard 1:  https://localhost:5501/em (NA region data)"
echo "   Shard 2:  https://localhost:5502/em (EU region data)"
echo "   Shard 3:  https://localhost:5503/em (APAC region data)"
echo ""
echo "Note: Catalog contains metadata + UNION views to query all shards"
echo "      Application data is stored on shards, but queryable via catalog views"
echo ""

