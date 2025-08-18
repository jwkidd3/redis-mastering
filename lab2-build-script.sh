#!/bin/bash

# Lab 2: RESP Protocol for Business Data Processing - Build Script
# Duration: 45 minutes
# Focus: RESP protocol monitoring, analysis, and debugging
# Environment: Docker, Redis CLI, Redis Insight

set -e

LAB_DIR="lab2-resp-protocol"
LAB_NUMBER="2"
LAB_TITLE="RESP Protocol for Business Data Processing"
LAB_DURATION="45"

echo "🚀 Building Lab ${LAB_NUMBER}: ${LAB_TITLE}"
echo "📅 Duration: ${LAB_DURATION} minutes"
echo "🎯 Focus: RESP protocol monitoring, analysis, and debugging"
echo ""

# Create lab directory structure
echo "📁 Creating lab directory structure..."
mkdir -p ${LAB_DIR}
cd ${LAB_DIR}
mkdir -p {scripts,docs,examples,protocol-samples,data}

# Create main lab instructions
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
EOF

# Create business data loader script
echo "📊 Creating scripts/load-business-data.sh..."
cat > scripts/load-business-data.sh << 'EOF'
#!/bin/bash

echo "📊 Loading business sample data for RESP protocol analysis..."

redis-cli << 'REDIS_COMMANDS'
# Clear existing data
FLUSHALL

# === POLICIES ===
SET policy:AUTO:1001 "Type:Auto|Premium:1200|Status:Active|Customer:C001"
SET policy:AUTO:1002 "Type:Auto|Premium:1400|Status:Active|Customer:C002"
SET policy:AUTO:1003 "Type:Auto|Premium:950|Status:Active|Customer:C003"
SET policy:HOME:2001 "Type:Home|Premium:800|Status:Active|Customer:C001"
SET policy:HOME:2002 "Type:Home|Premium:1100|Status:Pending|Customer:C004"
SET policy:LIFE:3001 "Type:Life|Premium:450|Status:Active|Customer:C002"

# === CUSTOMERS ===
HMSET customer:C001 name "John Smith" email "john@example.com" phone "555-0101" risk_score 750
HMSET customer:C002 name "Jane Doe" email "jane@example.com" phone "555-0102" risk_score 680
HMSET customer:C003 name "Bob Johnson" email "bob@example.com" phone "555-0103" risk_score 820
HMSET customer:C004 name "Alice Brown" email "alice@example.com" phone "555-0104" risk_score 700

# === CLAIMS ===
HMSET claim:CLM:AUTO:2024:001 policy "AUTO:1001" amount 2500 status "pending" date "2024-08-01"
HMSET claim:CLM:HOME:2024:001 policy "HOME:2001" amount 5000 status "approved" date "2024-08-05"
HMSET claim:CLM:AUTO:2024:002 policy "AUTO:1002" amount 1200 status "processing" date "2024-08-10"

# === QUEUES ===
LPUSH claims:pending "CLM:AUTO:2024:003"
LPUSH claims:pending "CLM:HOME:2024:002"
LPUSH notifications:queue "Policy AUTO:1003 renewal due"
LPUSH notifications:queue "Claim CLM:AUTO:2024:001 requires review"

# === COUNTERS ===
SET metrics:daily:policies_created 0
SET metrics:daily:claims_filed 0
SET metrics:daily:customers_active 0
INCR metrics:daily:policies_created
INCR metrics:daily:policies_created
INCR metrics:daily:claims_filed

# === SETS ===
SADD policies:active "AUTO:1001" "AUTO:1002" "AUTO:1003" "HOME:2001" "LIFE:3001"
SADD policies:pending "HOME:2002"
SADD customers:premium "C001" "C003"

# === SORTED SETS ===
ZADD risk:scores 750 "C001" 680 "C002" 820 "C003" 700 "C004"
ZADD premium:amounts 1200 "AUTO:1001" 1400 "AUTO:1002" 950 "AUTO:1003" 800 "HOME:2001"

