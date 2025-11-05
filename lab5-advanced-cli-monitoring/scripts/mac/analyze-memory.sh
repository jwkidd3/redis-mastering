#!/bin/bash
#
# Lab 5: Redis Memory Analysis Script
# Analyzes memory usage and provides recommendations
#

echo "=== Redis Memory Analysis ==="
echo ""

# Get memory information
echo "Current Memory Usage:"
redis-cli INFO memory | grep -E "used_memory_human|used_memory_peak_human|used_memory_rss_human|mem_fragmentation_ratio|maxmemory_human|maxmemory_policy"

echo ""
echo "Memory by Data Type:"
redis-cli MEMORY STATS | grep -E "keys.count|dataset.bytes"

echo ""
echo "Database Size:"
redis-cli DBSIZE

echo ""
echo "Sample Key Memory Usage:"
# Get a sample key to analyze
SAMPLE_KEY=$(redis-cli RANDOMKEY)
if [ -n "$SAMPLE_KEY" ]; then
    echo "Analyzing key: $SAMPLE_KEY"
    redis-cli MEMORY USAGE "$SAMPLE_KEY"
fi

echo ""
echo "=== Analysis Complete ==="
