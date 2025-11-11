# Lab 13: Production Configuration with Redis Insight

**Duration:** 45 minutes
**Focus:** Persistence, security, memory management using Redis Insight
**Prerequisites:** Lab 12 completed, Redis Insight connected

## 🎯 Learning Objectives

- Configure RDB and AOF persistence using Workbench
- Implement memory management and eviction policies
- Configure security and connection limits
- Monitor persistence status with Redis Insight
- Understand production configuration best practices

---

## 🚀 Quick Start

### Step 1: Ensure Redis Insight is Connected

1. Open Redis Insight
2. Verify connection to your Redis instance
3. Open **Workbench** tab

### Step 2: Test Connection

**In Workbench:**
```redis
PING
INFO server
```

Expected: `PONG` and server information

💡 **Important:** All configuration commands in this lab will be executed in Redis Insight Workbench - no terminal needed!

---

## Part 1: RDB Persistence Configuration

### What is RDB?

RDB (Redis Database) creates point-in-time snapshots of your dataset. Perfect for:
- **Backups:** Regular data snapshots
- **Disaster recovery:** Copy RDB files to another location
- **Replication:** Bootstrap replicas

### Configure RDB Snapshots

**In Workbench:**

```redis
// Configure automatic snapshot intervals
CONFIG SET save "900 1 300 10 60 1000"

// Enable compression (saves disk space)
CONFIG SET rdbcompression yes

// Enable checksum (data integrity)
CONFIG SET rdbchecksum yes

// Verify configuration
CONFIG GET save
CONFIG GET rdbcompression
CONFIG GET rdbchecksum
```

**RDB Snapshot Intervals Explained:**
- `900 1` = Save if 1+ keys changed in 15 minutes
- `300 10` = Save if 10+ keys changed in 5 minutes
- `60 1000` = Save if 1000+ keys changed in 1 minute

💡 **Smart Triggering:** Redis only saves if BOTH time AND key change thresholds are met!

### Force Manual Snapshot

```redis
// Trigger background save (non-blocking)
BGSAVE

// Check last save time (Unix timestamp)
LASTSAVE

// Get persistence stats
INFO persistence
```

### Monitor RDB Status in Redis Insight

1. After running `INFO persistence` in Workbench, look for:
   - `rdb_last_save_time` - When last saved
   - `rdb_changes_since_last_save` - Unsaved changes
   - `rdb_last_bgsave_status` - Success or failure
   - `rdb_last_bgsave_time_sec` - How long save took

2. **Visual Alternative:**
   - Some Redis Insight versions show persistence status in the UI
   - Check database info panel for RDB indicators

---

## Part 2: AOF (Append-Only File) Configuration

### What is AOF?

AOF logs every write operation to a file. More durable than RDB:
- **Every write is logged:** Minimal data loss
- **Human-readable:** Plain Redis commands
- **Incremental:** Grows over time (needs rewrite)

### Enable and Configure AOF

**In Workbench:**

```redis
// Enable AOF persistence
CONFIG SET appendonly yes

// Configure sync policy (everysec = recommended balance)
CONFIG SET appendfsync everysec

// Configure automatic rewrite thresholds
CONFIG SET auto-aof-rewrite-percentage 100
CONFIG SET auto-aof-rewrite-min-size 67108864

// Verify configuration
CONFIG GET appendonly
CONFIG GET appendfsync
CONFIG GET auto-aof-rewrite-percentage
```

**AOF Sync Policies Explained:**

| Policy | Durability | Performance | When to Use |
|--------|------------|-------------|-------------|
| `always` | Highest (every write synced) | Slowest | Financial data, zero loss tolerance |
| `everysec` | High (1 second max loss) | Good | **Recommended for most use cases** |
| `no` | Lowest (OS decides sync) | Fastest | Cache, acceptable data loss |

💡 **Production Recommendation:** Use `everysec` - best balance of durability and performance!

### Test AOF with Sample Data

**In Workbench:**

