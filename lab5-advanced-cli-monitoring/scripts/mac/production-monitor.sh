#!/bin/bash

# Production-grade Redis monitoring script
# Monitors key metrics and provides real-time dashboard

REDIS_HOST="redis-server.training.com"
REDIS_PORT="6379"
ALERT_LOG="monitoring/alerts.log"
METRICS_LOG="monitoring/metrics.log"

# Create monitoring directory
mkdir -p monitoring

echo "🔍 Starting Redis Production Monitor"
echo "Press Ctrl+C to stop monitoring"
echo "Logging to: $METRICS_LOG"

# Trap Ctrl+C for clean exit
trap 'echo -e "\n\n🛑 Monitoring stopped."; exit 0' INT

while true; do
    clear
    
    # Header
    echo "┌─────────────────────────────────────────────────────────┐"
    echo "│                 Redis Production Monitor                 │"
    echo "│                  $(date '+%Y-%m-%d %H:%M:%S')                    │"
    echo "└─────────────────────────────────────────────────────────┘"
    
    # Get Redis info
    INFO_OUTPUT=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        # Extract key metrics
        USED_MEMORY=$(echo "$INFO_OUTPUT" | grep "used_memory_human:" | cut -d: -f2 | tr -d '\r')
        CONNECTED_CLIENTS=$(echo "$INFO_OUTPUT" | grep "connected_clients:" | cut -d: -f2 | tr -d '\r')
        TOTAL_COMMANDS=$(echo "$INFO_OUTPUT" | grep "total_commands_processed:" | cut -d: -f2 | tr -d '\r')
        KEYSPACE_HITS=$(echo "$INFO_OUTPUT" | grep "keyspace_hits:" | cut -d: -f2 | tr -d '\r')
        KEYSPACE_MISSES=$(echo "$INFO_OUTPUT" | grep "keyspace_misses:" | cut -d: -f2 | tr -d '\r')
        TOTAL_KEYS=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT DBSIZE 2>/dev/null)
        
        # Calculate hit ratio
        if [ "$KEYSPACE_HITS" != "" ] && [ "$KEYSPACE_MISSES" != "" ]; then
            TOTAL_HITS=$((KEYSPACE_HITS + KEYSPACE_MISSES))
            if [ $TOTAL_HITS -gt 0 ]; then
                HIT_RATIO=$(echo "scale=2; $KEYSPACE_HITS * 100 / $TOTAL_HITS" | bc -l 2>/dev/null || echo "0")
            else
                HIT_RATIO="0"
            fi
        else
            HIT_RATIO="0"
        fi
        
        # Display metrics
        echo "📊 SYSTEM METRICS:"
        echo "   Memory Usage: ${USED_MEMORY:-Unknown}"
        echo "   Connected Clients: ${CONNECTED_CLIENTS:-0}"
        echo "   Total Keys: ${TOTAL_KEYS:-0}"
        echo "   Commands Processed: ${TOTAL_COMMANDS:-0}"
        echo "   Cache Hit Ratio: ${HIT_RATIO}%"
        echo ""
        
        # Key Distribution
        echo "🗝️  KEY DISTRIBUTION:"
        redis-cli -h $REDIS_HOST -p $REDIS_PORT EVAL "
        local stats = {}
        stats.customers = #redis.call('KEYS', 'customer:*')
        stats.policies = #redis.call('KEYS', 'policy:*')
        stats.claims = #redis.call('KEYS', 'claim:*')
        stats.sessions = #redis.call('KEYS', 'session:*')
        stats.analytics = #redis.call('KEYS', 'analytics:*')
        stats.cache = #redis.call('KEYS', 'cache:*')
        return cjson.encode(stats)
        " 0 2>/dev/null | sed 's/[{}"]//g' | sed 's/,/\n   /g' | sed 's/:/: /'
        
        echo ""
        
        # TTL Analysis
        echo "⏰ TTL ANALYSIS:"
        EXPIRING_KEYS=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT EVAL "
        local count = 0
        local keys = redis.call('KEYS', '*')
        for i=1,#keys do
            local ttl = redis.call('TTL', keys[i])
            if ttl > 0 and ttl < 3600 then
                count = count + 1
            end
        end
        return count
        " 0 2>/dev/null)
        echo "   Keys expiring in < 1 hour: ${EXPIRING_KEYS:-0}"
        
        # Log metrics
        echo "$(date '+%Y-%m-%d %H:%M:%S'),${USED_MEMORY:-0},${CONNECTED_CLIENTS:-0},${TOTAL_KEYS:-0},${HIT_RATIO}" >> $METRICS_LOG
        
        # Alerts
        if [ "${CONNECTED_CLIENTS:-0}" -gt 100 ]; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') ALERT: High client connections: $CONNECTED_CLIENTS" >> $ALERT_LOG
        fi
        
        echo ""
        echo "🔄 Refreshing in 5 seconds... (Press Ctrl+C to stop)"
        
    else
        echo "❌ Cannot connect to Redis server"
        echo "   Host: $REDIS_HOST:$REDIS_PORT"
        echo "   Check connection and try again"
    fi
    
    sleep 5
done
