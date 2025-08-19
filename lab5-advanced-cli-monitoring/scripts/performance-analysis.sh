#!/bin/bash

# Performance Analysis Script
set -e

echo "⚡ Redis Performance Analysis"
echo "============================"

mkdir -p analysis
REPORT_FILE="analysis/performance-$(date +%Y%m%d-%H%M%S).txt"

echo "📊 Running performance tests..."

{
    echo "Redis Performance Analysis Report"
    echo "Generated: $(date)"
    echo "================================"
    echo ""
    
    echo "Memory Analysis:"
    redis-cli INFO memory | grep -E "(used_memory|fragmentation)"
    echo ""
    
    echo "Key Distribution:"
    echo "Total keys: $(redis-cli DBSIZE)"
    echo "Customer keys: $(redis-cli EVAL \"return #redis.call(\\\"keys\\\", \\\"customer:*\\\")\" 0)"
    echo "Policy keys: $(redis-cli EVAL \"return #redis.call(\\\"keys\\\", \\\"policy:*\\\")\" 0)"
    echo "Claim keys: $(redis-cli EVAL \"return #redis.call(\\\"keys\\\", \\\"claim:*\\\")\" 0)"
    echo ""
    
    echo "Performance Stats:"
    redis-cli INFO stats | grep -E "(keyspace_hits|keyspace_misses|total_commands)"
    echo ""
    
    echo "Client Connections:"
    redis-cli INFO clients
    echo ""
    
    echo "Slow Operations:"
    redis-cli SLOWLOG GET 5
    
} | tee "$REPORT_FILE"

echo "✅ Performance analysis complete!"
echo "📄 Report saved: $REPORT_FILE"
