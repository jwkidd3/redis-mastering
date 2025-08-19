#!/bin/bash

# Lab 5 Generation Script - Advanced CLI Operations with Client-Side Host Parameter
# Redis Mastering Course - Client-Side Host Configuration Only

set -e

LAB_DIR="lab5-advanced-cli-host"
echo "🚀 Generating Lab 5: Advanced CLI Operations with Client-Side Host Parameter..."
echo "=============================================================================="

# Create lab directory structure
echo "📁 Creating lab directory structure..."
mkdir -p ${LAB_DIR}/{examples,reference,exercises}
cd ${LAB_DIR}

# Create main lab document
echo "📋 Creating lab5.md..."
cat > lab5.md << 'EOF'
# Lab 5: Advanced CLI Operations with Host Parameter

**Duration:** 45 minutes  
**Objective:** Master Redis CLI operations using host parameters for client-side connection management

## Prerequisites

- Redis server available (instructor will provide connection details)
- Redis CLI installed on your machine
- Redis Insight installed
- Basic Redis CLI knowledge from previous labs
- Command line familiarity (Windows/Mac compatible)

## Lab Overview

This lab focuses on using the `-h` (host) and `-p` (port) parameters with redis-cli to connect to Redis servers. You'll learn to specify connection details at the client level for each command.

## Part 1: Basic Host Parameter Usage (15 minutes)

### Step 1: Understanding Host Parameter Syntax

The redis-cli host parameter allows you to specify which Redis server to connect to:

```bash
# Basic syntax
redis-cli -h <hostname> -p <port> <command>

# Examples with different host formats
redis-cli -h localhost -p 6379 PING
redis-cli -h 127.0.0.1 -p 6379 PING
redis-cli -h redis.example.com -p 6379 PING
redis-cli -h 10.0.1.100 -p 6380 PING
```

### Step 2: Connection Testing with Host Parameters

Practice connecting to Redis using host parameters (replace with your actual Redis server details):

```bash
# Test connection (replace localhost:6379 with your Redis server)
redis-cli -h localhost -p 6379 PING

# Get server information
redis-cli -h localhost -p 6379 INFO server

# Check Redis version
redis-cli -h localhost -p 6379 INFO server | grep redis_version

# Test connectivity and measure response time
time redis-cli -h localhost -p 6379 PING
```

### Step 3: Basic Operations with Host Parameters

Perform basic Redis operations using host parameters:

```bash
# Set and get operations (replace host/port as needed)
redis-cli -h localhost -p 6379 SET test:lab5 "Hello from Lab 5"
redis-cli -h localhost -p 6379 GET test:lab5

# Check if key exists
redis-cli -h localhost -p 6379 EXISTS test:lab5

# Set key with expiration
redis-cli -h localhost -p 6379 SETEX temp:session "user123" 300

# Check TTL
redis-cli -h localhost -p 6379 TTL temp:session

# Delete key
redis-cli -h localhost -p 6379 DEL test:lab5
```

### Step 4: Working with Business Data

Create and manage business data using host parameters:

```bash
# Customer data operations
redis-cli -h localhost -p 6379 HSET customer:C001 name "Alice Johnson"
redis-cli -h localhost -p 6379 HSET customer:C001 email "alice@company.com"
redis-cli -h localhost -p 6379 HSET customer:C001 tier "premium"
redis-cli -h localhost -p 6379 HSET customer:C001 balance "15000"

# Retrieve customer information
redis-cli -h localhost -p 6379 HGETALL customer:C001
redis-cli -h localhost -p 6379 HGET customer:C001 name
redis-cli -h localhost -p 6379 HGET customer:C001 balance

# Product catalog
redis-cli -h localhost -p 6379 HSET product:P001 name "Business Package A"
redis-cli -h localhost -p 6379 HSET product:P001 price "299.99"
redis-cli -h localhost -p 6379 HSET product:P001 stock "50"

redis-cli -h localhost -p 6379 HGETALL product:P001

# Order queue operations
redis-cli -h localhost -p 6379 LPUSH orders:pending "ORD-2024-001:C001:P001"
redis-cli -h localhost -p 6379 LPUSH orders:pending "ORD-2024-002:C001:P002"
redis-cli -h localhost -p 6379 LPUSH orders:pending "ORD-2024-003:C002:P001"

# Check queue length and contents
redis-cli -h localhost -p 6379 LLEN orders:pending
redis-cli -h localhost -p 6379 LRANGE orders:pending 0 -1

# Process orders (move from pending to processing)
redis-cli -h localhost -p 6379 LPOP orders:pending
redis-cli -h localhost -p 6379 RPUSH orders:processing "ORD-2024-001:C001:P001"
```

## Part 2: Advanced Host Parameter Operations (15 minutes)

### Step 5: Batch Operations with Host Parameters

Execute multiple commands using host parameters:

```bash
# Multiple operations in sequence (replace host/port)
redis-cli -h localhost -p 6379 MULTI
redis-cli -h localhost -p 6379 SET counter:daily 0
redis-cli -h localhost -p 6379 INCR counter:daily
redis-cli -h localhost -p 6379 INCR counter:daily
redis-cli -h localhost -p 6379 EXEC

# Pipeline operations using --pipe
cat << 'PIPELINE' | redis-cli -h localhost -p 6379 --pipe
SET batch:key1 value1
SET batch:key2 value2
SET batch:key3 value3
GET batch:key1
GET batch:key2
GET batch:key3
PIPELINE

# Lua script execution with host parameters
redis-cli -h localhost -p 6379 EVAL "
local keys = redis.call('KEYS', 'customer:*')
return #keys
" 0

# Advanced operations
redis-cli -h localhost -p 6379 ZADD leaderboard 100 "user1" 200 "user2" 150 "user3"
redis-cli -h localhost -p 6379 ZREVRANGE leaderboard 0 -1 WITHSCORES

redis-cli -h localhost -p 6379 SADD tags:product:P001 "business" "software" "premium"
redis-cli -h localhost -p 6379 SMEMBERS tags:product:P001
```

### Step 6: Monitoring and Analysis with Host Parameters

Monitor Redis operations using host parameters:

