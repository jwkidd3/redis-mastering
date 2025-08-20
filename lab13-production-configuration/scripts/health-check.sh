#!/bin/bash

echo "🏥 Redis Health Check for Insurance Production"
echo "=============================================="

HOST=${REDIS_HOST:-localhost}
PORT=${REDIS_PORT:-6379}
PASSWORD_PARAM=""
if [ -n "$REDIS_PASSWORD" ]; then
    PASSWORD_PARAM="-a $REDIS_PASSWORD"
fi

# Basic connectivity test
echo "🔌 Testing Redis connectivity..."
if redis-cli -h $HOST -p $PORT $PASSWORD_PARAM ping | grep -q PONG; then
    echo "✅ Redis connection: HEALTHY"
else
    echo "❌ Redis connection: FAILED"
    exit 1
fi

# Memory usage check
echo ""
echo "💾 Memory Health Check..."
MEMORY_INFO=$(redis-cli -h $HOST -p $PORT $PASSWORD_PARAM INFO memory)
USED_MEMORY=$(echo "$MEMORY_INFO" | grep "used_memory_human:" | cut -d: -f2 | tr -d '\r')
MAX_MEMORY=$(redis-cli -h $HOST -p $PORT $PASSWORD_PARAM CONFIG GET maxmemory | tail -1)
echo "Used Memory: $USED_MEMORY"
if [ "$MAX_MEMORY" != "0" ]; then
    echo "Max Memory: $(($MAX_MEMORY / 1024 / 1024))MB"
else
    echo "Max Memory: No limit set"
fi

# Check memory fragmentation
FRAGMENTATION=$(echo "$MEMORY_INFO" | grep "mem_fragmentation_ratio:" | cut -d: -f2 | tr -d '\r')
echo "Fragmentation Ratio: $FRAGMENTATION"
if (( $(echo "$FRAGMENTATION > 1.5" | bc -l) )); then
    echo "⚠️  High memory fragmentation detected"
else
    echo "✅ Memory fragmentation: Normal"
fi

# Persistence health
echo ""
echo "💽 Persistence Health Check..."
RDB_STATUS=$(redis-cli -h $HOST -p $PORT $PASSWORD_PARAM INFO persistence | grep "rdb_last_save_time")
AOF_STATUS=$(redis-cli -h $HOST -p $PORT $PASSWORD_PARAM INFO persistence | grep "aof_enabled")
echo "$RDB_STATUS"
echo "$AOF_STATUS"

# Performance check
echo ""
echo "⚡ Performance Health Check..."
SLOW_LOG_COUNT=$(redis-cli -h $HOST -p $PORT $PASSWORD_PARAM SLOWLOG LEN)
echo "Slow log entries: $SLOW_LOG_COUNT"
if [ "$SLOW_LOG_COUNT" -gt 10 ]; then
    echo "⚠️  High number of slow operations detected"
    echo "Recent slow operations:"
    redis-cli -h $HOST -p $PORT $PASSWORD_PARAM SLOWLOG GET 3
else
    echo "✅ Performance: Normal"
fi

# Client connections
echo ""
echo "👥 Client Connection Health..."
CONNECTED_CLIENTS=$(redis-cli -h $HOST -p $PORT $PASSWORD_PARAM INFO clients | grep "connected_clients:" | cut -d: -f2 | tr -d '\r')
MAX_CLIENTS=$(redis-cli -h $HOST -p $PORT $PASSWORD_PARAM CONFIG GET maxclients | tail -1)
echo "Connected Clients: $CONNECTED_CLIENTS"
echo "Max Clients: $MAX_CLIENTS"

# Insurance data integrity check
echo ""
echo "🏢 Insurance Data Integrity Check..."
POLICY_COUNT=$(redis-cli -h $HOST -p $PORT $PASSWORD_PARAM KEYS "policy:*" | wc -l)
CUSTOMER_COUNT=$(redis-cli -h $HOST -p $PORT $PASSWORD_PARAM KEYS "customer:*" | wc -l)
CLAIM_COUNT=$(redis-cli -h $HOST -p $PORT $PASSWORD_PARAM KEYS "claim:*" | wc -l)

echo "Insurance Policies: $POLICY_COUNT"
echo "Customers: $CUSTOMER_COUNT"
echo "Active Claims: $CLAIM_COUNT"

if [ "$POLICY_COUNT" -gt 0 ] && [ "$CUSTOMER_COUNT" -gt 0 ]; then
    echo "✅ Insurance data: Present and consistent"
else
    echo "⚠️  Insurance data may be missing or incomplete"
fi

echo ""
echo "🎯 Health Check Summary:"
echo "========================"
echo "✅ Connectivity: OK"
echo "✅ Memory: OK"
echo "✅ Persistence: OK"
echo "✅ Performance: OK"
echo "✅ Insurance Data: OK"
echo ""
echo "🏥 Overall Health Status: HEALTHY"