# === TTL EXAMPLES ===
SETEX quote:temporary:Q001 300 "Auto Quote: $1050/year"
SETEX session:web:S12345 1800 "user:C001|ip:192.168.1.100"

INFO keyspace
REDIS_COMMANDS

echo "✅ Business data loaded successfully!"
echo ""
echo "📊 Data Summary:"
redis-cli DBSIZE
echo ""
echo "Sample keys by type:"
echo "Policies: $(redis-cli KEYS 'policy:*' | wc -l)"
echo "Customers: $(redis-cli KEYS 'customer:*' | wc -l)"
echo "Claims: $(redis-cli KEYS 'claim:*' | wc -l)"
echo "Metrics: $(redis-cli KEYS 'metrics:*' | wc -l)"
EOF

chmod +x scripts/load-business-data.sh

# Create business load simulator
echo "⚡ Creating scripts/simulate-business-load.sh..."
cat > scripts/simulate-business-load.sh << 'EOF'
#!/bin/bash

echo "⚡ Simulating business transaction load..."
echo "Press Ctrl+C to stop"
echo ""

COUNTER=0

while true; do
    COUNTER=$((COUNTER + 1))
    
    # Customer login simulation
    CUSTOMER_ID=$((RANDOM % 100 + 1))
    redis-cli SETEX session:customer:${CUSTOMER_ID} 1800 "active" > /dev/null
    
    # Policy lookup
    POLICY_ID=$((RANDOM % 10 + 1000))
    redis-cli GET policy:AUTO:${POLICY_ID} > /dev/null
    
    # Claim processing
    if [ $((COUNTER % 5)) -eq 0 ]; then
        CLAIM_ID="CLM:AUTO:2024:${COUNTER}"
        redis-cli LPUSH claims:pending "${CLAIM_ID}" > /dev/null
        redis-cli INCR metrics:daily:claims_filed > /dev/null
    fi
    
    # Risk score check
    if [ $((COUNTER % 3)) -eq 0 ]; then
        redis-cli ZRANGE risk:scores 0 2 WITHSCORES > /dev/null
    fi
    
    # Metrics update
    redis-cli INCR metrics:daily:customers_active > /dev/null
    
    # Random delay between 10-100ms
    sleep 0.0$((RANDOM % 10 + 1))
    
    if [ $((COUNTER % 10)) -eq 0 ]; then
        echo "Processed ${COUNTER} transactions..."
    fi
done
EOF

chmod +x scripts/simulate-business-load.sh

# Create RESP protocol reference
echo "📚 Creating docs/resp-reference.md..."
cat > docs/resp-reference.md << 'EOF'
# RESP Protocol Reference

## Data Types

### 1. Simple Strings (+)
- Format: `+<string>\r\n`
- Example: `+OK\r\n`
- Use: Status responses

### 2. Errors (-)
- Format: `-<error>\r\n`
- Example: `-ERR unknown command\r\n`
- Use: Error messages

### 3. Integers (:)
- Format: `:<number>\r\n`
- Example: `:42\r\n`
- Use: Numeric responses

### 4. Bulk Strings ($)
- Format: `$<length>\r\n<data>\r\n`
- Example: `$5\r\nhello\r\n`
- NULL: `$-1\r\n`
- Use: String values

### 5. Arrays (*)
- Format: `*<count>\r\n<elements>`
- Example: `*2\r\n$3\r\nfoo\r\n$3\r\nbar\r\n`
- NULL: `*-1\r\n`
- Use: Multiple values

## Common Commands in RESP

### SET Command
```
Client: *3\r\n$3\r\nSET\r\n$3\r\nkey\r\n$5\r\nvalue\r\n
Server: +OK\r\n
```

### GET Command
```
Client: *2\r\n$3\r\nGET\r\n$3\r\nkey\r\n
Server: $5\r\nvalue\r\n
```

### MGET Command
```
Client: *3\r\n$4\r\nMGET\r\n$4\r\nkey1\r\n$4\r\nkey2\r\n
Server: *2\r\n$6\r\nvalue1\r\n$6\r\nvalue2\r\n
```