```bash
# Monitor commands in real-time (run in background)
redis-cli -h localhost -p 6379 MONITOR &
MONITOR_PID=$!

# Generate some activity to monitor
redis-cli -h localhost -p 6379 SET activity:test1 "monitoring test"
redis-cli -h localhost -p 6379 INCR activity:counter
redis-cli -h localhost -p 6379 LPUSH activity:log "test activity"

# Stop monitoring after a few seconds
sleep 5
kill $MONITOR_PID 2>/dev/null || true

# Performance analysis
redis-cli -h localhost -p 6379 INFO stats | grep instantaneous_ops_per_sec
redis-cli -h localhost -p 6379 INFO memory | grep used_memory_human
redis-cli -h localhost -p 6379 INFO clients | grep connected_clients

# Slow query analysis
redis-cli -h localhost -p 6379 SLOWLOG LEN
redis-cli -h localhost -p 6379 SLOWLOG GET 5

# Key analysis
redis-cli -h localhost -p 6379 DBSIZE
redis-cli -h localhost -p 6379 KEYS "customer:*"
redis-cli -h localhost -p 6379 KEYS "product:*"
redis-cli -h localhost -p 6379 KEYS "orders:*"
```

### Step 7: Different Output Formats with Host Parameters

Practice different output formats using host parameters:

```bash
# CSV output format
redis-cli -h localhost -p 6379 --csv HGETALL customer:C001
redis-cli -h localhost -p 6379 --csv LRANGE orders:pending 0 -1
redis-cli -h localhost -p 6379 --csv ZRANGE leaderboard 0 -1 WITHSCORES

# Raw output format (useful for scripts)
redis-cli -h localhost -p 6379 --raw GET customer:C001
redis-cli -h localhost -p 6379 --raw HGET product:P001 name

# JSON output format (if supported)
redis-cli -h localhost -p 6379 --json HGETALL customer:C001

# No raw output (default)
redis-cli -h localhost -p 6379 HGETALL customer:C001

# Compare formats
echo "=== Default Format ==="
redis-cli -h localhost -p 6379 HGETALL customer:C001

echo "=== CSV Format ==="
redis-cli -h localhost -p 6379 --csv HGETALL customer:C001

echo "=== Raw Format ==="
redis-cli -h localhost -p 6379 --raw HGET customer:C001 name
```

## Part 3: Production Scenarios with Host Parameters (15 minutes)

### Step 8: Connection Options and Authentication

Practice advanced connection options:

```bash
# Connection with timeout (useful for remote servers)
redis-cli -h localhost -p 6379 --connect-timeout 5 PING

# Connection with socket timeout
redis-cli -h localhost -p 6379 --timeout 3 PING

# If Redis requires authentication (uncomment and modify as needed)
# redis-cli -h localhost -p 6379 -a yourpassword PING
# redis-cli -h localhost -p 6379 --askpass PING

# Connect to specific database number
redis-cli -h localhost -p 6379 -n 1 PING
redis-cli -h localhost -p 6379 -n 1 SET db1:test "database 1 test"
redis-cli -h localhost -p 6379 -n 1 GET db1:test

# Switch back to database 0
redis-cli -h localhost -p 6379 -n 0 PING
```

### Step 9: Latency and Performance Testing

Test connection performance using host parameters:

```bash
# Latency testing (press Ctrl+C to stop after 10-15 seconds)
echo "Testing latency to Redis server (press Ctrl+C to stop)..."
redis-cli -h localhost -p 6379 --latency

# Latency history (press Ctrl+C to stop)
echo "Testing latency history (press Ctrl+C to stop)..."
redis-cli -h localhost -p 6379 --latency-history

# Intrinsic latency testing
echo "Testing intrinsic latency..."
redis-cli -h localhost -p 6379 --intrinsic-latency 5

# Benchmark specific operations
echo "Benchmarking SET operations..."
redis-cli -h localhost -p 6379 EVAL "
for i=1,1000 do
  redis.call('SET', 'benchmark:' .. i, 'value' .. i)
end
return 'OK'
" 0

echo "Benchmarking GET operations..."
redis-cli -h localhost -p 6379 EVAL "
local results = {}
for i=1,100 do
  table.insert(results, redis.call('GET', 'benchmark:' .. i))
end
return #results
" 0
```

### Step 10: Business Reporting with Host Parameters

Create business reports using Redis data:

```bash
# Customer analytics report
echo "=== Customer Analytics Report ==="
echo "Date: $(date)"
echo "Redis Server: localhost:6379"  # Update with your server details
echo ""

# Count customers by tier
echo "Customer Tiers:"
redis-cli -h localhost -p 6379 EVAL "
local customers = redis.call('KEYS', 'customer:*')
local tiers = {}
for i=1,#customers do
  local tier = redis.call('HGET', customers[i], 'tier')
  if tier then
    tiers[tier] = (tiers[tier] or 0) + 1
  end
end
local result = {}
for tier, count in pairs(tiers) do
  table.insert(result, tier .. ':' .. count)
end
return result
" 0

# Order status report
echo ""
echo "Order Status:"
PENDING_ORDERS=$(redis-cli -h localhost -p 6379 LLEN orders:pending)
PROCESSING_ORDERS=$(redis-cli -h localhost -p 6379 LLEN orders:processing)
echo "Pending Orders: ${PENDING_ORDERS:-0}"
echo "Processing Orders: ${PROCESSING_ORDERS:-0}"

# Cache efficiency
echo ""
echo "Cache Metrics:"
redis-cli -h localhost -p 6379 INFO stats | grep keyspace_hits
redis-cli -h localhost -p 6379 INFO stats | grep keyspace_misses

# Memory usage
echo ""
echo "Memory Usage:"
redis-cli -h localhost -p 6379 INFO memory | grep used_memory_human
redis-cli -h localhost -p 6379 INFO memory | grep used_memory_peak_human

# Active keys by pattern
echo ""
echo "Key Distribution:"
CUSTOMER_KEYS=$(redis-cli -h localhost -p 6379 KEYS "customer:*" | wc -l)
PRODUCT_KEYS=$(redis-cli -h localhost -p 6379 KEYS "product:*" | wc -l)
ORDER_KEYS=$(redis-cli -h localhost -p 6379 KEYS "orders:*" | wc -l)
echo "Customer Keys: ${CUSTOMER_KEYS:-0}"
echo "Product Keys: ${PRODUCT_KEYS:-0}"
echo "Order Keys: ${ORDER_KEYS:-0}"
```

