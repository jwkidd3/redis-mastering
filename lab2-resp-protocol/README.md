# Lab 2: RESP Protocol & Redis Insight Profiler

**Duration:** 45 minutes
**Focus:** RESP protocol understanding, real-time monitoring with Profiler, hash operations
**Prerequisites:** Redis Insight connected to Redis server

## 🎯 Learning Objectives

- Understand RESP protocol data types
- Monitor real-time Redis operations using Profiler
- Use hash data structures for structured data
- Analyze command patterns and performance
- Debug Redis operations visually

## 🚀 Quick Start

### Step 1: Ensure Redis Insight is Connected

1. Open Redis Insight
2. Verify you're connected to your Redis database
3. Open **Workbench** tab (this is your Redis CLI)

### Step 2: Test Connection

In Workbench, run:
```redis
PING
```
Expected response: `PONG`

---

## Part 1: RESP Protocol Fundamentals

### Understanding RESP Data Types

Redis uses **RE**dis **S**erialization **P**rotocol (RESP) to communicate. All data types are represented as text:

| Type | Symbol | Example | Description |
|------|--------|---------|-------------|
| **Simple String** | `+` | `+OK\r\n` | Short text responses |
| **Error** | `-` | `-ERR unknown command\r\n` | Error messages |
| **Integer** | `:` | `:42\r\n` | Numbers |
| **Bulk String** | `$` | `$5\r\nhello\r\n` | Data with length prefix |
| **Array** | `*` | `*2\r\n$3\r\nfoo\r\n$3\r\nbar\r\n` | Multiple items |

### Observe Protocol with Profiler

**Redis Insight Profiler** is much better than MONITOR command because it:
- ✅ Doesn't block your CLI
- ✅ Provides visual filtering and search
- ✅ Shows timing information
- ✅ Can be paused/resumed easily

**Let's use it:**

1. **Open Profiler:**
   - Click **"Profiler"** in Redis Insight left sidebar
   - Click **"Start"** button

2. **Run Commands in Workbench:**

```redis
// Simple String response
PING

// Integer response
INCR counter:views

// Bulk String response
SET policy:POL001 "Life Insurance"
GET policy:POL001

// Error response (intentional)
WRONGCOMMAND

// Array response
MSET customer:C001 "John" customer:C002 "Jane"
MGET customer:C001 customer:C002
```

3. **View in Profiler:**
   - See all commands logged in real-time
   - Notice the RESP response types
   - View execution timestamps

4. **Stop Profiler:**
   - Click **"Stop"** button
   - Review captured commands

---

## Part 2: Hash Data Structures

### What are Hashes?

Hashes are Redis data structures that map string fields to string values - perfect for objects like customers, policies, companies.

### Create and Query Hashes

**In Workbench, run these commands:**

```redis
// Create a company record with multiple fields
HMSET company:ACME001 name "ACME Corp" industry "Tech" employees 500 revenue "50M"

// Get a single field
HGET company:ACME001 name

// Get multiple fields
HMGET company:ACME001 industry employees

// Get all fields and values
HGETALL company:ACME001

// Check if field exists
HEXISTS company:ACME001 revenue

// Get all field names
HKEYS company:ACME001

// Get all values
HVALS company:ACME001

// Count fields
HLEN company:ACME001

// Increment a numeric field
HINCRBY company:ACME001 employees 50
```

### View Hashes in Browser

1. Switch to **Browser** tab
2. Find `company:ACME001`
3. See the hash visualized as key-value pairs
4. Edit values directly through the GUI

---

## Part 3: Sorted Sets (Leaderboards)

### Create Risk Score Leaderboard

```redis
// Add customers with risk scores (0-100)
ZADD risk:scores 25 "CUST001" 85 "CUST002" 45 "CUST003" 92 "CUST004"

// Get top 3 highest risk (descending order)
ZREVRANGE risk:scores 0 2 WITHSCORES

// Get customers in risk range (30-90)
ZRANGEBYSCORE risk:scores 30 90 WITHSCORES

// Get customer's risk score
ZSCORE risk:scores "CUST002"

// Get customer's rank (0-based, ascending)
ZRANK risk:scores "CUST001"

// Get reverse rank (descending - highest = 0)
ZREVRANK risk:scores "CUST004"

// Increment risk score
ZINCRBY risk:scores 10 "CUST001"

// Count customers in range
ZCOUNT risk:scores 0 50

// Get total customers
ZCARD risk:scores
```

---

## Part 4: Performance Optimization

### Batch Operations

**❌ Bad: Individual commands (multiple round trips)**
```redis
SET policy:POL001 "Life Insurance"
SET policy:POL002 "Auto Insurance"
SET policy:POL003 "Home Insurance"
```

**✅ Good: Batch command (one round trip)**
```redis
MSET policy:POL004 "Health" policy:POL005 "Travel" policy:POL006 "Business"
```

### Monitor Performance with Profiler

1. **Start Profiler** again
2. **Run both approaches:**

