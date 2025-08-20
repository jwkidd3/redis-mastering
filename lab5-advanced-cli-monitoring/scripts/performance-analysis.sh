#!/bin/bash

# Performance analysis and benchmarking script

REDIS_HOST="redis-server.training.com"
REDIS_PORT="6379"
REPORT_FILE="analysis/performance-report.txt"

mkdir -p analysis

echo "⚡ Redis Performance Analysis Report" > $REPORT_FILE
echo "====================================" >> $REPORT_FILE
echo "Generated: $(date)" >> $REPORT_FILE
echo "" >> $REPORT_FILE

# Function to run basic performance tests
run_performance_tests() {
    echo "🚀 PERFORMANCE BENCHMARKS:" >> $REPORT_FILE
    echo "" >> $REPORT_FILE
    
    # Test SET operations
    echo "   SET Operations Benchmark:" >> $REPORT_FILE
    SET_RESULT=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT --latency-history -i 1 SET test_key test_value 2>/dev/null | head -1)
    echo "      Result: ${SET_RESULT:-Not available}" >> $REPORT_FILE
    
    # Test GET operations
    echo "   GET Operations Benchmark:" >> $REPORT_FILE
    GET_RESULT=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT --latency-history -i 1 GET test_key 2>/dev/null | head -1)
    echo "      Result: ${GET_RESULT:-Not available}" >> $REPORT_FILE
    
    # Test PING latency
    echo "   PING Latency Test:" >> $REPORT_FILE
    PING_RESULT=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT --latency -i 1 2>/dev/null | head -1)
    echo "      Result: ${PING_RESULT:-Not available}" >> $REPORT_FILE
    
    echo "" >> $REPORT_FILE
}

# Function to analyze current performance metrics
analyze_current_performance() {
    echo "📊 CURRENT PERFORMANCE METRICS:" >> $REPORT_FILE
    
    STATS_INFO=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO stats 2>/dev/null)
    if [ $? -eq 0 ]; then
        TOTAL_COMMANDS=$(echo "$STATS_INFO" | grep "total_commands_processed:" | cut -d: -f2)
        TOTAL_CONNECTIONS=$(echo "$STATS_INFO" | grep "total_connections_received:" | cut -d: -f2)
        REJECTED_CONNECTIONS=$(echo "$STATS_INFO" | grep "rejected_connections:" | cut -d: -f2)
        
        echo "   Total Commands Processed: ${TOTAL_COMMANDS}" >> $REPORT_FILE
        echo "   Total Connections: ${TOTAL_CONNECTIONS}" >> $REPORT_FILE
        echo "   Rejected Connections: ${REJECTED_CONNECTIONS}" >> $REPORT_FILE
        
        # Calculate command rate (if uptime available)
        SERVER_INFO=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO server 2>/dev/null)
        UPTIME_SECONDS=$(echo "$SERVER_INFO" | grep "uptime_in_seconds:" | cut -d: -f2)
        
        if [ "$UPTIME_SECONDS" != "" ] && [ "$UPTIME_SECONDS" -gt 0 ]; then
            COMMANDS_PER_SEC=$((TOTAL_COMMANDS / UPTIME_SECONDS))
            echo "   Average Commands/Second: ${COMMANDS_PER_SEC}" >> $REPORT_FILE
        fi
    fi
    
    echo "" >> $REPORT_FILE
}

# Function to check slow operations
analyze_slow_operations() {
    echo "🐌 SLOW OPERATIONS ANALYSIS:" >> $REPORT_FILE
    
    SLOW_COUNT=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT SLOWLOG LEN 2>/dev/null)
    echo "   Slow Operations Count: ${SLOW_COUNT}" >> $REPORT_FILE
    
    if [ "$SLOW_COUNT" -gt 0 ]; then
        echo "   Recent Slow Operations:" >> $REPORT_FILE
        SLOW_LOG=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT SLOWLOG GET 3 2>/dev/null)
        echo "$SLOW_LOG" | sed 's/^/      /' >> $REPORT_FILE
    else
        echo "   ✅ No slow operations detected" >> $REPORT_FILE
    fi
    
    echo "" >> $REPORT_FILE
}

# Function to analyze memory performance
analyze_memory_performance() {
    echo "💾 MEMORY PERFORMANCE:" >> $REPORT_FILE
    
    MEMORY_INFO=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO memory 2>/dev/null)
    if [ $? -eq 0 ]; then
        USED_MEMORY=$(echo "$MEMORY_INFO" | grep "used_memory_human:" | cut -d: -f2)
        FRAGMENTATION=$(echo "$MEMORY_INFO" | grep "mem_fragmentation_ratio:" | cut -d: -f2)
        
        echo "   Memory Usage: ${USED_MEMORY}" >> $REPORT_FILE
        echo "   Fragmentation Ratio: ${FRAGMENTATION}" >> $REPORT_FILE
        
        # Memory efficiency analysis
        TOTAL_KEYS=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT DBSIZE 2>/dev/null)
        USED_MEMORY_BYTES=$(echo "$MEMORY_INFO" | grep "used_memory:" | head -1 | cut -d: -f2)
        
        if [ "$TOTAL_KEYS" -gt 0 ] && [ "$USED_MEMORY_BYTES" != "" ]; then
            AVG_MEMORY_PER_KEY=$((USED_MEMORY_BYTES / TOTAL_KEYS))
            echo "   Average Memory per Key: ${AVG_MEMORY_PER_KEY} bytes" >> $REPORT_FILE
        fi
    fi
    
    echo "" >> $REPORT_FILE
}

# Function to generate performance recommendations
generate_performance_recommendations() {
    echo "💡 PERFORMANCE OPTIMIZATION RECOMMENDATIONS:" >> $REPORT_FILE
    echo "1. Monitor and optimize slow operations" >> $REPORT_FILE
    echo "2. Implement connection pooling for high-traffic applications" >> $REPORT_FILE
    echo "3. Use appropriate data structures for your use case" >> $REPORT_FILE
    echo "4. Set up regular performance benchmarking" >> $REPORT_FILE
    echo "5. Monitor memory fragmentation and defragment if needed" >> $REPORT_FILE
    echo "6. Consider read replicas for read-heavy workloads" >> $REPORT_FILE
    echo "7. Optimize key naming patterns for better performance" >> $REPORT_FILE
    echo "8. Use pipelining for bulk operations" >> $REPORT_FILE
    echo "" >> $REPORT_FILE
}

# Main execution
echo "⚡ Generating performance analysis report..."

run_performance_tests
analyze_current_performance
analyze_slow_operations
analyze_memory_performance
generate_performance_recommendations

echo "Report generated: $(date)" >> $REPORT_FILE

echo "✅ Performance analysis completed: $REPORT_FILE"
echo ""
echo "📋 Report Summary:"
head -25 $REPORT_FILE
echo ""
echo "💡 Full report available at: $REPORT_FILE"