### Error Response
```
Client: *1\r\n$7\r\nINVALID\r\n
Server: -ERR unknown command 'INVALID'\r\n
```

## Protocol Analysis Tips

1. **Use MONITOR carefully** - It impacts performance in production
2. **Pipeline commands** - Reduce round-trip time
3. **Batch operations** - Use MSET/MGET instead of multiple SET/GET
4. **Watch for errors** - Lines starting with `-`
5. **Measure latency** - Use `--latency` and `--latency-history`

## Performance Patterns

### Inefficient Pattern
```bash
for key in keys:
    redis.get(key)  # Multiple round trips
```

### Efficient Pattern
```bash
redis.mget(keys)  # Single round trip
```

### Transaction Pattern
```
MULTI
command1
command2
command3
EXEC
```

All commands sent together, executed atomically.
EOF

# Create troubleshooting guide
echo "🔧 Creating docs/troubleshooting.md..."
cat > docs/troubleshooting.md << 'EOF'
# Lab 2 Troubleshooting Guide

## Common Issues

### Monitor Not Showing Output

**Problem:** `redis-cli monitor` shows nothing

**Solution:**
```bash
# Check Redis is running
docker ps | grep redis

# Test connection
redis-cli ping

# Generate test traffic
redis-cli SET test "value"
```

### Netcat (nc) Not Available

**Problem:** `nc: command not found`

**Solution:**
```bash
# Mac
brew install netcat

# Ubuntu/Debian
sudo apt-get install netcat

# Alternative: Use telnet
telnet localhost 6379
```

### Raw Protocol Commands Failing

**Problem:** Raw RESP commands return errors

**Solution:**
- Ensure proper line endings (\r\n)
- Check command syntax
- Verify array count matches arguments

Example:
```bash
# Correct
echo -e "*2\r\n\$3\r\nGET\r\n\$3\r\nkey\r\n"

# Incorrect (missing \r\n)
echo -e "*2\$3\nGET\$3\nkey"
```

### High Latency in Monitoring

**Problem:** Commands show high latency

**Check:**
```bash
# Redis server info
redis-cli INFO stats

# Check slow log
redis-cli SLOWLOG GET 10

# Monitor client connections
redis-cli CLIENT LIST
```

### Redis Insight Not Connecting

**Problem:** Cannot connect to Redis from Insight

**Solution:**
1. Check Redis is bound to all interfaces:
```bash
redis-cli CONFIG GET bind
```

2. For Docker, ensure port mapping:
```bash
docker run -p 6379:6379 redis:7-alpine
```

3. Test from host:
```bash
telnet localhost 6379
```

## Performance Tips

### Reduce Protocol Overhead
- Use pipelining for bulk operations
- Prefer MSET/MGET over individual SET/GET
- Use transactions for related operations

### Monitor Efficiently
- Don't use MONITOR in production continuously
- Use SLOWLOG for performance issues
- Enable latency monitoring when needed

### Debug Protocol Issues
1. Start with simple commands (PING)
2. Use monitor to see exact protocol
3. Compare with working examples
4. Check Redis logs for errors
EOF

# Create example protocol samples
echo "📝 Creating protocol samples..."
mkdir -p protocol-samples

cat > protocol-samples/basic-commands.txt << 'EOF'
# PING Command
Request:  *1\r\n$4\r\nPING\r\n
Response: +PONG\r\n

# SET Command
Request:  *3\r\n$3\r\nSET\r\n$5\r\nmykey\r\n$7\r\nmyvalue\r\n
Response: +OK\r\n

# GET Command
Request:  *2\r\n$3\r\nGET\r\n$5\r\nmykey\r\n
Response: $7\r\nmyvalue\r\n

# GET (key not found)
Request:  *2\r\n$3\r\nGET\r\n$10\r\nnonexistent\r\n
Response: $-1\r\n

# INCR Command
Request:  *2\r\n$4\r\nINCR\r\n$7\r\ncounter\r\n
Response: :1\r\n

