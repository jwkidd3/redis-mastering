#!/bin/bash

# Fixed Capacity planning and growth analysis script
# Compatible with systems that may not have 'bc' installed

REDIS_HOST="redis-server.training.com"
REDIS_PORT="6379"
REPORT_FILE="analysis/capacity-report.txt"

mkdir -p analysis

echo "📈 Redis Capacity Planning Report" > $REPORT_FILE
echo "=================================" >> $REPORT_FILE
echo "Generated: $(date)" >> $REPORT_FILE
echo "" >> $REPORT_FILE

# Function to perform integer math (avoiding bc dependency)
calculate_percentage() {
    local numerator=$1
    local denominator=$2
    if [ "$denominator" -eq 0 ]; then
        echo "0"
    else
        echo $(( (numerator * 100) / denominator ))
    fi
}

# Function to get current metrics
get_current_metrics() {
    echo "📊 CURRENT METRICS:" >> $REPORT_FILE
    
    # Memory metrics
    MEMORY_INFO=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO memory 2>/dev/null)
    if [ $? -eq 0 ]; then
        USED_MEMORY_BYTES=$(echo "$MEMORY_INFO" | grep "used_memory:" | head -1 | cut -d: -f2 | tr -d '\r')
        USED_MEMORY_HUMAN=$(echo "$MEMORY_INFO" | grep "used_memory_human:" | cut -d: -f2 | tr -d '\r')
        PEAK_MEMORY_HUMAN=$(echo "$MEMORY_INFO" | grep "used_memory_peak_human:" | cut -d: -f2 | tr -d '\r')
        FRAGMENTATION=$(echo "$MEMORY_INFO" | grep "mem_fragmentation_ratio:" | cut -d: -f2 | tr -d '\r')
        
        echo "   Current Memory Usage: ${USED_MEMORY_HUMAN}" >> $REPORT_FILE
        echo "   Peak Memory Usage: ${PEAK_MEMORY_HUMAN}" >> $REPORT_FILE
        echo "   Memory Usage (bytes): ${USED_MEMORY_BYTES}" >> $REPORT_FILE
        echo "   Fragmentation Ratio: ${FRAGMENTATION}" >> $REPORT_FILE
    else
        echo "   ❌ Unable to retrieve memory information" >> $REPORT_FILE
        USED_MEMORY_BYTES="0"
    fi
    
    # Key metrics
    TOTAL_KEYS=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT DBSIZE 2>/dev/null)
    if [ $? -eq 0 ]; then
        echo "   Total Keys: ${TOTAL_KEYS}" >> $REPORT_FILE
    else
        echo "   ❌ Unable to retrieve key count" >> $REPORT_FILE
        TOTAL_KEYS="0"
    fi
    
    # Client connections
    CLIENTS_INFO=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO clients 2>/dev/null)
    if [ $? -eq 0 ]; then
        CONNECTED_CLIENTS=$(echo "$CLIENTS_INFO" | grep "connected_clients:" | cut -d: -f2 | tr -d '\r')
        MAX_CLIENTS=$(echo "$CLIENTS_INFO" | grep "maxclients:" | cut -d: -f2 | tr -d '\r')
        echo "   Connected Clients: ${CONNECTED_CLIENTS}" >> $REPORT_FILE
        echo "   Max Clients: ${MAX_CLIENTS}" >> $REPORT_FILE
    else
        echo "   ❌ Unable to retrieve client information" >> $REPORT_FILE
    fi
    
    echo "" >> $REPORT_FILE
}

# Function to analyze key distribution
analyze_key_distribution() {
    echo "🗝️  KEY DISTRIBUTION ANALYSIS:" >> $REPORT_FILE
    
    # Get key counts by pattern using SCAN instead of KEYS for better performance
    CUSTOMER_KEYS=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT EVAL "return #redis.call('keys', 'customer:*')" 0 2>/dev/null || echo "0")
    POLICY_KEYS=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT EVAL "return #redis.call('keys', 'policy:*')" 0 2>/dev/null || echo "0")
    CLAIM_KEYS=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT EVAL "return #redis.call('keys', 'claim:*')" 0 2>/dev/null || echo "0")
    SESSION_KEYS=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT EVAL "return #redis.call('keys', 'session:*')" 0 2>/dev/null || echo "0")
    ANALYTICS_KEYS=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT EVAL "return #redis.call('keys', 'analytics:*')" 0 2>/dev/null || echo "0")
    CACHE_KEYS=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT EVAL "return #redis.call('keys', 'cache:*')" 0 2>/dev/null || echo "0")
    QUOTE_KEYS=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT EVAL "return #redis.call('keys', 'quote:*')" 0 2>/dev/null || echo "0")
    
    echo "   Key Distribution by Type:" >> $REPORT_FILE
    echo "      customers: ${CUSTOMER_KEYS}" >> $REPORT_FILE
    echo "      policies: ${POLICY_KEYS}" >> $REPORT_FILE
    echo "      claims: ${CLAIM_KEYS}" >> $REPORT_FILE
    echo "      sessions: ${SESSION_KEYS}" >> $REPORT_FILE
    echo "      analytics: ${ANALYTICS_KEYS}" >> $REPORT_FILE
    echo "      cache: ${CACHE_KEYS}" >> $REPORT_FILE
    echo "      quotes: ${QUOTE_KEYS}" >> $REPORT_FILE
    echo "      total: ${TOTAL_KEYS}" >> $REPORT_FILE
    
    # Calculate percentages
    if [ "$TOTAL_KEYS" -gt 0 ]; then
        CUSTOMER_PCT=$(calculate_percentage $CUSTOMER_KEYS $TOTAL_KEYS)
        POLICY_PCT=$(calculate_percentage $POLICY_KEYS $TOTAL_KEYS)
        CLAIM_PCT=$(calculate_percentage $CLAIM_KEYS $TOTAL_KEYS)
        
        echo "" >> $REPORT_FILE
        echo "   Key Distribution Percentages:" >> $REPORT_FILE
        echo "      customers: ${CUSTOMER_PCT}%" >> $REPORT_FILE
        echo "      policies: ${POLICY_PCT}%" >> $REPORT_FILE
        echo "      claims: ${CLAIM_PCT}%" >> $REPORT_FILE
    fi
    
    echo "" >> $REPORT_FILE
}

