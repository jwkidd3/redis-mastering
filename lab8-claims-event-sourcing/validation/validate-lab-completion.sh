#!/bin/bash

# Lab 8 Completion Validation Script
# Validates all components are working correctly

echo "🎯 Lab 8 Completion Validation"
echo "==============================="

SCORE=0
TOTAL=10

# Test 1: Redis Connection
echo "Test 1: Redis Connection"
if npm run test-connection > /dev/null 2>&1; then
    echo "✅ Redis connection working"
    ((SCORE++))
else
    echo "❌ Redis connection failed"
fi

# Test 2: Dependencies
echo "Test 2: Dependencies"
if [ -d "node_modules" ] && [ -f "package.json" ]; then
    echo "✅ Dependencies installed"
    ((SCORE++))
else
    echo "❌ Dependencies missing"
fi

# Test 3: Stream Operations
echo "Test 3: Stream Operations"
if node -e "
const RedisClient = require('./src/utils/redis-client');
(async () => {
    const client = new RedisClient();
    await client.connect();
    await client.getClient().xAdd('test:validation', '*', {test: 'value'});
    await client.getClient().del('test:validation');
    await client.disconnect();
})().catch(() => process.exit(1));
" > /dev/null 2>&1; then
    echo "✅ Stream operations working"
    ((SCORE++))
else
    echo "❌ Stream operations failed"
fi

# Test 4: Claims Producer
echo "Test 4: Claims Producer"
if [ -f "src/services/claims-producer.js" ]; then
    echo "✅ Claims producer exists"
    ((SCORE++))
else
    echo "❌ Claims producer missing"
fi

# Test 5: Consumer Components
echo "Test 5: Consumer Components"
CONSUMER_COUNT=0
[ -f "src/consumers/claims-processor.js" ] && ((CONSUMER_COUNT++))
[ -f "src/consumers/analytics-consumer.js" ] && ((CONSUMER_COUNT++))
[ -f "src/consumers/notification-consumer.js" ] && ((CONSUMER_COUNT++))

if [ $CONSUMER_COUNT -eq 3 ]; then
    echo "✅ All consumers present"
    ((SCORE++))
else
    echo "❌ Missing consumers ($CONSUMER_COUNT/3)"
fi

# Test 6: Monitoring Tools
echo "Test 6: Monitoring Tools"
if [ -f "monitoring/monitor-processing.js" ] && [ -f "monitoring/check-consumer-lag.js" ]; then
    echo "✅ Monitoring tools present"
    ((SCORE++))
else
    echo "❌ Monitoring tools missing"
fi

# Test 7: Test Suite
echo "Test 7: Test Suite"
if [ -f "tests/run-all-tests.js" ]; then
    echo "✅ Test suite available"
    ((SCORE++))
else
    echo "❌ Test suite missing"
fi

# Test 8: Validation Scripts
echo "Test 8: Validation Scripts"
VALIDATION_COUNT=0
[ -f "validation/validate-environment.sh" ] && ((VALIDATION_COUNT++))
[ -f "validation/test-connection.js" ] && ((VALIDATION_COUNT++))
[ -f "validation/validate-lab-completion.sh" ] && ((VALIDATION_COUNT++))

if [ $VALIDATION_COUNT -eq 3 ]; then
    echo "✅ Validation scripts complete"
    ((SCORE++))
else
    echo "❌ Validation scripts incomplete"
fi

# Test 9: Documentation
echo "Test 9: Documentation"
if [ -f "lab8.md" ] && [ -f "README.md" ]; then
    echo "✅ Documentation complete"
    ((SCORE++))
else
    echo "❌ Documentation missing"
fi

# Test 10: Project Structure
echo "Test 10: Project Structure"
STRUCTURE_COUNT=0
[ -d "src/models" ] && ((STRUCTURE_COUNT++))
[ -d "src/services" ] && ((STRUCTURE_COUNT++))
[ -d "src/consumers" ] && ((STRUCTURE_COUNT++))
[ -d "scripts" ] && ((STRUCTURE_COUNT++))
[ -d "tests" ] && ((STRUCTURE_COUNT++))
[ -d "validation" ] && ((STRUCTURE_COUNT++))
[ -d "monitoring" ] && ((STRUCTURE_COUNT++))

if [ $STRUCTURE_COUNT -eq 7 ]; then
    echo "✅ Project structure complete"
    ((SCORE++))
else
    echo "❌ Project structure incomplete ($STRUCTURE_COUNT/7)"
fi

# Results
echo ""
echo "================================="
echo "📊 Lab Completion Score: $SCORE/$TOTAL"

PERCENTAGE=$((SCORE * 100 / TOTAL))

if [ $SCORE -eq $TOTAL ]; then
    echo "🎉 EXCELLENT! Lab 8 completed successfully!"
    echo "🌟 You've mastered Redis Streams and event sourcing!"
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
    echo "- Run the full test suite: npm test"
    echo "- Start the monitoring dashboard: npm run dashboard"
    echo "- Prepare for Lab 9: Insurance Analytics with Sets"
else
    echo "- Fix the failed tests listed above"
    echo "- Review lab8.md instructions carefully"
    echo "- Run npm install to ensure dependencies"
    echo "- Check Redis connection configuration"
fi