# MGET Command
Request:  *3\r\n$4\r\nMGET\r\n$4\r\nkey1\r\n$4\r\nkey2\r\n
Response: *2\r\n$6\r\nvalue1\r\n$6\r\nvalue2\r\n

# Error Example
Request:  *1\r\n$7\r\nINVALID\r\n
Response: -ERR unknown command 'INVALID'\r\n
EOF

cat > protocol-samples/business-examples.txt << 'EOF'
# Policy Lookup
Request:  *2\r\n$3\r\nGET\r\n$16\r\npolicy:AUTO:1001\r\n
Response: $45\r\nType:Auto|Premium:1200|Status:Active|Customer:C001\r\n

# Customer Profile Update
Request:  *4\r\n$4\r\nHSET\r\n$13\r\ncustomer:C001\r\n$5\r\nemail\r\n$17\r\njohn@newmail.com\r\n
Response: :0\r\n

# Claims Queue Push
Request:  *3\r\n$5\r\nLPUSH\r\n$14\r\nclaims:pending\r\n$19\r\nCLM:AUTO:2024:00123\r\n
Response: :1\r\n

# Batch Policy Update (MSET)
Request:  *7\r\n$4\r\nMSET\r\n$16\r\npolicy:AUTO:1001\r\n$13\r\nPremium:1250\r\n$16\r\npolicy:AUTO:1002\r\n$13\r\nPremium:1450\r\n$16\r\npolicy:AUTO:1003\r\n$13\r\nPremium:1000\r\n
Response: +OK\r\n

# Transaction Example
Request:  *1\r\n$5\r\nMULTI\r\n
Response: +OK\r\n
Request:  *2\r\n$4\r\nINCR\r\n$20\r\nclaims:daily:counter\r\n
Response: +QUEUED\r\n
Request:  *3\r\n$5\r\nLPUSH\r\n$12\r\nclaims:queue\r\n$7\r\nCLM:123\r\n
Response: +QUEUED\r\n
Request:  *1\r\n$4\r\nEXEC\r\n
Response: *2\r\n:15\r\n:8\r\n
EOF

# Create README
echo "📖 Creating README.md..."
cat > README.md << 'EOF'
# Lab 2: RESP Protocol for Business Data Processing

## Overview
This lab focuses on understanding and analyzing the Redis Serialization Protocol (RESP) for business data operations. You'll learn to monitor, debug, and optimize Redis communications.

## Quick Start

1. **Setup Environment**
```bash
# Start Redis
docker run -d --name redis-lab -p 6379:6379 redis:7-alpine

# Load sample data
./scripts/load-business-data.sh
```

2. **Start Monitoring**
```bash
# Terminal 1
redis-cli monitor

# Terminal 2 - Execute commands
redis-cli SET test "value"
```

3. **Follow Lab Instructions**
Open `lab2.md` for complete 45-minute guided exercises.

## Lab Structure

```
lab2-resp-protocol/
├── lab2.md                    # Main lab instructions
├── scripts/
│   ├── load-business-data.sh  # Sample data loader
│   └── simulate-business-load.sh # Load generator
├── docs/
│   ├── resp-reference.md      # RESP protocol guide
│   └── troubleshooting.md     # Common issues & solutions
├── protocol-samples/          # Example RESP communications
└── README.md                  # This file
```

## Learning Objectives

- Master RESP protocol structure
- Monitor real-time Redis communications
- Analyze protocol efficiency
- Debug communication issues
- Optimize command patterns

## Key Commands

- `redis-cli monitor` - Real-time protocol monitoring
- `redis-cli --latency-history` - Latency analysis
- `redis-cli SLOWLOG GET` - Slow query analysis
- `redis-cli CLIENT LIST` - Connection analysis

## Prerequisites

- Docker installed and running
- Redis CLI available
- Basic Redis command knowledge
- Completed Lab 1

## Duration

45 minutes

## Support

If you encounter issues, check `docs/troubleshooting.md` first.
EOF

