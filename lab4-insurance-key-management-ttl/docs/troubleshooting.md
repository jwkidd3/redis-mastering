# Lab 4 Troubleshooting Guide

## Common Issues and Solutions

### 1. TTL Not Working as Expected

**Problem:** Keys not expiring or TTL values incorrect

**Solutions:**
```bash
# Check current TTL
redis-cli TTL quote:auto:Q001

# Verify TTL was set correctly
redis-cli SETEX test:ttl 60 "test value"
redis-cli TTL test:ttl

# Check Redis time
redis-cli TIME

# Monitor TTL countdown
watch "redis-cli TTL quote:auto:Q001"

# Check if key expired
redis-cli EXISTS quote:auto:Q001  # Returns 0 if expired

# Verify TTL configuration
redis-cli CONFIG GET "maxmemory*"
```

### 2. Key Pattern Issues

**Problem:** Keys not following expected patterns or not found

**Solutions:**
```bash
# Verify key patterns exist
redis-cli KEYS "policy:*" | head -5
redis-cli KEYS "customer:*" | head -5

# Check specific key existence
redis-cli EXISTS policy:auto:100001:details
redis-cli EXISTS customer:CUST001:profile

# Use SCAN for production-safe pattern search
redis-cli SCAN 0 MATCH "policy:auto:*" COUNT 10

# Validate key structure
redis-cli TYPE policy:auto:100001:details
redis-cli GET policy:auto:100001:customer
```

### 3. Memory Usage Issues

**Problem:** High memory usage or inefficient key storage

**Solutions:**
```bash
# Check overall memory usage
redis-cli INFO memory | grep used_memory_human

# Analyze key memory usage (Redis 4.0+)
redis-cli MEMORY USAGE policy:auto:100001:details
redis-cli MEMORY USAGE customer:CUST001:profile

# Find large keys
redis-cli --bigkeys

# Check memory by key pattern
redis-cli EVAL "
local patterns = {'policy:*', 'customer:*', 'quote:*'}
local counts = {}
for i, pattern in ipairs(patterns) do
  local keys = redis.call('KEYS', pattern)
  table.insert(counts, pattern .. ': ' .. #keys .. ' keys')
end
return counts
" 0

# Monitor memory efficiency
redis-cli INFO memory | grep -E "used_memory_human|used_memory_peak_human"
```

### 4. Data Loading Script Issues

**Problem:** Sample data not loading properly

**Solutions:**
```bash
# Make script executable
chmod +x scripts/load-key-management-data.sh

# Run with verbose output
bash -x scripts/load-key-management-data.sh

# Check Redis connection
redis-cli ping

# Verify data loaded
redis-cli DBSIZE
redis-cli KEYS "*" | wc -l

# Check specific data types
redis-cli KEYS "policy:*" | wc -l
redis-cli KEYS "customer:*" | wc -l
redis-cli KEYS "quote:*" | wc -l

# Manual verification
redis-cli GET policy:auto:100001:details
redis-cli TTL quote:auto:Q001

# Clear and reload if needed
redis-cli FLUSHALL
./scripts/load-key-management-data.sh
```

### 5. TTL Monitoring Issues

**Problem:** Cannot monitor TTL properly or keys expiring unexpectedly

**Solutions:**
```bash
# Enable keyspace notifications for expiration events
redis-cli CONFIG SET notify-keyspace-events Ex

# Monitor expiration events
redis-cli PSUBSCRIBE '__keyevent@0__:expired' &

# Test expiration monitoring
redis-cli SETEX test:expire 5 "test value"
# Wait 5 seconds and check expiration event

# Check TTL distribution
./monitoring-tools/key-ttl-monitor.sh

# Manual TTL checking
redis-cli EVAL "
local keys = redis.call('KEYS', '*')
local with_ttl = 0
local without_ttl = 0
for i, key in ipairs(keys) do
  local ttl = redis.call('TTL', key)
  if ttl > 0 then
    with_ttl = with_ttl + 1
  elseif ttl == -1 then
    without_ttl = without_ttl + 1
  end
end
return 'With TTL: ' .. with_ttl .. ', Without TTL: ' .. without_ttl
" 0
```

### 6. Key Relationships Issues

**Problem:** Related keys not properly linked or inconsistent

**Solutions:**
```bash
# Verify key relationships
redis-cli GET policy:auto:100001:customer
redis-cli EXISTS customer:CUST001:profile

# Check cross-references
redis-cli MGET policy:auto:100001:customer customer:CUST001:policies

# Validate data consistency
redis-cli EVAL "
local policy_customer = redis.call('GET', 'policy:auto:100001:customer')
local customer_exists = redis.call('EXISTS', 'customer:' .. policy_customer .. ':profile')
return 'Policy customer: ' .. policy_customer .. ', Customer exists: ' .. customer_exists
" 0

# Find orphaned keys
redis-cli EVAL "
local policies = redis.call('KEYS', 'policy:*:customer')
local orphaned = {}
for i, key in ipairs(policies) do
  local customer_id = redis.call('GET', key)
  local customer_exists = redis.call('EXISTS', 'customer:' .. customer_id .. ':profile')
  if customer_exists == 0 then
    table.insert(orphaned, key .. ' -> ' .. customer_id)
  end
end
return orphaned
" 0
```

