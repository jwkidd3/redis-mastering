# Redis Insight Workbench - Complete Course Guide

This document explains how to use **Redis Insight Workbench** for ALL 15 labs in this Redis Mastering course.

## 🎯 Overview

**All 15 labs can be completed using Redis Insight Workbench!**

- **Day 1 (Labs 1-5)**: 100% runnable in Workbench - pure Redis CLI commands
- **Day 2-3 (Labs 6-15)**: JavaScript labs with Redis command practice available in Workbench

---

## 🚀 Getting Started with Redis Insight

### Installation

1. **Download Redis Insight:**
   - Desktop: https://redis.io/insight/
   - Or use web version: `http://localhost:8001` (if Redis Stack is running)

2. **Connect to Redis:**
   - Click **"Add Database"**
   - Enter connection details:
     - Host: (provided by instructor or `localhost`)
     - Port: 6379
     - Password: (if required)
   - Click **"Test Connection"** → **"Add Database"**

### Using Workbench

**Workbench** is Redis Insight's command execution interface (like a CLI but better):

1. Click your database connection
2. Select **"Workbench"** tab from left sidebar
3. Type Redis commands and press **Enter** or click **"Run"**
4. View results immediately below

**Browser** tab lets you visually explore all keys, edit values, and manage data through a GUI.

**Profiler** replaces the MONITOR command - it shows all commands executing in real-time without blocking.

---

## 📋 Lab-by-Lab Guide

### Day 1: CLI-Focused Labs

#### Lab 1: Redis CLI Basics
**Status:** ✅ **100% Workbench Compatible**
**File:** `lab1-redis-cli-basics/REDIS-INSIGHT.md`

**What You'll Run:**
- Basic SET/GET operations
- INCR/INCRBY counters
- Key management (EXISTS, KEYS, TYPE, DEL)
- TTL operations (SETEX, EXPIRE, TTL, PERSIST)
- Server info (DBSIZE, INFO)

**Lab explicitly teaches Redis Insight** - includes Browser and CLI tab exercises!

---

#### Lab 2: RESP Protocol & Monitoring
**Status:** ✅ **95% Workbench Compatible**
**File:** `lab2-resp-protocol/REDIS-INSIGHT.md`

**What You'll Run:**
- Hash operations (HMSET, HGET, HGETALL)
- Sorted sets (ZADD, ZREVRANGE)
- Client management (CLIENT LIST, CLIENT SETNAME)
- Slow query analysis (SLOWLOG)
- Configuration (CONFIG SET/GET)

**Note:** Use Redis Insight's **Profiler** instead of MONITOR command - it's better!

---

#### Lab 3: Data Operations with Strings
**Status:** ✅ **100% Workbench Compatible**
**File:** `lab3-data-operations-strings/REDIS-INSIGHT.md` (create)

**What You'll Run:**
- Advanced string operations
- Atomic counters (INCR, INCRBY, DECRBY)
- Batch operations (MSET, MGET)
- String manipulation (APPEND, STRLEN)

**All commands work perfectly in Workbench!**

---

#### Lab 4: Key Management & TTL
**Status:** ✅ **100% Workbench Compatible**
**File:** `lab4-key-management-ttl/REDIS-INSIGHT.md` (create)

**What You'll Run:**
- Hierarchical key patterns
- SCAN operations (better than KEYS *)
- TTL strategies
- Key expiration management

**Redis Insight's Browser tab provides excellent key visualization!**

---

#### Lab 5: Advanced CLI & Monitoring
**Status:** ✅ **90% Workbench Compatible**
**File:** `lab5-advanced-cli-monitoring/REDIS-INSIGHT.md` (create)

**What You'll Run:**
- SCAN with patterns
- Memory analysis (MEMORY USAGE, MEMORY STATS)
- Lua scripts (EVAL)
- Performance monitoring (INFO, SLOWLOG)

**Note:** Use Redis Insight's Memory Analysis tool instead of `redis-cli --bigkeys`

---

### Day 2-3: JavaScript Labs with CLI Components

#### Lab 6: JavaScript Redis Client
**Status:** ⚠️ **30% CLI Practice Available**
**Primary Focus:** JavaScript/Node.js programming
**CLI Commands:** Basic SET/GET operations for testing

**Redis Insight Use:**
- Test your JavaScript app's Redis commands
- Monitor data created by your Node.js application
- Use Profiler to see what your app is doing to Redis

---

#### Lab 7: Customer Profiles & Hashes
**Status:** ✅ **70% CLI Practice Available**
**File:** `lab7-customer-policy-hashes/REDIS-INSIGHT.md` (create)

