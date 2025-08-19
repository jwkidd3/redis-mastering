#!/bin/bash

# Redis capacity planning and growth analysis

REPORT_FILE="analysis/capacity-report-$(date +%Y%m%d).txt"
mkdir -p analysis

echo "📈 Redis Capacity Planning Report" > $REPORT_FILE
echo "Generated: $(date)" >> $REPORT_FILE
echo "=================================" >> $REPORT_FILE

# Function to get current metrics
get_current_metrics() {
    echo "" >> $REPORT_FILE
    echo "📊 CURRENT METRICS:" >> $REPORT_FILE
    echo "==================" >> $REPORT_FILE
    
    # Memory metrics
    MEMORY_USED=$(redis-cli INFO memory | grep "used_memory_human:" | cut -d: -f2)
    MEMORY_PEAK=$(redis-cli INFO memory | grep "used_memory_peak_human:" | cut -d: -f2)
    MEMORY_RSS=$(redis-cli INFO memory | grep "used_memory_rss_human:" | cut -d: -f2)
    FRAGMENTATION=$(redis-cli INFO memory | grep "mem_fragmentation_ratio:" | cut -d: -f2)
    
    echo "Memory Used: $MEMORY_USED" >> $REPORT_FILE
    echo "Memory Peak: $MEMORY_PEAK" >> $REPORT_FILE
    echo "Memory RSS: $MEMORY_RSS" >> $REPORT_FILE
    echo "Fragmentation Ratio: $FRAGMENTATION" >> $REPORT_FILE
    
    # Key metrics
    TOTAL_KEYS=$(redis-cli DBSIZE)
    echo "Total Keys: $TOTAL_KEYS" >> $REPORT_FILE
    
    # Client metrics
    CLIENTS=$(redis-cli INFO clients | grep "connected_clients:" | cut -d: -f2)
    echo "Connected Clients: $CLIENTS" >> $REPORT_FILE
    
    # Performance metrics
    COMMANDS=$(redis-cli INFO stats | grep "total_commands_processed:" | cut -d: -f2)
    echo "Total Commands: $COMMANDS" >> $REPORT_FILE
}

# Function to analyze key distribution
analyze_key_distribution() {
    echo "" >> $REPORT_FILE
    echo "🔑 KEY DISTRIBUTION ANALYSIS:" >> $REPORT_FILE
    echo "============================" >> $REPORT_FILE
    
    # Count keys by pattern
    echo "Key Patterns:" >> $REPORT_FILE
    echo "- customer:* = $(redis-cli --scan --pattern 'customer:*' | wc -l)" >> $REPORT_FILE
    echo "- policy:* = $(redis-cli --scan --pattern 'policy:*' | wc -l)" >> $REPORT_FILE
    echo "- claim:* = $(redis-cli --scan --pattern 'claim:*' | wc -l)" >> $REPORT_FILE
    echo "- session:* = $(redis-cli --scan --pattern 'session:*' | wc -l)" >> $REPORT_FILE
    echo "- cache:* = $(redis-cli --scan --pattern 'cache:*' | wc -l)" >> $REPORT_FILE
    echo "- quote:* = $(redis-cli --scan --pattern 'quote:*' | wc -l)" >> $REPORT_FILE
    
    # TTL analysis
    echo "" >> $REPORT_FILE
    echo "TTL Distribution:" >> $REPORT_FILE
    TEMP_TTL=$(redis-cli --scan | while read key; do
        TTL=$(redis-cli TTL "$key")
        if [ "$TTL" -gt 0 ]; then echo "expiring"; fi
        if [ "$TTL" -eq -1 ]; then echo "persistent"; fi
    done | sort | uniq -c)
    echo "$TEMP_TTL" >> $REPORT_FILE
}

# Function to project growth
project_growth() {
    echo "" >> $REPORT_FILE
    echo "📈 GROWTH PROJECTIONS:" >> $REPORT_FILE
    echo "=====================" >> $REPORT_FILE
    
    # Simulate growth scenarios
    CURRENT_KEYS=$(redis-cli DBSIZE)
    CURRENT_MEMORY=$(redis-cli INFO memory | grep "used_memory:" | cut -d: -f2)
    
    echo "Growth Scenarios (assuming 20% monthly growth):" >> $REPORT_FILE
    echo "" >> $REPORT_FILE
    
    for month in 1 3 6 12; do
        PROJECTED_KEYS=$(echo "$CURRENT_KEYS * (1.20 ^ $month)" | bc -l | cut -d. -f1)
        PROJECTED_MEMORY=$(echo "$CURRENT_MEMORY * (1.20 ^ $month)" | bc -l | cut -d. -f1)
        PROJECTED_MEMORY_MB=$(echo "scale=2; $PROJECTED_MEMORY / 1024 / 1024" | bc -l)
        
        echo "Month $month:" >> $REPORT_FILE
        echo "  Projected Keys: $PROJECTED_KEYS" >> $REPORT_FILE
        echo "  Projected Memory: ${PROJECTED_MEMORY_MB} MB" >> $REPORT_FILE
        echo "" >> $REPORT_FILE
    done
}

# Function to generate recommendations
generate_recommendations() {
    echo "" >> $REPORT_FILE
    echo "💡 RECOMMENDATIONS:" >> $REPORT_FILE
    echo "==================" >> $REPORT_FILE
    
    MEMORY_MB=$(redis-cli INFO memory | grep "used_memory:" | cut -d: -f2)
    MEMORY_MB_INT=$(echo "scale=0; $MEMORY_MB / 1024 / 1024" | bc -l)
    FRAGMENTATION=$(redis-cli INFO memory | grep "mem_fragmentation_ratio:" | cut -d: -f2)
    
    # Memory recommendations
    if [ $(echo "$MEMORY_MB_INT > 100" | bc -l) -eq 1 ]; then
        echo "⚠️  Consider memory optimization - usage > 100MB" >> $REPORT_FILE
    fi
    
    if [ $(echo "$FRAGMENTATION > 1.5" | bc -l) -eq 1 ]; then
        echo "⚠️  High memory fragmentation - consider restart" >> $REPORT_FILE
    fi
    
    # General recommendations
    echo "" >> $REPORT_FILE
    echo "General Recommendations:" >> $REPORT_FILE
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
