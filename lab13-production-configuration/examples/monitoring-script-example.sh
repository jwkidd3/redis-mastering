#!/bin/bash

# Example Redis monitoring script for production
# Customize this script for your specific monitoring needs

REDIS_HOST="your-redis-host"
REDIS_PORT="6379"
LOG_FILE="/var/log/redis-monitoring.log"

# Function to log with timestamp
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

# Check Redis health
if redis-cli -h $REDIS_HOST -p $REDIS_PORT ping &>/dev/null; then
    log_message "Health check: PASSED"
else
    log_message "Health check: FAILED"
    # Send alert here
fi

# Check memory usage
MEMORY_USAGE=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO memory | grep "used_memory:" | cut -d: -f2)
log_message "Memory usage: $MEMORY_USAGE bytes"

# Check slow operations
SLOW_COUNT=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT SLOWLOG LEN)
if [ $SLOW_COUNT -gt 10 ]; then
    log_message "WARNING: High number of slow operations: $SLOW_COUNT"
fi