**Primary Focus:** JavaScript hash management
**CLI Commands Available:**
- HSET, HGET, HGETALL for customer profiles
- HMGET for multiple fields
- HINCRBY for numeric fields
- HEXISTS, HKEYS, HVALS
- HLEN for field count

**Great lab for practicing hash commands in Workbench!**

---

#### Lab 8: Claims Event Sourcing (Streams)
**Status:** ⚠️ **60% CLI Practice Available**
**File:** `lab8-claims-event-sourcing/REDIS-INSIGHT.md` (create)

**Primary Focus:** JavaScript event sourcing system
**CLI Commands Available:**
- XADD to create events
- XREAD to read events
- XGROUP for consumer groups
- XREADGROUP for consuming
- XINFO for stream information
- XPENDING for pending messages

**Redis Insight visualizes streams beautifully!**

---

#### Lab 9: Insurance Analytics (Sets & Sorted Sets)
**Status:** ✅ **80% CLI Practice Available**
**File:** `lab9-sets-analytics/REDIS-INSIGHT.md` ✅ **CREATED**

**Primary Focus:** JavaScript analytics
**CLI Commands Available:**
- SADD, SMEMBERS, SISMEMBER for customer segments
- SINTER, SUNION, SDIFF for set operations
- ZADD, ZREVRANGE for risk scoring
- ZRANGEBYSCORE for range queries
- ZINCRBY for score updates

**Excellent lab for extensive Workbench practice!**

---

#### Lab 10: Advanced Caching Patterns
**Status:** ✅ **75% CLI Practice Available**
**File:** `lab10-advanced-caching-patterns/examples/redis-insight/insight-commands.md` ✅ **EXISTS**

**Primary Focus:** JavaScript caching system
**CLI Commands Available:**
- SET with EX for cache entries
- GET for cache retrieval
- TTL for cache monitoring
- DEL for cache invalidation
- MEMORY USAGE for cache analysis

**Lab already includes dedicated Insight commands file!**

---

#### Lab 11: Session Management
**Status:** ✅ **85% CLI Practice Available**
**File:** `lab11-session-management/REDIS-INSIGHT.md` (create)

**Primary Focus:** JavaScript session system
**CLI Commands Available:**
- HSET for session data
- HGETALL to view sessions
- SMEMBERS for active sessions
- TTL for session expiration
- LRANGE for security logs
- Lua scripts for analytics

**Lab explicitly includes Redis Insight monitoring section!**

---

#### Lab 12: Rate Limiting & API Protection
**Status:** ⚠️ **60% CLI Practice Available**
**File:** `lab12-rate-limiting-api-protection/REDIS-INSIGHT.md` (create)

**Primary Focus:** Express.js API server
**CLI Commands Available:**
- KEYS for rate limit inspection
- ZRANGE for rate limit windows
- MEMORY USAGE for analysis
- INFO stats for monitoring

**Use Workbench to monitor rate limiting in action!**

---

#### Lab 13: Production Configuration
**Status:** ✅ **90% Workbench Compatible**
**File:** `lab13-production-configuration/REDIS-INSIGHT.md` (create)

**What You'll Run:**
- CONFIG SET for persistence (save, appendonly)
- CONFIG SET for memory (maxmemory, maxmemory-policy)
- CONFIG GET to view settings
- BGSAVE, BGREWRITEAOF for backups
- LASTSAVE, INFO persistence

**All configuration commands work in Workbench!**

---

#### Lab 14: Production Monitoring
**Status:** ⚠️ **50% CLI Practice Available**
**File:** `lab14-production-monitoring/REDIS-INSIGHT.md` (create)

**Primary Focus:** Node.js monitoring dashboard
**CLI Commands Available:**
- INFO server, INFO memory, INFO stats
- INFO clients, INFO commandstats
- DBSIZE, CLIENT LIST
- SLOWLOG GET

**Redis Insight provides better built-in monitoring tools!**

---

#### Lab 15: Redis Cluster HA
**Status:** ✅ **70% Workbench Compatible**
**File:** `lab15-redis-cluster-ha/REDIS-INSIGHT.md` (create)

**Setup:** Terminal/Docker required for cluster creation
**Monitoring:** Redis Insight can connect to cluster nodes!

**CLI Commands Available:**
- CLUSTER INFO, CLUSTER NODES
- CLUSTER SLOTS
- SET/GET with hash slot awareness
- INFO replication
- CLUSTER REPLICAS

**Redis Insight can manage cluster connections!**

---

## 🎓 How to Use This Guide

### For Day 1 (Labs 1-5):

