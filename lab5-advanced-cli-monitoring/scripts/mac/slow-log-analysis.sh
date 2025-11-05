#!/bin/bash
#
# Lab 5: Redis Slow Log Analysis Script
# Analyzes slow queries and provides insights
#

echo "=== Redis Slow Log Analysis ==="
echo ""

# Get slow log configuration
echo "Slow Log Configuration:"
redis-cli CONFIG GET slowlog-log-slower-than
redis-cli CONFIG GET slowlog-max-len

echo ""
echo "Slow Log Entries:"
redis-cli SLOWLOG GET 10

echo ""
echo "Slow Log Statistics:"
echo "Total slow log entries: $(redis-cli SLOWLOG LEN)"

echo ""
echo "=== Analysis Complete ==="
echo ""
echo "To adjust slow log threshold:"
echo "redis-cli CONFIG SET slowlog-log-slower-than 10000"
