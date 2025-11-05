#!/bin/bash

# Setup monitoring alerts for Redis

REDIS_HOST="redis-server.training.com"
REDIS_PORT="6379"
ALERT_CONFIG="monitoring/alert-config.conf"
ALERT_SCRIPT="monitoring/check-alerts.sh"

mkdir -p monitoring

echo "🚨 Setting up Redis monitoring alerts..."

# Create alert configuration
echo "# Redis Alert Configuration" > $ALERT_CONFIG
echo "# Generated: $(date)" >> $ALERT_CONFIG
echo "" >> $ALERT_CONFIG
echo "# Memory threshold (bytes)" >> $ALERT_CONFIG
echo "MEMORY_THRESHOLD=100000000  # 100MB" >> $ALERT_CONFIG
echo "" >> $ALERT_CONFIG
echo "# Client connection threshold" >> $ALERT_CONFIG
echo "CLIENT_THRESHOLD=50" >> $ALERT_CONFIG
echo "" >> $ALERT_CONFIG
echo "# Cache hit ratio threshold (percentage)" >> $ALERT_CONFIG
echo "HIT_RATIO_THRESHOLD=80" >> $ALERT_CONFIG
echo "" >> $ALERT_CONFIG
echo "# Slow operation threshold (microseconds)" >> $ALERT_CONFIG
echo "SLOW_OP_THRESHOLD=100000  # 100ms" >> $ALERT_CONFIG

# Create alert checking script
cat > $ALERT_SCRIPT << 'ALERT_EOF'
#!/bin/bash

# Alert checking script
source monitoring/alert-config.conf

REDIS_HOST="redis-server.training.com"
REDIS_PORT="6379"
ALERT_LOG="monitoring/alerts.log"

check_memory() {
    MEMORY_INFO=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO memory 2>/dev/null)
    USED_MEMORY=$(echo "$MEMORY_INFO" | grep "used_memory:" | head -1 | cut -d: -f2)
    
    if [ "$USED_MEMORY" -gt "$MEMORY_THRESHOLD" ]; then
        echo "$(date): ALERT - High memory usage: ${USED_MEMORY} bytes" >> $ALERT_LOG
        return 1
    fi
    return 0
}

check_clients() {
    CLIENT_INFO=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO clients 2>/dev/null)
    CONNECTED_CLIENTS=$(echo "$CLIENT_INFO" | grep "connected_clients:" | cut -d: -f2)
    
    if [ "$CONNECTED_CLIENTS" -gt "$CLIENT_THRESHOLD" ]; then
        echo "$(date): ALERT - High client connections: ${CONNECTED_CLIENTS}" >> $ALERT_LOG
        return 1
    fi
    return 0
}

check_hit_ratio() {
    STATS_INFO=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO stats 2>/dev/null)
    HITS=$(echo "$STATS_INFO" | grep "keyspace_hits:" | cut -d: -f2)
    MISSES=$(echo "$STATS_INFO" | grep "keyspace_misses:" | cut -d: -f2)
    
    if [ "$HITS" != "" ] && [ "$MISSES" != "" ]; then
        TOTAL_HITS=$((HITS + MISSES))
        if [ $TOTAL_HITS -gt 0 ]; then
            HIT_RATIO=$(echo "scale=0; $HITS * 100 / $TOTAL_HITS" | bc -l 2>/dev/null || echo "0")
            if [ "$HIT_RATIO" -lt "$HIT_RATIO_THRESHOLD" ]; then
                echo "$(date): ALERT - Low cache hit ratio: ${HIT_RATIO}%" >> $ALERT_LOG
                return 1
            fi
        fi
    fi
    return 0
}

check_slow_operations() {
    SLOW_COUNT=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT SLOWLOG LEN 2>/dev/null)
    
    if [ "$SLOW_COUNT" -gt 5 ]; then
        echo "$(date): ALERT - High slow operation count: ${SLOW_COUNT}" >> $ALERT_LOG
        return 1
    fi
    return 0
}

# Run all checks
ALERT_COUNT=0

if ! check_memory; then
    ((ALERT_COUNT++))
fi

if ! check_clients; then
    ((ALERT_COUNT++))
fi

if ! check_hit_ratio; then
    ((ALERT_COUNT++))
fi

if ! check_slow_operations; then
    ((ALERT_COUNT++))
fi

if [ $ALERT_COUNT -eq 0 ]; then
    echo "$(date): INFO - All systems normal" >> $ALERT_LOG
fi

echo "Alert check completed. $ALERT_COUNT alerts generated."
ALERT_EOF

chmod +x $ALERT_SCRIPT

echo "✅ Alert system configured:"
echo "   Configuration: $ALERT_CONFIG"
echo "   Alert Script: $ALERT_SCRIPT"
echo "   Log File: monitoring/alerts.log"
echo ""
echo "To run manual alert check:"
echo "   ./$ALERT_SCRIPT"
