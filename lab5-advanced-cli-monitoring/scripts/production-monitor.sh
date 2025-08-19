#!/bin/bash

# Real-time Redis production monitoring dashboard
echo "🔍 Starting Redis Production Monitoring Dashboard"
echo "Press Ctrl+C to stop monitoring"
echo ""

# Redis connection configuration
REDIS_HOST=${REDIS_HOST:-localhost}
REDIS_PORT=${REDIS_PORT:-6379}
REDIS_PASSWORD=${REDIS_PASSWORD:-}

# Build Redis CLI command with connection parameters
REDIS_CLI_CMD="redis-cli -h $REDIS_HOST -p $REDIS_PORT"
if [ -n "$REDIS_PASSWORD" ]; then
    REDIS_CLI_CMD="$REDIS_CLI_CMD -a $REDIS_PASSWORD"
fi

echo "🔗 Monitoring Redis at $REDIS_HOST:$REDIS_PORT"

MONITOR_LOG="monitoring/monitor.log"
mkdir -p monitoring

# Create monitoring header
echo "========================================" > $MONITOR_LOG
echo "Redis Production Monitoring Started" >> $MONITOR_LOG
echo "Timestamp: $(date)" >> $MONITOR_LOG
echo "Redis Host: $REDIS_HOST:$REDIS_PORT" >> $MONITOR_LOG
echo "========================================" >> $MONITOR_LOG

while true; do
    clear
    echo "🚀 Redis Production Monitoring Dashboard"
    echo "========================================"
    echo "🔗 Connected to: $REDIS_HOST:$REDIS_PORT"
    echo "⏰ $(date)"
    echo ""
    
    # Server Information
    echo "🖥️  Server Information:"
    $REDIS_CLI_CMD INFO server | grep -E "(redis_version|uptime_in_seconds|tcp_port)" | sed 's/^/   /'
    echo ""
    
    # Memory Information
    echo "💾 Memory Usage:"
    MEMORY_INFO=$($REDIS_CLI_CMD INFO memory)
    USED_MEMORY=$(echo "$MEMORY_INFO" | grep "used_memory:" | cut -d: -f2 | sed 's/\r//')
    USED_MEMORY_PEAK=$(echo "$MEMORY_INFO" | grep "used_memory_peak:" | cut -d: -f2 | sed 's/\r//')
    FRAGMENTATION=$(echo "$MEMORY_INFO" | grep "mem_fragmentation_ratio:" | cut -d: -f2 | sed 's/\r//')
    
    echo "   Used Memory: $(($USED_MEMORY / 1024 / 1024)) MB"
    echo "   Peak Memory: $(($USED_MEMORY_PEAK / 1024 / 1024)) MB"
    echo "   Fragmentation: ${FRAGMENTATION}"
    echo ""
    
    # Client Information
    echo "👥 Client Connections:"
    CLIENT_INFO=$($REDIS_CLI_CMD INFO clients)
    CONNECTED_CLIENTS=$(echo "$CLIENT_INFO" | grep "connected_clients:" | cut -d: -f2 | sed 's/\r//')
    echo "   Connected: $CONNECTED_CLIENTS"
    echo ""
    
    # Database Information
    echo "🗄️  Database Statistics:"
    DB_INFO=$($REDIS_CLI_CMD INFO keyspace)
    if [ -n "$DB_INFO" ]; then
        echo "$DB_INFO" | sed 's/^/   /'
    else
        echo "   No databases with keys"
    fi
    echo ""
    
    # Performance Metrics
    echo "⚡ Performance Metrics:"
    STATS_INFO=$($REDIS_CLI_CMD INFO stats)
    TOTAL_COMMANDS=$(echo "$STATS_INFO" | grep "total_commands_processed:" | cut -d: -f2 | sed 's/\r//')
    OPS_PER_SEC=$(echo "$STATS_INFO" | grep "instantaneous_ops_per_sec:" | cut -d: -f2 | sed 's/\r//')
    echo "   Total Commands: $TOTAL_COMMANDS"
    echo "   Ops/sec: $OPS_PER_SEC"
    echo ""
    
    # Hit Ratio
    echo "🎯 Cache Performance:"
    KEYSPACE_HITS=$(echo "$STATS_INFO" | grep "keyspace_hits:" | cut -d: -f2 | sed 's/\r//')
    KEYSPACE_MISSES=$(echo "$STATS_INFO" | grep "keyspace_misses:" | cut -d: -f2 | sed 's/\r//')
    if [ "$KEYSPACE_HITS" -gt 0 ] || [ "$KEYSPACE_MISSES" -gt 0 ]; then
        TOTAL_REQUESTS=$((KEYSPACE_HITS + KEYSPACE_MISSES))
        HIT_RATIO=$(echo "scale=2; $KEYSPACE_HITS * 100 / $TOTAL_REQUESTS" | bc -l 2>/dev/null || echo "0")
        echo "   Hits: $KEYSPACE_HITS"
        echo "   Misses: $KEYSPACE_MISSES"
        echo "   Hit Ratio: ${HIT_RATIO}%"
    else
        echo "   No cache activity yet"
    fi
    echo ""
    
    # Slow Log
    echo "🐌 Recent Slow Operations:"
    SLOW_LOG=$($REDIS_CLI_CMD SLOWLOG GET 3)
    if [ -n "$SLOW_LOG" ]; then
        echo "$SLOW_LOG" | head -10 | sed 's/^/   /'
    else
        echo "   No slow operations"
    fi
    echo ""
    
    # Key Expiration Tracking
    echo "⏱️  TTL Information:"
    EXPIRING_KEYS=$($REDIS_CLI_CMD EVAL "
        local keys = redis.call('KEYS', '*')
        local expiring = 0
        local expired_soon = 0
        for i=1,#keys do
            local ttl = redis.call('TTL', keys[i])
            if ttl > 0 then
                expiring = expiring + 1
                if ttl < 3600 then
                    expired_soon = expired_soon + 1
                end
            end
        end
        return {expiring, expired_soon}
    " 0)
    echo "   Keys with TTL: $(echo $EXPIRING_KEYS | cut -d' ' -f1)"
    echo "   Expiring < 1hr: $(echo $EXPIRING_KEYS | cut -d' ' -f2)"
    echo ""
    
    # Log current stats
    echo "$(date): Memory=${USED_MEMORY}B, Clients=${CONNECTED_CLIENTS}, Ops/sec=${OPS_PER_SEC}" >> $MONITOR_LOG
    
    echo "📊 Monitoring log: $MONITOR_LOG"
    echo "Press Ctrl+C to stop monitoring..."
    
    sleep 5
done