## Redis Insight Integration

### Step 11: Configure Redis Insight with Host Parameters

1. **Open Redis Insight**

2. **Add Database Connection:**
   - Click "Add Database"
   - **Host:** Use the same host you've been using in commands (e.g., localhost)
   - **Port:** Use the same port from your commands (e.g., 6379)
   - **Name:** Lab5-Business-Redis
   - **Password:** (if required)
   - Click "Add Database"

3. **Use Command Line Interface in Redis Insight:**
   - Navigate to your database
   - Click on "Command Line Interface" or "CLI"
   - Run the same commands you practiced:
     ```
     HGETALL customer:C001
     LRANGE orders:pending 0 -1
     ZRANGE leaderboard 0 -1 WITHSCORES
     INFO stats
     ```

4. **Compare CLI vs GUI:**
   - Use Browser view to see keys visually
   - Use CLI for command practice
   - Notice how both connect to the same Redis instance

### Step 12: Interactive Session Practice

Start an interactive Redis CLI session:

```bash
# Start interactive session (replace with your Redis server details)
redis-cli -h localhost -p 6379

# Inside the interactive session, run these commands:
# (Note: No need for host parameters inside interactive session)

# Basic operations
> PING
> INFO server
> DBSIZE

# Customer operations  
> HGETALL customer:C001
> HKEYS customer:C001
> HVALS customer:C001

# List operations
> LRANGE orders:pending 0 -1
> LLEN orders:pending

# Set operations
> SMEMBERS tags:product:P001
> SCARD tags:product:P001

# Sorted set operations
> ZRANGE leaderboard 0 -1 WITHSCORES
> ZREVRANGE leaderboard 0 2 WITHSCORES

# Exit interactive session
> EXIT
```

## Troubleshooting Host Parameters

### Common Issues and Solutions

1. **Connection Refused:**
   ```bash
   # Check if you're using the correct host and port
   redis-cli -h localhost -p 6379 PING
   
   # Try different host formats
   redis-cli -h 127.0.0.1 -p 6379 PING
   
   # Check if Redis server is running (ask instructor)
   telnet localhost 6379
   ```

2. **Timeout Issues:**
   ```bash
   # Increase connection timeout for slow networks
   redis-cli -h remote-server.com -p 6379 --connect-timeout 10 PING
   
   # Set socket timeout
   redis-cli -h remote-server.com -p 6379 --timeout 5 PING
   ```

3. **Authentication Errors:**
   ```bash
   # If Redis requires password
   redis-cli -h localhost -p 6379 -a password PING
   
   # Prompt for password (secure)
   redis-cli -h localhost -p 6379 --askpass PING
   ```

4. **DNS Resolution Issues:**
   ```bash
   # Use IP address instead of hostname
   redis-cli -h 192.168.1.100 -p 6379 PING
   
   # Check DNS resolution
   nslookup redis-server.company.com
   ```

5. **Wrong Database:**
   ```bash
   # Make sure you're connecting to the right database number
   redis-cli -h localhost -p 6379 -n 0 PING  # Database 0
   redis-cli -h localhost -p 6379 -n 1 PING  # Database 1
   ```

### Testing Different Host Configurations

Practice with various host parameter combinations:

```bash
# Local connections
redis-cli -h localhost -p 6379 PING
redis-cli -h 127.0.0.1 -p 6379 PING

# Remote connections (replace with actual remote server)
# redis-cli -h redis.company.com -p 6379 PING
# redis-cli -h 10.0.1.50 -p 6380 PING

# With authentication (if needed)
# redis-cli -h secure-redis.com -p 6379 -a secret123 PING

# With database selection
# redis-cli -h localhost -p 6379 -n 1 PING

# With timeouts for unreliable networks
# redis-cli -h slow-server.com -p 6379 --connect-timeout 15 --timeout 10 PING
```

## Performance Tips for Host Parameters

1. **Use IP addresses for faster DNS resolution:**
   ```bash
   redis-cli -h 192.168.1.100 -p 6379 PING
   ```

2. **Set appropriate timeouts for remote connections:**
   ```bash
   redis-cli -h remote-server.com -p 6379 --connect-timeout 10 PING
   ```

3. **Use pipelining for multiple commands:**
   ```bash
   echo -e "PING\nINFO server\nDBSIZE" | redis-cli -h localhost -p 6379 --pipe
   ```

4. **Monitor network latency regularly:**
   ```bash
   redis-cli -h localhost -p 6379 --latency
   ```

## Data Cleanup

Clean up the data created during this lab:

```bash
# Remove test data (replace host/port with your server)
redis-cli -h localhost -p 6379 DEL test:lab5
redis-cli -h localhost -p 6379 DEL temp:session
redis-cli -h localhost -p 6379 DEL counter:daily

# Remove customer data
redis-cli -h localhost -p 6379 DEL customer:C001

# Remove product data  
redis-cli -h localhost -p 6379 DEL product:P001

# Remove order queues
redis-cli -h localhost -p 6379 DEL orders:pending
redis-cli -h localhost -p 6379 DEL orders:processing

# Remove other test data
redis-cli -h localhost -p 6379 DEL leaderboard
redis-cli -h localhost -p 6379 DEL tags:product:P001

# Remove batch keys
redis-cli -h localhost -p 6379 DEL batch:key1 batch:key2 batch:key3

# Remove benchmark data
redis-cli -h localhost -p 6379 EVAL "
local keys = redis.call('KEYS', 'benchmark:*')
for i=1,#keys do
  redis.call('DEL', keys[i])
end
return #keys
" 0

# Remove activity test data
redis-cli -h localhost -p 6379 DEL activity:test1
redis-cli -h localhost -p 6379 DEL activity:counter  
redis-cli -h localhost -p 6379 DEL activity:log

echo "✅ Lab data cleanup completed"
```

## Key Takeaways

1. **Host Parameter Mastery:** Use `-h` and `-p` to specify Redis server connection details
2. **Client-Side Configuration:** Connection details are specified with each command
3. **Flexible Connections:** Easy to switch between different Redis servers
4. **Production Ready:** Master authentication, timeouts, and error handling
5. **Performance Awareness:** Understand latency and connection optimization
6. **Redis Insight Integration:** Configure GUI tools with same connection parameters

## Next Steps

