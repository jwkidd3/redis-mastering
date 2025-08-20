#!/bin/bash

echo "📊 Setting up Redis Monitoring for Insurance Production"
echo "======================================================"

HOST=${REDIS_HOST:-localhost}
PORT=${REDIS_PORT:-6379}

# Create monitoring directories
mkdir -p monitoring/{logs,alerts,reports}

echo "📝 Creating monitoring configuration..."

# Create Redis Insight connection file
cat > monitoring/redis-insight-connection.json << INSIGHT
{
  "name": "Insurance Production",
  "host": "$HOST",
  "port": $PORT,
  "password": "",
  "username": "",
  "tls": false,
  "sentinelMaster": "",
  "databases": [0]
}
INSIGHT

echo "✅ Redis Insight connection configuration created"

# Create basic monitoring script
cat > monitoring/monitor-redis.sh << 'MONITOR'
#!/bin/bash

# Simple Redis monitoring script
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
LOG_FILE="monitoring/logs/redis-monitor.log"

echo "[$TIMESTAMP] Starting Redis monitoring check..." >> $LOG_FILE

# Check basic health
if redis-cli -h $REDIS_HOST -p $REDIS_PORT ping &>/dev/null; then
    echo "[$TIMESTAMP] Health: OK" >> $LOG_FILE
else
    echo "[$TIMESTAMP] Health: FAILED" >> $LOG_FILE
fi

# Log key metrics
MEMORY_USED=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO memory | grep "used_memory_human" | cut -d: -f2 | tr -d '\r')
CONNECTED_CLIENTS=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO clients | grep "connected_clients" | cut -d: -f2 | tr -d '\r')
TOTAL_COMMANDS=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO stats | grep "total_commands_processed" | cut -d: -f2 | tr -d '\r')

echo "[$TIMESTAMP] Memory: $MEMORY_USED, Clients: $CONNECTED_CLIENTS, Commands: $TOTAL_COMMANDS" >> $LOG_FILE
MONITOR

chmod +x monitoring/monitor-redis.sh

echo "🔔 Creating alert thresholds..."
cat > monitoring/alerts/thresholds.conf << 'THRESHOLDS'
# Redis Monitoring Thresholds for Insurance Production
MAX_MEMORY_USAGE_MB=900
MAX_CONNECTED_CLIENTS=800
MAX_SLOW_LOG_ENTRIES=50
MIN_KEYSPACE_HIT_RATE=0.8
MAX_MEMORY_FRAGMENTATION=2.0
THRESHOLDS

echo "📈 Creating performance report template..."
cat > monitoring/reports/performance-report-template.md << 'REPORT'
# Redis Performance Report - Insurance Production

**Date:** $(date)
**Redis Host:** $REDIS_HOST:$REDIS_PORT

## Key Metrics

### Memory Usage
- Used Memory: $(redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO memory | grep "used_memory_human")
- Max Memory: $(redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG GET maxmemory)
- Fragmentation: $(redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO memory | grep "mem_fragmentation_ratio")

### Performance
- Total Commands: $(redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO stats | grep "total_commands_processed")
- Keyspace Hits: $(redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO stats | grep "keyspace_hits")
- Keyspace Misses: $(redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO stats | grep "keyspace_misses")

### Insurance Data
- Policies: $(redis-cli -h $REDIS_HOST -p $REDIS_PORT KEYS "policy:*" | wc -l)
- Customers: $(redis-cli -h $REDIS_HOST -p $REDIS_PORT KEYS "customer:*" | wc -l)
- Claims: $(redis-cli -h $REDIS_HOST -p $REDIS_PORT KEYS "claim:*" | wc -l)
REPORT

echo ""
echo "✅ Monitoring setup completed!"
echo ""
echo "📊 Monitoring Components Created:"
echo "├── monitoring/redis-insight-connection.json"
echo "├── monitoring/monitor-redis.sh"
echo "├── monitoring/alerts/thresholds.conf"
echo "└── monitoring/reports/performance-report-template.md"
echo ""
echo "🔍 Next Steps:"
echo "1. Import redis-insight-connection.json into Redis Insight"
echo "2. Run './monitoring/monitor-redis.sh' to start basic monitoring"
echo "3. Set up cron job for automated monitoring"
echo "4. Customize alert thresholds in monitoring/alerts/thresholds.conf"
