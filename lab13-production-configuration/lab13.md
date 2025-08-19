# Lab 13: Basic Production Configuration

**Duration:** 45 minutes  
**Objective:** Configure Redis for basic production deployment with insurance data persistence, security, and backup strategies

## 🎯 Learning Objectives

By the end of this lab, you will be able to:
- Configure RDB persistence for insurance data backup
- Set up AOF (Append Only File) for transaction logging
- Implement memory management and eviction policies
- Configure basic authentication for production security
- Create automated backup scripts for insurance data
- Set up production-ready Redis configuration files
- Monitor production Redis instances with Redis Insight

---

## Part 1: RDB Persistence Configuration (15 minutes)

### Step 1: Environment Setup

**Important:** Connect to your assigned remote Redis host (replace with actual values provided by instructor).

```bash
# Set your Redis connection parameters
export REDIS_HOST="your-redis-host.com"  # Replace with actual host
export REDIS_PORT="6379"                  # Replace with actual port
export REDIS_PASSWORD=""                  # Replace if password required

# Test connection to remote Redis instance
redis-cli -h $REDIS_HOST -p $REDIS_PORT ping

# Create production configuration directory
mkdir -p /tmp/redis-production-config

# Start with our insurance sample data
./scripts/load-insurance-production-data.sh
```

### Step 2: Configure RDB Snapshots for Insurance Data

RDB (Redis Database) provides point-in-time snapshots of your insurance data.

```bash
# Connect to Redis and configure RDB settings
redis-cli -h $REDIS_HOST -p $REDIS_PORT

# Configure automatic snapshots based on insurance data changes
CONFIG SET save "900 1 300 10 60 10000"
# Explanation:
# - Save if at least 1 key changed in 900 seconds (15 minutes) - for low activity
# - Save if at least 10 keys changed in 300 seconds (5 minutes) - for moderate activity  
# - Save if at least 10,000 keys changed in 60 seconds - for high activity (claims processing)

# Set RDB filename for insurance backups
CONFIG SET dbfilename "insurance-data.rdb"

# Configure RDB compression (saves disk space for large datasets)
CONFIG SET rdbcompression yes

# Enable RDB checksum for data integrity
CONFIG SET rdbchecksum yes

# View current RDB configuration
CONFIG GET save
CONFIG GET dbfilename
CONFIG GET rdbcompression
```

### Step 3: Test RDB Backup Process

```bash
# Load sample insurance data for testing
HSET policy:12345 policyholder "Sarah Johnson" type "Auto" premium 1200 status "Active"
HSET policy:12346 policyholder "Mike Chen" type "Home" premium 800 status "Active"
HSET policy:12347 policyholder "Lisa Rodriguez" type "Life" premium 300 status "Pending"

# Set claims processing queues
LPUSH claims:urgent "claim:54321:total_loss" "claim:54322:theft"
LPUSH claims:standard "claim:54323:fender_bender" "claim:54324:glass_damage"

# Trigger manual backup
BGSAVE

# Check backup status
LASTSAVE

# Monitor backup progress
INFO persistence
```

---

## Part 2: AOF Configuration for Transaction Logging (15 minutes)

### Step 4: Enable AOF (Append Only File)

AOF logs every write operation, providing better durability for critical insurance transactions.

```bash
# Enable AOF logging
CONFIG SET appendonly yes

# Set AOF filename
CONFIG SET appendfilename "insurance-transactions.aof"

# Configure AOF sync policy for insurance compliance
CONFIG SET appendfsync everysec
# Options:
# - always: Sync every write (highest durability, slower performance)
# - everysec: Sync every second (good balance for insurance data)
# - no: Let OS decide when to sync (fastest, least durable)

# Enable AOF rewrite to compact the log file
CONFIG SET auto-aof-rewrite-percentage 100
CONFIG SET auto-aof-rewrite-min-size 64mb

# Check AOF configuration
CONFIG GET appendonly
CONFIG GET appendfilename
CONFIG GET appendfsync
```

### Step 5: Test AOF Logging

```bash
# Simulate insurance business operations
HSET customer:67890 name "Jennifer Walsh" email "j.walsh@email.com" phone "555-0123"
SADD customer:67890:policies "policy:12345" "policy:12346"

# Process claim updates
HSET claim:54321 status "investigating" adjuster "John Smith" amount 25000
HSET claim:54322 status "approved" adjuster "Maria Garcia" amount 1200

# Update policy premiums (rate changes)
HINCRBY policy:12345 premium 50
HINCRBY policy:12346 premium -25

# Check AOF file growth
INFO persistence

# View recent AOF entries (be careful with large files)
# tail -20 /path/to/insurance-transactions.aof
```

---

## Part 3: Memory Management & Eviction Policies (10 minutes)

