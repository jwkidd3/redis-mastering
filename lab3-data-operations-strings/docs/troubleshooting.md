# Redis String Operations Troubleshooting Guide
## Lab 3: Data Operations with Strings

This guide helps resolve common issues encountered during Redis string operations for data management.

## Common Issues and Solutions

### 1. Connection Issues

**Problem:** Cannot connect to Redis server
```bash
Error: Could not connect to Redis at 127.0.0.1:6379: Connection refused
```

**Solutions:**
```bash
# Check if Redis container is running
docker ps | grep redis

# Start Redis container if not running
docker run -d --name redis-lab3 -p 6379:6379 redis:7-alpine

# Verify Redis is responding
redis-cli ping
# Expected: PONG

# Check Docker logs for errors
docker logs redis-lab3
```

### 2. Numeric Operation Errors

**Problem:** Cannot perform INCR/INCRBY on non-numeric strings
```bash
redis-cli SET policy:premium "not_a_number"
redis-cli INCR policy:premium
# Error: ERR value is not an integer or out of range
```

**Solutions:**
```bash
# Check the current value and type
redis-cli GET policy:premium
redis-cli TYPE policy:premium

# Reset with numeric value
redis-cli SET policy:premium 1000

# Verify numeric operations work
redis-cli INCR policy:premium
redis-cli GET policy:premium
```

### 3. Memory Issues

**Problem:** String operations consuming excessive memory

**Solutions:**
```bash
# Check memory usage
redis-cli INFO memory

# Analyze individual key memory usage
redis-cli MEMORY USAGE customer:CUST001
redis-cli STRLEN customer:CUST001

# Find large keys
redis-cli --bigkeys | grep string

# Optimize large strings by splitting into multiple keys
```

### 4. Performance Issues

**Problem:** Slow string operations

**Solutions:**
```bash
# Use batch operations instead of individual commands
# Instead of:
SET key1 "value1"
SET key2 "value2"
SET key3 "value3"

# Use:
MSET key1 "value1" key2 "value2" key3 "value3"

# Monitor slow operations
redis-cli SLOWLOG GET 10

# Check operation latency
redis-cli --latency-history -i 1
```

### 5. Data Consistency Issues

**Problem:** Race conditions in concurrent operations

**Solutions:**
```bash
# Use atomic operations for financial calculations
INCRBY premium:AUTO-100001 150  # Atomic
DECRBY premium:AUTO-100001 100  # Atomic

# Use transactions for multi-step operations
MULTI
INCR policy:counter:auto
SET policy:AUTO-100003 "data"
SET premium:AUTO-100003 1400
EXEC
```

## Getting Help

If you encounter issues not covered here:

1. **Check Redis logs:** `docker logs redis-lab3`
2. **Verify Redis configuration:** `redis-cli CONFIG GET "*"`
3. **Test basic connectivity:** `redis-cli ping`
4. **Check Docker status:** `docker ps | grep redis`
5. **Monitor operations:** `redis-cli monitor`
6. **Ask instructor** for assistance

## Useful Debugging Commands

```bash
# Complete Redis status check
redis-cli INFO server
redis-cli INFO memory  
redis-cli INFO stats
redis-cli INFO commandstats

# String-specific debugging
redis-cli --bigkeys | grep string
redis-cli MEMORY USAGE policy:AUTO-100001
redis-cli DEBUG OBJECT policy:AUTO-100001

# Performance monitoring
redis-cli --latency-history -i 1 | head -10
redis-cli SLOWLOG GET 5

# Data verification
redis-cli DBSIZE
redis-cli KEYS "*" | wc -l
redis-cli KEYS "policy:*" | wc -l
```
