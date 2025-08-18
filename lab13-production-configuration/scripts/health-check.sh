#!/bin/bash

# Redis Health Check Script
REDIS_HOST="localhost"
REDIS_PORT="6379"
WARNING_MEMORY_PERCENT=80
CRITICAL_MEMORY_PERCENT=90

echo "Redis Health Check Report"
echo "========================="
date

# Check if Redis is running
redis-cli -h ${REDIS_HOST} -p ${REDIS_PORT} ping > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "❌ CRITICAL: Redis is not responding!"
    exit 1
fi
echo "✅ Redis is responding"

# Check memory usage
MEMORY_USED=$(redis-cli -h ${REDIS_HOST} -p ${REDIS_PORT} INFO memory | grep used_memory_human | cut -d: -f2 | tr -d '\r')
MEMORY_MAX=$(redis-cli -h ${REDIS_HOST} -p ${REDIS_PORT} CONFIG GET maxmemory | tail -1)

echo "Memory Used: ${MEMORY_USED}"
echo "Memory Limit: ${MEMORY_MAX}"

# Check persistence
LAST_SAVE=$(redis-cli -h ${REDIS_HOST} -p ${REDIS_PORT} LASTSAVE)
CURRENT_TIME=$(date +%s)
SAVE_AGE=$((CURRENT_TIME - LAST_SAVE))

if [ ${SAVE_AGE} -gt 3600 ]; then
    echo "⚠️ WARNING: Last save was ${SAVE_AGE} seconds ago"
else
    echo "✅ Persistence: Last save ${SAVE_AGE} seconds ago"
fi

# Check replication (if configured)
ROLE=$(redis-cli -h ${REDIS_HOST} -p ${REDIS_PORT} INFO replication | grep role | cut -d: -f2 | tr -d '\r')
echo "Role: ${ROLE}"

# Check slow queries
SLOW_COUNT=$(redis-cli -h ${REDIS_HOST} -p ${REDIS_PORT} SLOWLOG LEN)
if [ ${SLOW_COUNT} -gt 10 ]; then
    echo "⚠️ WARNING: ${SLOW_COUNT} slow queries detected"
else
    echo "✅ Performance: ${SLOW_COUNT} slow queries"
fi

# Check connected clients
CLIENT_COUNT=$(redis-cli -h ${REDIS_HOST} -p ${REDIS_PORT} CLIENT LIST | wc -l)
echo "Connected Clients: ${CLIENT_COUNT}"

echo "========================="
echo "Health check completed"
