#!/bin/bash

# Start Oracle Sharding Infrastructure
# Usage: ./docker/start-sharding.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_DIR"

echo "========================================="
echo "Starting Oracle Sharding Infrastructure"
echo "========================================="
echo ""

# Check if .env file exists
if [ ! -f .env ]; then
    echo "⚠️  .env file not found. Creating from .env.example..."
    if [ -f .env.example ]; then
        cp .env.example .env
        echo "✅ .env file created. Please review and update passwords if needed."
    else
        echo "❌ .env.example not found. Creating default .env..."
        cat > .env <<EOF
ORACLE_PWD=tuPDqNJWLr7QcA
BANK_APP_PASSWORD=BankAppPass123
SHARD_CATALOG_PASSWORD=CatalogPass123
EOF
    fi
fi

# Start all containers
echo "Starting Docker containers..."
docker-compose -f docker-compose-sharding.yml up -d

echo ""
echo "Waiting for containers to initialize..."
sleep 5

echo ""
echo "Container status:"
docker-compose -f docker-compose-sharding.yml ps

echo ""
echo "========================================="
echo "✅ Containers started!"
echo "========================================="
echo ""
echo "Please wait 2-5 minutes for databases to initialize."
echo ""
echo "To check logs:"
echo "  docker-compose -f docker-compose-sharding.yml logs -f"
echo ""
echo "To setup sharding (after databases are ready):"
echo "  ./scripts/setup-sharding.sh"
echo ""
echo "Web interfaces:"
echo "  Catalog: https://localhost:5500/em"
echo "  Shard 1:  https://localhost:5501/em"
echo "  Shard 2:  https://localhost:5502/em"
echo "  Shard 3:  https://localhost:5503/em"
echo ""

