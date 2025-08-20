#!/bin/bash

# Test script for Lab 14 monitoring system
# Validates all monitoring components are working

set -e

echo "🧪 Testing Lab 14 Monitoring System..."

# Check if services are running
echo "🔍 Checking if services are running..."

# Test health check service
echo "Testing health check service..."
if curl -f http://localhost:3000/health > /dev/null 2>&1; then
    echo "✅ Health check service is running"
else
    echo "❌ Health check service is not responding"
    exit 1
fi

# Test business metrics endpoint
echo "Testing business metrics endpoint..."
if curl -f http://localhost:3000/health/business > /dev/null 2>&1; then
    echo "✅ Business metrics endpoint is working"
else
    echo "❌ Business metrics endpoint is not responding"
    exit 1
fi

# Test performance metrics endpoint
echo "Testing performance metrics endpoint..."
if curl -f http://localhost:3000/health/performance > /dev/null 2>&1; then
    echo "✅ Performance metrics endpoint is working"
else
    echo "❌ Performance metrics endpoint is not responding"
    exit 1
fi

# Test monitoring dashboard API
echo "Testing monitoring dashboard API..."
if curl -f http://localhost:4000/api/metrics/realtime > /dev/null 2>&1; then
    echo "✅ Monitoring dashboard API is working"
else
    echo "❌ Monitoring dashboard API is not responding"
    exit 1
fi

# Test Redis connectivity
echo "Testing Redis connectivity..."
if redis-cli -h ${REDIS_HOST:-redis.training.local} -p ${REDIS_PORT:-6379} ping > /dev/null 2>&1; then
    echo "✅ Redis connectivity is working"
else
    echo "❌ Redis is not accessible"
    exit 1
fi

echo ""
echo "🎉 All monitoring components are working correctly!"
echo "📊 Monitoring system is ready for production use"
echo ""
echo "📝 Available endpoints:"
echo "   • Health Check: http://localhost:3000/health"
echo "   • Business Metrics: http://localhost:3000/health/business"
echo "   • Performance: http://localhost:3000/health/performance"
echo "   • Dashboard: http://localhost:4000"
echo "   • Real-time API: http://localhost:4000/api/metrics/realtime"
