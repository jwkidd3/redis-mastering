#!/bin/bash

# Capacity planning and growth analysis script

REDIS_HOST="redis-server.training.com"
REDIS_PORT="6379"
REPORT_FILE="analysis/capacity-report.txt"

mkdir -p analysis

echo "📈 Redis Capacity Planning Report" > $REPORT_FILE
echo "=================================" >> $REPORT_FILE
echo "Generated: $(date)" >> $REPORT_FILE
echo "" >> $REPORT_FILE

# Function to get current metrics
get_current_metrics() {
    echo "📊 CURRENT METRICS:" >> $REPORT_FILE
    
    # Memory metrics
    MEMORY_INFO=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO memory 2>/dev/null)
    if [ $? -eq 0 ]; then
        USED_MEMORY_BYTES=$(echo "$MEMORY_INFO" | grep "used_memory:" | head -1 | cut -d: -f2)
        USED_MEMORY_HUMAN=$(echo "$MEMORY_INFO" | grep "used_memory_human:" | cut -d: -f2)
        PEAK_MEMORY_HUMAN=$(echo "$MEMORY_INFO" | grep "used_memory_peak_human:" | cut -d: -f2)
        
        echo "   Current Memory Usage: ${USED_MEMORY_HUMAN}" >> $REPORT_FILE
        echo "   Peak Memory Usage: ${PEAK_MEMORY_HUMAN}" >> $REPORT_FILE
        echo "   Memory Usage (bytes): ${USED_MEMORY_BYTES}" >> $REPORT_FILE
    fi
    
    # Key metrics
    TOTAL_KEYS=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT DBSIZE 2>/dev/null)
    echo "   Total Keys: ${TOTAL_KEYS}" >> $REPORT_FILE
    
    # Client connections
    CLIENTS_INFO=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO clients 2>/dev/null)
    if [ $? -eq 0 ]; then
        CONNECTED_CLIENTS=$(echo "$CLIENTS_INFO" | grep "connected_clients:" | cut -d: -f2)
        MAX_CLIENTS=$(echo "$CLIENTS_INFO" | grep "maxclients:" | cut -d: -f2)
        echo "   Connected Clients: ${CONNECTED_CLIENTS}" >> $REPORT_FILE
        echo "   Max Clients: ${MAX_CLIENTS}" >> $REPORT_FILE
    fi
    
    echo "" >> $REPORT_FILE
}

# Function to analyze key distribution
analyze_key_distribution() {
    echo "🗝️  KEY DISTRIBUTION ANALYSIS:" >> $REPORT_FILE
    
    # Get key counts by pattern
    KEY_ANALYSIS=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT EVAL "
    local stats = {}
    stats.total = redis.call('DBSIZE')
    stats.customers = #redis.call('KEYS', 'customer:*')
    stats.policies = #redis.call('KEYS', 'policy:*')
    stats.claims = #redis.call('KEYS', 'claim:*')
    stats.sessions = #redis.call('KEYS', 'session:*')
    stats.analytics = #redis.call('KEYS', 'analytics:*')
    stats.cache = #redis.call('KEYS', 'cache:*')
    stats.quotes = #redis.call('KEYS', 'quote:*')
    return cjson.encode(stats)
    " 0 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        echo "   Key Distribution by Type:" >> $REPORT_FILE
        echo "$KEY_ANALYSIS" | sed 's/[{}"]//g' | sed 's/,/\n      /g' | sed 's/:/: /' >> $REPORT_FILE
    fi
    
    # Memory usage by key type
    echo "" >> $REPORT_FILE
    echo "   Memory Usage Analysis:" >> $REPORT_FILE
    BIGKEYS_OUTPUT=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT --bigkeys 2>/dev/null | grep "Biggest")
    if [ $? -eq 0 ]; then
        echo "$BIGKEYS_OUTPUT" | sed 's/^/      /' >> $REPORT_FILE
    fi
    
    echo "" >> $REPORT_FILE
}

