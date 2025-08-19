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