- Practice connecting to remote Redis instances
- Explore Redis Cluster connections with host parameters
- Learn about Redis Sentinel for high availability
- Study Redis Cloud and managed service connections
- Practice with SSL/TLS secured Redis connections

## Additional Practice

Try these additional exercises to reinforce host parameter usage:

1. **Multiple Environment Practice:**
   - Connect to different Redis servers
   - Compare data between servers
   - Practice switching between environments

2. **Network Scenarios:**
   - Test with different latency conditions
   - Practice with authentication requirements
   - Handle connection timeouts gracefully

3. **Real-World Scenarios:**
   - Connect to Redis Cloud instances
   - Practice with Redis clusters
   - Use Redis Insight with various connection types

Remember: The key skill is using `-h hostname -p port` with every redis-cli command to specify exactly which Redis server you want to connect to!
EOF

# Create examples directory with practical exercises
echo "📋 Creating practical examples..."

cat > examples/basic-host-examples.sh << 'EOF'
#!/bin/bash

# Basic Host Parameter Examples
# Replace localhost:6379 with your actual Redis server details

echo "=== Basic Host Parameter Examples ==="
echo "====================================="

# Basic connection test
echo "1. Testing basic connection:"
echo "   Command: redis-cli -h localhost -p 6379 PING"
redis-cli -h localhost -p 6379 PING

echo ""
echo "2. Getting server information:"
echo "   Command: redis-cli -h localhost -p 6379 INFO server"
redis-cli -h localhost -p 6379 INFO server | head -5

echo ""
echo "3. Setting and getting a value:"
echo "   Command: redis-cli -h localhost -p 6379 SET example:key 'example value'"
redis-cli -h localhost -p 6379 SET example:key "example value"
echo "   Command: redis-cli -h localhost -p 6379 GET example:key"
redis-cli -h localhost -p 6379 GET example:key

echo ""
echo "4. Checking database size:"
echo "   Command: redis-cli -h localhost -p 6379 DBSIZE"
redis-cli -h localhost -p 6379 DBSIZE

echo ""
echo "5. Cleaning up example:"
echo "   Command: redis-cli -h localhost -p 6379 DEL example:key"
redis-cli -h localhost -p 6379 DEL example:key

echo ""
echo "✅ Basic examples completed"
echo "💡 Remember to replace 'localhost:6379' with your actual Redis server details"
EOF

cat > examples/business-operations-examples.sh << 'EOF'
#!/bin/bash

# Business Operations Examples with Host Parameters
# Replace localhost:6379 with your actual Redis server details

HOST="localhost"
PORT="6379"

echo "=== Business Operations Examples ==="
echo "===================================="
echo "Using Redis server: $HOST:$PORT"
echo ""

echo "1. Customer Management:"
echo "   Creating customer profile..."
redis-cli -h $HOST -p $PORT HSET customer:DEMO name "Demo Customer"
redis-cli -h $HOST -p $PORT HSET customer:DEMO email "demo@example.com"
redis-cli -h $HOST -p $PORT HSET customer:DEMO tier "standard"

echo "   Retrieving customer profile:"
redis-cli -h $HOST -p $PORT HGETALL customer:DEMO

echo ""
echo "2. Order Processing:"
echo "   Adding orders to queue..."
redis-cli -h $HOST -p $PORT LPUSH demo:orders "ORDER-001"
redis-cli -h $HOST -p $PORT LPUSH demo:orders "ORDER-002"

echo "   Checking queue status:"
echo "   Queue length: $(redis-cli -h $HOST -p $PORT LLEN demo:orders)"
echo "   Queue contents:"
redis-cli -h $HOST -p $PORT LRANGE demo:orders 0 -1

echo ""
echo "3. Analytics:"
echo "   Adding customer scores..."
redis-cli -h $HOST -p $PORT ZADD demo:scores 100 "customer1" 150 "customer2" 200 "customer3"

echo "   Top customers:"
redis-cli -h $HOST -p $PORT ZREVRANGE demo:scores 0 2 WITHSCORES

echo ""
echo "4. Session Management:"
echo "   Creating session with expiration..."
redis-cli -h $HOST -p $PORT SETEX demo:session:abc123 300 "user:demo"

echo "   Checking session TTL:"
redis-cli -h $HOST -p $PORT TTL demo:session:abc123

echo ""
echo "5. Cleanup:"
redis-cli -h $HOST -p $PORT DEL customer:DEMO
redis-cli -h $HOST -p $PORT DEL demo:orders
redis-cli -h $HOST -p $PORT DEL demo:scores
redis-cli -h $HOST -p $PORT DEL demo:session:abc123

echo "✅ Business operations examples completed"
echo "💡 Modify HOST and PORT variables at the top of this script for different servers"
EOF

cat > examples/output-formats-examples.sh << 'EOF'
#!/bin/bash

# Output Format Examples with Host Parameters
# Replace localhost:6379 with your actual Redis server details

HOST="localhost" 
PORT="6379"

echo "=== Output Format Examples ==="
echo "=============================="
echo "Using Redis server: $HOST:$PORT"
echo ""

# Create sample data
echo "Creating sample data..."
redis-cli -h $HOST -p $PORT HSET demo:formats name "Demo User" age "30" city "New York"
redis-cli -h $HOST -p $PORT LPUSH demo:list "item1" "item2" "item3"

echo ""
echo "1. Default Format:"
echo "   Command: redis-cli -h $HOST -p $PORT HGETALL demo:formats"
redis-cli -h $HOST -p $PORT HGETALL demo:formats

echo ""
echo "2. CSV Format:"
echo "   Command: redis-cli -h $HOST -p $PORT --csv HGETALL demo:formats"
redis-cli -h $HOST -p $PORT --csv HGETALL demo:formats

echo ""
echo "3. Raw Format:"
echo "   Command: redis-cli -h $HOST -p $PORT --raw HGET demo:formats name"
redis-cli -h $HOST -p $PORT --raw HGET demo:formats name

echo ""
echo "4. List Operations - Different Formats:"
echo "   Default:"
redis-cli -h $HOST -p $PORT LRANGE demo:list 0 -1

echo "   CSV:"
redis-cli -h $HOST -p $PORT --csv LRANGE demo:list 0 -1