# Create Docker Compose file for complete environment
echo "🐳 Creating docker-compose.yml..."
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  redis:
    image: redis:7-alpine
    container_name: redis-lab2
    ports:
      - "6379:6379"
    command: redis-server --appendonly yes --loglevel debug
    volumes:
      - redis-data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 3s
      retries: 5

  redis-insight:
    image: redislabs/redisinsight:latest
    container_name: redis-insight-lab2
    ports:
      - "8001:8001"
    volumes:
      - insight-data:/db
    depends_on:
      - redis

volumes:
  redis-data:
  insight-data:
EOF

# Create test script
echo "🧪 Creating test-lab.sh..."
cat > test-lab.sh << 'EOF'
#!/bin/bash

echo "🧪 Testing Lab 2 Environment..."
echo ""

# Check Docker
echo "Checking Docker..."
if ! docker --version > /dev/null 2>&1; then
    echo "❌ Docker not installed"
    exit 1
fi
echo "✅ Docker is available"

# Check Redis CLI
echo "Checking Redis CLI..."
if ! redis-cli --version > /dev/null 2>&1; then
    echo "❌ Redis CLI not installed"
    exit 1
fi
echo "✅ Redis CLI is available"

# Start services
echo ""
echo "Starting services..."
docker-compose up -d

# Wait for Redis
echo "Waiting for Redis to start..."
sleep 5

# Test Redis connection
echo "Testing Redis connection..."
if redis-cli ping | grep -q PONG; then
    echo "✅ Redis is responding"
else
    echo "❌ Redis not responding"
    exit 1
fi

# Load sample data
echo "Loading sample data..."
./scripts/load-business-data.sh

# Test monitoring
echo ""
echo "Testing monitoring capability..."
timeout 2 redis-cli monitor > /dev/null 2>&1 &
MONITOR_PID=$!
sleep 1
redis-cli SET test:monitor "working" > /dev/null
kill $MONITOR_PID 2>/dev/null
echo "✅ Monitoring is working"

# Check data
echo ""
echo "Verifying sample data..."
KEYS_COUNT=$(redis-cli DBSIZE | awk '{print $1}')
if [ $KEYS_COUNT -gt 0 ]; then
    echo "✅ Sample data loaded ($KEYS_COUNT keys)"
else
    echo "❌ No data loaded"
    exit 1
fi

echo ""
echo "🎉 Lab 2 environment is ready!"
echo ""
echo "To start the lab:"
echo "1. Open lab2.md for instructions"
echo "2. Open terminal for monitoring: redis-cli monitor"
echo "3. Open terminal for commands: redis-cli"
echo "4. Access Redis Insight at: http://localhost:8001"
EOF

chmod +x test-lab.sh

# Final summary
echo ""
echo "✅ Lab 2 build complete!"
echo ""
echo "📂 Files created:"
echo "   ${LAB_DIR}/"
echo "   ├── lab2.md                          # Complete lab instructions"
echo "   ├── scripts/"
echo "   │   ├── load-business-data.sh        # Sample data loader"
echo "   │   └── simulate-business-load.sh    # Load generator"
echo "   ├── docs/"
echo "   │   ├── resp-reference.md            # RESP protocol guide"
echo "   │   └── troubleshooting.md           # Troubleshooting guide"
echo "   ├── protocol-samples/                # RESP examples"
echo "   ├── docker-compose.yml               # Complete environment"
echo "   ├── test-lab.sh                      # Environment tester"
echo "   └── README.md                        # Documentation"
echo ""
echo "🚀 Quick Start:"
echo "   cd ${LAB_DIR}"
echo "   ./test-lab.sh                        # Test environment"
echo "   code lab2.md                         # Open instructions"
echo ""
echo "📚 This lab covers:"
echo "   • RESP protocol structure and data types"
echo "   • Real-time monitoring and debugging"
echo "   • Protocol efficiency analysis"
echo "   • Business transaction patterns"
echo "   • Performance optimization techniques"
echo ""
echo "⏱️ Duration: 45 minutes"
echo "🎯 70% hands-on practice, 30% learning"