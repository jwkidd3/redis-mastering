#!/bin/bash

###############################################################################
# Cleanup Test Environment for Redis Mastering Course
# This script cleans up after integration tests
###############################################################################

set -e

echo "=================================================="
echo "Cleaning up Test Environment"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Flush all Redis databases
echo ""
echo "Flushing Redis databases..."
if redis-cli ping > /dev/null 2>&1; then
    redis-cli FLUSHALL
    echo -e "${GREEN}✓${NC} Redis databases flushed"
else
    echo -e "${YELLOW}!${NC} Redis not running, skipping flush"
fi

# Stop Docker containers
echo ""
echo "Stopping Docker containers..."

# Stop test Redis container if it exists
if docker ps -a --format '{{.Names}}' | grep -q '^redis-test$'; then
    echo "  Stopping redis-test container..."
    docker stop redis-test > /dev/null 2>&1 || true
    docker rm redis-test > /dev/null 2>&1 || true
    echo -e "${GREEN}✓${NC} Stopped redis-test container"
fi

# Stop Lab 15 cluster if running
if [ -d "lab15-redis-cluster-ha" ]; then
    if [ -f "lab15-redis-cluster-ha/docker-compose.yml" ]; then
        echo "  Stopping Lab 15 cluster..."
        (cd lab15-redis-cluster-ha && docker-compose down > /dev/null 2>&1) || true
        echo -e "${GREEN}✓${NC} Stopped Lab 15 cluster"
    fi
fi

# Clean test results (optional, commented out by default)
# echo ""
# echo "Cleaning test results..."
# rm -rf tests/results/*
# echo -e "${GREEN}✓${NC} Test results cleaned"

echo ""
echo -e "${GREEN}✓${NC} Cleanup complete!"
echo ""
