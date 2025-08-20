#!/bin/bash

# Generate optimization recommendations based on current Redis state

REDIS_HOST="redis-server.training.com"
REDIS_PORT="6379"
RECOMMENDATIONS_FILE="analysis/optimization-recommendations.txt"

mkdir -p analysis

echo "💡 Redis Optimization Recommendations" > $RECOMMENDATIONS_FILE
echo "=====================================" >> $RECOMMENDATIONS_FILE
echo "Generated: $(date)" >> $RECOMMENDATIONS_FILE
echo "" >> $RECOMMENDATIONS_FILE

# Function to analyze memory optimization opportunities
analyze_memory_optimization() {
    echo "💾 MEMORY OPTIMIZATION:" >> $RECOMMENDATIONS_FILE
    
    MEMORY_INFO=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO memory 2>/dev/null)
    if [ $? -eq 0 ]; then
        FRAGMENTATION=$(echo "$MEMORY_INFO" | grep "mem_fragmentation_ratio:" | cut -d: -f2)
        USED_MEMORY_BYTES=$(echo "$MEMORY_INFO" | grep "used_memory:" | head -1 | cut -d: -f2)
        
        # Check fragmentation
        FRAG_INT=$(echo $FRAGMENTATION | cut -d. -f1)
        if [ "$FRAG_INT" -gt 1 ]; then
            if [ "$FRAG_INT" -gt 2 ]; then
                echo "⚠️  HIGH PRIORITY: Memory fragmentation is high ($FRAGMENTATION)" >> $RECOMMENDATIONS_FILE
                echo "   - Consider running MEMORY DOCTOR command" >> $RECOMMENDATIONS_FILE
                echo "   - Evaluate data structure choices" >> $RECOMMENDATIONS_FILE
                echo "   - Consider Redis restart during maintenance window" >> $RECOMMENDATIONS_FILE
            else
                echo "⚠️  MEDIUM PRIORITY: Memory fragmentation is elevated ($FRAGMENTATION)" >> $RECOMMENDATIONS_FILE
                echo "   - Monitor fragmentation trends" >> $RECOMMENDATIONS_FILE
                echo "   - Review memory usage patterns" >> $RECOMMENDATIONS_FILE
            fi
        else
            echo "✅ Memory fragmentation is healthy ($FRAGMENTATION)" >> $RECOMMENDATIONS_FILE
        fi
    fi
    echo "" >> $RECOMMENDATIONS_FILE
}

# Function to analyze key distribution and TTL optimization
analyze_key_optimization() {
    echo "🗝️  KEY OPTIMIZATION:" >> $RECOMMENDATIONS_FILE
    
    # Count keys with and without TTL
    KEYS_WITH_TTL=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT EVAL "
    local count = 0
    local keys = redis.call('KEYS', '*')
    for i=1,#keys do
        if redis.call('TTL', keys[i]) > 0 then
            count = count + 1
        end
    end
    return count
    " 0 2>/dev/null)
    
    TOTAL_KEYS=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT DBSIZE 2>/dev/null)
    
    if [ "$KEYS_WITH_TTL" != "" ] && [ "$TOTAL_KEYS" != "" ]; then
        KEYS_WITHOUT_TTL=$((TOTAL_KEYS - KEYS_WITH_TTL))
        
        echo "   Key TTL Analysis:" >> $RECOMMENDATIONS_FILE
        echo "      Total Keys: $TOTAL_KEYS" >> $RECOMMENDATIONS_FILE
        echo "      Keys with TTL: $KEYS_WITH_TTL" >> $RECOMMENDATIONS_FILE
        echo "      Keys without TTL: $KEYS_WITHOUT_TTL" >> $RECOMMENDATIONS_FILE
        
        if [ $KEYS_WITHOUT_TTL -gt $((TOTAL_KEYS / 2)) ]; then
            echo "⚠️  RECOMMENDATION: Many keys lack TTL settings" >> $RECOMMENDATIONS_FILE
            echo "   - Review which keys should have expiration" >> $RECOMMENDATIONS_FILE
            echo "   - Implement TTL for temporary data (sessions, cache)" >> $RECOMMENDATIONS_FILE
            echo "   - Consider default TTL policies" >> $RECOMMENDATIONS_FILE
        else
            echo "✅ Good TTL coverage on keys" >> $RECOMMENDATIONS_FILE
        fi
    fi
    echo "" >> $RECOMMENDATIONS_FILE
}

