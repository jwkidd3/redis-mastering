#!/bin/bash

echo "🧪 Lab 11 Testing: Session Management & Security"
echo "==============================================="

# Test Redis connection
echo "1. Testing Redis connection..."
if redis-cli -h $REDIS_HOST -p ${REDIS_PORT:-6379} PING | grep -q PONG; then
    echo "✅ Redis connection successful"
else
    echo "❌ Redis connection failed"
    echo "Please check REDIS_HOST and REDIS_PORT in .env file"
    exit 1
fi

# Test Node.js scripts
echo ""
echo "2. Testing session management components..."

if [ -f "examples/basic-session-test.js" ]; then
    echo "   Running basic session test..."
    timeout 30s node examples/basic-session-test.js
    echo ""
fi

if [ -f "examples/rbac-test.js" ]; then
    echo "   Running RBAC test..."
    timeout 30s node examples/rbac-test.js
    echo ""
fi

if [ -f "examples/security-test.js" ]; then
    echo "   Running security monitoring test..."
    timeout 30s node examples/security-test.js
    echo ""
fi

echo "✅ Lab 11 testing completed!"
echo ""
echo "📋 Next steps:"
echo "1. Open Redis Insight and explore session keys"
echo "2. Monitor session TTL behavior"
echo "3. Test role-based access patterns"
echo "4. Review security monitoring features"
echo "5. Complete lab11.md exercises"
