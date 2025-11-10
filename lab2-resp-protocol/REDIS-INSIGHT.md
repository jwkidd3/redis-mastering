# Lab 2: RESP Protocol - Redis Insight Workbench Commands

This guide contains all Redis commands for Lab 2 that can be executed directly in **Redis Insight Workbench**.

## 🚀 Redis Insight Profiler vs MONITOR

**Important:** Instead of using `MONITOR` command (which blocks the CLI), Redis Insight provides a **Profiler** tool that's much better!

### Using the Profiler:
1. In Redis Insight, click **"Profiler"** in the left sidebar
2. Click **"Start"**
3. Run your Redis commands in Workbench or from your application
4. See all commands in real-time with timing information
5. Click **"Stop"** when done

This is **better than MONITOR** because it doesn't block your CLI and provides better visualization!

---

## Part 1: Hash Operations

### Create Company Records

```redis
// Create company hash
HMSET company:ACME001 name "ACME Corp" industry "Tech" employees 500 revenue "50M"

// Get single field
HGET company:ACME001 name
HGET company:ACME001 revenue

// Get multiple fields
HMGET company:ACME001 name industry employees

// Get all fields and values
HGETALL company:ACME001

// Check if field exists
HEXISTS company:ACME001 revenue
HEXISTS company:ACME001 profit

// Get all field names
HKEYS company:ACME001

// Get all values
HVALS company:ACME001

// Count fields
HLEN company:ACME001
```

**Expected Output:**
```
OK
"ACME Corp"
"50M"
1) "ACME Corp"
2) "Tech"
3) "500"
1) "name"
2) "ACME Corp"
3) "industry"
4) "Tech"
...
(integer) 1
(integer) 0
1) "name"
2) "industry"
...
(integer) 4
```

---

## Part 2: Connection & Client Management

### Client Information

```redis
// List all connected clients
CLIENT LIST

// Set a name for this connection
CLIENT SETNAME insight-lab2

// Get current client name
CLIENT GETNAME

// View your client in the list again
CLIENT LIST
```

**Expected Output:**
```
id=123 addr=127.0.0.1:52156 name= ...
OK
"insight-lab2"
id=123 addr=127.0.0.1:52156 name=insight-lab2 ...
```

### Server Information

```redis
// Get server info
INFO server

// Get stats
INFO stats

// Get memory info
INFO memory

// Get clients info
INFO clients

// Get all sections
INFO
```

---

## Part 3: Monitoring with Profiler

Instead of using MONITOR (which blocks the CLI), use Redis Insight Profiler:

1. **Open Profiler**
   - Click "Profiler" in Redis Insight left sidebar
   - Click "Start" button

2. **Run Commands in Workbench**
   ```redis
   SET test:1 "value1"
   GET test:1
   HSET user:100 name "John"
   HGET user:100 name
   ```

3. **View in Profiler**
   - See all commands as they execute
   - View command timing
   - Filter by command type
   - Export results

4. **Stop Profiler**
   - Click "Stop" when done
   - Review captured commands

---

## Part 4: Slow Query Analysis

### Configure Slow Log

```redis
// Set slow log threshold (microseconds)
// 10000 = log commands taking more than 10ms
CONFIG SET slowlog-log-slower-than 10000

// Set how many slow queries to keep
CONFIG SET slowlog-max-len 128

// View current config
CONFIG GET slowlog-log-slower-than
CONFIG GET slowlog-max-len
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

**Expected Output:**
```
1) 1) (integer) 0        <- Slow log ID
   2) (integer) 1699564123  <- Timestamp
   3) (integer) 12450       <- Execution time (microseconds)
   4) 1) "KEYS"             <- Command
      2) "customer:*"
```

---

## Part 5: Sorted Sets (Leaderboards)

### Create Risk Score Leaderboard

```redis
// Add customers with risk scores
ZADD risk:scores 25 "CUST001" 85 "CUST002" 45 "CUST003" 92 "CUST004"

// Get top 3 highest risk customers
ZREVRANGE risk:scores 0 2 WITHSCORES

// Get customers by risk range (30-90)
ZRANGEBYSCORE risk:scores 30 90 WITHSCORES

// Get customer's risk score
ZSCORE risk:scores "CUST002"

// Get customer's rank (0-based)
ZRANK risk:scores "CUST001"        // Low risk = low rank
ZREVRANK risk:scores "CUST001"     // High risk = low rank

// Increment risk score
ZINCRBY risk:scores 10 "CUST001"

// Count customers in risk range
ZCOUNT risk:scores 0 50

// Remove customer
ZREM risk:scores "CUST004"

