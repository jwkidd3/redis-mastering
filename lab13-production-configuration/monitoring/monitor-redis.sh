#!/bin/bash

# Simple Redis monitoring script
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
LOG_FILE="monitoring/logs/redis-monitor.log"

echo "[$TIMESTAMP] Starting Redis monitoring check..." >> $LOG_FILE

# Check basic health
if redis-cli -h $REDIS_HOST -p $REDIS_PORT ping &>/dev/null; then
    echo "[$TIMESTAMP] Health: OK" >> $LOG_FILE
else
    echo "[$TIMESTAMP] Health: FAILED" >> $LOG_FILE
fi

# Log key metrics
MEMORY_USED=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO memory | grep "used_memory_human" | cut -d: -f2 | tr -d '\r')
CONNECTED_CLIENTS=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO clients | grep "connected_clients" | cut -d: -f2 | tr -d '\r')
TOTAL_COMMANDS=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO stats | grep "total_commands_processed" | cut -d: -f2 | tr -d '\r')

echo "[$TIMESTAMP] Memory: $MEMORY_USED, Clients: $CONNECTED_CLIENTS, Commands: $TOTAL_COMMANDS" >> $LOG_FILE
