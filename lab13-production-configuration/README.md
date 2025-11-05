# Lab 13: Production Configuration

**Duration:** 45 minutes
**Focus:** Persistence, security, memory management, and backups
**Prerequisites:** Lab 12 completed

## 🎯 Learning Objectives

- Configure RDB and AOF persistence
- Implement memory management and eviction policies
- Configure security and connection limits
- Create automated backup scripts
- Monitor production instances

## Part 1: Persistence Configuration

### Step 1: Environment Setup

```bash
# Set connection parameters
export REDIS_HOST="your-redis-host.com"
export REDIS_PORT="6379"

# Test connection
redis-cli -h $REDIS_HOST -p $REDIS_PORT ping

# Alias for convenience
alias rcli='redis-cli -h $REDIS_HOST -p $REDIS_PORT'
```

### Step 2: RDB Persistence

RDB provides point-in-time snapshots for backup.

```bash
# Configure RDB snapshots
rcli CONFIG SET save "900 1 300 10 60 1000"

# Enable compression and checksum
rcli CONFIG SET rdbcompression yes
rcli CONFIG SET rdbchecksum yes

# Force immediate snapshot
rcli BGSAVE

# Check status
rcli LASTSAVE
rcli INFO persistence | grep rdb
```

**RDB intervals:**
- 900 sec (15 min): 1+ key changed
- 300 sec (5 min): 10+ keys changed
- 60 sec (1 min): 1000+ keys changed

## Part 2: AOF Configuration

### Step 1: Enable AOF

AOF logs every write operation for maximum durability.

```bash
# Enable AOF
rcli CONFIG SET appendonly yes

# Configure sync policy (everysec recommended)
rcli CONFIG SET appendfsync everysec

# Configure auto-rewrite
rcli CONFIG SET auto-aof-rewrite-percentage 100
rcli CONFIG SET auto-aof-rewrite-min-size 67108864

# Check status
rcli INFO persistence | grep aof
```

**AOF sync policies:**
- `always` - Slowest, safest
- `everysec` - Recommended (good balance)
- `no` - Fastest, least safe

### Step 2: Test AOF

```bash
# Generate some writes
rcli SET policy:P123 "Auto Policy"
rcli SET claim:C456 "Active claim"
rcli HSET customer:C789 name "John Smith" policies 3

# Force rewrite
rcli BGREWRITEAOF

# Check rewrite status
rcli INFO persistence | grep aof_rewrite
```

## Part 3: Memory & Security

### Step 1: Memory Management

```bash
# Set memory limit
rcli CONFIG SET maxmemory 1gb

# Configure eviction policy
rcli CONFIG SET maxmemory-policy allkeys-lru

# Set sampling
rcli CONFIG SET maxmemory-samples 5

# Check configuration
rcli CONFIG GET maxmemory*
```

**Eviction policies:**
- `allkeys-lru` - LRU (recommended)
- `volatile-lru` - LRU with TTL only
- `allkeys-lfu` - LFU
- `noeviction` - No eviction (return errors)

### Step 2: Security Configuration

```bash
# Set password (if supported)
# rcli CONFIG SET requirepass "secure-password"

# Configure timeouts and limits
rcli CONFIG SET timeout 300
rcli CONFIG SET maxclients 1000

# Verify
rcli CONFIG GET timeout
rcli CONFIG GET maxclients
```

### Step 3: Performance Monitoring

```bash
# Enable slow log (commands >10ms)
rcli CONFIG SET slowlog-log-slower-than 10000
rcli CONFIG SET slowlog-max-len 128

# View slow log
rcli SLOWLOG GET 5

# Brief monitoring
timeout 10s rcli MONITOR | head -20 || true
```

## Part 4: Backup & Monitoring

### Step 1: Automated Backups

```bash
# Run backup script
./scripts/backup-redis.sh

# Verify backup
ls -la backup/
```

### Step 2: Redis Insight Setup

1. Open Redis Insight
2. Add connection:
   - Host: `$REDIS_HOST`
   - Port: `$REDIS_PORT`
   - Name: `Production`
3. Navigate to Analysis section
4. Review memory and performance

## 🧪 Verification

```bash
# Verify all settings
rcli CONFIG GET save
rcli CONFIG GET appendonly
rcli CONFIG GET maxmemory
rcli CONFIG GET maxmemory-policy
rcli CONFIG GET timeout
rcli CONFIG GET maxclients
```

## 📋 Configuration Summary

| Setting | Value | Purpose |
|---------|-------|---------|
| `save` | "900 1 300 10 60 1000" | RDB intervals |
| `appendonly` | yes | Durability |
| `appendfsync` | everysec | Balance |
| `maxmemory` | 1gb | Memory limit |
| `maxmemory-policy` | allkeys-lru | Eviction |
| `timeout` | 300 | Client timeout |
| `maxclients` | 1000 | Connections |
| `slowlog-log-slower-than` | 10000 | Monitoring |

## 🎓 Exercises

### Exercise 1: Test Persistence

1. Configure RDB and AOF
2. Write test data
3. Force BGSAVE and BGREWRITEAOF
4. Verify with INFO persistence

### Exercise 2: Memory Management

1. Set maxmemory to 100MB
2. Load data until limit reached
3. Verify eviction with different policies
4. Compare behavior

### Exercise 3: Security

1. Configure timeouts
2. Set connection limits
3. Test slow log
4. Monitor with Redis Insight

## 🔧 Troubleshooting

```bash
# RDB save failures
rcli INFO persistence | grep rdb_last_save_time
rcli CONFIG GET dir

# AOF file too large
rcli BGREWRITEAOF
rcli INFO persistence | grep aof_rewrite

# Memory issues
rcli INFO memory | grep fragmentation
rcli --bigkeys
```

## ✅ Lab Completion Checklist

- [ ] RDB persistence configured
- [ ] AOF enabled with everysec sync
- [ ] Memory limits and eviction set
- [ ] Security timeouts configured
- [ ] Slow log enabled
- [ ] Backup script tested
- [ ] Redis Insight monitoring setup

**Estimated time:** 45 minutes

## 📚 Additional Resources

- **Persistence:** `https://redis.io/topics/persistence`
- **Security:** `https://redis.io/topics/security`
- **Memory:** `https://redis.io/topics/memory-optimization`
