# Lab 5: Redis Insight Monitoring & Analysis

**Duration:** 45 minutes
**Focus:** Production monitoring with Redis Insight's advanced features
**Prerequisites:** Lab 4 completed, Redis Insight connected, some data in Redis

## 🎯 Learning Objectives

- Master Redis Insight Profiler for real-time command monitoring
- Use Analysis tab for memory and performance insights
- Monitor slow queries with Slowlog viewer
- Perform capacity planning with built-in tools
- Troubleshoot performance issues visually
- Understand production-safe monitoring techniques

---

## 🚀 Quick Start

### Step 1: Ensure Redis is Running and Has Data

**Windows:**
```cmd
cd scripts
start-redis.bat
```

**Mac/Linux:**
```bash
docker run -d -p 6379:6379 --name redis redis/redis-stack:latest
```

### Step 2: Create Sample Data for Monitoring

**In Workbench, run these commands to create test data:**

```redis
// Create various data types
MSET customer:1001 "John" customer:1002 "Jane" customer:1003 "Bob"
HMSET policy:AUTO-001 type "auto" premium "1200" status "active"
HMSET policy:HOME-001 type "home" premium "850" status "active"
SADD tags:popular "insurance" "claims" "policies"
ZADD leaderboard 100 "user1" 200 "user2" 300 "user3"

// Create session data with TTL
SETEX session:user:alice 1800 '{"userId":"alice"}'
SETEX session:user:bob 1800 '{"userId":"bob"}'

// Create cache entries
SETEX cache:page:home 300 "<html>Home Page</html>"
SETEX cache:api:users 60 '[{"id":1},{"id":2}]'
```

### Step 3: Verify Data in Browser

1. Open **Browser** tab in Redis Insight
2. See all your keys organized by pattern
3. Click on different keys to inspect their values
4. Note the TTL countdown on session and cache keys

---

## Part 1: Redis Insight Profiler (Real-Time Monitoring)

### What is Profiler?

Profiler monitors ALL Redis commands in real-time. It's like MONITOR command but better:
- ✅ Doesn't block your Redis server
- ✅ Provides visual filtering and search
- ✅ Shows execution timestamps
- ✅ Can be paused/resumed/cleared
- ✅ Perfect for debugging and performance analysis

### Using Profiler

1. **Open Profiler:**
   - Click **"Profiler"** in Redis Insight left sidebar
   - Click **"Start"** button

2. **Generate Activity in Workbench:**
   ```redis
   // Run various commands
   GET customer:1001
   HGETALL policy:AUTO-001
   SMEMBERS tags:popular
   ZRANGE leaderboard 0 -1 WITHSCORES

   // Batch operations
   MGET customer:1001 customer:1002 customer:1003

   // Slow operations (intentional)
   KEYS *
   ```

3. **Analyze in Profiler:**
   - See all commands logged with timestamps
   - Notice command execution order
   - Use filter to find specific commands (e.g., "GET")
   - Click on a command to see full details

4. **Stop Profiler:**
   - Click **"Stop"** button
   - Review captured commands
   - Export logs if needed

### Profiler Use Cases

**1. Debug Application Behavior:**
- See exactly what commands your app is sending
- Verify command parameters
- Check command frequency

**2. Performance Analysis:**
- Identify slow commands
- Find commands executed too frequently
- Spot inefficient patterns (e.g., N+1 queries)

**3. Security Monitoring:**
- Watch for unusual command patterns
- Detect potential attacks
- Audit command usage

💡 **Pro Tip:** Use Profiler during development to ensure your app uses Redis efficiently!

---

## Part 2: Analysis Tab (Memory & Performance Insights)

### What is Analysis Tab?

Analysis tab provides comprehensive memory and performance analysis without blocking Redis. It's perfect for:
- 📊 Memory usage by key pattern
- 🔍 Finding largest keys
- 📈 Data distribution analysis
- 💾 Capacity planning

### Using Analysis Tab

1. **Open Analysis Tab:**
   - Click **"Analysis"** in Redis Insight left sidebar
   - Click **"New Report"** button

2. **Run Memory Analysis:**
   - Redis Insight scans your database safely (uses SCAN, not KEYS)
   - Wait for analysis to complete
   - View results organized by key patterns

3. **Explore Results:**
   - **Memory by Pattern:** See which key patterns use most memory
   - **Top Keys:** Identify largest individual keys
   - **Data Type Distribution:** Breakdown by string, hash, set, etc.
   - **Key Distribution:** Number of keys per pattern

### Practical Analysis Example

**Create test data with different sizes:**