# Function to analyze performance optimization
analyze_performance_optimization() {
    echo "⚡ PERFORMANCE OPTIMIZATION:" >> $RECOMMENDATIONS_FILE
    
    # Check slow operations
    SLOW_COUNT=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT SLOWLOG LEN 2>/dev/null)
    
    if [ "$SLOW_COUNT" -gt 10 ]; then
        echo "⚠️  HIGH PRIORITY: High number of slow operations ($SLOW_COUNT)" >> $RECOMMENDATIONS_FILE
        echo "   - Review and optimize slow queries" >> $RECOMMENDATIONS_FILE
        echo "   - Consider indexing strategies" >> $RECOMMENDATIONS_FILE
        echo "   - Analyze data access patterns" >> $RECOMMENDATIONS_FILE
    elif [ "$SLOW_COUNT" -gt 0 ]; then
        echo "⚠️  MEDIUM PRIORITY: Some slow operations detected ($SLOW_COUNT)" >> $RECOMMENDATIONS_FILE
        echo "   - Monitor slow operation trends" >> $RECOMMENDATIONS_FILE
        echo "   - Review query complexity" >> $RECOMMENDATIONS_FILE
    else
        echo "✅ No significant slow operations detected" >> $RECOMMENDATIONS_FILE
    fi
    
    # Check cache hit ratio
    STATS_INFO=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO stats 2>/dev/null)
    HITS=$(echo "$STATS_INFO" | grep "keyspace_hits:" | cut -d: -f2)
    MISSES=$(echo "$STATS_INFO" | grep "keyspace_misses:" | cut -d: -f2)
    
    if [ "$HITS" != "" ] && [ "$MISSES" != "" ]; then
        TOTAL_REQUESTS=$((HITS + MISSES))
        if [ $TOTAL_REQUESTS -gt 0 ]; then
            HIT_RATIO=$((HITS * 100 / TOTAL_REQUESTS))
            
            if [ $HIT_RATIO -lt 70 ]; then
                echo "⚠️  HIGH PRIORITY: Low cache hit ratio ($HIT_RATIO%)" >> $RECOMMENDATIONS_FILE
                echo "   - Review caching strategy" >> $RECOMMENDATIONS_FILE
                echo "   - Analyze data access patterns" >> $RECOMMENDATIONS_FILE
                echo "   - Consider cache warming strategies" >> $RECOMMENDATIONS_FILE
            elif [ $HIT_RATIO -lt 85 ]; then
                echo "⚠️  MEDIUM PRIORITY: Cache hit ratio could be improved ($HIT_RATIO%)" >> $RECOMMENDATIONS_FILE
                echo "   - Fine-tune cache policies" >> $RECOMMENDATIONS_FILE
                echo "   - Monitor access patterns" >> $RECOMMENDATIONS_FILE
            else
                echo "✅ Good cache hit ratio ($HIT_RATIO%)" >> $RECOMMENDATIONS_FILE
            fi
        fi
    fi
    echo "" >> $RECOMMENDATIONS_FILE
}

# Function to generate operational recommendations
generate_operational_recommendations() {
    echo "🔧 OPERATIONAL RECOMMENDATIONS:" >> $RECOMMENDATIONS_FILE
    echo "" >> $RECOMMENDATIONS_FILE
    
    echo "Monitoring & Alerting:" >> $RECOMMENDATIONS_FILE
    echo "• Set up continuous monitoring dashboard" >> $RECOMMENDATIONS_FILE
    echo "• Configure alerts for memory, connections, and performance" >> $RECOMMENDATIONS_FILE
    echo "• Implement log aggregation and analysis" >> $RECOMMENDATIONS_FILE
    echo "" >> $RECOMMENDATIONS_FILE
    
    echo "Backup & Recovery:" >> $RECOMMENDATIONS_FILE
    echo "• Establish regular backup procedures" >> $RECOMMENDATIONS_FILE
    echo "• Test recovery procedures periodically" >> $RECOMMENDATIONS_FILE
    echo "• Document disaster recovery plans" >> $RECOMMENDATIONS_FILE
    echo "" >> $RECOMMENDATIONS_FILE
    
    echo "Scaling & Growth:" >> $RECOMMENDATIONS_FILE
    echo "• Plan for horizontal scaling with clustering" >> $RECOMMENDATIONS_FILE
    echo "• Monitor growth trends and capacity planning" >> $RECOMMENDATIONS_FILE
    echo "• Consider read replicas for read-heavy workloads" >> $RECOMMENDATIONS_FILE
    echo "" >> $RECOMMENDATIONS_FILE
    
    echo "Security & Compliance:" >> $RECOMMENDATIONS_FILE
    echo "• Implement authentication and authorization" >> $RECOMMENDATIONS_FILE
    echo "• Enable TLS encryption for data in transit" >> $RECOMMENDATIONS_FILE
    echo "• Regular security audits and updates" >> $RECOMMENDATIONS_FILE
    echo "" >> $RECOMMENDATIONS_FILE
}

# Main execution
echo "💡 Generating optimization recommendations..."

analyze_memory_optimization
analyze_key_optimization
analyze_performance_optimization
generate_operational_recommendations

echo "Report generated: $(date)" >> $RECOMMENDATIONS_FILE

echo "✅ Optimization recommendations generated: $RECOMMENDATIONS_FILE"
echo ""
echo "📋 Key Recommendations:"
head -30 $RECOMMENDATIONS_FILE
echo ""
echo "💡 Full recommendations available at: $RECOMMENDATIONS_FILE"
