#!/bin/bash

# Capacity Planning Analysis
set -e

echo "📈 Redis Capacity Planning"
echo "=========================="

mkdir -p analysis
REPORT_FILE="analysis/capacity-$(date +%Y%m%d-%H%M%S).txt"

{
    echo "Capacity Planning Report"
    echo "Generated: $(date)"
    echo "======================="
    echo ""
    
    # Current usage
    INFO=$(redis-cli INFO)
    MEMORY_USED=$(echo "$INFO" | grep "used_memory:" | cut -d: -f2 | tr -d "\r")
    TOTAL_KEYS=$(redis-cli DBSIZE)
    CLIENTS=$(echo "$INFO" | grep "connected_clients:" | cut -d: -f2 | tr -d "\r")
    
    echo "Current Status:"
    echo "Memory Used: $MEMORY_USED bytes"
    echo "Total Keys: $TOTAL_KEYS"
    echo "Connected Clients: $CLIENTS"
    echo ""
    
    # Growth projections
    MEMORY_MB=$((MEMORY_USED / 1048576))
    echo "Growth Projections (20% quarterly):"
    echo "Q1: $((MEMORY_MB * 120 / 100))MB"
    echo "Q2: $((MEMORY_MB * 144 / 100))MB"
    echo "Q3: $((MEMORY_MB * 173 / 100))MB"
    echo "Q4: $((MEMORY_MB * 207 / 100))MB"
    echo ""
    
    # Recommendations
    echo "Recommendations:"
    if [ "$MEMORY_MB" -lt 100 ]; then
        echo "✅ Current usage is low - no immediate action needed"
    elif [ "$MEMORY_MB" -lt 500 ]; then
        echo "⚠️  Plan for memory upgrade in 6-12 months"
    else
        echo "🚨 Consider immediate memory upgrade"
    fi
    
    if [ "$CLIENTS" -gt 50 ]; then
        echo "⚠️  High client connections - consider connection pooling"
    fi
    
} | tee "$REPORT_FILE"

echo "✅ Capacity planning complete!"
echo "📄 Report: $REPORT_FILE"
