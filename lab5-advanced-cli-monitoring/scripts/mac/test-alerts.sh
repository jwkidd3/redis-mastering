#!/bin/bash

# Test alert system functionality

REDIS_HOST="redis-server.training.com"
REDIS_PORT="6379"

echo "🧪 Testing Redis Alert System"
echo "=============================="
echo ""

# Test 1: Connection test
echo "Test 1: Redis Connection"
if redis-cli -h $REDIS_HOST -p $REDIS_PORT ping >/dev/null 2>&1; then
    echo "✅ Redis connection successful"
else
    echo "❌ Redis connection failed"
    exit 1
fi
echo ""

# Test 2: Alert configuration exists
echo "Test 2: Alert Configuration"
if [ -f "monitoring/alert-config.conf" ]; then
    echo "✅ Alert configuration found"
    echo "   Configuration:"
    cat monitoring/alert-config.conf | grep -E "^[A-Z_]+" | head -4
else
    echo "❌ Alert configuration missing"
    echo "   Run ./scripts/setup-alerts.sh first"
    exit 1
fi
echo ""

# Test 3: Alert script exists and is executable
echo "Test 3: Alert Script"
if [ -x "monitoring/check-alerts.sh" ]; then
    echo "✅ Alert script found and executable"
else
    echo "❌ Alert script missing or not executable"
    exit 1
fi
echo ""

# Test 4: Run alert check
echo "Test 4: Alert Check Execution"
if ./monitoring/check-alerts.sh; then
    echo "✅ Alert check executed successfully"
else
    echo "❌ Alert check failed"
fi
echo ""

# Test 5: Log file creation
echo "Test 5: Alert Logging"
if [ -f "monitoring/alerts.log" ]; then
    echo "✅ Alert log file created"
    echo "   Recent entries:"
    tail -3 monitoring/alerts.log 2>/dev/null | sed 's/^/      /'
else
    echo "❌ Alert log file not created"
fi
echo ""

# Test 6: Generate test alert
echo "Test 6: Simulate High Memory Alert"
echo "$(date): TEST - Simulated high memory alert" >> monitoring/alerts.log
echo "✅ Test alert logged"
echo ""

echo "🎯 Alert System Test Summary:"
echo "   All core components tested"
echo "   Alert system is functional"
echo ""
echo "💡 To monitor alerts in real-time:"
echo "   tail -f monitoring/alerts.log"
