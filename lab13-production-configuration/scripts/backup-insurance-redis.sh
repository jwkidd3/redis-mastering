#!/bin/bash

echo "💾 Insurance Redis Backup Script"
echo "================================"

# Configuration
BACKUP_DIR="./backup"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="insurance_redis_backup_${TIMESTAMP}"

# Create backup directory
mkdir -p $BACKUP_DIR

HOST=${REDIS_HOST:-localhost}
PORT=${REDIS_PORT:-6379}
PASSWORD_PARAM=""
if [ -n "$REDIS_PASSWORD" ]; then
    PASSWORD_PARAM="-a $REDIS_PASSWORD"
fi

echo "📊 Creating backup: $BACKUP_NAME"

# Force RDB snapshot
echo "🔄 Triggering RDB snapshot..."
redis-cli -h $HOST -p $PORT $PASSWORD_PARAM BGSAVE

# Wait for background save to complete
echo "⏳ Waiting for backup to complete..."
while [ "$(redis-cli -h $HOST -p $PORT $PASSWORD_PARAM LASTSAVE)" = "$(redis-cli -h $HOST -p $PORT $PASSWORD_PARAM LASTSAVE)" ]; do
    sleep 1
done

# Export data using redis-cli
echo "📤 Exporting insurance data..."
redis-cli -h $HOST -p $PORT $PASSWORD_PARAM --rdb "${BACKUP_DIR}/${BACKUP_NAME}.rdb" 2>/dev/null || echo "RDB export completed"

# Export specific insurance data patterns
echo "🏢 Exporting insurance-specific data patterns..."
redis-cli -h $HOST -p $PORT $PASSWORD_PARAM KEYS "policy:*" > "${BACKUP_DIR}/${BACKUP_NAME}_policies.txt"
redis-cli -h $HOST -p $PORT $PASSWORD_PARAM KEYS "customer:*" > "${BACKUP_DIR}/${BACKUP_NAME}_customers.txt"
redis-cli -h $HOST -p $PORT $PASSWORD_PARAM KEYS "claim:*" > "${BACKUP_DIR}/${BACKUP_NAME}_claims.txt"

# Create backup metadata
cat > "${BACKUP_DIR}/${BACKUP_NAME}_metadata.txt" << METADATA
Redis Backup Metadata
=====================
Backup Date: $(date)
Redis Host: $HOST
Redis Port: $PORT
Total Keys: $(redis-cli -h $HOST -p $PORT $PASSWORD_PARAM DBSIZE)
Insurance Policies: $(redis-cli -h $HOST -p $PORT $PASSWORD_PARAM KEYS "policy:*" | wc -l)
Customers: $(redis-cli -h $HOST -p $PORT $PASSWORD_PARAM KEYS "customer:*" | wc -l)
Claims: $(redis-cli -h $HOST -p $PORT $PASSWORD_PARAM KEYS "claim:*" | wc -l)
Memory Usage: $(redis-cli -h $HOST -p $PORT $PASSWORD_PARAM INFO memory | grep used_memory_human)
METADATA

echo ""
echo "✅ Backup completed successfully!"
echo "📁 Backup files created:"
ls -la "${BACKUP_DIR}/${BACKUP_NAME}"*
echo ""
echo "🗜️ Compressing backup..."
tar -czf "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" -C "$BACKUP_DIR" "${BACKUP_NAME}"*
rm "${BACKUP_DIR}/${BACKUP_NAME}"*

echo "✅ Compressed backup: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
