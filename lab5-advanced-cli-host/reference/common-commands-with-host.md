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
