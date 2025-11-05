#!/bin/bash

# Comprehensive Redis health check and report

REDIS_HOST="redis-server.training.com"
REDIS_PORT="6379"
REPORT_FILE="analysis/health-report.txt"

mkdir -p analysis

echo "🏥 Redis Health Report" > $REPORT_FILE
echo "=====================" >> $REPORT_FILE
echo "Generated: $(date)" >> $REPORT_FILE
echo "" >> $REPORT_FILE

# Function to check connection
check_connection() {
    echo "🔌 CONNECTION STATUS:" >> $REPORT_FILE
    if redis-cli -h $REDIS_HOST -p $REDIS_PORT ping >/dev/null 2>&1; then
        echo "✅ Redis connection: OK" >> $REPORT_FILE
        SERVER_INFO=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO server 2>/dev/null)
        echo "   Server: $(echo "$SERVER_INFO" | grep redis_version | cut -d: -f2)" >> $REPORT_FILE
        echo "   Mode: $(redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO replication | grep role | cut -d: -f2)" >> $REPORT_FILE
        echo "   Uptime: $(echo "$SERVER_INFO" | grep uptime_in_seconds | cut -d: -f2) seconds" >> $REPORT_FILE
        return 0
    else
        echo "❌ Redis connection: FAILED" >> $REPORT_FILE
        return 1
    fi
    echo "" >> $REPORT_FILE
}

# Function to check memory health
check_memory() {
    echo "💾 MEMORY HEALTH:" >> $REPORT_FILE
    
    MEMORY_INFO=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO memory 2>/dev/null)
    if [ $? -eq 0 ]; then
        USED_MEMORY=$(echo "$MEMORY_INFO" | grep "used_memory_human:" | cut -d: -f2)
        PEAK_MEMORY=$(echo "$MEMORY_INFO" | grep "used_memory_peak_human:" | cut -d: -f2)
        FRAGMENTATION=$(echo "$MEMORY_INFO" | grep "mem_fragmentation_ratio:" | cut -d: -f2)
        
        echo "   Used Memory: ${USED_MEMORY}" >> $REPORT_FILE
        echo "   Peak Memory: ${PEAK_MEMORY}" >> $REPORT_FILE
        echo "   Fragmentation Ratio: ${FRAGMENTATION}" >> $REPORT_FILE
        
        # Memory warnings
        FRAGMENTATION_NUM=$(echo $FRAGMENTATION | cut -d. -f1)
        if [ "$FRAGMENTATION_NUM" -gt 1 ]; then
            if [ "$FRAGMENTATION_NUM" -gt 2 ]; then
                echo "   ⚠️  WARNING: High memory fragmentation (${FRAGMENTATION})" >> $REPORT_FILE
            fi
        fi
    else
        echo "   ❌ Unable to retrieve memory information" >> $REPORT_FILE
    fi
    echo "" >> $REPORT_FILE
}

# Function to check performance
check_performance() {
    echo "⚡ PERFORMANCE METRICS:" >> $REPORT_FILE
    
    STATS_INFO=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO stats 2>/dev/null)
    if [ $? -eq 0 ]; then
        TOTAL_COMMANDS=$(echo "$STATS_INFO" | grep "total_commands_processed:" | cut -d: -f2)
        HITS=$(echo "$STATS_INFO" | grep "keyspace_hits:" | cut -d: -f2)
        MISSES=$(echo "$STATS_INFO" | grep "keyspace_misses:" | cut -d: -f2)
        
        echo "   Total Commands: ${TOTAL_COMMANDS}" >> $REPORT_FILE
        echo "   Keyspace Hits: ${HITS}" >> $REPORT_FILE
        echo "   Keyspace Misses: ${MISSES}" >> $REPORT_FILE
        
        # Calculate hit ratio
        if [ "$HITS" != "" ] && [ "$MISSES" != "" ]; then
            TOTAL_HITS=$((HITS + MISSES))
            if [ $TOTAL_HITS -gt 0 ]; then
                HIT_RATIO=$(echo "scale=2; $HITS * 100 / $TOTAL_HITS" | bc -l 2>/dev/null || echo "0")
                echo "   Hit Ratio: ${HIT_RATIO}%" >> $REPORT_FILE
                
                # Performance warnings
                HIT_RATIO_NUM=$(echo $HIT_RATIO | cut -d. -f1)
                if [ "$HIT_RATIO_NUM" -lt 80 ]; then
                    echo "   ⚠️  WARNING: Low cache hit ratio (${HIT_RATIO}%)" >> $REPORT_FILE
                fi
            fi
        fi
    fi
    echo "" >> $REPORT_FILE
}