1. **Open Redis Insight** and connect to your Redis server
2. **Open Workbench** tab
3. **Open the lab's REDIS-INSIGHT.md file** in a second window/monitor
4. **Copy commands** from the guide into Workbench
5. **Run and observe** the results
6. **Switch to Browser tab** to visualize the data you created

### For Day 2-3 (Labs 6-15):

1. **Work through the JavaScript code** in your IDE/terminal first
2. **While your app runs**, open Redis Insight
3. **Use Profiler** to see what your app is doing to Redis
4. **Open the lab's REDIS-INSIGHT.md file** for CLI practice
5. **Run the Redis commands** to understand what your code does
6. **Use Browser tab** to inspect data created by your application

---

## 💡 Redis Insight Advantages Over Terminal CLI

| Feature | redis-cli | Redis Insight Workbench |
|---------|-----------|-------------------------|
| **Command Execution** | Text only | Syntax highlighting, autocomplete |
| **Results Display** | Raw text | Formatted, color-coded, collapsible |
| **Key Browsing** | KEYS command | Visual tree browser with search |
| **Monitoring** | MONITOR (blocks) | Profiler (non-blocking, filterable) |
| **Memory Analysis** | Manual commands | Visual analyzer with charts |
| **Slow Log** | Text output | Formatted table with sorting |
| **Multiple Commands** | One at a time | Select and run multiple |
| **Data Visualization** | None | Sets, hashes, streams visualized |
| **Cluster Management** | Complex | GUI-based node management |

---

## 🛠️ Workbench Features

### Command Execution
- **Autocomplete:** Start typing command names
- **History:** Up/down arrows to recall commands
- **Multi-line:** Shift+Enter for new line
- **Batch Run:** Select multiple commands and run together

### Results Display
- **Collapsible:** Collapse large results
- **Copy:** Click to copy results to clipboard
- **Format:** JSON, arrays, nested data beautifully formatted
- **Export:** Save results to file

### Profiler (Monitoring)
- **Start/Stop:** Non-blocking command monitoring
- **Filter:** By command type, key pattern
- **Export:** Save monitoring session
- **Better than MONITOR:** Doesn't block your CLI

### Browser Tab
- **Tree View:** Hierarchical key organization
- **Search/Filter:** Find keys by pattern
- **Edit:** Modify values through GUI
- **Add:** Create new keys visually
- **Delete:** Remove keys with confirmation
- **TTL:** See expiration countdown in real-time

---

## ✅ Verification Checklist

### Connection Setup
- [ ] Redis Insight installed
- [ ] Connected to Redis server
- [ ] Can run PING command in Workbench
- [ ] Browser tab shows existing keys
- [ ] Profiler can start/stop

### Lab Files Available
- [ ] Lab 1: REDIS-INSIGHT.md ✅
- [ ] Lab 2: REDIS-INSIGHT.md ✅
- [ ] Lab 3: REDIS-INSIGHT.md (create)
- [ ] Lab 4: REDIS-INSIGHT.md (create)
- [ ] Lab 5: REDIS-INSIGHT.md (create)
- [ ] Lab 6-8: REDIS-INSIGHT.md (create)
- [ ] Lab 9: REDIS-INSIGHT.md ✅
- [ ] Lab 10: insight-commands.md ✅
- [ ] Lab 11-15: REDIS-INSIGHT.md (create)

### Skills Practiced
- [ ] Basic string operations (SET/GET)
- [ ] Hash operations (HSET/HGET)
- [ ] Set operations (SADD/SINTER/SUNION)
- [ ] Sorted set operations (ZADD/ZRANGE)
- [ ] List operations (LPUSH/RPUSH/LRANGE)
- [ ] Stream operations (XADD/XREAD)
- [ ] TTL management (EXPIRE/TTL/PERSIST)
- [ ] Key patterns (KEYS/SCAN)
- [ ] Monitoring (Profiler)
- [ ] Configuration (CONFIG SET/GET)

---

## 📚 Additional Resources

- **Redis Insight Documentation:** https://redis.io/docs/stack/insight/
- **Redis Commands:** https://redis.io/commands/
- **Redis Data Types:** https://redis.io/docs/data-types/
- **Redis Insight Download:** https://redis.io/insight/

---

## 🎉 Course Completion

By the end of this course, you will have used Redis Insight Workbench to:

✅ Execute 100+ Redis commands across all data types
✅ Monitor Redis operations in real-time with Profiler
✅ Visualize data structures in Browser tab
✅ Analyze memory usage and performance
✅ Manage sessions, caching, and rate limiting
✅ Work with production configurations
✅ Monitor cluster operations

**Redis Insight is your production tool for Redis management!**