**In Workbench:**
```redis
// Create large string
SET large:data "x" // Now expand it
APPEND large:data "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
APPEND large:data "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
APPEND large:data "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

// Create large hash
HMSET large:policy:001 field1 "data1" field2 "data2" field3 "data3" field4 "data4" field5 "data5"

// Create many small keys
MSET small:1 "a" small:2 "b" small:3 "c" small:4 "d" small:5 "e"
```

**Run Analysis again and compare:**
- Which pattern uses more memory: `large:*` or `small:*`?
- Which individual key is largest?
- How much memory does each data type consume?

### Memory Optimization Tips

Use Analysis tab to:
1. **Find memory leaks:** Keys that should have TTL but don't
2. **Identify bloat:** Keys storing redundant data
3. **Plan capacity:** Project future memory needs
4. **Optimize structure:** Consider more efficient data types

💡 **Production Tip:** Run Analysis reports regularly to track memory growth trends!

---

## Part 3: Slowlog Monitoring

### What is Slowlog?

Slowlog records commands that exceed a specified execution time threshold. Perfect for finding performance bottlenecks!

### Configure Slowlog

**In Workbench:**

```redis
// Set threshold: log commands slower than 10ms (10000 microseconds)
CONFIG SET slowlog-log-slower-than 10000

// Set how many slow queries to keep (default: 128)
CONFIG SET slowlog-max-len 128

// Verify configuration
CONFIG GET slowlog-log-slower-than
```

### Generate Slow Queries

**In Workbench:**

```redis
// These operations might appear in slowlog
KEYS *                        // Slow: scans entire keyspace
HGETALL large:policy:001      // Potentially slow with many fields

// Create more test data
SADD large:set 1 2 3 4 5 6 7 8 9 10
SMEMBERS large:set            // Gets all members

// Pattern matching is slow
SCAN 0 MATCH customer:* COUNT 1000
```

### View Slowlog

**Method 1: In Workbench**

```redis
// Get last 10 slow queries
SLOWLOG GET 10

// Get slowlog length
SLOWLOG LEN

// Reset slowlog
SLOWLOG RESET
```

**Method 2: In Redis Insight (Easier!)**

1. Some versions of Redis Insight have a **Slowlog** viewer
2. Or use **Workbench** to run SLOWLOG commands
3. Results are formatted nicely for easy reading

### Interpret Slowlog Output

Each entry shows:
- **Slow log ID** - Unique identifier
- **Unix timestamp** - When the command executed
- **Execution time** - In microseconds
- **Command** - The actual command that was slow
- **Client** - Which client executed it

**Example:**
```
1) (integer) 123           # Slowlog ID
2) (integer) 1699564800    # Timestamp
3) (integer) 15000         # 15ms execution time
4) 1) "KEYS"               # Command
   2) "*"                  # Argument
5) "127.0.0.1:54321"       # Client address
```

💡 **Optimization Workflow:**
1. Configure slowlog threshold
2. Run your application
3. Check slowlog for slow commands
4. Optimize those commands
5. Verify improvement!

---

## Part 4: Performance Metrics & Server Stats

### Monitor Server Health in Workbench

**In Workbench, run these commands:**

```redis
// Overall server info
INFO

// Specific sections
INFO memory              // Memory usage and stats
INFO stats               // General statistics
INFO clients             // Connected clients
INFO cpu                 // CPU usage
INFO replication         // Replication status
INFO persistence         // RDB/AOF status

// Key database stats
DBSIZE                   // Total key count
INFO keyspace            // Keys per database
```

### Key Metrics to Monitor

**Memory Metrics:**
```redis
INFO memory
```

Look for:
- `used_memory_human` - Current memory usage
- `used_memory_peak_human` - Peak memory usage
- `mem_fragmentation_ratio` - Memory efficiency (ideal: 1.0-1.5)
- `maxmemory` - Memory limit (0 = unlimited)

**Performance Metrics:**
```redis
INFO stats
```

Look for:
- `instantaneous_ops_per_sec` - Current throughput
- `total_commands_processed` - Lifetime command count
- `rejected_connections` - Connection limit hits
- `expired_keys` - Keys auto-deleted by TTL
- `evicted_keys` - Keys removed due to memory limits

**Connection Metrics:**
```redis
INFO clients
CLIENT LIST              // List all connected clients
```

Look for:
- `connected_clients` - Current connections
- `blocked_clients` - Clients waiting on blocking operations

### Troubleshooting Common Issues

**Issue 1: High Memory Usage**

```redis
// 1. Check current memory
INFO memory

// 2. Find largest keys (use Analysis tab or:)
// Note: This can be slow, use carefully
MEMORY USAGE customer:1001

// 3. Check for keys without TTL that should have one
TTL suspicious:key

// 4. Look at key distribution
INFO keyspace
```

**Fix:** Use Analysis tab to identify memory hotspots and clean up unnecessary data.

