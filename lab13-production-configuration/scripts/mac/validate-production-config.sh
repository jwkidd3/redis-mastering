#!/bin/bash

echo "✅ Production Configuration Validation"
echo "====================================="

HOST=${REDIS_HOST:-localhost}
PORT=${REDIS_PORT:-6379}
PASSWORD_PARAM=""
if [ -n "$REDIS_PASSWORD" ]; then
    PASSWORD_PARAM="-a $REDIS_PASSWORD"
fi

PASS_COUNT=0
TOTAL_CHECKS=8

# Check RDB configuration
echo "1. Checking RDB persistence configuration..."
RDB_SAVE=$(redis-cli -h $HOST -p $PORT $PASSWORD_PARAM CONFIG GET save | tail -1)
if [[ "$RDB_SAVE" == *"900 1"* ]]; then
    echo "✅ RDB save configuration: PASS"
    ((PASS_COUNT++))
else
    echo "❌ RDB save configuration: FAIL"
fi

# Check AOF configuration
echo "2. Checking AOF configuration..."
AOF_ENABLED=$(redis-cli -h $HOST -p $PORT $PASSWORD_PARAM CONFIG GET appendonly | tail -1)
if [ "$AOF_ENABLED" = "yes" ]; then
    echo "✅ AOF enabled: PASS"
    ((PASS_COUNT++))
else
    echo "❌ AOF enabled: FAIL"
fi

# Check memory configuration
echo "3. Checking memory limit configuration..."
MAX_MEMORY=$(redis-cli -h $HOST -p $PORT $PASSWORD_PARAM CONFIG GET maxmemory | tail -1)
if [ "$MAX_MEMORY" != "0" ]; then
    echo "✅ Memory limit set: PASS"
    ((PASS_COUNT++))
else
    echo "❌ Memory limit set: FAIL"
fi

# Check eviction policy
echo "4. Checking eviction policy..."
EVICTION_POLICY=$(redis-cli -h $HOST -p $PORT $PASSWORD_PARAM CONFIG GET maxmemory-policy | tail -1)
if [[ "$EVICTION_POLICY" == *"lru"* ]] || [[ "$EVICTION_POLICY" == *"lfu"* ]]; then
    echo "✅ Eviction policy: PASS ($EVICTION_POLICY)"
    ((PASS_COUNT++))
else
    echo "❌ Eviction policy: FAIL ($EVICTION_POLICY)"
fi

# Check timeout configuration
echo "5. Checking client timeout..."
TIMEOUT=$(redis-cli -h $HOST -p $PORT $PASSWORD_PARAM CONFIG GET timeout | tail -1)
if [ "$TIMEOUT" -gt 0 ]; then
    echo "✅ Client timeout set: PASS ($TIMEOUT seconds)"
    ((PASS_COUNT++))
else
    echo "❌ Client timeout set: FAIL"
fi

# Check slow log configuration
echo "6. Checking slow log configuration..."
SLOWLOG_THRESHOLD=$(redis-cli -h $HOST -p $PORT $PASSWORD_PARAM CONFIG GET slowlog-log-slower-than | tail -1)
if [ "$SLOWLOG_THRESHOLD" -lt 100000 ]; then
    echo "✅ Slow log threshold: PASS ($SLOWLOG_THRESHOLD microseconds)"
    ((PASS_COUNT++))
else
    echo "❌ Slow log threshold: FAIL"
fi

# Check data presence
echo "7. Checking insurance data presence..."
POLICY_COUNT=$(redis-cli -h $HOST -p $PORT $PASSWORD_PARAM KEYS "policy:*" | wc -l)
if [ "$POLICY_COUNT" -gt 0 ]; then
    echo "✅ Insurance data present: PASS ($POLICY_COUNT policies)"
    ((PASS_COUNT++))
else
    echo "❌ Insurance data present: FAIL"
fi

# Check connectivity
echo "8. Checking Redis connectivity..."
if redis-cli -h $HOST -p $PORT $PASSWORD_PARAM ping | grep -q PONG; then
    echo "✅ Redis connectivity: PASS"
    ((PASS_COUNT++))
else
    echo "❌ Redis connectivity: FAIL"
fi

echo ""
echo "📊 Validation Summary:"
echo "======================"
echo "Passed: $PASS_COUNT/$TOTAL_CHECKS checks"

if [ "$PASS_COUNT" -eq "$TOTAL_CHECKS" ]; then
    echo "🎉 All validation checks PASSED! Production configuration is ready."
    exit 0
elif [ "$PASS_COUNT" -ge 6 ]; then
    echo "⚠️  Most checks passed. Review failed items before production deployment."
    exit 1
else
    echo "❌ Multiple validation failures. Configuration needs significant work."
    exit 1
fi
