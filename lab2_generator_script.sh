#!/bin/bash

# Lab 2 Content Generator Script
# Generates complete content and code for Lab 2: RESP Protocol for Business Data Processing
# Duration: 45 minutes
# Focus: RESP protocol analysis, monitoring, and debugging (NO JAVASCRIPT)

set -e

LAB_DIR="lab2-resp-protocol"
LAB_NUMBER="2"
LAB_TITLE="RESP Protocol for Business Data Processing"
LAB_DURATION="45"

echo "🚀 Generating Lab ${LAB_NUMBER}: ${LAB_TITLE}"
echo "📅 Duration: ${LAB_DURATION} minutes"
echo "🎯 Focus: RESP protocol monitoring, analysis, and debugging"
echo ""

# Create lab directory structure
mkdir -p ${LAB_DIR}
cd ${LAB_DIR}

echo "📁 Creating lab directory structure..."
mkdir -p {scripts,docs,examples,protocol-samples}

# Create main lab instructions markdown file
echo "📋 Creating lab2.md..."
cat > lab2.md << 'EOF'
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

## Part 1: RESP Protocol Fundamentals (15 minutes)

### Step 1: Understanding RESP Data Types

RESP (Redis Serialization Protocol) uses 5 data types for communication:

```
+ Simple Strings  → +OK\r\n
- Errors          → -ERR unknown command\r\n  
: Integers        → :42\r\n
$ Bulk Strings    → $5\r\nhello\r\n
* Arrays          → *2\r\n$3\r\nfoo\r\n$3\r\nbar\r\n
```

Let's observe these in practice:

```bash
# Start Redis if not running
docker run -d --name redis-lab -p 6379:6379 redis:7-alpine

# Open monitoring terminal
redis-cli monitor
```

**Keep this monitor terminal open** - we'll observe RESP communication throughout the lab.

### Step 2: Basic RESP Protocol Observation

In a **new terminal**, execute these commands while watching the monitor:

```redis
# Connect to Redis CLI
redis-cli

# Simple String response
PING

# Integer response  
INCR counter:test

# Bulk String response
SET policy:test "Auto Policy Details"
GET policy:test

# Error response (intentional)
UNKNOWN_COMMAND

# Array response
MGET policy:test counter:test
```

**Monitor Observations:**
- Notice the protocol format for each command and response
- Observe how different data types are encoded
- See the efficiency of the binary protocol

### Step 3: Load Business Data for Protocol Analysis

```bash
# Load sample data using the script from Lab 1
./scripts/load-sample-data.sh

# Or manually load key data:
redis-cli << 'EOF'
SET policy:POL001 "Auto Policy - Toyota Camry - Premium: $1200"
SET policy:POL002 "Home Policy - 123 Main St - Premium: $800"
SET customer:CUST001 "John Smith - DOB:1985-03-15"
SET customer:CUST002 "Jane Doe - DOB:1990-07-22"
SET claim:CLM001 "Auto Accident - Amount: $2500 - Status: Processing"
SADD active:policies POL001 POL002
LPUSH claims:queue "CLM001:urgent" "CLM002:standard"
EOF
```

---

## Part 2: Business Transaction Protocol Analysis (20 minutes)

### Step 1: Policy Management Transaction Patterns

Monitor RESP traffic for typical business operations:

```redis
# Policy lookup transaction (customer portal scenario)
GET policy:POL001
EXISTS policy:POL001
STRLEN policy:POL001

# Batch policy retrieval (dashboard loading)
MGET policy:POL001 policy:POL002

# Policy update transaction
SET policy:POL001:last_accessed "2024-08-18T10:30:00Z"
EXPIRE policy:POL001:last_accessed 3600
```

**Protocol Analysis:**
- Count the number of round trips for each operation
- Observe payload sizes for different operations
- Note the efficiency of batch vs individual operations

### Step 2: Customer Session and Activity Monitoring

```redis
# Customer login simulation
INCR customer:CUST001:login_count
SET customer:CUST001:last_login "2024-08-18T10:30:00Z"
EXPIRE customer:CUST001:session:12345 1800

# Activity tracking
LPUSH customer:CUST001:activity "login:2024-08-18T10:30:00Z"
LPUSH customer:CUST001:activity "policy_view:POL001"
LLEN customer:CUST001:activity

# Session validation
EXISTS customer:CUST001:session:12345
TTL customer:CUST001:session:12345
```

**Monitor Key Observations:**
- Protocol overhead for session management
- Efficiency of counter operations vs string operations  
- TTL command protocol structure

### Step 3: Claims Processing Workflow Analysis

