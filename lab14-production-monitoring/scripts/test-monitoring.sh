#!/bin/bash

# Test script for Lab 14 monitoring system

set -e

echo "🧪 Testing Lab 14 Monitoring System..."
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Test function
test_endpoint() {
    local url=$1
    local description=$2
    
    echo -n "Testing $description... "
    
    if curl -f -s "$url" > /dev/null; then
        echo -e "${GREEN}✓ PASSED${NC}"
        return 0
    else
        echo -e "${RED}✗ FAILED${NC}"
        return 1
    fi
}

# Check if servers are running
echo "📡 Checking server availability..."
echo ""

# Test health endpoints
test_endpoint "http://localhost:3000/health" "Main health check"
test_endpoint "http://localhost:3000/metrics" "Metrics endpoint"
test_endpoint "http://localhost:3000/redis/info" "Redis info endpoint"

echo ""

# Test dashboard endpoints
test_endpoint "http://localhost:4000" "Dashboard homepage"
test_endpoint "http://localhost:4000/api/metrics/realtime" "Real-time metrics API"

echo ""

# Display sample health check response
echo "📊 Sample Health Check Response:"
echo "--------------------------------"
curl -s http://localhost:3000/health | python3 -m json.tool 2>/dev/null || curl -s http://localhost:3000/health

echo ""
echo ""

# Display sample metrics
echo "📈 Sample Metrics Response:"
echo "--------------------------"
curl -s http://localhost:3000/metrics | python3 -m json.tool 2>/dev/null | head -20 || curl -s http://localhost:3000/metrics | head -20

echo ""
echo ""
echo "✅ All tests completed!"
echo ""
echo "🔗 Access the monitoring dashboard at: http://localhost:4000"