// Get total customers
ZCARD risk:scores
```

**Expected Output:**
```
(integer) 4
1) "CUST004"
2) "92"
3) "CUST002"
4) "85"
...
"85"
(integer) 0
(integer) 3
"35"
(integer) 2
(integer) 1
(integer) 3
```

---

## Part 6: Protocol Observation

### Observe RESP Protocol in Profiler

1. **Start Profiler** in Redis Insight

2. **Run Commands:**
```redis
PING
SET key "hello"
GET key
DEL key
```

3. **In Profiler, you'll see:**
   - `PING` → Response: `+PONG`
   - `SET key "hello"` → Response: `+OK`
   - `GET key` → Response: `$5\r\nhello`
   - `DEL key` → Response: `:1`

4. **RESP Protocol Types:**
   - `+` = Simple String (OK, PONG)
   - `:` = Integer (1, 0, count)
   - `$` = Bulk String (actual data)
   - `*` = Array (multiple values)
   - `-` = Error

---

## Part 7: Performance Testing

### Batch Operations

```redis
// Instead of using --pipe, run multiple commands
MSET key1 "value1" key2 "value2" key3 "value3"
MGET key1 key2 key3

// Create multiple hashes
HSET customer:1001 name "John"
HSET customer:1002 name "Jane"
HSET customer:1003 name "Bob"

// Batch get
HGET customer:1001 name
HGET customer:1002 name
HGET customer:1003 name
```

### Check Performance Stats

```redis
// Total commands processed
INFO stats

// Command statistics
INFO commandstats

// Operations per second
INFO stats | grep instantaneous_ops_per_sec
```

---

## 🎓 Exercises

### Exercise 1: Company Management

```redis
// 1. Create 3 company records with hashes
HMSET company:TECH001 name "TechCorp" industry "Technology" employees 500
HMSET company:FIN001 name "FinBank" industry "Finance" employees 1000
HMSET company:HEALTH001 name "HealthCo" industry "Healthcare" employees 300

// 2. Retrieve all fields for each company
HGETALL company:TECH001
HGETALL company:FIN001
HGETALL company:HEALTH001

// 3. Get just the names
HGET company:TECH001 name
HGET company:FIN001 name
HGET company:HEALTH001 name

// 4. Update employee count
HINCRBY company:TECH001 employees 50
```

### Exercise 2: Risk Monitoring

```redis
// 1. Create risk leaderboard with 5 customers
ZADD risk:scores 35 "CUST001" 72 "CUST002" 45 "CUST003" 88 "CUST004" 15 "CUST005"

// 2. Find top 3 highest risk customers
ZREVRANGE risk:scores 0 2 WITHSCORES

// 3. Count customers with risk > 50
ZCOUNT risk:scores 50 100

// 4. Get all low risk customers (< 40)
ZRANGEBYSCORE risk:scores 0 40 WITHSCORES
```

### Exercise 3: Monitoring Practice

```redis
// 1. Start Profiler in Redis Insight

// 2. Run these commands:
SET test:monitor:1 "value1"
SET test:monitor:2 "value2"
HSET user:100 name "John" age 30
ZADD scores 100 "player1"

// 3. Check Profiler for all commands

// 4. Check slow log
SLOWLOG GET 5

// 5. Get client info
CLIENT LIST
```

---

## ✅ Lab Completion Checklist

Using Redis Insight Workbench and Profiler:

- [ ] Created and queried hashes with HSET/HGET/HGETALL
- [ ] Used CLIENT LIST and CLIENT SETNAME
- [ ] Created sorted sets with ZADD
- [ ] Queried leaderboards with ZREVRANGE
- [ ] Used Profiler instead of MONITOR
- [ ] Configured and checked SLOWLOG
- [ ] Viewed INFO stats
- [ ] Completed all exercises

---

## 💡 Redis Insight Advantages

| Feature | redis-cli | Redis Insight |
|---------|-----------|---------------|
| **Monitoring** | MONITOR (blocks CLI) | Profiler (non-blocking, better UI) |
| **Slow Log** | SLOWLOG GET | Visual slow log viewer |
| **Client List** | Text output | Formatted table |
| **Memory Analysis** | Manual commands | Visual memory analyzer |
| **Key Browser** | KEYS command | Tree view with search |

---

## 🎯 Key Redis Commands Used

| Command | Purpose | Example |
|---------|---------|---------|
| `HMSET` | Set multiple hash fields | `HMSET key f1 v1 f2 v2` |
| `HGET` | Get hash field | `HGET key field` |
| `HGETALL` | Get all hash fields | `HGETALL key` |
| `ZADD` | Add to sorted set | `ZADD key score member` |
| `ZREVRANGE` | Get top members | `ZREVRANGE key 0 10 WITHSCORES` |
| `CLIENT LIST` | List clients | `CLIENT LIST` |
| `SLOWLOG GET` | Get slow queries | `SLOWLOG GET 10` |
| `CONFIG SET` | Set configuration | `CONFIG SET param value` |
| `INFO` | Server information | `INFO stats` |

---

## 📚 Additional Resources

- **RESP Protocol:** https://redis.io/docs/reference/protocol-spec/
- **Monitoring:** https://redis.io/docs/management/optimization/latency/
- **Profiler:** Available in Redis Insight (built-in tool)