**Issue 2: Slow Performance**

```redis
// 1. Check operations per second
INFO stats

// 2. Check slow queries
SLOWLOG GET 10

// 3. Check if server is busy
INFO cpu
```

**Fix:** Use Profiler to identify frequent or slow commands, then optimize them.

**Issue 3: Too Many Connections**

```redis
// 1. Check current connections
INFO clients

// 2. List all clients
CLIENT LIST

// 3. Check limit
CONFIG GET maxclients

// 4. Disconnect idle client (if needed)
// CLIENT KILL addr 127.0.0.1:12345
```

**Fix:** Review application connection pooling settings.

---

## Part 5: Capacity Planning with Redis Insight

### Estimate Future Needs

1. **Baseline Current Usage:**
   - Run Analysis tab to get current memory usage
   - Note keys per pattern
   - Check growth rate in INFO stats

2. **Calculate Per-Item Cost:**
   ```redis
   // Check memory usage of typical keys
   MEMORY USAGE customer:1001
   MEMORY USAGE policy:AUTO-001
   MEMORY USAGE session:user:alice
   ```

3. **Project Growth:**
   - If you have 1,000 customers now using 100KB
   - Expected 10,000 customers = ~1MB
   - Add 20-30% buffer for Redis overhead

4. **Monitor Trends:**
   - Run Analysis reports weekly
   - Track memory growth in INFO memory
   - Watch `used_memory_peak` trends

### Capacity Planning Checklist

- [ ] Current memory usage documented
- [ ] Memory per key type calculated
- [ ] Growth projections created
- [ ] Peak usage identified
- [ ] Buffer capacity planned (recommend 30%)
- [ ] maxmemory policy configured
- [ ] Eviction policy set (if using maxmemory)

**Set Memory Limits (if needed):**
```redis
// Set max memory to 2GB
CONFIG SET maxmemory 2gb

// Set eviction policy
CONFIG SET maxmemory-policy allkeys-lru

// Verify
CONFIG GET maxmemory
CONFIG GET maxmemory-policy
```

---

## 🎓 Exercises

Complete these exercises using **Redis Insight**:

### Exercise 1: Profiler Analysis

**Goal:** Monitor and analyze Redis commands in real-time

1. **Setup:**
   - Start Profiler in Redis Insight
   - Switch to Workbench

2. **Generate Activity:**
   ```redis
   // Run these commands in Workbench
   MSET test:1 "a" test:2 "b" test:3 "c"
   MGET test:1 test:2 test:3
   HSET user:100 name "Alice" age 30
   HGETALL user:100
   ZADD scores 100 "player1" 200 "player2"
   ZRANGE scores 0 -1 WITHSCORES
   ```

3. **Analyze in Profiler:**
   - How many commands were executed?
   - Which commands took longest?
   - Find the MSET command - what was its timestamp?
   - Use filter to show only "GET" commands

4. **Stop Profiler** and review findings

---

### Exercise 2: Memory Analysis

**Goal:** Identify memory usage patterns

1. **Create Test Data:**
   ```redis
   // Large hash
   HMSET profile:large:001 f1 "x" f2 "x" f3 "x" f4 "x" f5 "x" f6 "x" f7 "x" f8 "x" f9 "x" f10 "x"

   // Many small keys
   MSET tiny:1 "a" tiny:2 "b" tiny:3 "c" tiny:4 "d" tiny:5 "e"

   // Medium string
   SET medium:data "This is a medium-sized string with some content"
   ```

2. **Run Analysis:**
   - Open Analysis tab
   - Create new report
   - Wait for completion

3. **Answer These Questions:**
   - Which key pattern uses most memory?
   - What is the largest individual key?
   - How many keys of each data type exist?
   - What percentage of memory does each pattern use?

---

### Exercise 3: Slowlog Investigation

**Goal:** Find and fix slow operations

1. **Configure Slowlog:**
   ```redis
   CONFIG SET slowlog-log-slower-than 5000  // 5ms threshold
   CONFIG SET slowlog-max-len 100
   ```

2. **Generate Mixed Workload:**
   ```redis
   // Fast operations
   GET customer:1001
   SET test:fast "quick"

   // Slow operations
   KEYS *
   SCAN 0 COUNT 10000

   // Check slowlog
   SLOWLOG GET 5
   ```

3. **Analyze:**
   - Which commands appear in slowlog?
   - What are their execution times?
   - Why are they slow?
   - How would you optimize them?

---

### Exercise 4: Health Monitoring Dashboard

**Goal:** Create a monitoring routine

1. **Collect Metrics:**
   ```redis
   INFO memory | grep used_memory_human
   INFO stats | grep instantaneous_ops_per_sec
   INFO clients | grep connected_clients
   DBSIZE
   SLOWLOG LEN
   ```