## Performance Optimization

### TTL Performance
```bash
# Test TTL performance with large datasets
time redis-cli EVAL "
for i=1,1000 do
  redis.call('SETEX', 'perf:test:' .. i, 300, 'test_value')
end
return 'Created 1000 keys with TTL'
" 0

# Monitor TTL operations
redis-cli monitor | grep -E "(SETEX|EXPIRE|TTL)"

# Check TTL distribution performance
time ./monitoring-tools/key-ttl-monitor.sh
```

### Memory Optimization
```bash
# Compare hash vs string memory usage
redis-cli HMSET test:hash:policy customer "CUST001" premium 1200 status "ACTIVE"
redis-cli SET test:string:policy:customer "CUST001"
redis-cli SET test:string:policy:premium 1200
redis-cli SET test:string:policy:status "ACTIVE"

redis-cli MEMORY USAGE test:hash:policy
redis-cli MEMORY USAGE test:string:policy:customer

# Cleanup test data
redis-cli DEL test:hash:policy test:string:policy:customer test:string:policy:premium test:string:policy:status
```

### Key Pattern Performance
```bash
# Test pattern scanning performance
time redis-cli KEYS "policy:*"
time redis-cli SCAN 0 MATCH "policy:*" COUNT 100

# Monitor key access patterns
redis-cli monitor | grep -E "(GET|SET|EXISTS)" | head -20
```

## Security and Compliance

### Session Security Issues
```bash
# Check session TTL values
redis-cli TTL session:customer:CUST001:portal
redis-cli TTL session:agent:AG001:workstation

# Verify session cleanup
redis-cli KEYS "session:*"
sleep 1
redis-cli KEYS "session:*"

# Test failed login lockout
redis-cli SETEX security:failed_logins:CUST001 300 "1"
redis-cli INCR security:failed_logins:CUST001
redis-cli GET security:failed_logins:CUST001
redis-cli TTL security:failed_logins:CUST001
```

### Data Retention Compliance
```bash
# Check compliance data TTL
redis-cli TTL audit:policy:auto:100001:change:20240818
redis-cli TTL audit:payment:transaction:TXN001

# Verify audit trail existence
redis-cli KEYS "audit:*"
redis-cli MGET audit:policy:auto:100001:change:20240818 audit:access:customer:CUST001:20240818
```

## Advanced Debugging

### Lua Script Debugging
```bash
# Test TTL analysis script
redis-cli EVAL "
local keys = redis.call('KEYS', 'quote:*')
local results = {}
for i, key in ipairs(keys) do
  local ttl = redis.call('TTL', key)
  table.insert(results, key .. ':' .. ttl)
end
return results
" 0

# Debug key relationship script
redis-cli EVAL "
local policy_keys = redis.call('KEYS', 'policy:*:customer')
local relationships = {}
for i, key in ipairs(policy_keys) do
  local customer = redis.call('GET', key)
  local customer_key = 'customer:' .. customer .. ':profile'
  local exists = redis.call('EXISTS', customer_key)
  table.insert(relationships, key .. ' -> ' .. customer .. ' (exists: ' .. exists .. ')')
end
return relationships
" 0
```

### Memory Usage Debugging
```bash
# Detailed memory analysis
redis-cli INFO memory | grep -E "used_memory|maxmemory|mem_fragmentation"

# Check for memory leaks
redis-cli EVAL "
local before = redis.call('INFO', 'memory')
for i=1,100 do
  redis.call('SETEX', 'temp:leak:' .. i, 10, 'test')
end
local after = redis.call('INFO', 'memory')
return 'Memory test completed'
" 0

# Monitor memory over time
watch "redis-cli INFO memory | grep used_memory_human"
```

## Getting Help

If you encounter issues not covered here:

1. **Check Redis logs:** `docker logs redis-insurance-lab4`
2. **Verify Redis configuration:** `redis-cli CONFIG GET "*"`
3. **Test basic connectivity:** `redis-cli ping`
4. **Check Docker status:** `docker ps | grep redis`
5. **Monitor operations:** `redis-cli monitor`
6. **Use monitoring tools:** `./monitoring-tools/key-ttl-monitor.sh`
7. **Ask instructor** for assistance

## Useful Debugging Commands

```bash
# Complete Redis status check
redis-cli INFO server
redis-cli INFO memory  
redis-cli INFO stats
redis-cli INFO keyspace

# TTL-specific debugging
redis-cli CONFIG GET "notify-keyspace-events"
redis-cli EVAL "return redis.call('TIME')" 0
redis-cli LASTSAVE

# Key management debugging
redis-cli DBSIZE
redis-cli KEYS "*" | wc -l
redis-cli SCAN 0 COUNT 1000 | wc -l

# Performance monitoring
redis-cli --latency-history -i 1 | head -10
redis-cli SLOWLOG GET 5
redis-cli CLIENT LIST | wc -l
```