```redis
# Claims queue processing simulation
LPUSH claims:processing "CLM003:water_damage:$5000"
BLPOP claims:processing 5

# Priority claims handling
LPUSH claims:urgent "CLM004:fire_damage:$25000"
LPUSH claims:standard "CLM005:minor_accident:$800"

# Claims status updates
HSET claim:CLM003 status "under_review" adjuster "ADJ001" updated "2024-08-18T10:35:00Z"
HGETALL claim:CLM003

# Claims metrics
INCR metrics:claims:processed:today
INCRBY metrics:claims:amount:today 5000
```

**Protocol Efficiency Analysis:**
- Compare LPUSH vs BLPOP protocol patterns
- Analyze hash operations vs string operations
- Observe blocking command behavior in RESP

### Step 4: Advanced Protocol Patterns

```redis
# Transaction-like operations
MULTI
SET policy:POL003:status "suspended" 
INCR metrics:policies:suspended
EXPIRE policy:POL003:status 86400
EXEC

# Conditional operations
SET policy:POL001:lock "processing" NX EX 300
GET policy:POL001:lock

# Pipeline simulation (rapid commands)
SET temp:1 "value1"
SET temp:2 "value2" 
SET temp:3 "value3"
MGET temp:1 temp:2 temp:3
DEL temp:1 temp:2 temp:3
```

**Advanced Protocol Observations:**
- MULTI/EXEC transaction protocol structure
- Conditional SET command variations
- Protocol efficiency of pipelined commands

---

## Part 3: Protocol Debugging and Performance Analysis (10 minutes)

### Step 1: Protocol Debugging with Raw Connections

Let's examine raw RESP communication:

```bash
# Use netcat to see raw protocol (in a new terminal)
echo -e "*1\r\n\$4\r\nPING\r\n" | nc localhost 6379

# More complex command - GET policy:POL001
echo -e "*2\r\n\$3\r\nGET\r\n\$11\r\npolicy:POL001\r\n" | nc localhost 6379

# SET command with expiration
echo -e "*4\r\n\$3\r\nSET\r\n\$9\r\ntest:resp\r\n\$5\r\nvalue\r\n\$2\r\nEX\r\n\$3\r\n300\r\n" | nc localhost 6379
```

**Raw Protocol Understanding:**
- See exactly what's transmitted over the wire
- Understand command encoding complexity
- Appreciate CLI abstraction benefits

### Step 2: Performance Monitoring with Redis CLI

```bash
# Enable latency monitoring
redis-cli CONFIG SET latency-monitor-threshold 100

# Generate some load
redis-cli --latency-history -i 1

# In another terminal, generate test load:
redis-cli eval "
for i=1,1000 do
  redis.call('SET', 'perf:test:' .. i, 'value' .. i)
  redis.call('GET', 'perf:test:' .. i)
end
return 'OK'
" 0

# Check latency stats
redis-cli LATENCY LATEST
redis-cli LATENCY HISTORY command
```

### Step 3: Protocol Analysis with Redis Insight

1. **Open Redis Insight Workbench**
2. **Navigate to Profiler section** (if available)
3. **Execute monitored commands:**

```redis
# Execute these in Redis Insight Workbench while monitoring
MSET customer:CUST003:name "Alice Brown" customer:CUST003:email "alice@email.com" customer:CUST003:phone "555-0789"

HMSET policy:POL003 type "home" premium 950 customer "CUST003" status "active"

ZADD agent:performance 95.5 "AG001" 87.2 "AG002" 92.8 "AG003"
ZRANGE agent:performance 0 -1 WITHSCORES
```

4. **Analyze command performance** in Redis Insight metrics
5. **Review memory usage** impact of different data structures

---

## 🏆 Challenge Exercises (Optional - if time permits)

### Challenge 1: Protocol Efficiency Comparison

Compare protocol overhead for equivalent operations:

```redis
# Method 1: Individual operations
SET policy:POL004:name "Life Policy"
SET policy:POL004:premium "500"
SET policy:POL004:customer "CUST004"

# Method 2: Hash-based storage  
HMSET policy:POL005 name "Life Policy" premium "500" customer "CUST004"

# Method 3: JSON-like string
SET policy:POL006 '{"name":"Life Policy","premium":"500","customer":"CUST004"}'
```

**Analyze:** Which method has the least protocol overhead?

### Challenge 2: Blocking vs Non-Blocking Protocol Patterns

```bash
# Terminal 1: Set up blocking operation
redis-cli BLPOP notifications:urgent 30

# Terminal 2: Monitor the protocol
redis-cli monitor

# Terminal 3: Trigger the blocking operation
redis-cli LPUSH notifications:urgent "Priority claim CLM006 requires immediate attention"
```

**Observe:** How blocking commands behave differently in RESP.