```redis
// Generate some write operations
SET policy:P123 "Auto Policy"
SET claim:C456 "Active claim"
HSET customer:C789 name "John Smith" policies 3
ZADD scores 100 "customer1" 200 "customer2"

// These writes are now logged in AOF file!
```

### Force AOF Rewrite

```redis
// Trigger background AOF rewrite (compaction)
BGREWRITEAOF

// Check rewrite status
INFO persistence
```

### Monitor AOF Status in Workbench

After running `INFO persistence`, look for:
- `aof_enabled` - Is AOF enabled? (0 or 1)
- `aof_rewrite_in_progress` - Is rewrite running?
- `aof_current_size` - Current AOF file size
- `aof_base_size` - Size before last rewrite
- `aof_last_rewrite_time_sec` - How long last rewrite took

**Why Rewrite?**
- AOF file grows indefinitely
- Rewrites compact it by replaying operations
- Auto-triggered when size doubles (`auto-aof-rewrite-percentage 100`)

---

## Part 3: Memory Management

### Configure Memory Limits

**In Workbench:**

```redis
// Set maximum memory (examples: 1gb, 512mb, 2gb)
CONFIG SET maxmemory 1gb

// Configure eviction policy when memory limit is reached
CONFIG SET maxmemory-policy allkeys-lru

// Set LRU sampling accuracy (higher = more accurate, slower)
CONFIG SET maxmemory-samples 5

// Verify all memory settings
CONFIG GET maxmemory
CONFIG GET maxmemory-policy
CONFIG GET maxmemory-samples
```

### Eviction Policies Explained

| Policy | Behavior | Use Case |
|--------|----------|----------|
| `allkeys-lru` | **Recommended** - Evict least recently used keys | General purpose cache |
| `allkeys-lfu` | Evict least frequently used keys | Better for frequency-based patterns |
| `volatile-lru` | LRU on keys with TTL only | Mix of cache and persistent data |
| `volatile-lfu` | LFU on keys with TTL only | Frequency-based with persistent data |
| `noeviction` | Return errors when memory full | When you never want data loss |

💡 **Production Tip:** `allkeys-lru` works well for most caching scenarios. `noeviction` for databases where you control memory externally.

### Test Memory Limits

```redis
// Check current memory usage
INFO memory

// Create test data
MSET test:1 "data" test:2 "data" test:3 "data"

// Check memory again
INFO memory
```

---

## Part 4: Security & Connection Configuration

### Connection Limits and Timeouts

**In Workbench:**

```redis
// Set client idle timeout (300 = 5 minutes)
CONFIG SET timeout 300

// Set maximum client connections
CONFIG SET maxclients 1000

// Verify configuration
CONFIG GET timeout
CONFIG GET maxclients
```

**Timeout Settings:**
- `timeout 0` = Never disconnect idle clients (not recommended)
- `timeout 300` = Disconnect after 5 minutes of inactivity (good default)
- `timeout 60` = Disconnect after 1 minute (very aggressive)

### Monitor Client Connections

```redis
// Check current connections
INFO clients

// List all connected clients
CLIENT LIST

// Count connections
CLIENT LIST | grep "addr" | wc -l
```

---

## Part 5: Performance Monitoring Configuration

### Configure Slowlog

**In Workbench:**

```redis
// Enable slowlog for commands taking >10ms (10000 microseconds)
CONFIG SET slowlog-log-slower-than 10000

// Keep last 128 slow queries
CONFIG SET slowlog-max-len 128

// Verify configuration
CONFIG GET slowlog-log-slower-than
CONFIG GET slowlog-max-len
```

### View Slow Queries

```redis
// Get last 5 slow queries
SLOWLOG GET 5

// Get slowlog length
SLOWLOG LEN

// Reset slowlog (clear all entries)
SLOWLOG RESET
```

### Use Profiler for Real-Time Monitoring

Instead of MONITOR command (which blocks Redis):

1. Open **Profiler** in Redis Insight (left sidebar)
2. Click **"Start"**
3. Execute commands in Workbench
4. Watch them appear in Profiler in real-time
5. Click **"Stop"** when done

