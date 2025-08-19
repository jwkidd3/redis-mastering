#!/bin/bash

# Comprehensive Redis health check and report

echo "🏥 Redis Health Report"
echo "===================="
echo "Generated: $(date)"
echo ""

# Function to check connection
check_connection() {
    echo "🔌 CONNECTION STATUS:"
    if redis-cli ping >/dev/null 2>&1; then
        echo "✅ Redis connection: OK"
        echo "   Server: $(redis-cli INFO server | grep redis_version | cut -d: -f2)"
        echo "   Mode: $(redis-cli INFO replication | grep role | cut -d: -f2)"
        echo "   Uptime: $(redis-cli INFO server | grep uptime_in_seconds | cut -d: -f2) seconds"
    else
        echo "❌ Redis connection: FAILED"
        return 1
    fi
    echo ""
}

# Function to check memory health
check_memory() {
    echo "💾 MEMORY HEALTH:"
    
    MEMORY_INFO=$(redis-cli INFO memory)
    USED_MEMORY=$(echo "$MEMORY_INFO" | grep "used_memory_human:" | cut -d: -f2)
    PEAK_MEMORY=$(echo "$MEMORY_INFO" | grep "used_memory_peak_human:" | cut -d: -f2)
    FRAGMENTATION=$(echo "$MEMORY_INFO" | grep "mem_fragmentation_ratio:" | cut -d: -f2)
    
    echo "   Used Memory: $USED_MEMORY"
    echo "   Peak Memory: $PEAK_MEMORY"
    echo "   Fragmentation: $FRAGMENTATION"
    
    # Health checks
    FRAG_CHECK=$(echo "$FRAGMENTATION > 1.5" | bc -l 2>/dev/null)
    if [ "$FRAG_CHECK" = "1" ]; then
        echo "   ⚠️  High fragmentation detected"
    else
        echo "   ✅ Fragmentation within normal range"
    fi
    echo ""
}

# Function to check performance
check_performance() {
    echo "⚡ PERFORMANCE HEALTH:"
    
    # Latency test
    echo "   Testing latency..."
    LATENCY=$(redis-cli --latency -h localhost -p 6379 -i 1 2>/dev/null | timeout 3s cat | tail -1)
    if [ -n "$LATENCY" ]; then
        echo "   ✅ Latency test completed"
        echo "   📊 $LATENCY"
    else
        echo "   ℹ️  Latency test skipped (requires time)"
    fi
    
    # Command stats
    COMMANDS=$(redis-cli INFO stats | grep "total_commands_processed:" | cut -d: -f2)
    echo "   Total Commands: $COMMANDS"
    
    # Slow log check
    SLOW_COUNT=$(redis-cli SLOWLOG LEN)
    echo "   Slow Operations: $SLOW_COUNT"
    
    if [ "$SLOW_COUNT" -gt 10 ]; then
        echo "   ⚠️  High number of slow operations"
    else
        echo "   ✅ Slow operations within normal range"
    fi
    echo ""
}

# Function to check data integrity
check_data_integrity() {
    echo "🔍 DATA INTEGRITY:"
    
    DBSIZE=$(redis-cli DBSIZE)
    echo "   Total Keys: $DBSIZE"
    
    # Check for keys without TTL that should have TTL
    SESSION_KEYS=$(redis-cli --scan --pattern "session:*" | wc -l)
    CACHE_KEYS=$(redis-cli --scan --pattern "cache:*" | wc -l)
    QUOTE_KEYS=$(redis-cli --scan --pattern "quote:*" | wc -l)
    
    echo "   Session Keys: $SESSION_KEYS"
    echo "   Cache Keys: $CACHE_KEYS"
    echo "   Quote Keys: $QUOTE_KEYS"
    
    # Check for orphaned or problematic keys
    PROBLEMATIC=0
    
    # Check sessions without TTL
    redis-cli --scan --pattern "session:*" | while read key; do
        TTL=$(redis-cli TTL "$key")
        if [ "$TTL" -eq -1 ]; then
            echo "   ⚠️  Session key without TTL: $key"
            PROBLEMATIC=$((PROBLEMATIC + 1))
        fi
    done
    
    if [ "$PROBLEMATIC" -eq 0 ]; then
        echo "   ✅ No data integrity issues detected"
    fi
    echo ""
}

