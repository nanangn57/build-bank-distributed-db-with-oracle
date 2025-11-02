#!/bin/bash

# Start Dashboard Server
# Usage: ./dashboard/start-dashboard.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$SCRIPT_DIR"

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed"
    exit 1
fi

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
source venv/bin/activate

# Install requirements from root requirements.txt
echo "Installing requirements..."
pip install -q -r "$PROJECT_DIR/requirements.txt"

# Set environment variables if running in Docker
if [ -f "$PROJECT_DIR/.env" ]; then
    export $(cat "$PROJECT_DIR/.env" | grep -v '^#' | xargs)
fi

# Check if Oracle container is running
if docker ps | grep -q oracle-catalog; then
    export DB_HOST=localhost
else
    echo "⚠️  Oracle catalog container is not running"
    echo "Starting containers..."
    cd "$PROJECT_DIR"
    ./docker/start-sharding.sh
    cd "$SCRIPT_DIR"
    export DB_HOST=localhost
fi

echo "Starting dashboard server..."
echo "Dashboard will be available at: http://localhost:5000"
echo ""
echo "Press Ctrl+C to stop the server"

# Run the Flask app
python3 app.py

