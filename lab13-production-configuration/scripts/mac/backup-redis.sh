#!/bin/bash
#
# Lab 13: Redis Backup Script
# Creates backups of Redis data (RDB and AOF files)
#

BACKUP_DIR="./backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="redis_backup_${TIMESTAMP}"

echo "=== Redis Backup Script ==="
echo "Starting backup: $BACKUP_NAME"
echo ""

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Trigger BGSAVE
echo "Triggering background save..."
redis-cli BGSAVE

# Wait for save to complete
while true; do
    SAVE_STATUS=$(redis-cli LASTSAVE)
    sleep 1
    NEW_SAVE_STATUS=$(redis-cli LASTSAVE)
    if [ "$SAVE_STATUS" != "$NEW_SAVE_STATUS" ]; then
        break
    fi
done

echo "✓ Background save completed"

# Get Redis data directory
DATA_DIR=$(redis-cli CONFIG GET dir | tail -1)
echo "Redis data directory: $DATA_DIR"

# Create backup archive
echo "Creating backup archive..."
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"

tar -czf "$BACKUP_PATH" -C "$DATA_DIR" \
    dump.rdb \
    appendonly.aof 2>/dev/null || true

if [ -f "$BACKUP_PATH" ]; then
    BACKUP_SIZE=$(du -h "$BACKUP_PATH" | cut -f1)
    echo "✓ Backup created: $BACKUP_PATH ($BACKUP_SIZE)"
else
    echo "✗ Backup failed"
    exit 1
fi

# Keep only last 7 backups
echo "Cleaning old backups (keeping last 7)..."
ls -t "${BACKUP_DIR}"/redis_backup_*.tar.gz | tail -n +8 | xargs -r rm

echo ""
echo "=== Backup Complete ==="
echo "Backup location: $BACKUP_PATH"
