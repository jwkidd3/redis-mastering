#!/bin/bash

# Setup monitoring alerts for Redis

ALERT_CONFIG="monitoring/alert-config.conf"
ALERT_SCRIPT="monitoring/check-alerts.sh"

mkdir -p monitoring

echo "🚨 Setting up Redis monitoring alerts..."

# Create alert configuration
cat > $ALERT_CONFIG << 'CONFIG'
# Redis Alert Configuration
# Threshold values for different metrics

# Memory thresholds (in MB)
MEMORY_WARNING=50
MEMORY_CRITICAL=100

# Client connection thresholds
CLIENTS_WARNING=50
CLIENTS_CRITICAL=100

# Cache hit ratio thresholds (percentage)
HIT_RATIO_WARNING=80
HIT_RATIO_CRITICAL=60

# Latency thresholds (milliseconds)
LATENCY_WARNING=10
LATENCY_CRITICAL=50

# Slow operations threshold
SLOW_OPS_WARNING=5
SLOW_OPS_CRITICAL=20

# Fragmentation ratio threshold
FRAGMENTATION_WARNING=1.5
FRAGMENTATION_CRITICAL=2.0
CONFIG

# Create alert checking script
cat > $ALERT_SCRIPT << 'ALERTSCRIPT'
#!/bin/bash

# Redis Alert Checker
source monitoring/alert-config.conf

ALERT_LOG="monitoring/alerts.log"
STATUS_FILE="monitoring/alert-status.txt"