# Function to check data integrity
check_data_integrity() {
    echo "🔒 DATA INTEGRITY:" >> $REPORT_FILE
    
    TOTAL_KEYS=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT DBSIZE 2>/dev/null)
    echo "   Total Keys: ${TOTAL_KEYS}" >> $REPORT_FILE
    
    # Check for expired keys
    EXPIRED_KEYS=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO stats | grep "expired_keys:" | cut -d: -f2)
    echo "   Expired Keys: ${EXPIRED_KEYS}" >> $REPORT_FILE
    
    # Check data distribution
    DATA_DIST=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT EVAL "
    local stats = {}
    stats.customers = #redis.call('KEYS', 'customer:*')
    stats.policies = #redis.call('KEYS', 'policy:*')
    stats.claims = #redis.call('KEYS', 'claim:*')
    stats.sessions = #redis.call('KEYS', 'session:*')
    return cjson.encode(stats)
    " 0 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        echo "   Data Distribution:" >> $REPORT_FILE
        echo "$DATA_DIST" | sed 's/[{}"]//g' | sed 's/,/\n      /g' | sed 's/:/: /' >> $REPORT_FILE
    fi
    
    echo "" >> $REPORT_FILE
}

# Function to check slow operations
check_slow_operations() {
    echo "🐌 SLOW OPERATIONS:" >> $REPORT_FILE
    
    SLOW_LOG=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT SLOWLOG GET 5 2>/dev/null)
    if [ $? -eq 0 ]; then
        SLOW_COUNT=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT SLOWLOG LEN 2>/dev/null)
        echo "   Slow Operations Count: ${SLOW_COUNT}" >> $REPORT_FILE
        
        if [ "$SLOW_COUNT" -gt 0 ]; then
            echo "   Recent Slow Operations:" >> $REPORT_FILE
            echo "$SLOW_LOG" | head -10 >> $REPORT_FILE
        else
            echo "   ✅ No slow operations detected" >> $REPORT_FILE
        fi
    fi
    echo "" >> $REPORT_FILE
}

# Function to generate recommendations
generate_recommendations() {
    echo "💡 RECOMMENDATIONS:" >> $REPORT_FILE
    echo "1. Monitor memory usage trends" >> $REPORT_FILE
    echo "2. Set up regular backup procedures" >> $REPORT_FILE
    echo "3. Implement automated alerts for critical metrics" >> $REPORT_FILE
    echo "4. Review TTL strategies for temporary data" >> $REPORT_FILE
    echo "5. Consider Redis clustering for high availability" >> $REPORT_FILE
    echo "6. Regular performance benchmarking" >> $REPORT_FILE
    echo "" >> $REPORT_FILE
}

# Main execution
echo "🏥 Generating comprehensive health report..."

if check_connection; then
    check_memory
    check_performance
    check_data_integrity
    check_slow_operations
    generate_recommendations
    
    echo "Report generated: $(date)" >> $REPORT_FILE
    
    echo "✅ Health report generated: $REPORT_FILE"
    echo ""
    echo "📋 Report Summary:"
    head -20 $REPORT_FILE
    echo ""
    echo "💡 Full report available at: $REPORT_FILE"
else
    echo "❌ Cannot generate report: Redis connection failed"
fi
