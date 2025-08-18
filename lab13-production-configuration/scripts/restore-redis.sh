#!/bin/bash

# Redis Production Restore Script
BACKUP_DIR="/backup/redis"
REDIS_DATA_DIR="/data/redis"

if [ -z "$1" ]; then
    echo "Usage: $0 <backup_timestamp>"
    echo "Available backups:"
    ls -la ${BACKUP_DIR}/dump_*.rdb
    exit 1
fi

TIMESTAMP=$1
BACKUP_FILE="${BACKUP_DIR}/dump_${TIMESTAMP}.rdb"

if [ ! -f "${BACKUP_FILE}" ]; then
    echo "Backup file not found: ${BACKUP_FILE}"
    exit 1
fi

echo "Restoring from backup: ${BACKUP_FILE}"

# Stop Redis server
echo "Stopping Redis server..."
redis-cli SHUTDOWN SAVE

# Wait for shutdown
sleep 5

# Backup current data
echo "Backing up current data..."
cp ${REDIS_DATA_DIR}/dump.rdb ${REDIS_DATA_DIR}/dump.rdb.before_restore

# Restore backup
echo "Restoring backup..."
cp ${BACKUP_FILE} ${REDIS_DATA_DIR}/dump.rdb

# Restore AOF if exists
AOF_BACKUP="${BACKUP_DIR}/aof_${TIMESTAMP}.tar.gz"
if [ -f "${AOF_BACKUP}" ]; then
    echo "Restoring AOF files..."
    tar xzf ${AOF_BACKUP} -C /
fi

# Start Redis server
echo "Starting Redis server..."
docker start redis-prod-lab13

# Wait for startup
sleep 5

# Verify
redis-cli PING
if [ $? -eq 0 ]; then
    echo "Restore completed successfully!"
    redis-cli DBSIZE
else
    echo "Restore failed - Redis not responding"
    exit 1
fi
