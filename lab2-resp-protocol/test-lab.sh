#!/bin/bash

echo "🧪 Testing Lab 2 Environment..."
echo ""

# Check Docker
echo "Checking Docker..."
if ! docker --version > /dev/null 2>&1; then
    echo "❌ Docker not installed"
    exit 1
fi
echo "✅ Docker is available"

# Check Redis CLI
echo "Checking Redis CLI..."
if ! redis-cli --version > /dev/null 2>&1; then
    echo "❌ Redis CLI not installed"
    exit 1
fi
echo "✅ Redis CLI is available"

# Start services
echo ""
echo "Starting services..."
docker-compose up -d

# Wait for Redis
echo "Waiting for Redis to start..."
sleep 5

# Test Redis connection
echo "Testing Redis connection..."
if redis-cli ping | grep -q PONG; then
    echo "✅ Redis is responding"
else
    echo "❌ Redis not responding"
    exit 1
fi

# Load sample data
echo "Loading sample data..."
./scripts/load-business-data.sh

# Test monitoring
echo ""
echo "Testing monitoring capability..."
timeout 2 redis-cli monitor > /dev/null 2>&1 &
MONITOR_PID=$!
sleep 1
redis-cli SET test:monitor "working" > /dev/null
kill $MONITOR_PID 2>/dev/null
echo "✅ Monitoring is working"

# Check data
echo ""
echo "Verifying sample data..."
KEYS_COUNT=$(redis-cli DBSIZE | awk '{print $1}')
if [ $KEYS_COUNT -gt 0 ]; then
    echo "✅ Sample data loaded ($KEYS_COUNT keys)"
else
    echo "❌ No data loaded"
    exit 1
fi

echo ""
echo "🎉 Lab 2 environment is ready!"
echo ""
echo "To start the lab:"
echo "1. Open lab2.md for instructions"
echo "2. Open terminal for monitoring: redis-cli monitor"
echo "3. Open terminal for commands: redis-cli"
echo "4. Access Redis Insight at: http://localhost:8001"
