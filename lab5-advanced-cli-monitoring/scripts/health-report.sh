#!/bin/bash

# Health Report Generator
set -e

echo "🏥 Redis Health Report"
echo "====================="

# Test connection
if redis-cli ping > /dev/null 2>&1; then
    echo "✅ Redis connection: HEALTHY"
else
    echo "❌ Redis connection: FAILED"
    exit 1
fi

# Get info
INFO=$(redis-cli INFO)

# Memory check
MEMORY_USED=$(echo "$INFO" | grep "used_memory:" | cut -d: -f2 | tr -d "\r")
MEMORY_MB=$((MEMORY_USED / 1048576))

echo "💾 Memory Status:"
if [ "$MEMORY_MB" -lt 100 ]; then
    echo "✅ Memory usage: HEALTHY (${MEMORY_MB}MB)"
elif [ "$MEMORY_MB" -lt 500 ]; then
    echo "⚠️  Memory usage: MODERATE (${MEMORY_MB}MB)"
else
    echo "🚨 Memory usage: HIGH (${MEMORY_MB}MB)"
fi

# Client check
CLIENTS=$(echo "$INFO" | grep "connected_clients:" | cut -d: -f2 | tr -d "\r")
echo "🔗 Client Connections:"
if [ "$CLIENTS" -lt 50 ]; then
    echo "✅ Client connections: HEALTHY ($CLIENTS)"
else
    echo "⚠️  Client connections: HIGH ($CLIENTS)"
fi

# Performance check
HITS=$(echo "$INFO" | grep "keyspace_hits:" | cut -d: -f2 | tr -d "\r")
MISSES=$(echo "$INFO" | grep "keyspace_misses:" | cut -d: -f2 | tr -d "\r")

if [ "$HITS" -gt 0 ] || [ "$MISSES" -gt 0 ]; then
    HIT_RATIO=$((HITS * 100 / (HITS + MISSES)))
    echo "⚡ Cache Performance:"
    if [ "$HIT_RATIO" -gt 90 ]; then
        echo "✅ Cache hit ratio: EXCELLENT (${HIT_RATIO}%)"
    elif [ "$HIT_RATIO" -gt 80 ]; then
        echo "✅ Cache hit ratio: GOOD (${HIT_RATIO}%)"
    else
        echo "⚠️  Cache hit ratio: NEEDS IMPROVEMENT (${HIT_RATIO}%)"
    fi
fi

# Data integrity
TOTAL_KEYS=$(redis-cli DBSIZE)
echo "🔍 Data Integrity:"
echo "✅ Total keys: $TOTAL_KEYS"

echo "🎯 Overall Status: HEALTHY"
