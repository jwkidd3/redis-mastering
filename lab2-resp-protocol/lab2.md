# Lab 2: RESP Protocol for Business Data Processing

**Duration:** 45 minutes  
**Objective:** Master RESP protocol observation, monitoring, and debugging for business applications

## 🎯 Learning Objectives

By the end of this lab, you will be able to:
- Understand RESP protocol structure and data types
- Monitor real-time Redis communications for business transactions
- Analyze protocol efficiency for high-volume operations
- Debug communication issues at the protocol level
- Use monitoring tools for production troubleshooting
- Optimize command patterns for better performance

---

## Prerequisites

Ensure you have completed Lab 1 and have:
- Docker running with Redis container
- Redis CLI available
- Redis Insight connected to localhost:6379
- Basic understanding of Redis commands

---

## Part 1: RESP Protocol Fundamentals (15 minutes)

### Step 1: Understanding RESP Data Types

RESP (Redis Serialization Protocol) uses 5 data types:

```
+ Simple Strings  → +OK\r\n
- Errors         → -ERR unknown command\r\n  
: Integers       → :42\r\n
$ Bulk Strings   → $5\r\nhello\r\n
* Arrays         → *2\r\n$3\r\nfoo\r\n$3\r\nbar\r\n
```

**Exercise 1: Observe Protocol in Action**

Open two terminals:

Terminal 1 - Start monitoring:
```bash
redis-cli monitor
```

Terminal 2 - Execute commands:
```bash
# Simple String response
redis-cli PING

# Integer response
redis-cli INCR counter:views

# Bulk String response
redis-cli GET policy:POL001

# Error response
redis-cli WRONGCOMMAND

# Array response
redis-cli MGET customer:C001 customer:C002
```

**Observe** the protocol format in Terminal 1.

### Step 2: Raw Protocol Communication

Test direct RESP protocol communication:

```bash
# Send raw PING command
echo -e "*1\r\n\$4\r\nPING\r\n" | nc localhost 6379

# Send raw SET command
echo -e "*3\r\n\$3\r\nSET\r\n\$8\r\ntest:key\r\n\$10\r\ntest value\r\n" | nc localhost 6379

# Send raw GET command
echo -e "*2\r\n\$3\r\nGET\r\n\$8\r\ntest:key\r\n" | nc localhost 6379
```

### Step 3: Protocol Efficiency Analysis

Load sample business data:
```bash
./scripts/load-business-data.sh
```

Compare protocol overhead for different operations:

```bash
# Individual operations (inefficient)
redis-cli SET policy:AUTO:1001 "Premium:1200"
redis-cli SET policy:AUTO:1002 "Premium:1400"
redis-cli SET policy:AUTO:1003 "Premium:950"

# Batch operation (efficient)
redis-cli MSET policy:AUTO:2001 "Premium:1200" policy:AUTO:2002 "Premium:1400" policy:AUTO:2003 "Premium:950"
```

Monitor the protocol differences between individual and batch operations.

---

## Part 2: Business Transaction Monitoring (15 minutes)

### Step 1: Customer Session Tracking

Monitor customer login session:

```bash
# Terminal 1: Monitor
redis-cli monitor

# Terminal 2: Simulate customer session
redis-cli SETEX session:customer:12345 1800 "logged_in"
redis-cli HSET customer:12345:activity login_time "2024-08-18T10:30:00"
redis-cli LPUSH customer:12345:actions "view_policy"
redis-cli LPUSH customer:12345:actions "update_contact"
redis-cli INCR customer:12345:page_views
```

### Step 2: Claims Processing Workflow

Monitor claims queue operations:

```bash
# Add claims to processing queue
redis-cli LPUSH claims:pending "CLM:AUTO:2024:10001"
redis-cli LPUSH claims:pending "CLM:HOME:2024:10002"

# Process claim (blocking operation)
redis-cli BRPOP claims:pending 5

# Move to processing
redis-cli LPUSH claims:processing "CLM:AUTO:2024:10001"

# Update claim status
redis-cli HSET claim:CLM:AUTO:2024:10001 status "under_review" reviewer "agent:007"
```

### Step 3: Performance Metrics Collection

```bash
# Enable latency monitoring
redis-cli CONFIG SET latency-monitor-threshold 100

# Check latency
redis-cli --latency-history

# Monitor slow queries
redis-cli SLOWLOG GET 10

# Check client connections
redis-cli CLIENT LIST
```

---

## Part 3: Redis Insight Protocol Analysis (15 minutes)

### Step 1: Connect to Redis Insight

1. Open Redis Insight (http://localhost:8001)
2. Navigate to CLI tab
3. Enable "Raw Mode" to see RESP protocol

### Step 2: Profile Commands

In Redis Insight CLI:

```redis
# Profile a batch operation
MONITOR
MGET policy:AUTO:1001 policy:AUTO:1002 policy:AUTO:1003

# Profile a transaction
MULTI
SET claim:new:001 "pending"
INCR claims:counter
LPUSH claims:queue "claim:new:001"
EXEC
```

### Step 3: Analyze Command Performance

Use Redis Insight Profiler:
1. Go to "Profiler" tab
2. Start recording
3. Execute business operations:

```redis
# Simulate business load
./scripts/simulate-business-load.sh
```

4. Stop recording and analyze:
   - Command frequency
   - Response times
   - Data transfer sizes
   - Protocol overhead

---

## Challenge Exercises

### Challenge 1: Protocol Optimization

Optimize this inefficient code pattern:

```bash
# Inefficient pattern
for i in {1..100}; do
  redis-cli GET customer:$i:name
  redis-cli GET customer:$i:email
  redis-cli GET customer:$i:phone
done

# Your optimized solution:
# Hint: Use MGET or pipeline
```

### Challenge 2: Debug Protocol Issue

Given this error in monitoring:
```
-ERR wrong number of arguments for 'hmset' command
```

Debug and fix the command:
```bash
redis-cli HMSET user:1001 name
```

### Challenge 3: Monitor Transaction

Create a transaction that:
1. Checks if a policy exists
2. Updates premium amount
3. Logs the change
4. Returns confirmation

Monitor the entire transaction in RESP protocol.

---

## 📊 Lab Summary

### Key Commands Used:
- `MONITOR` - Real-time protocol observation
- `PING/PONG` - Connection testing
- `CLIENT LIST` - Connection analysis
- `SLOWLOG` - Performance debugging
- `--latency-history` - Latency monitoring

### Protocol Patterns Observed:
- Simple vs batch operations
- Blocking vs non-blocking commands
- Transaction protocols
- Error handling patterns
- Performance characteristics

---

## 🎯 Learning Validation

You should now be able to:
- [ ] Identify all 5 RESP data types in monitor output
- [ ] Send raw RESP commands using netcat
- [ ] Analyze protocol efficiency for business operations
- [ ] Use monitoring tools for debugging
- [ ] Optimize command patterns based on protocol analysis

---

## Next Lab

**Lab 3: Business Data Operations with Strings**
- Apply protocol knowledge to string operations
- Implement atomic business operations
- Optimize data patterns for production use
