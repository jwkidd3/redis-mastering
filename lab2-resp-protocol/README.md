# Lab 2: RESP Protocol & Monitoring

**Duration:** 45 minutes
**Focus:** RESP protocol, monitoring, and network performance optimization
**Prerequisites:** Redis CLI, Redis Insight installed

## 🎯 Learning Objectives

- Connect to remote Redis instances
- Understand RESP protocol data types
- Monitor real-time Redis communications
- Optimize command patterns for network performance
- Debug protocol-level issues

## Prerequisites

**Remote Redis:** `redis.training.local:6379`

Verify connection:
```bash
redis-cli -h redis.training.local -p 6379 ping
# Expected: PONG
```

**Note:** Set alias for convenience: `alias rcli='redis-cli -h redis.training.local -p 6379'`

## Part 1: RESP Protocol Fundamentals

### RESP Data Types

```
+ Simple Strings  → +OK\r\n
- Errors         → -ERR unknown command\r\n
: Integers       → :42\r\n
$ Bulk Strings   → $5\r\nhello\r\n
* Arrays         → *2\r\n$3\r\nfoo\r\n$3\r\nbar\r\n
```

### Observe Protocol

Terminal 1 - Monitor:
```bash
rcli monitor
```

Terminal 2 - Execute commands:
```bash
rcli PING                                  # Simple String
rcli INCR counter:views                    # Integer
rcli GET policy:POL001                     # Bulk String
rcli WRONGCOMMAND                          # Error
rcli MGET customer:C001 customer:C002      # Array
```

Watch Terminal 1 for RESP protocol format.

### Protocol Efficiency

```bash
# ❌ Bad: Individual operations (3 round trips)
rcli SET policy:POL001 "Life Insurance"
rcli SET policy:POL002 "Auto Insurance"
rcli SET policy:POL003 "Home Insurance"

# ✅ Good: Batch operation (1 round trip)
rcli MSET policy:POL004 "Health" policy:POL005 "Travel" policy:POL006 "Business"

# ✅ Best: Pipeline
echo -e "SET p:1 v1\nSET p:2 v2\nSET p:3 v3" | rcli --pipe
```

## Part 2: Redis Insight Setup

### Connect to Remote Redis

1. Open Redis Insight: `http://localhost:8001`
2. Click **"Add Database"**
3. Configure:
   - Host: `redis.training.local`
   - Port: `6379`
   - Alias: `Training Redis`
4. Navigate to **CLI** tab

### Execute Commands

```bash
# Hash operations
HMSET company:ACME001 name "ACME Corp" industry "Tech" employees 5000

# Get fields
HGET company:ACME001 name
HMGET company:ACME001 industry employees
HGETALL company:ACME001
```

### Use Profiler

1. Open **Profiler** in Redis Insight
2. Enable profiling
3. Execute operations:

```bash
# Customer operations
SET customer:C001 "John Doe, Age: 35"
INCR metrics:total_customers
EXPIRE customer:C001 3600

# Policy ranking
ZADD policies:premium 1200.50 "POL001" 2500.00 "POL002" 750.25 "POL003"
ZRANGE policies:premium 0 -1 WITHSCORES
```

4. Review captured commands and timing

### Error Handling

```bash
WRONGCOMMAND test              # Invalid command
GET nonexistent:key            # Key not found
INCR string:key               # Type mismatch
CLIENT LIST                    # Connection info
CLIENT SETNAME "Lab2:Test"    # Set client name
```

## Part 3: Performance Optimization

### Pipeline vs Individual Commands

```bash
# Test individual commands
for i in {1..100}; do
  rcli SET test:ind:$i "val$i" > /dev/null
done

# Test pipeline
for i in {1..100}; do
  echo "SET test:pipe:$i val$i"
done | rcli --pipe
```

Pipeline is 5-10x faster over network!

### Batch Operations

```bash
# ❌ Bad: 4 network round trips
rcli HSET customer:C001 name "John"
rcli HSET customer:C001 age 35
rcli HSET customer:C001 location "TX"
rcli HSET customer:C001 policies 3

# ✅ Good: 1 network round trip
rcli HMSET customer:C002 name "Jane" age 28 location "CA" policies 2
```

## Part 4: Monitoring & Debugging

### Connection Analysis

```bash
# List connections
rcli CLIENT LIST

# Set client name
rcli CLIENT SETNAME "PolicyService"

# Filter connections
rcli CLIENT LIST | grep PolicyService

# Connection stats
rcli INFO clients
```

### Slow Query Analysis

```bash
# Enable slow log (>10ms)
rcli CONFIG SET slowlog-log-slower-than 10000

# Trigger slow command
rcli DEBUG SLEEP 0.1

# View slow log
rcli SLOWLOG GET 10

# Reset log
rcli SLOWLOG RESET
```

### Raw Protocol Inspection

```bash
# Connect via telnet
telnet redis.training.local 6379

# Send raw RESP:
*1
$4
PING

# Expected response:
+PONG
```

## 🎓 Exercises

### Exercise 1: Protocol Analysis

1. Monitor protocol for 2 minutes
2. Count command types (GET, SET, HGET, etc.)
3. Identify optimization opportunities

### Exercise 2: Performance Testing

1. Compare individual vs batch vs pipeline operations
2. Measure time difference with `time` command
3. Calculate performance improvement percentage

### Exercise 3: Error Debugging

1. Trigger 5 different error types
2. Capture protocol responses
3. Document error handling patterns

## 📋 Key Commands

```bash
MONITOR                    # Real-time command stream
CLIENT LIST                # List connections
CLIENT SETNAME name        # Set connection name
INFO clients              # Connection statistics
SLOWLOG GET count         # View slow queries
CONFIG SET param value    # Configure Redis
```

## 💡 Best Practices

1. **Use batch operations:** MSET, HMSET instead of multiple SET/HSET
2. **Pipeline when possible:** Reduces network round trips by 90%+
3. **Monitor in development:** Understand protocol overhead
4. **Name your clients:** Easier debugging with CLIENT SETNAME
5. **Track slow queries:** Identify performance bottlenecks

## ✅ Lab Completion Checklist

- [ ] Connected to remote Redis
- [ ] Observed RESP protocol format
- [ ] Used Redis Insight Profiler
- [ ] Compared individual vs batch vs pipeline performance
- [ ] Monitored real-time commands
- [ ] Debugged protocol errors
- [ ] Analyzed slow queries

**Estimated time:** 45 minutes

## 📚 Additional Resources

- **RESP Spec:** `https://redis.io/docs/reference/protocol-spec/`
- **Redis Insight:** `https://redis.io/docs/stack/insight/`
- **Performance:** `https://redis.io/docs/management/optimization/`

## 🔧 Troubleshooting

```bash
# Connection test
rcli ping

# Check latency
rcli --latency

# Monitor latency patterns
rcli --latency-history

# View server info
rcli INFO server
```