# Function to project growth (using integer math)
project_growth() {
    echo "📈 GROWTH PROJECTIONS:" >> $REPORT_FILE
    
    # Current data points (ensure they're integers)
    CURRENT_KEYS_INT=$(echo "$TOTAL_KEYS" | grep -o '[0-9]*' | head -1)
    CURRENT_MEMORY_INT=$(echo "$USED_MEMORY_BYTES" | grep -o '[0-9]*' | head -1)
    
    # Set defaults if values are empty or invalid
    [ -z "$CURRENT_KEYS_INT" ] && CURRENT_KEYS_INT=0
    [ -z "$CURRENT_MEMORY_INT" ] && CURRENT_MEMORY_INT=0
    
    if [ "$CURRENT_KEYS_INT" -gt 0 ] && [ "$CURRENT_MEMORY_INT" -gt 0 ]; then
        # Calculate average memory per key (integer division)
        AVG_MEMORY_PER_KEY=$(( CURRENT_MEMORY_INT / CURRENT_KEYS_INT ))
        
        echo "   Current State:" >> $REPORT_FILE
        echo "      Keys: ${CURRENT_KEYS_INT}" >> $REPORT_FILE
        echo "      Memory: ${CURRENT_MEMORY_INT} bytes" >> $REPORT_FILE
        echo "      Avg Memory per Key: ${AVG_MEMORY_PER_KEY} bytes" >> $REPORT_FILE
        echo "" >> $REPORT_FILE
        
        # Project growth scenarios (20% monthly growth, using integer math)
        echo "   Growth Scenarios (assuming 20% monthly growth):" >> $REPORT_FILE
        
        # 3 months: 1.2^3 ≈ 1.73, using 173/100
        KEYS_3M=$(( CURRENT_KEYS_INT * 173 / 100 ))
        MEMORY_3M=$(( KEYS_3M * AVG_MEMORY_PER_KEY ))
        MEMORY_3M_MB=$(( MEMORY_3M / 1024 / 1024 ))
        echo "      3 Months: ${KEYS_3M} keys, ~${MEMORY_3M_MB}MB" >> $REPORT_FILE
        
        # 6 months: 1.2^6 ≈ 2.99, using 299/100
        KEYS_6M=$(( CURRENT_KEYS_INT * 299 / 100 ))
        MEMORY_6M=$(( KEYS_6M * AVG_MEMORY_PER_KEY ))
        MEMORY_6M_MB=$(( MEMORY_6M / 1024 / 1024 ))
        echo "      6 Months: ${KEYS_6M} keys, ~${MEMORY_6M_MB}MB" >> $REPORT_FILE
        
        # 12 months: 1.2^12 ≈ 8.91, using 891/100
        KEYS_12M=$(( CURRENT_KEYS_INT * 891 / 100 ))
        MEMORY_12M=$(( KEYS_12M * AVG_MEMORY_PER_KEY ))
        MEMORY_12M_MB=$(( MEMORY_12M / 1024 / 1024 ))
        echo "      12 Months: ${KEYS_12M} keys, ~${MEMORY_12M_MB}MB" >> $REPORT_FILE
        
        # Calculate growth rates
        GROWTH_3M_PCT=$(calculate_percentage $(( KEYS_3M - CURRENT_KEYS_INT )) $CURRENT_KEYS_INT)
        GROWTH_6M_PCT=$(calculate_percentage $(( KEYS_6M - CURRENT_KEYS_INT )) $CURRENT_KEYS_INT)
        GROWTH_12M_PCT=$(calculate_percentage $(( KEYS_12M - CURRENT_KEYS_INT )) $CURRENT_KEYS_INT)
        
        echo "" >> $REPORT_FILE
        echo "   Growth Rates:" >> $REPORT_FILE
        echo "      3 Months: +${GROWTH_3M_PCT}%" >> $REPORT_FILE
        echo "      6 Months: +${GROWTH_6M_PCT}%" >> $REPORT_FILE
        echo "      12 Months: +${GROWTH_12M_PCT}%" >> $REPORT_FILE
        
    else
        echo "   ⚠️  Insufficient data for growth projections" >> $REPORT_FILE
        echo "      Current Keys: ${CURRENT_KEYS_INT}" >> $REPORT_FILE
        echo "      Current Memory: ${CURRENT_MEMORY_INT} bytes" >> $REPORT_FILE
        echo "      Recommendation: Collect baseline metrics over time" >> $REPORT_FILE
    fi
    
    echo "" >> $REPORT_FILE
}