check_alerts() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local alerts_triggered=0
    
    # Check if Redis is running
    if ! redis-cli ping >/dev/null 2>&1; then
        echo "[$timestamp] CRITICAL: Redis is down!" >> $ALERT_LOG
        echo "CRITICAL: Redis is down!"
        return 1
    fi
    
    # Get metrics
    local memory_mb=$(redis-cli INFO memory | grep "used_memory:" | cut -d: -f2 | awk '{print int($1/1024/1024)}')
    local clients=$(redis-cli INFO clients | grep "connected_clients:" | cut -d: -f2 | tr -d '\r')
    local fragmentation=$(redis-cli INFO memory | grep "mem_fragmentation_ratio:" | cut -d: -f2 | tr -d '\r')
    local slow_ops=$(redis-cli SLOWLOG LEN)
    
    # Calculate hit ratio
    local hits=$(redis-cli INFO stats | grep "keyspace_hits:" | cut -d: -f2 | tr -d '\r')
    local misses=$(redis-cli INFO stats | grep "keyspace_misses:" | cut -d: -f2 | tr -d '\r')
    
    if [ "$hits" -gt 0 ] && [ "$misses" -gt 0 ]; then
        local hit_ratio=$(echo "scale=2; $hits * 100 / ($hits + $misses)" | bc -l)
        local hit_ratio_int=${hit_ratio%.*}
    else
        local hit_ratio_int=100
    fi
    
    # Memory alerts
    if [ "$memory_mb" -gt "$MEMORY_CRITICAL" ]; then
        echo "[$timestamp] CRITICAL: Memory usage ${memory_mb}MB exceeds critical threshold ${MEMORY_CRITICAL}MB" >> $ALERT_LOG
        alerts_triggered=$((alerts_triggered + 1))
    elif [ "$memory_mb" -gt "$MEMORY_WARNING" ]; then
        echo "[$timestamp] WARNING: Memory usage ${memory_mb}MB exceeds warning threshold ${MEMORY_WARNING}MB" >> $ALERT_LOG
        alerts_triggered=$((alerts_triggered + 1))
    fi
    
    # Client connection alerts
    if [ "$clients" -gt "$CLIENTS_CRITICAL" ]; then
        echo "[$timestamp] CRITICAL: Connected clients $clients exceeds critical threshold $CLIENTS_CRITICAL" >> $ALERT_LOG
        alerts_triggered=$((alerts_triggered + 1))
    elif [ "$clients" -gt "$CLIENTS_WARNING" ]; then
        echo "[$timestamp] WARNING: Connected clients $clients exceeds warning threshold $CLIENTS_WARNING" >> $ALERT_LOG
        alerts_triggered=$((alerts_triggered + 1))
    fi
    
    # Hit ratio alerts
    if [ "$hit_ratio_int" -lt "$HIT_RATIO_CRITICAL" ]; then
        echo "[$timestamp] CRITICAL: Cache hit ratio ${hit_ratio_int}% below critical threshold ${HIT_RATIO_CRITICAL}%" >> $ALERT_LOG
        alerts_triggered=$((alerts_triggered + 1))
    elif [ "$hit_ratio_int" -lt "$HIT_RATIO_WARNING" ]; then
        echo "[$timestamp] WARNING: Cache hit ratio ${hit_ratio_int}% below warning threshold ${HIT_RATIO_WARNING}%" >> $ALERT_LOG
        alerts_triggered=$((alerts_triggered + 1))
    fi
    
    # Slow operations alerts
    if [ "$slow_ops" -gt "$SLOW_OPS_CRITICAL" ]; then
        echo "[$timestamp] CRITICAL: Slow operations $slow_ops exceeds critical threshold $SLOW_OPS_CRITICAL" >> $ALERT_LOG
        alerts_triggered=$((alerts_triggered + 1))
    elif [ "$slow_ops" -gt "$SLOW_OPS_WARNING" ]; then
        echo "[$timestamp] WARNING: Slow operations $slow_ops exceeds warning threshold $SLOW_OPS_WARNING" >> $ALERT_LOG
        alerts_triggered=$((alerts_triggered + 1))
    fi
    
    # Fragmentation alerts
    if [ $(echo "$fragmentation > $FRAGMENTATION_CRITICAL" | bc -l) -eq 1 ]; then
        echo "[$timestamp] CRITICAL: Memory fragmentation $fragmentation exceeds critical threshold $FRAGMENTATION_CRITICAL" >> $ALERT_LOG
        alerts_triggered=$((alerts_triggered + 1))
    elif [ $(echo "$fragmentation > $FRAGMENTATION_WARNING" | bc -l) -eq 1 ]; then
        echo "[$timestamp] WARNING: Memory fragmentation $fragmentation exceeds warning threshold $FRAGMENTATION_WARNING" >> $ALERT_LOG
        alerts_triggered=$((alerts_triggered + 1))
    fi
    
    # Update status file
    echo "Last check: $timestamp" > $STATUS_FILE
    echo "Alerts triggered: $alerts_triggered" >> $STATUS_FILE
    echo "Memory: ${memory_mb}MB" >> $STATUS_FILE
    echo "Clients: $clients" >> $STATUS_FILE
    echo "Hit ratio: ${hit_ratio_int}%" >> $STATUS_FILE
    echo "Slow ops: $slow_ops" >> $STATUS_FILE
    echo "Fragmentation: $fragmentation" >> $STATUS_FILE
    
    if [ $alerts_triggered -eq 0 ]; then
        echo "[$timestamp] INFO: All systems normal" >> $ALERT_LOG
        echo "✅ All systems normal"
    else
        echo "⚠️  $alerts_triggered alerts triggered - check $ALERT_LOG"
    fi
    
    return $alerts_triggered
}

# Run the check
check_alerts
ALERTSCRIPT

chmod +x $ALERT_SCRIPT

# Create test alerts script
cat > scripts/test-alerts.sh << 'EOF'
#!/bin/bash

echo "🧪 Testing alert system..."

# Test by running the alert checker
monitoring/check-alerts.sh

echo ""
echo "📋 Alert configuration:"
cat monitoring/alert-config.conf

echo ""
echo "📊 Current alert status:"
if [ -f monitoring/alert-status.txt ]; then
    cat monitoring/alert-status.txt
else
    echo "No status file yet - run alerts checker first"
fi

echo ""
echo "📜 Recent alerts:"
if [ -f monitoring/alerts.log ]; then
    tail -10 monitoring/alerts.log
else
    echo "No alerts logged yet"
fi
