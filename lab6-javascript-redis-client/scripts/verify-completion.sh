#!/bin/bash

echo "🎯 Lab 6 Completion Verification"
echo "================================"

SCORE=0
TOTAL=10

echo "Testing lab completion requirements..."
echo ""

# Test 1: Connection test passes
echo "Test 1: Redis Connection"
if node tests/connection-test.js > /dev/null 2>&1; then
    echo "✅ Redis connection successful"
    ((SCORE++))
else
    echo "❌ Redis connection failed"
fi

# Test 2: Main application runs
echo ""
echo "Test 2: Main Application"
if timeout 10s node src/app.js > /dev/null 2>&1; then
    echo "✅ Main application runs without errors"
    ((SCORE++))
else
    echo "❌ Main application has errors"
fi

# Test 3: Customer model functionality
echo ""
echo "Test 3: Customer Model"
cat > temp_customer_test.js << 'EOT'
const RedisClient = require('./src/clients/redisClient');
const Customer = require('./src/models/customer');

async function test() {
    const redisClient = new RedisClient();
    await redisClient.connect();
    const customer = new Customer(redisClient);
    
    await customer.create('TEST001', {
        name: 'Test Customer',
        email: 'test@test.com'
    });
    
    const retrieved = await customer.get('TEST001');
    await customer.delete('TEST001');
    await redisClient.disconnect();
    
    if (retrieved && retrieved.name === 'Test Customer') {
        console.log('SUCCESS');
    } else {
        throw new Error('Customer operations failed');
    }
}

test().catch(() => process.exit(1));
EOT

if timeout 15s node temp_customer_test.js > /dev/null 2>&1; then
    echo "✅ Customer model operations work"
    ((SCORE++))
else
    echo "❌ Customer model operations failed"
fi
rm -f temp_customer_test.js

# Test 4: Policy model functionality
echo ""
echo "Test 4: Policy Model"
cat > temp_policy_test.js << 'EOT'
const RedisClient = require('./src/clients/redisClient');
const Policy = require('./src/models/policy');

async function test() {
    const redisClient = new RedisClient();
    await redisClient.connect();
    const policy = new Policy(redisClient);
    
    await policy.create('TEST_POL001', {
        customerId: 'TEST001',
        type: 'auto',
        premium: 1000
    });
    
    const retrieved = await policy.get('TEST_POL001');
    
    // Cleanup
    const client = redisClient.getClient();
    await client.del('policy:TEST_POL001');
    await client.sRem('policies:index', 'TEST_POL001');
    await redisClient.disconnect();
    
    if (retrieved && retrieved.type === 'auto') {
        console.log('SUCCESS');
    } else {
        throw new Error('Policy operations failed');
    }
}

test().catch(() => process.exit(1));
EOT

if timeout 15s node temp_policy_test.js > /dev/null 2>&1; then
    echo "✅ Policy model operations work"
    ((SCORE++))
else
    echo "❌ Policy model operations failed"
fi
rm -f temp_policy_test.js

# Test 5: Environment configuration
echo ""
echo "Test 5: Environment Configuration"
if [ -f ".env" ] && grep -q "REDIS_HOST=" .env && grep -q "REDIS_PORT=" .env; then
    echo "✅ Environment properly configured"
    ((SCORE++))
else
    echo "❌ Environment configuration incomplete"
fi

# Test 6: Error handling
echo ""
echo "Test 6: Error Handling"
cat > temp_error_test.js << 'EOT'
const RedisClient = require('./src/clients/redisClient');

async function test() {
    const redisClient = new RedisClient();
    await redisClient.connect();
    
    try {
        // Try to get non-existent customer
        const client = redisClient.getClient();
        const result = await client.get('customer:NONEXISTENT');
        
        if (result === null) {
            console.log('SUCCESS');
        }
    } catch (error) {
        throw error;
    } finally {
        await redisClient.disconnect();
    }
}

test().catch(() => process.exit(1));
EOT