# Function to check configuration
check_configuration() {
    echo "⚙️  CONFIGURATION:"
    
    # Check persistence
    AOF_ENABLED=$(redis-cli CONFIG GET appendonly | tail -1)
    SAVE_CONFIG=$(redis-cli CONFIG GET save | tail -1)
    
    echo "   AOF Enabled: $AOF_ENABLED"
    echo "   Save Config: $SAVE_CONFIG"
    
    # Check memory policy
    MAXMEMORY=$(redis-cli CONFIG GET maxmemory | tail -1)
    MAXMEMORY_POLICY=$(redis-cli CONFIG GET maxmemory-policy | tail -1)
    
    echo "   Max Memory: $MAXMEMORY"
    echo "   Eviction Policy: $MAXMEMORY_POLICY"
    
    # Recommendations
    if [ "$AOF_ENABLED" = "no" ] && [ "$SAVE_CONFIG" = "" ]; then
        echo "   ⚠️  No persistence configured"
    else
        echo "   ✅ Persistence configured"
    fi
    echo ""
}

# Function to check client connections
check_clients() {
    echo "👥 CLIENT CONNECTIONS:"
    
    CLIENT_INFO=$(redis-cli INFO clients)
    CONNECTED=$(echo "$CLIENT_INFO" | grep "connected_clients:" | cut -d: -f2)
    MAX_CLIENTS=$(redis-cli CONFIG GET maxclients | tail -1)
    
    echo "   Connected: $CONNECTED"
    echo "   Max Allowed: $MAX_CLIENTS"
    
    CLIENT_PERCENT=$(echo "scale=2; $CONNECTED * 100 / $MAX_CLIENTS" | bc -l 2>/dev/null || echo "N/A")
    echo "   Usage: $CLIENT_PERCENT%"
    
    if [ $(echo "$CLIENT_PERCENT > 80" | bc -l 2>/dev/null) ]; then
        echo "   ⚠️  High client connection usage"
    else
        echo "   ✅ Client connections within normal range"
    fi
    echo ""
}

# Function to generate overall health score
generate_health_score() {
    echo "📊 OVERALL HEALTH SCORE:"
    echo "======================="
    
    SCORE=100
    ISSUES=0
    
    # Deduct points for issues found
    # This is a simplified scoring system
    FRAGMENTATION=$(redis-cli INFO memory | grep "mem_fragmentation_ratio:" | cut -d: -f2)
    SLOW_COUNT=$(redis-cli SLOWLOG LEN)
    
    if [ $(echo "$FRAGMENTATION > 1.5" | bc -l 2>/dev/null) ]; then
        SCORE=$((SCORE - 10))
        ISSUES=$((ISSUES + 1))
    fi
    
    if [ "$SLOW_COUNT" -gt 10 ]; then
        SCORE=$((SCORE - 15))
        ISSUES=$((ISSUES + 1))
    fi
    
    echo "   Health Score: $SCORE/100"
    echo "   Issues Found: $ISSUES"
    
    if [ "$SCORE" -ge 90 ]; then
        echo "   Status: ✅ EXCELLENT"
    elif [ "$SCORE" -ge 70 ]; then
        echo "   Status: ⚠️  GOOD (monitor closely)"
    else
        echo "   Status: ❌ NEEDS ATTENTION"
    fi
    echo ""
}

# Main execution
check_connection
if [ $? -eq 0 ]; then
    check_memory
    check_performance
    check_data_integrity
    check_configuration
    check_clients
    generate_health_score
    
    echo "💡 RECOMMENDATIONS:"
    echo "   • Review this report regularly"
    echo "   • Monitor memory and performance trends"
    echo "   • Set up automated alerts for critical thresholds"
    echo "   • Use Redis Insight for detailed analysis"
fi
