#!/bin/bash
#
# Lab 5: Redis Performance Monitoring Script
# Monitors Redis performance metrics in real-time
#

echo "=== Redis Performance Monitor ==="
echo "Press Ctrl+C to stop"
echo ""

while true; do
    clear
    echo "=== Redis Performance Metrics - $(date) ==="
    echo ""

    # Get INFO stats
    redis-cli INFO stats | grep -E "total_commands_processed|instantaneous_ops_per_sec|rejected_connections"

    echo ""

    # Get memory info
    redis-cli INFO memory | grep -E "used_memory_human|used_memory_peak_human|mem_fragmentation_ratio"

    echo ""

    # Get client connections
    redis-cli INFO clients | grep -E "connected_clients|blocked_clients"

    sleep 2
done
