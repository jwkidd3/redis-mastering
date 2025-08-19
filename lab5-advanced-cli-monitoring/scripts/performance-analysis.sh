#!/bin/bash

# Comprehensive Redis performance analysis
echo "⚡ Running Redis Performance Analysis..."

# Redis connection configuration
REDIS_HOST=${REDIS_HOST:-localhost}
REDIS_PORT=${REDIS_PORT:-6379}
REDIS_PASSWORD=${REDIS_PASSWORD:-}

# Build Redis CLI command with connection parameters
REDIS_CLI_CMD="redis-cli -h $REDIS_HOST -p $REDIS_PORT"
if [ -n "$REDIS_PASSWORD" ]; then
    REDIS_CLI_CMD="$REDIS_CLI_CMD -a $REDIS_PASSWORD"
fi

echo "🔗 Analyzing Redis performance at $REDIS_HOST:$REDIS_PORT"

REPORT_FILE="analysis/performance-report.txt"
mkdir -p analysis

# Create performance report
cat > $REPORT_FILE << REPORT
Redis Performance Analysis Report
=================================
Generated: $(date)
Redis Host: $REDIS_HOST:$REDIS_PORT

1. Server Information
--------------------
$($REDIS_CLI_CMD INFO server | grep -E "(redis_version|uptime_in_seconds|tcp_port)")

2. Memory Analysis
-----------------
$($REDIS_CLI_CMD INFO memory | grep -E "(used_memory|fragmentation|peak)")

3. Performance Statistics
------------------------
$($REDIS_CLI_CMD INFO stats | grep -E "(total_commands|ops_per_sec|keyspace)")

4. Client Information
--------------------
$($REDIS_CLI_CMD INFO clients)

5. Database Statistics
---------------------
$($REDIS_CLI_CMD INFO keyspace)

6. Recent Slow Operations
------------------------
$($REDIS_CLI_CMD SLOWLOG GET 10)

7. Configuration Analysis
------------------------
$($REDIS_CLI_CMD CONFIG GET "*timeout*")
$($REDIS_CLI_CMD CONFIG GET "maxmemory*")

8. Key Distribution Analysis
---------------------------
REPORT

# Add key distribution analysis
echo "Analyzing key patterns..." >> $REPORT_FILE
$REDIS_CLI_CMD EVAL "
local patterns = {}
local keys = redis.call('KEYS', '*')
for i=1,#keys do
    local pattern = string.match(keys[i], '^([^:]+):')
    if pattern then
        if patterns[pattern] then
            patterns[pattern] = patterns[pattern] + 1
        else
            patterns[pattern] = 1
        end
    end
end
local result = {}
for k,v in pairs(patterns) do
    table.insert(result, k .. ': ' .. v .. ' keys')
end
return table.concat(result, '\n')
" 0 >> $REPORT_FILE

echo "" >> $REPORT_FILE
echo "9. Memory Usage by Data Type" >> $REPORT_FILE
echo "-----------------------------" >> $REPORT_FILE
$REDIS_CLI_CMD --bigkeys >> $REPORT_FILE 2>&1

echo "" >> $REPORT_FILE
echo "10. Performance Recommendations" >> $REPORT_FILE
echo "-------------------------------" >> $REPORT_FILE

# Add recommendations based on analysis
USED_MEMORY=$($REDIS_CLI_CMD INFO memory | grep "used_memory:" | cut -d: -f2 | sed 's/\r//')
FRAGMENTATION=$($REDIS_CLI_CMD INFO memory | grep "mem_fragmentation_ratio:" | cut -d: -f2 | sed 's/\r//')
CONNECTED_CLIENTS=$($REDIS_CLI_CMD INFO clients | grep "connected_clients:" | cut -d: -f2 | sed 's/\r//')

echo "Memory Usage: $(($USED_MEMORY / 1024 / 1024)) MB" >> $REPORT_FILE
echo "Fragmentation Ratio: $FRAGMENTATION" >> $REPORT_FILE
echo "Connected Clients: $CONNECTED_CLIENTS" >> $REPORT_FILE
echo "" >> $REPORT_FILE

# Performance recommendations
if (( $(echo "$FRAGMENTATION > 1.5" | bc -l) )); then
    echo "⚠️  HIGH FRAGMENTATION: Consider memory defragmentation" >> $REPORT_FILE
fi

if [ "$CONNECTED_CLIENTS" -gt 100 ]; then
    echo "⚠️  HIGH CLIENT COUNT: Monitor connection pooling" >> $REPORT_FILE
fi

if [ "$(($USED_MEMORY / 1024 / 1024))" -gt 500 ]; then
    echo "⚠️  HIGH MEMORY USAGE: Consider data archival or scaling" >> $REPORT_FILE
fi

echo "✅ Performance analysis complete!"
echo "📊 Report saved to: $REPORT_FILE"
cat $REPORT_FILE
