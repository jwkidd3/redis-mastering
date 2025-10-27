#!/bin/bash

###############################################################################
# Setup Test Environment for Redis Mastering Course
# This script prepares the environment for running integration tests
###############################################################################

set -e

echo "=================================================="
echo "Setting up Test Environment"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if Redis is running
check_redis() {
    if redis-cli ping > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Redis is running on localhost:6379"
        return 0
    else
        echo -e "${RED}✗${NC} Redis is not running on localhost:6379"
        return 1
    fi
}

# Function to check if Docker is running
check_docker() {
    if docker info > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Docker is running"
        return 0
    else
        echo -e "${RED}✗${NC} Docker is not running"
        return 1
    fi
}

# Check prerequisites
echo ""
echo "Checking prerequisites..."
echo ""

# Check Node.js
if command -v node > /dev/null 2>&1; then
    NODE_VERSION=$(node --version)
    echo -e "${GREEN}✓${NC} Node.js is installed: $NODE_VERSION"
else
    echo -e "${RED}✗${NC} Node.js is not installed"
    exit 1
fi

# Check redis-cli
if command -v redis-cli > /dev/null 2>&1; then
    REDIS_VERSION=$(redis-cli --version)
    echo -e "${GREEN}✓${NC} Redis CLI is installed: $REDIS_VERSION"
else
    echo -e "${YELLOW}!${NC} Redis CLI is not installed (tests will still work with Docker)"
fi

# Check Docker
check_docker || {
    echo -e "${YELLOW}!${NC} Docker is not running (some tests may be skipped)"
}

# Check if Redis is running
echo ""
echo "Checking Redis connection..."
check_redis || {
    echo -e "${YELLOW}!${NC} Starting Redis with Docker..."
    docker run -d -p 6379:6379 --name redis-test redis:latest
    sleep 3
    check_redis || {
        echo -e "${RED}✗${NC} Failed to start Redis"
        exit 1
    }
}

# Install dependencies in root
echo ""
echo "Installing root dependencies..."
npm install

# Install dependencies in each lab
echo ""
echo "Installing lab dependencies..."

LABS_WITH_NODE=(
    "lab6-javascript-redis-client-setup"
    "lab7-customer-profiles-hashes"
    "lab8-claims-event-sourcing-streams"
    "lab9-insurance-analytics-sets-sorted-sets"
    "lab10-advanced-caching-patterns"
    "lab11-session-management"
    "lab12-rate-limiting-api-protection"
    "lab14-production-monitoring"
)

for lab in "${LABS_WITH_NODE[@]}"; do
    if [ -d "$lab" ] && [ -f "$lab/package.json" ]; then
        echo "  Installing dependencies for $lab..."
        (cd "$lab" && npm install --silent)
    fi
done

# Clean any existing test data
echo ""
echo "Cleaning test data..."
redis-cli FLUSHALL > /dev/null 2>&1 || true

# Create test results directory
mkdir -p tests/results

echo ""
echo -e "${GREEN}✓${NC} Test environment setup complete!"
echo ""
echo "Run tests with: npm test"
echo ""