echo ""
echo "5. JSON Format (if supported):"
echo "   Command: redis-cli -h $HOST -p $PORT --json HGETALL demo:formats"
redis-cli -h $HOST -p $PORT --json HGETALL demo:formats 2>/dev/null || echo "   JSON format not supported in this Redis CLI version"

echo ""
echo "Cleanup:"
redis-cli -h $HOST -p $PORT DEL demo:formats demo:list

echo "✅ Output format examples completed"
echo "💡 Different formats are useful for scripts and data processing"
EOF

chmod +x examples/*.sh

# Create reference materials
echo "📚 Creating reference materials..."

cat > reference/host-parameter-reference.md << 'EOF'
# Redis CLI Host Parameter Reference

## Basic Syntax

```bash
redis-cli -h <hostname> -p <port> [options] <command>
```

## Connection Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `-h <host>` | Redis server hostname or IP | `-h localhost`, `-h 192.168.1.100` |
| `-p <port>` | Redis server port | `-p 6379`, `-p 6380` |
| `-a <password>` | Authentication password | `-a mypassword` |
| `-n <db>` | Database number | `-n 0`, `-n 1` |
| `--askpass` | Prompt for password | `--askpass` |

## Connection Options

| Option | Description | Example |
|--------|-------------|---------|
| `--connect-timeout <sec>` | Connection timeout | `--connect-timeout 10` |
| `--timeout <sec>` | Socket timeout | `--timeout 5` |

## Output Format Options

| Option | Description | Example |
|--------|-------------|---------|
| `--csv` | CSV output format | `--csv HGETALL key` |
| `--raw` | Raw output (no formatting) | `--raw GET key` |
| `--json` | JSON output format | `--json HGETALL key` |

## Monitoring Options

| Option | Description | Usage |
|--------|-------------|-------|
| `--latency` | Show latency statistics | Press Ctrl+C to stop |
| `--latency-history` | Latency over time | Press Ctrl+C to stop |
| `--intrinsic-latency <sec>` | Test intrinsic latency | Duration in seconds |

## Common Host Formats

```bash
# Local connections
redis-cli -h localhost -p 6379
redis-cli -h 127.0.0.1 -p 6379

# Remote connections
redis-cli -h redis.company.com -p 6379
redis-cli -h 10.0.1.100 -p 6380

# With authentication
redis-cli -h secure-redis.com -p 6379 -a password123

# Different database
redis-cli -h localhost -p 6379 -n 1

# With timeouts
redis-cli -h slow-server.com -p 6379 --connect-timeout 15 --timeout 10
```

## Interactive Session

```bash
# Start interactive session
redis-cli -h localhost -p 6379

# Inside session (no host parameters needed)
> PING
> INFO server
> SET key value
> GET key
> EXIT
```

## Pipeline Operations

```bash
# Pipe multiple commands
echo -e "PING\nINFO server\nDBSIZE" | redis-cli -h localhost -p 6379 --pipe

# From file
redis-cli -h localhost -p 6379 --pipe < commands.txt
```

## Error Handling

```bash
# Test connectivity
redis-cli -h localhost -p 6379 ping >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "Redis is reachable"
else
    echo "Redis connection failed"
fi
```

## Best Practices

1. **Always specify host and port explicitly**
2. **Use IP addresses for better performance**
3. **Set appropriate timeouts for remote connections**
4. **Use authentication when required**
5. **Handle connection errors gracefully**
6. **Use appropriate output formats for scripts**
EOF

cat > reference/common-commands-with-host.md << 'EOF'
# Common Redis Commands with Host Parameters

Replace `localhost:6379` with your actual Redis server details.

## Basic Operations

```bash
# Connection test
redis-cli -h localhost -p 6379 PING

# Server information
redis-cli -h localhost -p 6379 INFO server
redis-cli -h localhost -p 6379 INFO memory
redis-cli -h localhost -p 6379 INFO stats

# Database operations
redis-cli -h localhost -p 6379 DBSIZE
redis-cli -h localhost -p 6379 FLUSHDB  # Use with caution!
```

## String Operations

```bash
# Set and get
redis-cli -h localhost -p 6379 SET mykey "myvalue"
redis-cli -h localhost -p 6379 GET mykey

# With expiration
redis-cli -h localhost -p 6379 SETEX session:123 3600 "user_data"
redis-cli -h localhost -p 6379 TTL session:123

# Increment operations
redis-cli -h localhost -p 6379 SET counter 0
redis-cli -h localhost -p 6379 INCR counter
redis-cli -h localhost -p 6379 INCRBY counter 5
```

## Hash Operations

```bash
# Set hash fields
redis-cli -h localhost -p 6379 HSET user:1001 name "John Doe"
redis-cli -h localhost -p 6379 HSET user:1001 email "john@example.com"
redis-cli -h localhost -p 6379 HSET user:1001 age 30

# Get hash data
redis-cli -h localhost -p 6379 HGET user:1001 name
redis-cli -h localhost -p 6379 HGETALL user:1001
redis-cli -h localhost -p 6379 HKEYS user:1001
```

## List Operations

```bash
# Add to list
redis-cli -h localhost -p 6379 LPUSH tasks "task1" "task2" "task3"
redis-cli -h localhost -p 6379 RPUSH queue "item1" "item2"

# Get from list
redis-cli -h localhost -p 6379 LRANGE tasks 0 -1
redis-cli -h localhost -p 6379 LLEN tasks
redis-cli -h localhost -p 6379 LPOP tasks
```

## Set Operations

```bash
# Add to set
redis-cli -h localhost -p 6379 SADD tags "redis" "database" "nosql"
redis-cli -h localhost -p 6379 SADD users:active "user1" "user2" "user3"

# Set operations
redis-cli -h localhost -p 6379 SMEMBERS tags
redis-cli -h localhost -p 6379 SCARD tags
redis-cli -h localhost -p 6379 SISMEMBER tags "redis"
```

## Sorted Set Operations

```bash
# Add to sorted set
redis-cli -h localhost -p 6379 ZADD leaderboard 100 "player1" 200 "player2" 150 "player3"

# Get from sorted set
redis-cli -h localhost -p 6379 ZRANGE leaderboard 0 -1
redis-cli -h localhost -p 6379 ZREVRANGE leaderboard 0 -1 WITHSCORES
redis-cli -h localhost -p 6379 ZSCORE leaderboard "player1"
```

## Key Management

```bash
# Key information
redis-cli -h localhost -p 6379 EXISTS mykey
redis-cli -h localhost -p 6379 TYPE mykey
redis-cli -h localhost -p 6379 TTL mykey

# Key patterns
redis-cli -h localhost -p 6379 KEYS "user:*"
redis-cli -h localhost -p 6379 KEYS "session:*"

# Delete keys
redis-cli -h localhost -p 6379 DEL mykey
redis-cli -h localhost -p 6379 DEL key1 key2 key3
```

## Monitoring Commands

```bash
# Real-time monitoring
redis-cli -h localhost -p 6379 MONITOR

# Performance metrics
redis-cli -h localhost -p 6379 INFO stats | grep ops_per_sec
redis-cli -h localhost -p 6379 SLOWLOG GET 10
redis-cli -h localhost -p 6379 CLIENT LIST

# Latency testing
redis-cli -h localhost -p 6379 --latency
redis-cli -h localhost -p 6379 --latency-history
```

## Transaction Commands

```bash
# Transaction example
redis-cli -h localhost -p 6379 MULTI
redis-cli -h localhost -p 6379 SET key1 value1
redis-cli -h localhost -p 6379 SET key2 value2
redis-cli -h localhost -p 6379 INCR counter
redis-cli -h localhost -p 6379 EXEC
```

## Lua Script Example

```bash
# Simple Lua script
redis-cli -h localhost -p 6379 EVAL "return redis.call('GET', KEYS[1])" 1 mykey

# Complex script
redis-cli -h localhost -p 6379 EVAL "
local count = 0
local keys = redis.call('KEYS', 'user:*')
for i=1,#keys do
  count = count + 1
end
return count
" 0
```
EOF

# Create exercises
echo "🏋️ Creating practice exercises..."

cat > exercises/exercise1-basic-connections.md << 'EOF'
# Exercise 1: Basic Connections with Host Parameters

## Objective
Practice basic Redis CLI connections using host parameters.

## Instructions

**Note:** Replace `localhost:6379` with the Redis server details provided by your instructor.

### Task 1: Connection Testing
1. Test basic connectivity:
   ```bash
   redis-cli -h localhost -p 6379 PING
   ```
   Expected result: `PONG`

2. Get Redis server version:
   ```bash
   redis-cli -h localhost -p 6379 INFO server | grep redis_version
   ```

3. Check current database size:
   ```bash
   redis-cli -h localhost -p 6379 DBSIZE
   ```

### Task 2: Basic Data Operations
1. Create a test key:
   ```bash
   redis-cli -h localhost -p 6379 SET exercise1:test "Hello Redis"
   ```

2. Retrieve the value:
   ```bash
   redis-cli -h localhost -p 6379 GET exercise1:test
   ```

3. Check if key exists:
   ```bash
   redis-cli -h localhost -p 6379 EXISTS exercise1:test
   ```

4. Set a key with expiration:
   ```bash
   redis-cli -h localhost -p 6379 SETEX exercise1:temp "Temporary data" 60
   ```

5. Check TTL:
   ```bash
   redis-cli -h localhost -p 6379 TTL exercise1:temp
   ```

### Task 3: Cleanup
Remove the test keys:
```bash
redis-cli -h localhost -p 6379 DEL exercise1:test exercise1:temp
```

## Verification
- All commands should execute without errors
- PING should return PONG
- TTL should show decreasing values
- Keys should be successfully deleted

## Questions
1. What happens if you use the wrong port number?
2. How can you tell if Redis is not running?
3. What does TTL -1 mean?
EOF

cat > exercises/exercise2-business-data.md << 'EOF'
# Exercise 2: Business Data Operations with Host Parameters

## Objective
Practice real business scenarios using Redis with host parameters.

## Instructions

**Note:** Replace `localhost:6379` with your Redis server details.

### Task 1: Customer Management
1. Create a customer profile:
   ```bash
   redis-cli -h localhost -p 6379 HSET customer:EX001 name "Exercise Customer"
   redis-cli -h localhost -p 6379 HSET customer:EX001 email "customer@example.com"
   redis-cli -h localhost -p 6379 HSET customer:EX001 tier "premium"
   redis-cli -h localhost -p 6379 HSET customer:EX001 balance "5000"
   ```

2. Retrieve customer information:
   ```bash
   redis-cli -h localhost -p 6379 HGETALL customer:EX001
   redis-cli -h localhost -p 6379 HGET customer:EX001 tier
   ```

3. Update customer balance:
   ```bash
   redis-cli -h localhost -p 6379 HSET customer:EX001 balance "5500"
   ```

### Task 2: Order Processing
1. Add orders to processing queue:
   ```bash
   redis-cli -h localhost -p 6379 LPUSH orders:exercise "EX-ORDER-001"
   redis-cli -h localhost -p 6379 LPUSH orders:exercise "EX-ORDER-002"
   redis-cli -h localhost -p 6379 LPUSH orders:exercise "EX-ORDER-003"
   ```

2. Check queue status:
   ```bash
   redis-cli -h localhost -p 6379 LLEN orders:exercise
   redis-cli -h localhost -p 6379 LRANGE orders:exercise 0 -1
   ```

3. Process an order (move from queue):
   ```bash
   redis-cli -h localhost -p 6379 LPOP orders:exercise
   ```

### Task 3: Analytics
1. Create customer scores:
   ```bash
   redis-cli -h localhost -p 6379 ZADD exercise:scores 100 "EX001" 150 "EX002" 200 "EX003"
   ```

2. Get top customers:
   ```bash
   redis-cli -h localhost -p 6379 ZREVRANGE exercise:scores 0 -1 WITHSCORES
   ```

3. Get specific customer score:
   ```bash
   redis-cli -h localhost -p 6379 ZSCORE exercise:scores "EX001"
   ```

### Task 4: Session Management
1. Create user sessions:
   ```bash
   redis-cli -h localhost -p 6379 SETEX session:EX123 1800 "user:EX001"
   redis-cli -h localhost -p 6379 SETEX session:EX456 3600 "user:EX002"
   ```

2. Check active sessions:
   ```bash
   redis-cli -h localhost -p 6379 KEYS "session:*"
   redis-cli -h localhost -p 6379 TTL session:EX123
   ```

### Task 5: Cleanup
Remove all exercise data:
```bash
redis-cli -h localhost -p 6379 DEL customer:EX001
redis-cli -h localhost -p 6379 DEL orders:exercise
redis-cli -h localhost -p 6379 DEL exercise:scores
redis-cli -h localhost -p 6379 DEL session:EX123 session:EX456
```

## Verification Checklist
- [ ] Customer profile created successfully
- [ ] Customer data retrieved correctly
- [ ] Orders added to queue
- [ ] Order processed (removed from queue)
- [ ] Analytics scores created and retrieved
- [ ] Sessions created with proper TTL
- [ ] All data cleaned up

## Challenge Questions
1. How would you get all customers with "premium" tier?
2. What command would show all orders in the queue without removing them?
3. How can you increase a customer's score by 50 points?
EOF

cat > exercises/exercise3-monitoring.md << 'EOF'
# Exercise 3: Monitoring and Performance with Host Parameters

## Objective
Learn to monitor Redis performance and analyze operations using host parameters.

## Instructions

**Note:** Replace `localhost:6379` with your Redis server details.

### Task 1: Server Information
1. Get comprehensive server information:
   ```bash
   redis-cli -h localhost -p 6379 INFO server
   redis-cli -h localhost -p 6379 INFO memory
   redis-cli -h localhost -p 6379 INFO stats
   ```

2. Check specific metrics:
   ```bash
   redis-cli -h localhost -p 6379 INFO stats | grep instantaneous_ops_per_sec
   redis-cli -h localhost -p 6379 INFO memory | grep used_memory_human
   redis-cli -h localhost -p 6379 INFO clients | grep connected_clients
   ```

### Task 2: Performance Testing
1. Create test data for performance analysis:
   ```bash
   redis-cli -h localhost -p 6379 EVAL "
   for i=1,1000 do
     redis.call('SET', 'perf:test:' .. i, 'value' .. i)
   end
   return 'Created 1000 keys'
   " 0
   ```

2. Test latency (run for 10 seconds, then press Ctrl+C):
   ```bash
   redis-cli -h localhost -p 6379 --latency
   ```

3. Check slow queries:
   ```bash
   redis-cli -h localhost -p 6379 SLOWLOG LEN
   redis-cli -h localhost -p 6379 SLOWLOG GET 5
   ```

### Task 3: Key Analysis
1. Count keys by pattern:
   ```bash
   redis-cli -h localhost -p 6379 KEYS "perf:test:*" | wc -l
   ```

2. Check database size:
   ```bash
   redis-cli -h localhost -p 6379 DBSIZE
   ```

3. Sample key types:
   ```bash
   redis-cli -h localhost -p 6379 TYPE perf:test:1
   redis-cli -h localhost -p 6379 TYPE perf:test:100
   ```

### Task 4: Real-time Monitoring
1. Start monitoring (run in background for 30 seconds):
   ```bash
   timeout 30s redis-cli -h localhost -p 6379 MONITOR &
   MONITOR_PID=$!
   ```

2. Generate activity:
   ```bash
   redis-cli -h localhost -p 6379 SET monitor:test1 "activity1"
   redis-cli -h localhost -p 6379 INCR monitor:counter
   redis-cli -h localhost -p 6379 LPUSH monitor:list "item1" "item2"
   redis-cli -h localhost -p 6379 HSET monitor:hash field1 "value1"
   ```

3. Wait for monitoring to complete (30 seconds)

### Task 5: Output Formats
1. Test different output formats:
   ```bash
   # Default format
   redis-cli -h localhost -p 6379 HSET format:test name "Test User" age "25"
   redis-cli -h localhost -p 6379 HGETALL format:test
   
   # CSV format
   redis-cli -h localhost -p 6379 --csv HGETALL format:test
   
   # Raw format
   redis-cli -h localhost -p 6379 --raw HGET format:test name
   ```

### Task 6: Cleanup
Remove performance test data:
```bash
redis-cli -h localhost -p 6379 EVAL "
local keys = redis.call('KEYS', 'perf:test:*')
for i=1,#keys do
  redis.call('DEL', keys[i])
end
return 'Deleted ' .. #keys .. ' keys'
" 0

redis-cli -h localhost -p 6379 DEL monitor:test1 monitor:counter monitor:list monitor:hash format:test
```

## Analysis Questions
1. What was the average latency to your Redis server?
2. How many operations per second is your Redis server handling?
3. What's the current memory usage?
4. Were there any slow queries detected?

## Performance Observations
Record your findings:
- Latency: _____ ms
- Memory usage: _____ MB
- Operations/sec: _____
- Connected clients: _____
- Slow queries: _____

## Bonus Challenge
Create a simple performance report using multiple INFO commands and format the output for easy reading.
EOF

# Create package.json
cat > package.json << 'EOF'
{
  "name": "lab5-advanced-cli-host",
  "version": "1.0.0",
  "description": "Lab 5: Advanced CLI Operations with Client-Side Host Parameter",
  "scripts": {
    "examples-basic": "./examples/basic-host-examples.sh",
    "examples-business": "./examples/business-operations-examples.sh",
    "examples-formats": "./examples/output-formats-examples.sh"
  },
  "keywords": ["redis", "cli", "host", "parameter", "client-side"],
  "author": "Redis Mastering Course",
  "license": "MIT"
}
EOF

# Create README
echo "📖 Creating README.md..."
cat > README.md << 'EOF'
# Lab 5: Advanced CLI Operations with Client-Side Host Parameter

## 🎯 Overview

Master Redis CLI operations using client-side host parameters. Learn to specify Redis server connection details with each command using `-h` (host) and `-p` (port) parameters.

## ⚙️ Key Concept

This lab focuses on **client-side configuration** - you specify the Redis server details with each `redis-cli` command:

```bash
redis-cli -h <hostname> -p <port> <command>
```

**No Docker setup required** - you'll connect to an existing Redis server using connection details provided by your instructor.

## 🚀 Quick Start

1. **Get Redis server details from your instructor**
   - Hostname (e.g., `localhost`, `redis.company.com`)
   - Port (e.g., `6379`, `6380`)
   - Password (if required)

2. **Test connection:**
   ```bash
   redis-cli -h [hostname] -p [port] PING
   ```

3. **Open lab instructions:**
   ```bash
   code lab5.md
   ```

## 📁 Lab Structure

```
lab5-advanced-cli-host/
├── lab5.md                              📋 Complete lab instructions
├── examples/                            
│   ├── basic-host-examples.sh           💡 Basic connection examples
│   ├── business-operations-examples.sh  💼 Business scenario examples
│   └── output-formats-examples.sh       📊 Different output formats
├── reference/
│   ├── host-parameter-reference.md      📚 Complete parameter reference
│   └── common-commands-with-host.md     📖 Command examples
├── exercises/
│   ├── exercise1-basic-connections.md   🏋️ Basic connection practice
│   ├── exercise2-business-data.md       💼 Business operations practice
│   └── exercise3-monitoring.md          📊 Monitoring and performance
└── README.md                            📖 This file
```

## 🎯 Learning Objectives

- **Master host parameter syntax:** `-h hostname -p port`
- **Client-side connection management:** Specify server details per command
- **Flexible Redis connections:** Connect to any Redis server
- **Production scenarios:** Authentication, timeouts, error handling
- **Performance monitoring:** Latency testing and analysis
- **Redis Insight integration:** Configure GUI with connection details

## 💡 Key Commands Pattern

```bash
# Basic pattern
redis-cli -h <host> -p <port> <command>

# Examples
redis-cli -h localhost -p 6379 PING
redis-cli -h redis.company.com -p 6379 INFO server
redis-cli -h 10.0.1.100 -p 6380 KEYS "*"

# With authentication
redis-cli -h secure-redis.com -p 6379 -a password PING

# With timeouts
redis-cli -h remote-server.com -p 6379 --connect-timeout 10 PING
```

## 🔧 Quick Examples

```bash
# Run basic examples (update host/port in script first)
npm run examples-basic

# Run business operations examples  
npm run examples-business

# Run output format examples
npm run examples-formats
```

## 📚 Reference Materials

- `reference/host-parameter-reference.md` - Complete parameter guide
- `reference/common-commands-with-host.md` - Command examples
- `examples/` - Practical working examples
- `exercises/` - Structured practice exercises

## 🏋️ Practice Exercises

1. **Exercise 1:** Basic connections and data operations
2. **Exercise 2:** Business scenarios (customers, orders, analytics)  
3. **Exercise 3:** Monitoring and performance analysis

## ⚠️ Important Notes

- **No Docker setup required** - connects to existing Redis server
- **Update examples** - Replace `localhost:6379` with your server details
- **Ask instructor** - Get correct hostname and port for your environment
- **Practice authentication** - If server requires password

## 🔍 Troubleshooting

1. **Connection refused:** Check hostname and port
2. **Timeout:** Use `--connect-timeout` for slow networks
3. **Authentication:** Use `-a password` if required
4. **DNS issues:** Try IP address instead of hostname

## 🎯 Key Skills Developed

✅ **Client-side host configuration**  
✅ **Flexible Redis server connections**  
✅ **Production connection handling**  
✅ **Performance monitoring techniques**  
✅ **Error handling and troubleshooting**  
✅ **Redis Insight GUI integration**  

## 📝 Before You Start

1. Get Redis server connection details from instructor
2. Test basic connectivity: `redis-cli -h [host] -p [port] PING`
3. Update examples with your server details
4. Open `lab5.md` and begin!

## 🏆 Success Criteria

By the end of this lab, you should be able to:
- Connect to any Redis server using host parameters
- Handle connection errors gracefully
- Monitor Redis performance effectively
- Configure Redis Insight with connection details
- Use different output formats for various needs

Ready to master Redis CLI host parameters? Start with `lab5.md`!
EOF

# Create .gitignore
cat > .gitignore << 'EOF'
# Logs
*.log
npm-debug.log*

# Dependencies
node_modules/
package-lock.json

# Environment files
.env
.env.local

# OS files
.DS_Store
Thumbs.db

# IDE files
.vscode/
.idea/
*.swp
*.swo

# Temporary files
*.tmp
*.temp
EOF

echo ""
echo "✅ Lab 5 generation completed successfully!"
echo ""
echo "📂 Project structure created:"
echo "   ${LAB_DIR}/"
echo "   ├── lab5.md                              📋 Main lab instructions"
echo "   ├── examples/                            💡 Practical examples"
echo "   │   ├── basic-host-examples.sh           🔗 Basic connections"
echo "   │   ├── business-operations-examples.sh  💼 Business scenarios"
echo "   │   └── output-formats-examples.sh       📊 Output formats"
echo "   ├── reference/                           📚 Reference materials"
echo "   │   ├── host-parameter-reference.md      📖 Complete parameter guide"
echo "   │   └── common-commands-with-host.md     💡 Command examples"
echo "   ├── exercises/                           🏋️ Practice exercises"
echo "   │   ├── exercise1-basic-connections.md   🔗 Basic connection practice"
echo "   │   ├── exercise2-business-data.md       💼 Business operations"
echo "   │   └── exercise3-monitoring.md          📊 Performance monitoring"
echo "   ├── package.json                         📦 NPM configuration"
echo "   ├── README.md                            📖 Quick start guide"
echo "   └── .gitignore                           🚫 Git ignore rules"
echo ""
echo "🎯 NEXT STEPS:"
echo "   1. cd ${LAB_DIR}"
echo "   2. Get Redis server details from instructor"
echo "   3. Test: redis-cli -h [hostname] -p [port] PING"
echo "   4. code lab5.md"
echo "   5. Start the lab!"
echo ""
echo "🔧 Quick Commands:"
echo "   npm run examples-basic        # Basic connection examples"
echo "   npm run examples-business     # Business operation examples"
echo "   npm run examples-formats      # Output format examples"
echo ""
echo "⚙️ Key Features:"
echo "   ✅ Client-side host parameter focus"
echo "   ✅ No Docker setup required"
echo "   ✅ Real Redis server connections"
echo "   ✅ Business-focused scenarios"
echo "   ✅ Cross-platform compatibility (Windows/Mac/Linux)"
echo "   ✅ Redis Insight integration"
echo "   ✅ Comprehensive reference materials"
echo "   ✅ Structured practice exercises"
echo ""
echo "💡 Remember: Replace 'localhost:6379' in examples with your actual Redis server details!"
echo ""
echo "🚀 Ready to master client-side Redis CLI host parameters!"