### Step 6: Configure Memory Limits and Eviction

```bash
# Set memory limit (adjust based on available system memory)
CONFIG SET maxmemory 256mb

# Configure eviction policy for insurance data
CONFIG SET maxmemory-policy allkeys-lru
# Policy options for insurance systems:
# - noeviction: Return errors when memory limit reached (safest for critical data)
# - allkeys-lru: Remove least recently used keys (good for cache scenarios)
# - volatile-lru: Remove LRU keys with TTL set (good for temporary data like quotes)
# - allkeys-lfu: Remove least frequently used keys (good for diverse data patterns)

# Set memory usage samples for eviction algorithm
CONFIG SET maxmemory-samples 5

# Check current memory usage
INFO memory

# View eviction statistics
INFO stats
```

### Step 7: Memory Optimization Settings

```bash
# Configure memory-efficient encoding for insurance data
CONFIG SET hash-max-ziplist-entries 512
CONFIG SET hash-max-ziplist-value 64

CONFIG SET list-max-ziplist-size -2
CONFIG SET list-compress-depth 0

CONFIG SET set-max-intset-entries 512

CONFIG SET zset-max-ziplist-entries 128
CONFIG SET zset-max-ziplist-value 64

# Enable key expiration notifications for monitoring
CONFIG SET notify-keyspace-events Ex

# View current encoding settings
CONFIG GET "*ziplist*"
CONFIG GET "*intset*"
```

---

## Part 4: Basic Authentication & Security (10 minutes)

### Step 8: Configure Authentication

```bash
# Set a strong password for production (replace with secure password)
CONFIG SET requirepass "Insurance2024$ecur3!"

# Restart Redis connection with authentication
# redis-cli -h $REDIS_HOST -p $REDIS_PORT -a "Insurance2024$ecur3!"

# Test authentication
AUTH "Insurance2024$ecur3!"
PING

# Create read-only user for monitoring (Redis 6+)
ACL SETUSER monitoring on +@read +ping +info ~* &Insurance2024$ecur3!

# Create application user with specific permissions
ACL SETUSER insurance-app on +@all -flushdb -flushall -shutdown ~* &Insurance2024$ecur3!

# List all users
ACL LIST

# Check current user permissions
ACL WHOAMI
```

### Step 9: Network Security Configuration

```bash
# Configure protected mode (if applicable)
CONFIG GET protected-mode

# Set bind address for production (example - adjust for your environment)
# CONFIG SET bind "127.0.0.1 192.168.1.100"

# Disable dangerous commands in production
CONFIG SET rename-command-flushdb ""
CONFIG SET rename-command-flushall ""
CONFIG SET rename-command-debug ""

# Check command renaming
CONFIG GET "*command*"
```

---

## Part 5: Backup Script Creation (10 minutes)

### Step 10: Create Automated Backup Script

```bash
# Create backup script
cat > scripts/backup-insurance-redis.sh << 'BACKUP_SCRIPT'
#!/bin/bash

# Insurance Redis Backup Script
# Creates both RDB and AOF backups with timestamps

REDIS_HOST="${REDIS_HOST:-localhost}"
REDIS_PORT="${REDIS_PORT:-6379}"
REDIS_PASSWORD="${REDIS_PASSWORD:-Insurance2024\$ecur3!}"
BACKUP_DIR="/tmp/redis-backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Create backup directory
mkdir -p "$BACKUP_DIR"

echo "Starting Redis backup for insurance data at $(date)"

# Trigger RDB backup
echo "Creating RDB snapshot..."
redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" -a "$REDIS_PASSWORD" BGSAVE

# Wait for backup to complete
while [ "$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" -a "$REDIS_PASSWORD" LASTSAVE)" = "$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" -a "$REDIS_PASSWORD" LASTSAVE)" ]; do
    sleep 1
done

# Copy RDB file with timestamp
echo "Copying RDB file..."
cp /tmp/insurance-data.rdb "$BACKUP_DIR/insurance-data_$TIMESTAMP.rdb"

# Copy AOF file with timestamp  
echo "Copying AOF file..."
cp /tmp/insurance-transactions.aof "$BACKUP_DIR/insurance-transactions_$TIMESTAMP.aof"

# Create backup info file
cat > "$BACKUP_DIR/backup_info_$TIMESTAMP.txt" << EOF
Backup Created: $(date)
Redis Host: $REDIS_HOST:$REDIS_PORT
RDB File: insurance-data_$TIMESTAMP.rdb
AOF File: insurance-transactions_$TIMESTAMP.aof
Database Info:
$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" -a "$REDIS_PASSWORD" INFO keyspace)
Memory Usage:
$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" -a "$REDIS_PASSWORD" INFO memory | grep used_memory_human)