if timeout 10s node temp_error_test.js > /dev/null 2>&1; then
    echo "✅ Error handling works correctly"
    ((SCORE++))
else
    echo "❌ Error handling issues"
fi
rm -f temp_error_test.js

# Test 7: JSON operations
echo ""
echo "Test 7: JSON Data Operations"
cat > temp_json_test.js << 'EOT'
const RedisClient = require('./src/clients/redisClient');

async function test() {
    const redisClient = new RedisClient();
    await redisClient.connect();
    const client = redisClient.getClient();
    
    const testData = { name: 'JSON Test', value: 123 };
    await client.set('test:json', JSON.stringify(testData));
    
    const retrieved = JSON.parse(await client.get('test:json'));
    await client.del('test:json');
    await redisClient.disconnect();
    
    if (retrieved.name === 'JSON Test' && retrieved.value === 123) {
        console.log('SUCCESS');
    } else {
        throw new Error('JSON operations failed');
    }
}

test().catch(() => process.exit(1));
EOT

if timeout 10s node temp_json_test.js > /dev/null 2>&1; then
    echo "✅ JSON operations work correctly"
    ((SCORE++))
else
    echo "❌ JSON operations failed"
fi
rm -f temp_json_test.js

# Test 8: Examples run
echo ""
echo "Test 8: Example Scripts"
if timeout 15s node examples/basic-operations.js > /dev/null 2>&1; then
    echo "✅ Example scripts run successfully"
    ((SCORE++))
else
    echo "❌ Example scripts have errors"
fi

# Test 9: Performance test
echo ""
echo "Test 9: Performance Testing"
if timeout 20s node examples/performance-test.js > /dev/null 2>&1; then
    echo "✅ Performance tests complete"
    ((SCORE++))
else
    echo "❌ Performance tests failed"
fi

# Test 10: Project structure
echo ""
echo "Test 10: Project Structure"
STRUCTURE_SCORE=0
[ -f "src/config/redis.js" ] && ((STRUCTURE_SCORE++))
[ -f "src/clients/redisClient.js" ] && ((STRUCTURE_SCORE++))
[ -f "src/models/customer.js" ] && ((STRUCTURE_SCORE++))
[ -f "src/models/policy.js" ] && ((STRUCTURE_SCORE++))
[ -f "examples/basic-operations.js" ] && ((STRUCTURE_SCORE++))

if [ $STRUCTURE_SCORE -eq 5 ]; then
    echo "✅ Project structure complete"
    ((SCORE++))
else
    echo "❌ Project structure incomplete ($STRUCTURE_SCORE/5 files)"
fi

# Results
echo ""
echo "================================="
echo "📊 Lab Completion Score: $SCORE/$TOTAL"

PERCENTAGE=$((SCORE * 100 / TOTAL))

if [ $SCORE -eq $TOTAL ]; then
    echo "🎉 EXCELLENT! Lab completed successfully!"
    echo "🌟 You've mastered JavaScript Redis client development!"
elif [ $SCORE -ge 8 ]; then
    echo "✅ GOOD! Lab mostly completed ($PERCENTAGE%)"
    echo "🔧 Minor issues to address for perfection"
elif [ $SCORE -ge 6 ]; then
    echo "⚠️ PASSING: Lab partially completed ($PERCENTAGE%)"
    echo "📚 Review the failed tests and improve"
else
    echo "❌ NEEDS WORK: Lab significantly incomplete ($PERCENTAGE%)"
    echo "🆘 Seek help and review the lab instructions"
fi

echo ""
echo "🎯 Next steps:"
if [ $SCORE -ge 8 ]; then
    echo "- Review any failed tests above"
    echo "- Prepare for Lab 7: Advanced Data Structures"
    echo "- Practice with Redis Insight integration"
else
    echo "- Fix the failed tests listed above"
    echo "- Review lab6.md instructions"
    echo "- Ask instructor for help if needed"
    echo "- Run this verification again after fixes"
fi

echo ""
