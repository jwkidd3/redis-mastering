#!/bin/bash

# Production-grade Redis monitoring script
# Monitors key metrics and provides real-time dashboard

REDIS_HOST="localhost"
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
    echo "┌─────────────────────────────────────────────────────────────┐"
    echo "│                 Redis Production Monitor                    │"
    echo "│                  $(date '+%Y-%m-%d %H:%M:%S')                    │"
    echo "└─────────────────────────────────────────────────────────────┘"
    
    # Get Redis info
    INFO_OUTPUT=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        echo "❌ ERROR: Cannot connect to Redis at $REDIS_HOST:$REDIS_PORT"
        echo "$(date): Connection failed" >> $ALERT_LOG
        sleep 5
        continue
    fi
    
    # Parse key metrics
    MEMORY_USED=$(echo "$INFO_OUTPUT" | grep "used_memory_human:" | cut -d: -f2 | tr -d '\r')
    MEMORY_PEAK=$(echo "$INFO_OUTPUT" | grep "used_memory_peak_human:" | cut -d: -f2 | tr -d '\r')
    CONNECTED_CLIENTS=$(echo "$INFO_OUTPUT" | grep "connected_clients:" | cut -d: -f2 | tr -d '\r')
    TOTAL_COMMANDS=$(echo "$INFO_OUTPUT" | grep "total_commands_processed:" | cut -d: -f2 | tr -d '\r')
    KEYSPACE_HITS=$(echo "$INFO_OUTPUT" | grep "keyspace_hits:" | cut -d: -f2 | tr -d '\r')
    KEYSPACE_MISSES=$(echo "$INFO_OUTPUT" | grep "keyspace_misses:" | cut -d: -f2 | tr -d '\r')
    UPTIME=$(echo "$INFO_OUTPUT" | grep "uptime_in_seconds:" | cut -d: -f2 | tr -d '\r')
    DBSIZE=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT DBSIZE 2>/dev/null)
    
    # Calculate derived metrics
    if [ "$KEYSPACE_HITS" -gt 0 ] && [ "$KEYSPACE_MISSES" -gt 0 ]; then
        HIT_RATIO=$(echo "scale=2; $KEYSPACE_HITS * 100 / ($KEYSPACE_HITS + $KEYSPACE_MISSES)" | bc -l 2>/dev/null || echo "N/A")
    else
        HIT_RATIO="N/A"
    fi
    
    UPTIME_HOURS=$((UPTIME / 3600))
    UPTIME_MINUTES=$(((UPTIME % 3600) / 60))
    
    # Display metrics
    echo ""
    echo "📊 SYSTEM METRICS"
    echo "├─ Memory Used:       $MEMORY_USED (Peak: $MEMORY_PEAK)"
    echo "├─ Connected Clients: $CONNECTED_CLIENTS"
    echo "├─ Total Keys:        $DBSIZE"
    echo "├─ Commands:          $TOTAL_COMMANDS"
    echo "├─ Cache Hit Ratio:   $HIT_RATIO%"
    echo "└─ Uptime:           ${UPTIME_HOURS}h ${UPTIME_MINUTES}m"
    
    # Key distribution analysis
    echo ""
    echo "🔑 KEY DISTRIBUTION"
    
    CUSTOMER_KEYS=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT --scan --pattern "customer:*" 2>/dev/null | wc -l)
    POLICY_KEYS=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT --scan --pattern "policy:*" 2>/dev/null | wc -l)
    CLAIM_KEYS=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT --scan --pattern "claim:*" 2>/dev/null | wc -l)
    SESSION_KEYS=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT --scan --pattern "session:*" 2>/dev/null | wc -l)
    CACHE_KEYS=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT --scan --pattern "cache:*" 2>/dev/null | wc -l)
    
    echo "├─ Customers:  $CUSTOMER_KEYS keys"
    echo "├─ Policies:   $POLICY_KEYS keys"
    echo "├─ Claims:     $CLAIM_KEYS keys"
    echo "├─ Sessions:   $SESSION_KEYS keys"
    echo "└─ Cache:      $CACHE_KEYS keys"
    
    # TTL analysis
    echo ""
    echo "⏰ TTL ANALYSIS"
    EXPIRING_KEYS=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT --scan 2>/dev/null | while read key; do
        TTL=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT TTL "$key" 2>/dev/null)
        if [ "$TTL" -gt 0 ]; then
            echo "$key:$TTL"
        fi
    done | wc -l)
    
    echo "└─ Keys with TTL: $EXPIRING_KEYS"
    
    # Performance monitoring
    echo ""
    echo "⚡ PERFORMANCE"
    
    # Simple latency test
    LATENCY_START=$(date +%s%N)
    redis-cli -h $REDIS_HOST -p $REDIS_PORT PING >/dev/null 2>&1
    LATENCY_END=$(date +%s%N)
    LATENCY_MS=$(echo "scale=2; ($LATENCY_END - $LATENCY_START) / 1000000" | bc -l 2>/dev/null || echo "N/A")
    
    echo "└─ Ping Latency: ${LATENCY_MS}ms"
    
    # Alerts
    echo ""
    echo "🚨 ALERTS"
    
    ALERTS=0
    
    # Memory usage alert (example: >50MB)
    MEMORY_MB=$(echo "$MEMORY_USED" | grep -o '[0-9]*')
    if [ "$MEMORY_MB" -gt 50 ] 2>/dev/null; then
        echo "⚠️  High memory usage: $MEMORY_USED"
        echo "$(date): High memory usage: $MEMORY_USED" >> $ALERT_LOG
        ALERTS=$((ALERTS + 1))
    fi
    
    # Client connection alert (example: >100)
    if [ "$CONNECTED_CLIENTS" -gt 100 ] 2>/dev/null; then
        echo "⚠️  High client connections: $CONNECTED_CLIENTS"
        echo "$(date): High client connections: $CONNECTED_CLIENTS" >> $ALERT_LOG
        ALERTS=$((ALERTS + 1))
    fi
    
    # Cache hit ratio alert (example: <80%)
    if [ "$HIT_RATIO" != "N/A" ]; then
        HIT_RATIO_INT=${HIT_RATIO%.*}
        if [ "$HIT_RATIO_INT" -lt 80 ] 2>/dev/null; then
            echo "⚠️  Low cache hit ratio: $HIT_RATIO%"
            echo "$(date): Low cache hit ratio: $HIT_RATIO%" >> $ALERT_LOG
            ALERTS=$((ALERTS + 1))
        fi
    fi
    
    if [ $ALERTS -eq 0 ]; then
        echo "✅ All systems normal"
    fi
    
    # Log metrics
    echo "$(date),$MEMORY_USED,$CONNECTED_CLIENTS,$DBSIZE,$HIT_RATIO,$LATENCY_MS" >> $METRICS_LOG
    
    echo ""
    echo "📈 Logs: $METRICS_LOG | 🚨 Alerts: $ALERT_LOG"
    echo "💡 Tip: Open Redis Insight for detailed analysis"
    
    sleep 5
done