# Function to analyze capacity thresholds
analyze_capacity_thresholds() {
    echo "⚠️  CAPACITY THRESHOLDS:" >> $REPORT_FILE
    
    # Memory threshold analysis (assuming 1GB as warning, 2GB as critical)
    MEMORY_WARNING_BYTES=1073741824   # 1GB
    MEMORY_CRITICAL_BYTES=2147483648  # 2GB
    
    CURRENT_MEMORY_INT=$(echo "$USED_MEMORY_BYTES" | grep -o '[0-9]*' | head -1)
    [ -z "$CURRENT_MEMORY_INT" ] && CURRENT_MEMORY_INT=0
    
    if [ "$CURRENT_MEMORY_INT" -gt 0 ]; then
        WARNING_PCT=$(calculate_percentage $CURRENT_MEMORY_INT $MEMORY_WARNING_BYTES)
        CRITICAL_PCT=$(calculate_percentage $CURRENT_MEMORY_INT $MEMORY_CRITICAL_BYTES)
        
        echo "   Memory Usage Analysis:" >> $REPORT_FILE
        echo "      Current: ${CURRENT_MEMORY_INT} bytes" >> $REPORT_FILE
        echo "      Warning threshold (1GB): ${WARNING_PCT}%" >> $REPORT_FILE
        echo "      Critical threshold (2GB): ${CRITICAL_PCT}%" >> $REPORT_FILE
        
        if [ "$CURRENT_MEMORY_INT" -gt "$MEMORY_CRITICAL_BYTES" ]; then
            echo "      🚨 STATUS: CRITICAL - Immediate action required" >> $REPORT_FILE
        elif [ "$CURRENT_MEMORY_INT" -gt "$MEMORY_WARNING_BYTES" ]; then
            echo "      ⚠️  STATUS: WARNING - Monitor closely" >> $REPORT_FILE
        else
            echo "      ✅ STATUS: HEALTHY" >> $REPORT_FILE
        fi
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
    echo "8. Plan for hardware upgrades based on growth projections" >> $REPORT_FILE
    echo "9. Implement automated monitoring and alerting" >> $REPORT_FILE
    echo "10. Regular backup and disaster recovery testing" >> $REPORT_FILE
    
    echo "" >> $REPORT_FILE
    echo "📊 MONITORING RECOMMENDATIONS:" >> $REPORT_FILE
    echo "• Set up daily capacity reports" >> $REPORT_FILE
    echo "• Monitor key distribution changes" >> $REPORT_FILE
    echo "• Track memory fragmentation trends" >> $REPORT_FILE
    echo "• Establish baseline performance metrics" >> $REPORT_FILE
    echo "• Implement automated scaling triggers" >> $REPORT_FILE
}

# Function to check system dependencies
check_dependencies() {
    echo "🔧 Checking system dependencies..." >&2
    
    # Check if redis-cli is available
    if ! command -v redis-cli >/dev/null 2>&1; then
        echo "❌ redis-cli not found. Please install Redis CLI tools." >&2
        exit 1
    fi
    
    # Test Redis connection
    if ! redis-cli -h $REDIS_HOST -p $REDIS_PORT ping >/dev/null 2>&1; then
        echo "❌ Cannot connect to Redis at $REDIS_HOST:$REDIS_PORT" >&2
        echo "   Please check your Redis server configuration." >&2
        exit 1
    fi
    
    echo "✅ Dependencies check passed" >&2
}

# Main execution
echo "📈 Generating capacity planning report..."

# Check dependencies first
check_dependencies

# Generate report sections
get_current_metrics
analyze_key_distribution
project_growth
analyze_capacity_thresholds
generate_recommendations

echo "" >> $REPORT_FILE
echo "Report generated: $(date)" >> $REPORT_FILE
echo "Generated by: Redis Capacity Planning Script v2.0" >> $REPORT_FILE

echo "✅ Capacity planning report generated: $REPORT_FILE"
echo ""
echo "📋 Report Summary:"
echo "=================="
head -30 $REPORT_FILE
echo ""
echo "💡 Full report available at: $REPORT_FILE"
echo ""
echo "🔍 Key Insights:"
echo "• Total Keys: ${TOTAL_KEYS}"
echo "• Memory Usage: ${USED_MEMORY_BYTES} bytes"
echo "• Report contains growth projections and recommendations"