Individual commands:
```redis
SET test:1 "value1"
SET test:2 "value2"
SET test:3 "value3"
```

Batch command:
```redis
MSET test:4 "value4" test:5 "value5" test:6 "value6"
```

3. **Compare in Profiler:**
   - Individual: 3 commands logged, 3 separate timestamps
   - Batch: 1 command logged, single timestamp
   - Batch is much faster!

---

## Part 5: Client Management

### View Connected Clients

```redis
// List all connected clients
CLIENT LIST

// Set a name for this connection
CLIENT SETNAME "workbench-lab2"

// Get current client name
CLIENT GETNAME

// View client list again to see your name
CLIENT LIST
```

---

## Part 6: Server Information

### Inspect Redis Server

```redis
// Get server information
INFO server

// Get memory stats
INFO memory

// Get client stats
INFO clients

// Get command stats
INFO stats

// Get all info sections
INFO
```

---

## Part 7: Slow Query Analysis

### Configure Slow Log

```redis
// Set threshold: log commands slower than 10ms (10000 microseconds)
CONFIG SET slowlog-log-slower-than 10000

// Set how many slow queries to keep
CONFIG SET slowlog-max-len 128

// View current config
CONFIG GET slowlog-log-slower-than
```

### View Slow Queries

```redis
// Get last 10 slow queries
SLOWLOG GET 10

// Get slow log length
SLOWLOG LEN

// Reset slow log
SLOWLOG RESET
```

**Each slow log entry shows:**
- Slow log ID
- Unix timestamp
- Execution time (microseconds)
- Command and arguments

---

## 🎓 Exercises

### Exercise 1: Company Management

Create 3 company records using hashes:

```redis
// 1. Create companies
HMSET company:TECH001 name "TechCorp" industry "Technology" employees 500 revenue "25M"
HMSET company:FIN001 name "FinBank" industry "Finance" employees 1000 revenue "100M"
HMSET company:HEALTH001 name "HealthCo" industry "Healthcare" employees 300 revenue "15M"

// 2. Query companies
HGETALL company:TECH001
HGET company:FIN001 revenue
HMGET company:HEALTH001 industry employees

// 3. Update employee count
HINCRBY company:TECH001 employees 50

// 4. View in Browser tab
```

### Exercise 2: Risk Leaderboard

Create and query a risk scoring system:

```redis
// 1. Add 5 customers with risk scores
ZADD risk:scores 35 "CUST001" 72 "CUST002" 45 "CUST003" 88 "CUST004" 15 "CUST005"

// 2. Find top 3 highest risk
ZREVRANGE risk:scores 0 2 WITHSCORES

// 3. Count customers with risk > 50
ZCOUNT risk:scores 50 100

// 4. Get all low risk customers (< 40)
ZRANGEBYSCORE risk:scores 0 40 WITHSCORES
```

### Exercise 3: Profiler Practice

1. **Start Profiler**
2. **Run these commands:**

```redis
SET test:monitor:1 "value1"
HSET user:100 name "John" age 30
ZADD scores 100 "player1"
SADD tags "redis" "insight" "profiler"
```

3. **In Profiler:**
   - Filter by command type
   - Find the HSET command
   - Note the execution times
4. **Stop Profiler**

---

## 🔍 Redis Insight Features Used

| Feature | Purpose | When to Use |
|---------|---------|-------------|
| **Workbench** | Execute Redis commands | All command execution |
| **Profiler** | Monitor commands in real-time | Debugging, performance analysis |
| **Browser** | Visual key explorer | View/edit data, inspect structures |
| **Slowlog Viewer** | Find slow commands | Performance optimization |

---

## ✅ Lab Completion Checklist

- [ ] Connected Redis Insight to Redis server
- [ ] Ran commands in Workbench
- [ ] Used Profiler to monitor operations
- [ ] Created and queried hash data structures
- [ ] Viewed hashes in Browser tab
- [ ] Created sorted sets for leaderboards
- [ ] Analyzed slow queries
- [ ] Completed all exercises

**Estimated time:** 45 minutes

---

## 📚 Additional Resources

- **RESP Protocol:** https://redis.io/docs/reference/protocol-spec/
- **Redis Hashes:** https://redis.io/docs/data-types/hashes/
- **Redis Sorted Sets:** https://redis.io/docs/data-types/sorted-sets/
- **Redis Insight:** https://redis.io/docs/stack/insight/

---

## 💡 Key Takeaways

1. **Redis Insight Profiler** > MONITOR command
   - Non-blocking
   - Better visualization
   - Filtering and search

2. **Hashes** are perfect for structured data
   - Use for customers, policies, products
   - More memory efficient than separate keys

3. **Sorted Sets** are perfect for rankings
   - Leaderboards, risk scores, trending data
   - Fast range queries

4. **Batch operations** (MSET, MGET) are faster
   - Reduce network round trips
   - Use Profiler to verify performance

5. **Workbench IS your Redis CLI**
   - No need for terminal redis-cli
   - Autocomplete, syntax highlighting
   - Integrated with Browser and Profiler
