#!/bin/bash

# Alert Checker
set -e

echo "🚨 Checking Redis Alerts"
echo "========================"

mkdir -p monitoring

# Get Redis info
INFO=$(redis-cli INFO 2>/dev/null)

if [ -z "$INFO" ]; then
    echo "🚨 CRITICAL: Redis connection failed"
    exit 1
fi

# Extract metrics
MEMORY_USED=$(echo "$INFO" | grep "used_memory:" | cut -d: -f2 | tr -d "\r")
CLIENTS=$(echo "$INFO" | grep "connected_clients:" | cut -d: -f2 | tr -d "\r")
HITS=$(echo "$INFO" | grep "keyspace_hits:" | cut -d: -f2 | tr -d "\r")
MISSES=$(echo "$INFO" | grep "keyspace_misses:" | cut -d: -f2 | tr -d "\r")

MEMORY_MB=$((MEMORY_USED / 1048576))
ALERTS=0

# Memory alerts
if [ "$MEMORY_MB" -ge 500 ]; then
    echo "🚨 CRITICAL: High memory usage - ${MEMORY_MB}MB"
    ALERTS=$((ALERTS + 1))
elif [ "$MEMORY_MB" -ge 100 ]; then
    echo "⚠️  WARNING: Memory usage - ${MEMORY_MB}MB"
    ALERTS=$((ALERTS + 1))
fi

# Client alerts
if [ "$CLIENTS" -ge 100 ]; then
    echo "🚨 CRITICAL: Too many clients - $CLIENTS"
    ALERTS=$((ALERTS + 1))
elif [ "$CLIENTS" -ge 50 ]; then
    echo "⚠️  WARNING: High client count - $CLIENTS"
    ALERTS=$((ALERTS + 1))
fi

# Performance alerts
if [ "$HITS" -gt 0 ] || [ "$MISSES" -gt 0 ]; then
    HIT_RATIO=$((HITS * 100 / (HITS + MISSES)))
    if [ "$HIT_RATIO" -le 60 ]; then
        echo "🚨 CRITICAL: Poor cache performance - ${HIT_RATIO}%"
        ALERTS=$((ALERTS + 1))
    elif [ "$HIT_RATIO" -le 80 ]; then
        echo "⚠️  WARNING: Cache performance declining - ${HIT_RATIO}%"
        ALERTS=$((ALERTS + 1))
    fi
fi

if [ "$ALERTS" -eq 0 ]; then
    echo "✅ All systems normal"
else
    echo "⚠️  $ALERTS alerts detected"
fi

# Log status
echo "$(date): Memory: ${MEMORY_MB}MB, Clients: $CLIENTS, Alerts: $ALERTS" >> monitoring/alerts.log