💡 **Profiler > MONITOR:** Non-blocking, visual, filterable, and doesn't impact production performance!

---

## Part 6: Backup Strategy

### Manual Backups with RDB

**In Workbench:**

```redis
// Trigger immediate RDB snapshot
BGSAVE

// Check save status
LASTSAVE

// Get RDB file location
CONFIG GET dir
CONFIG GET dbfilename
```

**Backup Workflow:**
1. Run `BGSAVE` command in Workbench
2. Wait for completion (monitor with `INFO persistence`)
3. Copy RDB file from Redis data directory to backup location
4. Store backups offsite (S3, cloud storage, etc.)

### Automated Backup Strategy

**Best Practices:**
- **Frequency:** Daily backups for production
- **Retention:** Keep 7 daily, 4 weekly, 12 monthly
- **Testing:** Regularly test restore procedures
- **Offsite:** Store copies outside primary infrastructure

💡 **Production Tip:** Use both RDB (point-in-time snapshots) and AOF (durability) together for best protection!

### Monitor Persistence Health

```redis
// Comprehensive persistence status
INFO persistence

// Check for issues
INFO replication
```

Look for:
- Last successful save/rewrite
- Any errors in status fields
- File sizes growing as expected

---

## 🧪 Verification

### Verify All Configuration Settings

**In Workbench:**

```redis
// Persistence settings
CONFIG GET save
CONFIG GET appendonly
CONFIG GET appendfsync

// Memory settings
CONFIG GET maxmemory
CONFIG GET maxmemory-policy
CONFIG GET maxmemory-samples

// Connection settings
CONFIG GET timeout
CONFIG GET maxclients

// Monitoring settings
CONFIG GET slowlog-log-slower-than
CONFIG GET slowlog-max-len
```

### Verify in Redis Insight

1. **Browser Tab:**
   - Check keys are being saved
   - Verify TTLs are working

2. **Analysis Tab:**
   - Run memory analysis
   - Check memory usage against maxmemory

3. **Workbench:**
   - Run `INFO` commands
   - Check all metrics are reasonable

---

## 📋 Production Configuration Summary

| Setting | Recommended Value | Purpose |
|---------|------------------|---------|
| `save` | "900 1 300 10 60 1000" | RDB snapshot intervals |
| `appendonly` | yes | Enable AOF durability |
| `appendfsync` | everysec | AOF sync balance |
| `auto-aof-rewrite-percentage` | 100 | Trigger rewrite when doubled |
| `maxmemory` | 1gb (adjust for your needs) | Memory limit |
| `maxmemory-policy` | allkeys-lru | LRU eviction |
| `maxmemory-samples` | 5 | LRU sampling accuracy |
| `timeout` | 300 (5 minutes) | Client idle timeout |
| `maxclients` | 1000 | Max connections |
| `slowlog-log-slower-than` | 10000 (10ms) | Slowlog threshold |
| `slowlog-max-len` | 128 | Slowlog entries to keep |

---

## 🎓 Exercises

Complete these exercises in **Redis Insight Workbench**:

### Exercise 1: Configure Complete Persistence

**Goal:** Set up both RDB and AOF

```redis
// 1. Configure RDB
CONFIG SET save "900 1 300 10 60 1000"
CONFIG SET rdbcompression yes
CONFIG SET rdbchecksum yes

// 2. Enable AOF
CONFIG SET appendonly yes
CONFIG SET appendfsync everysec

// 3. Write test data
MSET test:1 "data1" test:2 "data2" test:3 "data3"

// 4. Force saves
BGSAVE
BGREWRITEAOF

// 5. Verify
INFO persistence
```

**Expected:** Both RDB and AOF status show successful saves

---

### Exercise 2: Test Memory Eviction

**Goal:** See eviction policies in action