### Challenge 3: Error Handling in RESP

```redis
# Generate various error types and observe protocol
INCR non:numeric:value
GET non:existent:key
LINDEX empty:list 0
HGET non:existent:hash field

# Type mismatches
LPUSH policy:POL001 "new_item"  # POL001 is a string, not a list
INCR policy:POL001              # POL001 is not numeric
```

**Analyze:** Different error response patterns in RESP.

---

## 📚 Key Takeaways

✅ **RESP Protocol Mastery**: Understand the 5 RESP data types and their wire format  
✅ **Real-time Monitoring**: Use redis-cli monitor for debugging business transactions  
✅ **Protocol Efficiency**: Recognize efficient vs inefficient command patterns  
✅ **Performance Analysis**: Identify bottlenecks through protocol observation  
✅ **Production Debugging**: Use protocol analysis for troubleshooting  
✅ **Command Optimization**: Choose optimal Redis commands for business workflows

## 🔗 Next Steps

In **Lab 3: Business Data Operations with Strings**, you'll apply this protocol knowledge to:
- Optimize string operations for policy and customer data
- Implement atomic operations for financial calculations
- Build efficient batch processing for business workflows
- Apply protocol knowledge to improve application performance

---

## 📖 Additional Resources

- [RESP Protocol Specification](https://redis.io/docs/reference/protocol-spec/)
- [Redis Protocol Debugging Guide](https://redis.io/docs/reference/clients/#client-timeouts)
- [Performance Monitoring Best Practices](https://redis.io/docs/management/optimization/)
- [Redis Latency Monitoring](https://redis.io/docs/management/optimization/latency/)

## 🔧 Troubleshooting

**Monitor Not Working:**
```bash
# Check Redis connection
redis-cli ping

# Restart monitor
redis-cli monitor

# Check Redis logs
docker logs redis-lab
```

**Raw Protocol Issues:**
```bash
# Verify netcat is available
which nc

# Test basic connection
telnet localhost 6379
ping
quit
```

**Performance Issues:**
```bash
# Check Redis info
redis-cli INFO stats

# Monitor slow queries
redis-cli CONFIG SET slowlog-log-slower-than 1000
redis-cli SLOWLOG GET 10
```
EOF

# Create sample data loading script (reuse from Lab 1)
echo "📊 Creating scripts/load-sample-data.sh..."
cat > scripts/load-sample-data.sh << 'EOF'
#!/bin/bash

# Business Sample Data Loader for RESP Protocol Analysis
# Optimized for protocol observation exercises

echo "📡 Loading Business Sample Data for RESP Protocol Analysis..."

redis-cli << 'REDIS_EOF'
# Clear existing data
FLUSHALL

# === BASIC POLICIES ===
SET policy:POL001 "Auto Policy - Toyota Camry 2020 - Customer: CUST001 - Premium: $1,200/year"
SET policy:POL002 "Home Policy - 123 Main St - Customer: CUST002 - Premium: $800/year"  
SET policy:POL003 "Life Policy - Term 20Y 500K - Customer: CUST003 - Premium: $420/year"

# === CUSTOMERS ===
SET customer:CUST001 "John Smith - DOB: 1985-03-15 - Phone: 555-0123"
SET customer:CUST002 "Jane Doe - DOB: 1990-07-22 - Phone: 555-0456"
SET customer:CUST003 "Bob Johnson - DOB: 1978-11-08 - Phone: 555-0789"

# === CLAIMS ===
SET claim:CLM001 "Auto Accident - Policy: POL001 - Amount: $2,500 - Status: Processing"
SET claim:CLM002 "Water Damage - Policy: POL002 - Amount: $8,200 - Status: Approved"

# === COMPLEX DATA STRUCTURES FOR PROTOCOL TESTING ===
# Sets for policy groups
SADD active:policies POL001 POL002 POL003
SADD auto:policies POL001
SADD home:policies POL002

# Lists for processing queues
LPUSH claims:processing "CLM001:urgent" "CLM002:standard"
LPUSH notifications:queue "Policy POL003 requires review"

# Hashes for detailed records
HMSET policy:POL001:details type "auto" make "Toyota" model "Camry" year "2020"
HMSET customer:CUST001:profile age "39" credit_score "750" region "North"

# Sorted sets for rankings
ZADD agent:performance 95.5 "AG001" 87.2 "AG002" 92.8 "AG003"
ZADD premium:amounts 1200 "POL001" 800 "POL002" 420 "POL003"

# === COUNTERS FOR PROTOCOL ANALYSIS ===
SET counter:daily_policies 15
SET counter:daily_claims 8
SET counter:active_sessions 42

# === TTL EXAMPLES ===
SETEX temp:quote:Q001 300 "Auto Quote - Honda Civic - $950/year"
SETEX session:user123 1800 "active_session_data"

REDIS_EOF

echo "✅ Sample data loaded successfully for RESP protocol analysis!"
echo ""
echo "📊 Data Summary:"
redis-cli << 'REDIS_EOF'
ECHO "=== STRING KEYS ==="
KEYS policy:*
ECHO ""
ECHO "=== SET KEYS ==="  
KEYS *:policies
ECHO ""
ECHO "=== LIST KEYS ==="
KEYS *:queue *:processing
ECHO ""
ECHO "=== HASH KEYS ==="
KEYS *:details *:profile
ECHO ""
ECHO "=== SORTED SET KEYS ==="
KEYS *:performance *:amounts
ECHO ""
ECHO "=== COUNTER KEYS ==="
KEYS counter:*
ECHO ""
ECHO "Database Size:"
DBSIZE
REDIS_EOF

echo ""
echo "🎯 Ready for RESP protocol analysis exercises!"
EOF

chmod +x scripts/load-sample-data.sh

# Create RESP protocol reference
echo "📚 Creating docs/resp-protocol-reference.md..."
cat > docs/resp-protocol-reference.md << 'EOF'
# RESP Protocol Reference Guide

## RESP Data Types

### 1. Simple Strings (+)
**Format:** `+<string>\r\n`
**Example:** `+OK\r\n`
**Use:** Status responses, short messages

### 2. Errors (-)
**Format:** `-<error>\r\n`
**Example:** `-ERR unknown command\r\n`
**Use:** Error messages and exceptions

### 3. Integers (:)
**Format:** `:<integer>\r\n`
**Example:** `:42\r\n`
**Use:** Numeric responses, counts, boolean values

### 4. Bulk Strings ($)
**Format:** `$<length>\r\n<string>\r\n`
**Example:** `$5\r\nhello\r\n`
**Special:** `$-1\r\n` for NULL values
**Use:** String values, binary data

### 5. Arrays (*)
**Format:** `*<count>\r\n<element1><element2>...<elementN>`
**Example:** `*2\r\n$3\r\nfoo\r\n$3\r\nbar\r\n`
**Special:** `*-1\r\n` for NULL arrays
**Use:** Multiple values, command arguments

## Command Encoding Examples

### SET Command
```
Command: SET mykey myvalue
Encoding: *3\r\n$3\r\nSET\r\n$5\r\nmykey\r\n$7\r\nmyvalue\r\n
```

### GET Command  
```
Command: GET mykey
Encoding: *2\r\n$3\r\nGET\r\n$5\r\nmykey\r\n
```

### MGET Command
```
Command: MGET key1 key2 key3
Encoding: *4\r\n$4\r\nMGET\r\n$4\r\nkey1\r\n$4\r\nkey2\r\n$4\r\nkey3\r\n
```

## Response Examples

### String Response
```
Response: $13\r\nHello, World!\r\n
Decoded: "Hello, World!"
```

### Integer Response
```
Response: :42\r\n
Decoded: 42
```

### Array Response
```
Response: *3\r\n$3\r\nfoo\r\n$3\r\nbar\r\n$3\r\nbaz\r\n
Decoded: ["foo", "bar", "baz"]
```

### Error Response
```
Response: -ERR wrong number of arguments for 'set' command\r\n
Decoded: Error: "ERR wrong number of arguments for 'set' command"
```

## Protocol Efficiency Tips

1. **Use Bulk Operations**: MGET/MSET reduce round trips
2. **Pipeline Commands**: Send multiple commands without waiting
3. **Choose Appropriate Data Types**: Hash vs String vs JSON
4. **Monitor Command Latency**: Use `redis-cli --latency`
5. **Avoid KEYS in Production**: Use SCAN instead

## Debugging Commands

```bash
# Monitor all commands
redis-cli monitor

# Latency monitoring
redis-cli --latency
redis-cli --latency-history

# Slow query log
redis-cli SLOWLOG GET 10

# Client connections
redis-cli CLIENT LIST

# Protocol statistics
redis-cli INFO stats
```

## Common Protocol Patterns

### Session Management
```
SET session:12345 "user_data" EX 3600
GET session:12345
DEL session:12345
```

### Counter Operations
```
INCR page:views:today
INCRBY revenue:daily 1500
DECR active:users
```

### Queue Operations
```
LPUSH task:queue "process_payment"
BRPOP task:queue 5
LLEN task:queue
```

### Hash Operations
```
HMSET user:1001 name "John" email "john@example.com" age 25
HGETALL user:1001
HGET user:1001 email
```
EOF

# Create protocol analysis examples
echo "📋 Creating examples/protocol-analysis-examples.md..."
cat > examples/protocol-analysis-examples.md << 'EOF'
# RESP Protocol Analysis Examples

## Business Transaction Patterns

### Customer Login Flow
```redis
# 1. Validate user credentials (simplified)
GET customer:CUST001:password_hash

# 2. Create session
SET session:abc123 "CUST001" EX 1800

# 3. Update login metrics
INCR customer:CUST001:login_count
SET customer:CUST001:last_login "2024-08-18T10:30:00Z"

# 4. Track activity
LPUSH customer:CUST001:activity "login:2024-08-18T10:30:00Z"
```

**Protocol Analysis:**
- 6 commands = 6 round trips
- Could be optimized with pipelining
- Session creation is most critical operation

### Policy Quote Generation
```redis
# 1. Check customer eligibility
GET customer:CUST001:credit_score
EXISTS customer:CUST001:active_policies

# 2. Calculate base premium
GET rates:auto:base_premium
GET rates:auto:age_factor:39

# 3. Generate quote with expiration
SETEX quote:Q001 600 "Auto Quote - Honda Civic - Premium: $950 - Customer: CUST001"

# 4. Log quote generation
INCR metrics:quotes:generated:today
LPUSH audit:quotes "Q001:generated:CUST001:2024-08-18T10:35:00Z"
```

**Protocol Efficiency:**
- Multiple GET operations could use MGET
- Consider using hash for quote data structure
- Audit logging adds overhead but necessary for compliance

### Claims Processing Workflow
```redis
# 1. Submit new claim
LPUSH claims:pending "CLM003:auto:$3200:CUST001:POL001"

# 2. Assign to adjuster
HMSET claim:CLM003 adjuster "ADJ001" status "assigned" amount "3200"

# 3. Update policy metrics  
INCR policy:POL001:claims_count
INCRBY policy:POL001:claims_amount 3200

# 4. Notify stakeholders
LPUSH notifications:adjuster:ADJ001 "New claim CLM003 assigned"
LPUSH notifications:customer:CUST001 "Claim CLM003 received and assigned"
```

**Workflow Analysis:**
- Clear separation of concerns
- Good use of different data structures
- Notification system adds complexity but improves user experience

## Performance Comparison Examples

### Individual vs Batch Operations

**Individual Operations:**
```redis
GET policy:POL001
GET policy:POL002  
GET policy:POL003
```
**Protocol:** 3 commands, 3 round trips

**Batch Operation:**
```redis
MGET policy:POL001 policy:POL002 policy:POL003
```
**Protocol:** 1 command, 1 round trip

### String vs Hash Storage

**String Storage:**
```redis
SET policy:POL001:type "auto"
SET policy:POL001:premium "1200"
SET policy:POL001:customer "CUST001"
```
**Protocol:** 3 SET commands, more memory overhead

**Hash Storage:**
```redis
HMSET policy:POL001 type "auto" premium "1200" customer "CUST001"
```
**Protocol:** 1 HMSET command, better memory efficiency

### Blocking vs Polling Patterns

**Polling Pattern:**
```redis
# Client repeatedly checks for new items
LLEN task:queue
LPOP task:queue
# ... wait 1 second ...
LLEN task:queue  
LPOP task:queue
```
**Protocol:** Continuous polling creates unnecessary traffic

**Blocking Pattern:**
```redis
# Client blocks until item available
BLPOP task:queue 30
```
**Protocol:** Single command blocks until data available, more efficient

## Monitoring Commands for Analysis

### Real-time Monitoring
```bash
# Monitor all commands
redis-cli monitor | grep -E "(GET|SET|INCR|LPUSH|HMSET)"

# Monitor specific patterns
redis-cli monitor | grep "policy:"

# Monitor with timestamps
redis-cli monitor | while read line; do echo "$(date): $line"; done
```

### Performance Analysis
```bash
# Command latency
redis-cli --latency-history -i 1

# Slow operations
redis-cli CONFIG SET slowlog-log-slower-than 1000
redis-cli SLOWLOG GET 10

# Memory usage by key pattern
redis-cli --bigkeys

# Client connection analysis
redis-cli CLIENT LIST
```

### Protocol Statistics
```bash
# Total commands processed
redis-cli INFO stats | grep total_commands_processed

# Keyspace hits/misses ratio
redis-cli INFO stats | grep keyspace

# Network I/O
redis-cli INFO stats | grep -E "(total_net_input_bytes|total_net_output_bytes)"
```

## Optimization Patterns

### 1. Pipeline Operations
```bash
# Instead of individual commands
redis-cli SET key1 value1
redis-cli SET key2 value2
redis-cli SET key3 value3

# Use pipeline
(echo "SET key1 value1"; echo "SET key2 value2"; echo "SET key3 value3") | redis-cli --pipe
```

### 2. Batch Key Operations
```redis
# Instead of multiple EXISTS
EXISTS policy:POL001
EXISTS policy:POL002
EXISTS policy:POL003

# Use single command with multiple arguments
EXISTS policy:POL001 policy:POL002 policy:POL003
```

### 3. Atomic Operations
```redis
# Instead of separate operations
GET counter:value
# ... calculate new value ...
SET counter:value 42

# Use atomic operation
INCR counter:value
INCRBY counter:value 10
```

### 4. Efficient Data Structures
```redis
# For small amounts of structured data, consider hashes
HMSET user:1001 name "John" email "john@example.com" age 25

# For large text data, consider compression at application level
SET document:large:001 "compressed_data_here"

# For time-series data, consider sorted sets
ZADD metrics:daily 20240818 "policy_count:150"
```
EOF

# Create troubleshooting guide
echo "🔧 Creating docs/troubleshooting.md..."
cat > docs/troubleshooting.md << 'EOF'
# Lab 2 Troubleshooting Guide

## Common Issues and Solutions

### 1. Monitor Command Not Showing Output

**Problem:** `redis-cli monitor` shows no output

**Solutions:**
```bash
# Check Redis connection
redis-cli ping

# Verify Redis is receiving commands
redis-cli info clients

# Start monitor in separate terminal
redis-cli monitor

# Generate test traffic in another terminal
redis-cli SET test:monitor "working"
redis-cli GET test:monitor
```

### 2. RESP Protocol Raw Commands Failing

**Problem:** Raw protocol commands with netcat not working

**Solutions:**
```bash
# Verify netcat is installed
which nc
# If not available, try: apt install netcat (Ubuntu) or brew install netcat (Mac)

# Test basic connection
telnet localhost 6379
PING
QUIT

# Ensure proper RESP formatting (must include \r\n)
echo -e "*1\r\n\$4\r\nPING\r\n" | nc localhost 6379

# Debug connection issues
redis-cli CONFIG GET bind
redis-cli CONFIG GET port
```

### 3. Performance Monitoring Issues

**Problem:** Latency monitoring not working or showing unexpected results

**Solutions:**
```bash
# Enable latency monitoring
redis-cli CONFIG SET latency-monitor-threshold 100

# Check current configuration
redis-cli CONFIG GET "latency-monitor-threshold"

# Reset latency history
redis-cli LATENCY RESET

# Monitor with different intervals
redis-cli --latency-history -i 5

# Check for slow queries
redis-cli SLOWLOG LEN
redis-cli SLOWLOG GET 10
```

### 4. Data Loading Script Issues

**Problem:** Sample data not loading properly

**Solutions:**
```bash
# Make script executable
chmod +x scripts/load-sample-data.sh

# Run with verbose output
bash -x scripts/load-sample-data.sh

# Manual verification
redis-cli KEYS "*"
redis-cli DBSIZE

# Clear and reload if needed
redis-cli FLUSHALL
./scripts/load-sample-data.sh
```

### 5. Redis Insight Connection Problems

**Problem:** Redis Insight not connecting or showing data

**Solutions:**
1. **Verify Redis Insight connection settings:**
   - Host: localhost or 127.0.0.1
   - Port: 6379
   - No authentication required for lab setup

2. **Check Redis binding:**
   ```bash
   redis-cli CONFIG GET bind
   # Should show 127.0.0.1 or 0.0.0.0
   ```

3. **Restart Redis Insight application**

4. **Check firewall settings** (Windows/Mac)

### 6. Protocol Analysis Issues

**Problem:** Unable to see clear protocol patterns

**Solutions:**
```bash
# Use more specific monitoring
redis-cli monitor | grep -E "(SET|GET|MGET|HMSET)"

# Add timing to monitor output
redis-cli monitor | while read line; do echo "$(date '+%H:%M:%S'): $line"; done

# Monitor specific key patterns
redis-cli monitor | grep "policy:"

# Check for pipelining effects
redis-cli --latency -i 1
```

## Performance Debugging Commands

### Command Timing Analysis
```bash
# Measure specific command performance
time redis-cli GET policy:POL001

# Bulk timing test
time redis-cli eval "
for i=1,100 do
  redis.call('GET', 'policy:POL00' .. (i % 3 + 1))
end
return 'OK'
" 0
```

### Memory Analysis
```bash
# Check memory usage by key type
redis-cli --bigkeys

# Detailed memory info
redis-cli INFO memory

# Memory usage of specific key
redis-cli MEMORY USAGE policy:POL001
```

### Connection Analysis
```bash
# List all connected clients
redis-cli CLIENT LIST

# Monitor client connections
watch "redis-cli CLIENT LIST | wc -l"

# Check for blocked clients
redis-cli CLIENT LIST | grep -i "blpop\|brpop"
```

### Network Analysis
```bash
# Check network statistics
redis-cli INFO stats | grep -E "net_input\|net_output"

# Monitor network I/O
watch "redis-cli INFO stats | grep -E 'total_net_input_bytes\|total_net_output_bytes'"
```

## Protocol-Specific Debugging

### RESP Format Validation
```bash
# Validate RESP format manually
echo -e "*2\r\n\$3\r\nGET\r\n\$11\r\npolicy:POL001\r\n" | xxd
echo -e "*2\r\n\$3\r\nGET\r\n\$11\r\npolicy:POL001\r\n" | nc localhost 6379 | xxd
```

### Command Parsing Issues
```bash
# Check for command parsing errors
redis-cli CONFIG GET "log-level"
redis-cli CONFIG SET "log-level" "debug"

# View Redis logs
docker logs redis-lab

# Reset log level
redis-cli CONFIG SET "log-level" "notice"
```

### Blocking Command Testing
```bash
# Test blocking behavior
# Terminal 1:
timeout 10 redis-cli BLPOP test:blocking:list 5

# Terminal 2:
redis-cli LPUSH test:blocking:list "test_item"

# Verify blocking worked correctly
echo $?  # Should be 0 if successful
```

## Getting Help

If you encounter issues not covered here:

1. **Check Redis logs:** `docker logs redis-lab`
2. **Verify Redis configuration:** `redis-cli CONFIG GET "*"`
3. **Test basic connectivity:** `redis-cli ping`
4. **Check Docker status:** `docker ps | grep redis`
5. **Review network connectivity:** `netstat -an | grep 6379`
6. **Ask instructor** for assistance

## Useful Debugging Commands

```bash
# Complete Redis status check
redis-cli INFO server
redis-cli INFO clients  
redis-cli INFO memory
redis-cli INFO stats

# Protocol monitoring with filtering
redis-cli monitor | tee protocol.log

# Performance baseline
redis-cli --latency-history -i 1 | head -20

# Memory usage check
redis-cli INFO memory | grep used_memory_human
```
EOF

# Create README
echo "📚 Creating README.md..."
cat > README.md << 'EOF'
# Lab 2: RESP Protocol for Business Data Processing

**Duration:** 45 minutes  
**Focus:** RESP protocol monitoring, analysis, and debugging  
**Industry:** Policy management and claims processing workflows

## 📁 Project Structure

```
lab2-resp-protocol/
├── lab2.md                           # Complete lab instructions (START HERE)
├── scripts/
│   └── load-sample-data.sh           # Business data loader for protocol analysis
├── docs/
│   ├── resp-protocol-reference.md    # Complete RESP protocol reference
│   └── troubleshooting.md            # Protocol debugging guide
├── examples/
│   └── protocol-analysis-examples.md # Business workflow analysis examples
├── protocol-samples/                 # Raw protocol examples
└── README.md                         # This file
```

## 🚀 Quick Start

1. **Read Instructions:** Open `lab2.md` for complete lab guidance
2. **Start Redis:** `docker run -d --name redis-lab -p 6379:6379 redis:7-alpine`
3. **Load Sample Data:** `./scripts/load-sample-data.sh`
4. **Start Monitoring:** `redis-cli monitor`
5. **Follow Lab Exercises:** Execute commands while observing protocol

## 🎯 Lab Objectives

✅ Master RESP protocol structure and data types  
✅ Monitor real-time Redis communications for business transactions  
✅ Analyze protocol efficiency for high-volume operations  
✅ Debug communication issues at the protocol level  
✅ Use monitoring tools for production troubleshooting  
✅ Optimize command patterns for better performance

## 📡 Protocol Focus Areas

### **RESP Data Types Covered:**
- **Simple Strings (+)**: Status responses
- **Errors (-)**: Error handling patterns  
- **Integers (:)**: Counter operations
- **Bulk Strings ($)**: Policy and customer data
- **Arrays (*)**: Batch operations and multi-value responses

### **Business Scenarios Analyzed:**
- **Policy Management**: Lookup, update, and batch operations
- **Customer Sessions**: Login, activity tracking, session management
- **Claims Processing**: Queue operations, status updates, workflow monitoring
- **Performance Patterns**: Blocking vs polling, individual vs batch operations

## 🔧 Key Commands for Protocol Analysis

```bash
# Real-time Protocol Monitoring
redis-cli monitor

# Raw Protocol Analysis
echo -e "*1\r\n\$4\r\nPING\r\n" | nc localhost 6379

# Performance Monitoring
redis-cli --latency-history -i 1

# Slow Query Analysis
redis-cli SLOWLOG GET 10

# Client Analysis
redis-cli CLIENT LIST
```

## 📊 Sample Data for Protocol Testing

The lab includes diverse data structures optimized for protocol observation:

- **String Keys**: Policies, customers, claims
- **Hash Keys**: Detailed records with multiple fields
- **List Keys**: Processing queues and activity logs
- **Set Keys**: Policy groups and categories
- **Sorted Set Keys**: Performance rankings and metrics
- **Counters**: Business metrics and session tracking

## 🆘 Troubleshooting

**Monitor Not Working:**
```bash
# Check Redis connection
redis-cli ping

# Restart monitor
redis-cli monitor

# Generate test traffic
redis-cli SET test:monitor "working"
```

**Raw Protocol Issues:**
```bash
# Test netcat availability
which nc

# Verify connection
telnet localhost 6379
```

**Performance Monitoring:**
```bash
# Enable latency monitoring
redis-cli CONFIG SET latency-monitor-threshold 100

# Check slow queries
redis-cli SLOWLOG GET 10
```

**Detailed troubleshooting:** See `docs/troubleshooting.md`

## 📚 Learning Resources

- **Protocol Reference:** `docs/resp-protocol-reference.md`
- **Business Examples:** `examples/protocol-analysis-examples.md`
- **Troubleshooting:** `docs/troubleshooting.md`
- **Raw Protocol Samples:** `protocol-samples/`

## 🎓 Learning Path

This lab is part of the Redis mastery series:

1. **Lab 1:** Environment & CLI Basics
2. **Lab 2:** RESP Protocol Analysis ← *You are here*
3. **Lab 3:** Business Data Operations with Strings
4. **Lab 4:** Key Management & TTL Strategies
5. **Lab 5:** Advanced CLI Operations & Monitoring

---

**Ready to start?** Open `lab2.md` and begin exploring Redis protocol communication! 🚀
EOF

# Create .gitignore
cat > .gitignore << 'EOF'
# Logs and monitoring output
*.log
protocol.log
monitor.log
latency.log

# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Backup files
*.bak
*.backup

# Temporary files
*.tmp
*.temp

# Docker volumes
/data/

# IDE files
.vscode/
.idea/
*.swp
*.swo

# Environment files
.env
.env.local
EOF

echo ""
echo "📂 Project structure created:"
echo "   ${LAB_DIR}/"
echo "   ├── lab2.md                           📋 START HERE - Complete lab guide"
echo "   ├── scripts/"
echo "   │   └── load-sample-data.sh           📊 Business data loader for protocol analysis"
echo "   ├── docs/"
echo "   │   ├── resp-protocol-reference.md    📚 Complete RESP protocol reference"
echo "   │   └── troubleshooting.md            🔧 Protocol debugging guide"
echo "   ├── examples/"
echo "   │   └── protocol-analysis-examples.md 📋 Business workflow analysis examples"
echo "   ├── protocol-samples/                 📁 Raw protocol examples directory"
echo "   ├── README.md                         📖 Project documentation"
echo "   └── .gitignore                        🚫 Git ignore rules"
echo ""
echo "🎯 NEXT STEPS:"
echo "   1. cd ${LAB_DIR}"
echo "   2. code .                              # Open in VS Code"
echo "   3. Read lab2.md                       # Follow complete lab guide"
echo "   4. docker run -d --name redis-lab -p 6379:6379 redis:7-alpine"
echo "   5. ./scripts/load-sample-data.sh"
echo "   6. redis-cli monitor                  # Start protocol monitoring"
echo ""
echo "📡 PROTOCOL ANALYSIS FOCUS:"
echo "   🔍 RESP Data Types: +, -, :, $, *"
echo "   📊 Business Transactions: Policy lookups, claims processing"
echo "   ⚡ Performance Patterns: Batch vs individual operations"
echo "   🐛 Debugging: Raw protocol analysis and monitoring"
echo "   📈 Optimization: Command efficiency and latency analysis"
echo ""
echo "🔗 MONITORING SETUP:"
echo "   📺 Terminal 1: redis-cli monitor      # Real-time protocol observation"
echo "   ⌨️  Terminal 2: redis-cli              # Command execution"
echo "   📊 Terminal 3: Redis Insight          # GUI analysis and profiling"
echo ""
echo "🎉 READY TO START LAB 2!"
echo "   Open lab2.md for the complete 45-minute RESP protocol deep dive!"