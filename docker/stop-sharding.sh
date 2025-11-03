#!/bin/bash

# Stop Oracle Sharding Infrastructure
# Usage: ./docker/stop-sharding.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_DIR"

echo "========================================="
echo "Stopping Oracle Sharding Infrastructure"
echo "========================================="
echo ""

# Stop all containers
docker-compose -f docker-compose-sharding.yml stop

echo ""
echo "========================================="
echo "✅ Containers stopped!"
echo "========================================="
echo ""
echo "To start again: ./docker/start-sharding.sh"
echo ""
echo "To remove containers:"
echo "  docker-compose -f docker-compose-sharding.yml down"
echo ""
echo "To remove volumes (deletes data!):"
echo "  docker-compose -f docker-compose-sharding.yml down -v"
echo ""