```redis
// 1. Set low memory limit for testing
CONFIG SET maxmemory 1mb
CONFIG SET maxmemory-policy allkeys-lru

// 2. Fill with data
MSET key1 "x" key2 "x" key3 "x" key4 "x" key5 "x"

// 3. Keep adding until eviction occurs
// ... add more keys until you see eviction in INFO stats

// 4. Check eviction stats
INFO stats

// 5. Try different policy
CONFIG SET maxmemory-policy noeviction
// Try adding more data - should get errors

// 6. Reset
CONFIG SET maxmemory 0
```

**Challenge:** Compare `allkeys-lru` vs `allkeys-lfu` behavior

---

### Exercise 3: Monitor Configuration Health

**Goal:** Create a health check routine

```redis
// 1. Check persistence status
INFO persistence

// 2. Check memory status
INFO memory

// 3. Check client connections
INFO clients
CLIENT LIST

// 4. Check slow queries
SLOWLOG LEN
SLOWLOG GET 5

// 5. Verify all config
CONFIG GET save
CONFIG GET appendonly
CONFIG GET maxmemory
```

**Document:**
- Last RDB save time
- AOF rewrite status
- Current memory usage vs limit
- Number of connections
- Number of slow queries

---

## 🔧 Troubleshooting

### Common Issues and Solutions

**Issue 1: RDB Save Failures**

```redis
// Check last save status
INFO persistence

// Look for disk space issues
CONFIG GET dir

// Check file permissions
// (requires file system access)
```

**Fix:** Ensure Redis has write permissions to data directory and sufficient disk space.

**Issue 2: AOF File Growing Too Large**

```redis
// Check AOF size
INFO persistence

// Force rewrite
BGREWRITEAOF

// Monitor rewrite progress
INFO persistence
```

**Fix:** Adjust auto-rewrite thresholds or schedule manual rewrites during off-peak hours.

**Issue 3: Memory Fragmentation**

```redis
// Check fragmentation ratio
INFO memory
```

**Fix:** Fragmentation ratio > 1.5 indicates issues. Consider Redis restart during maintenance window.

**Issue 4: High Slowlog Count**

```redis
// Review slow queries
SLOWLOG GET 10

// Check for patterns
// Look for KEYS *, large HGETALL, etc.
```

**Fix:** Use Profiler to identify problem commands and optimize application code.

---

## ✅ Lab Completion Checklist

- [ ] Opened Redis Insight and connected to database
- [ ] Configured RDB persistence with proper intervals
- [ ] Enabled AOF with everysec sync policy
- [ ] Set memory limits and eviction policy
- [ ] Configured connection timeouts and limits
- [ ] Enabled and configured slowlog
- [ ] Tested BGSAVE and BGREWRITEAOF
- [ ] Verified all settings with CONFIG GET
- [ ] Monitored persistence with INFO commands
- [ ] Used Redis Insight Analysis tab
- [ ] Completed all 3 exercises

**Estimated time:** 45 minutes

---

## 🔍 Redis Insight Features Used

| Feature | Purpose | When Used |
|---------|---------|-----------|
| **Workbench** | Execute all CONFIG commands | All configuration tasks |
| **Analysis** | Memory analysis | Capacity planning, troubleshooting |
| **Profiler** | Real-time monitoring | Better than MONITOR command |
| **Browser** | Verify data persistence | Confirming backups work |

---

## 📚 Additional Resources

- **Redis Persistence:** https://redis.io/docs/management/persistence/
- **Redis Security:** https://redis.io/docs/management/security/
- **Memory Optimization:** https://redis.io/docs/management/optimization/memory-optimization/
- **Production Checklist:** https://redis.io/docs/management/optimization/

---

## 💡 Key Takeaways

1. **Use both RDB + AOF** for maximum data safety
2. **everysec sync policy** provides best balance of durability and performance
3. **allkeys-lru eviction** works well for most caching use cases
4. **Regular backups** are essential - test your restore procedures!
5. **Monitor slowlog** to identify performance issues
6. **Redis Insight** makes configuration and monitoring visual and accessible
7. **CONFIG commands** can be run in Workbench - no terminal required!

---

## ⏭️ Next Steps

**Lab 14:** Advanced data structures and use cases.

Ready to continue? Open Lab 14's README.md!