2. **Document:**
   - Current memory usage
   - Operations per second
   - Number of connected clients
   - Total keys
   - Number of slow queries

3. **Set Thresholds:**
   - Decide acceptable ranges for each metric
   - Plan what to do if thresholds are exceeded

4. **Use Redis Insight:**
   - Bookmark commonly used INFO commands in Workbench
   - Schedule regular Analysis reports
   - Check Slowlog daily

---

## 📋 Key Commands Reference

**Run these in Redis Insight Workbench:**

### Monitoring Commands
```redis
INFO                           // Server information (all sections)
INFO memory                    // Memory metrics
INFO stats                     // Performance statistics
INFO clients                   // Client connections
INFO cpu                       // CPU usage
INFO persistence               // RDB/AOF status
INFO keyspace                  // Keys per database

DBSIZE                         // Total key count
CLIENT LIST                    // List all connected clients
CONFIG GET parameter           // Get configuration value
CONFIG SET parameter value     // Set configuration value
```

### Performance Analysis
```redis
SLOWLOG GET count              // View slow queries
SLOWLOG LEN                    // Slowlog entry count
SLOWLOG RESET                  // Clear slowlog

MEMORY USAGE key               // Memory used by specific key
MEMORY STATS                   // Memory allocation stats
```

### Safe Key Scanning
```redis
SCAN cursor MATCH pattern COUNT count  // Production-safe iteration
// Example:
SCAN 0 MATCH customer:* COUNT 10
```

💡 **Remember:** Redis Insight's Profiler, Analysis, and Browser tabs provide these features visually without typing commands!

---

## 💡 Best Practices

1. **Use Redis Insight Tools First**
   - Profiler > MONITOR command (non-blocking)
   - Analysis tab > `--bigkeys` (safer, visual)
   - Browser > KEYS command (uses SCAN internally)

2. **Monitor Continuously**
   - Run Analysis reports regularly (weekly/monthly)
   - Check Slowlog daily in production
   - Use Profiler during development

3. **Set Slowlog Thresholds**
   - Production: 10ms (`slowlog-log-slower-than 10000`)
   - Development: 5ms for stricter monitoring
   - Review slowlog regularly

4. **Track Memory Growth**
   - Baseline current usage
   - Monitor trends with INFO memory
   - Set alerts for 80% capacity
   - Plan capacity 6 months ahead

5. **Understand Your Data**
   - Know memory cost per key type
   - Set appropriate TTLs
   - Use most efficient data structures
   - Regular cleanup of stale data

---

## ✅ Lab Completion Checklist

- [ ] Opened Redis Insight and connected to database
- [ ] Created sample data for monitoring
- [ ] Used Profiler to monitor real-time commands
- [ ] Filtered and analyzed Profiler output
- [ ] Ran Analysis tab to identify memory usage patterns
- [ ] Configured and checked Slowlog
- [ ] Generated and analyzed slow queries
- [ ] Ran INFO commands for server statistics
- [ ] Troubleshot common performance issues
- [ ] Created capacity planning estimates
- [ ] Completed all 4 exercises

**Estimated time:** 45 minutes

---

## 🔍 Redis Insight Features Used in This Lab

| Feature | Purpose | When to Use |
|---------|---------|-------------|
| **Profiler** | Real-time command monitoring | Debugging, development, performance analysis |
| **Analysis** | Memory usage by pattern | Capacity planning, optimization |
| **Workbench** | Execute monitoring commands | Running INFO, SLOWLOG, CONFIG commands |
| **Browser** | Visual key exploration | Understanding data distribution |

---

## 📚 Additional Resources

- **Redis Monitoring:** https://redis.io/docs/management/optimization/
- **Redis INFO Command:** https://redis.io/commands/info/
- **Redis Slowlog:** https://redis.io/commands/slowlog/
- **Redis Insight Documentation:** https://redis.io/docs/stack/insight/
- **Capacity Planning:** https://redis.io/docs/management/scaling/

---

## 💡 Key Takeaways

1. **Redis Insight Profiler** is superior to MONITOR command - non-blocking and visual
2. **Analysis tab** provides production-safe memory analysis without manual scripting
3. **Slowlog** is essential for identifying performance bottlenecks
4. **INFO command** provides comprehensive server metrics
5. **Regular monitoring** prevents issues before they become critical
6. **Visual tools** make Redis monitoring accessible without complex scripts
7. **No external scripts needed** - Redis Insight has all monitoring features built-in!

---

## ⏭️ Next Steps

**Lab 6:** Introduction to JavaScript Redis client for building applications with Node.js.

Ready to continue? Open Lab 6's README.md!