# Function to project growth
project_growth() {
    echo "📈 GROWTH PROJECTIONS:" >> $REPORT_FILE
    
    # Current data points
    CURRENT_KEYS=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT DBSIZE 2>/dev/null)
    CURRENT_MEMORY_BYTES=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO memory | grep "used_memory:" | head -1 | cut -d: -f2)
    
    if [ "$CURRENT_KEYS" != "" ] && [ "$CURRENT_MEMORY_BYTES" != "" ]; then
        # Calculate average memory per key
        AVG_MEMORY_PER_KEY=$((CURRENT_MEMORY_BYTES / CURRENT_KEYS))
        
        echo "   Current State:" >> $REPORT_FILE
        echo "      Keys: ${CURRENT_KEYS}" >> $REPORT_FILE
        echo "      Memory: ${CURRENT_MEMORY_BYTES} bytes" >> $REPORT_FILE
        echo "      Avg Memory per Key: ${AVG_MEMORY_PER_KEY} bytes" >> $REPORT_FILE
        echo "" >> $REPORT_FILE
        
        # Project growth scenarios
        echo "   Growth Scenarios (assuming 20% monthly growth):" >> $REPORT_FILE
        
        # 3 months
        KEYS_3M=$((CURRENT_KEYS * 173 / 100))  # 1.2^3 ≈ 1.73
        MEMORY_3M=$((KEYS_3M * AVG_MEMORY_PER_KEY))
        MEMORY_3M_MB=$((MEMORY_3M / 1024 / 1024))
        echo "      3 Months: ${KEYS_3M} keys, ~${MEMORY_3M_MB}MB" >> $REPORT_FILE
        
        # 6 months
        KEYS_6M=$((CURRENT_KEYS * 299 / 100))  # 1.2^6 ≈ 2.99
        MEMORY_6M=$((KEYS_6M * AVG_MEMORY_PER_KEY))
        MEMORY_6M_MB=$((MEMORY_6M / 1024 / 1024))
        echo "      6 Months: ${KEYS_6M} keys, ~${MEMORY_6M_MB}MB" >> $REPORT_FILE
        
        # 12 months
        KEYS_12M=$((CURRENT_KEYS * 891 / 100))  # 1.2^12 ≈ 8.91
        MEMORY_12M=$((KEYS_12M * AVG_MEMORY_PER_KEY))
        MEMORY_12M_MB=$((MEMORY_12M / 1024 / 1024))
        echo "      12 Months: ${KEYS_12M} keys, ~${MEMORY_12M_MB}MB" >> $REPORT_FILE
    fi
    
    echo "" >> $REPORT_FILE
}

# Function to generate recommendations
generate_recommendations() {
    echo "💡 CAPACITY RECOMMENDATIONS:" >> $REPORT_FILE
    echo "1. Monitor memory usage trends weekly" >> $REPORT_FILE
    echo "2. Set up alerts for memory > 80% of available" >> $REPORT_FILE
    echo "3. Review TTL strategies for temporary data" >> $REPORT_FILE
    echo "4. Consider Redis clustering for horizontal scaling" >> $REPORT_FILE
    echo "5. Implement data archival for old records" >> $REPORT_FILE
    echo "6. Regular performance benchmarking" >> $REPORT_FILE
    echo "7. Monitor slow operations and optimize queries" >> $REPORT_FILE
}

# Main execution
echo "📈 Generating capacity planning report..."

get_current_metrics
analyze_key_distribution
project_growth
generate_recommendations

echo "" >> $REPORT_FILE
echo "Report generated: $(date)" >> $REPORT_FILE

echo "✅ Capacity planning report generated: $REPORT_FILE"
echo ""
echo "📋 Report Summary:"
cat $REPORT_FILE | head -30
echo ""
echo "💡 Full report available at: $REPORT_FILE"
