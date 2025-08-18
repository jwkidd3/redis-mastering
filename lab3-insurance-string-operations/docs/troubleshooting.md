# Lab 3 Troubleshooting Guide

## Common Issues and Solutions

### 1. Atomic Operations Not Working

**Problem:** Concurrent operations causing race conditions

**Solutions:**
```bash
# Test atomic operations
redis-cli INCR test:counter
redis-cli INCR test:counter
redis-cli GET test:counter

# Use MULTI/EXEC for related operations
redis-cli MULTI
redis-cli INCR premium:test
redis-cli SET policy:test:status "updated"
redis-cli EXEC

# Verify transactions work
redis-cli MULTI
redis-cli SET test:transaction "value1"
redis-cli INCR test:counter
redis-cli EXEC
redis-cli MGET test:transaction test:counter
```

### 2. String Length Issues

**Problem:** Strings too long or causing memory issues

**Solutions:**
```bash
# Check string length limits
redis-cli CONFIG GET proto-max-bulk-len

# Monitor string sizes
redis-cli STRLEN policy:AUTO-100001
redis-cli MEMORY USAGE customer:CUST001

# Check memory usage
redis-cli INFO memory | grep used_memory_human

# Optimize large strings
redis-cli APPEND test:large "initial content"
redis-cli STRLEN test:large
```

### 3. Numeric Operations on Non-Numeric Strings

**Problem:** INCR/DECR operations failing on non-numeric values

**Solutions:**
```bash
# Verify value is numeric before operations
redis-cli GET premium:AUTO-100001
redis-cli TYPE premium:AUTO-100001

# Test numeric operations
redis-cli SET test:numeric 100
redis-cli INCR test:numeric

# Handle non-numeric strings
redis-cli SET test:string "abc"
redis-cli INCR test:string  # This will fail with error

# Reset to numeric value
redis-cli SET test:string 0
redis-cli INCR test:string
```

### 4. Key Pattern Issues

**Problem:** Keys not following expected patterns or not found

**Solutions:**
```bash
# Check key existence
redis-cli EXISTS policy:AUTO-100001
redis-cli EXISTS customer:CUST001

# Verify key patterns
redis-cli KEYS policy:*
redis-cli KEYS customer:*

# Use SCAN for large datasets (production safe)
redis-cli SCAN 0 MATCH policy:* COUNT 10

# Check key types
redis-cli TYPE policy:AUTO-100001
redis-cli TYPE premium:AUTO-100001
```

### 5. Data Loading Script Issues

**Problem:** Sample data not loading correctly

**Solutions:**
```bash
# Make script executable
chmod +x scripts/load-insurance-string-data.sh

# Run with verbose output
bash -x scripts/load-insurance-string-data.sh

# Check Redis connection
redis-cli ping

# Verify data loaded
redis-cli DBSIZE
redis-cli KEYS "*" | head -10

# Manual verification of specific keys
redis-cli GET policy:AUTO-100001
redis-cli GET customer:CUST001
redis-cli GET premium:AUTO-100001

# Clear and reload if needed
redis-cli FLUSHALL
./scripts/load-insurance-string-data.sh
```

### 6. String Concatenation Problems

**Problem:** APPEND operations not working as expected

**Solutions:**
```bash
# Test basic append
redis-cli SET test:append "initial"
redis-cli APPEND test:append " addition"
redis-cli GET test:append

# Check string length after append
redis-cli STRLEN test:append

# Verify append return value (should be new length)
redis-cli APPEND test:append " more"

# Handle missing keys (APPEND creates if not exists)
redis-cli APPEND nonexistent:key "new content"
redis-cli GET nonexistent:key
```

### 7. Performance Issues

**Problem:** String operations running slowly

**Solutions:**
```bash
# Monitor string operations
redis-cli monitor | grep -E "(SET|GET|APPEND|INCR)"

# Check slow operations
redis-cli CONFIG SET slowlog-log-slower-than 1000
redis-cli SLOWLOG GET 10

# Test individual operation performance
time redis-cli GET policy:AUTO-100001
time redis-cli SET test:performance "test data"

# Check memory usage patterns
redis-cli INFO memory | grep -E "(used_memory|maxmemory)"

# Monitor command statistics
redis-cli INFO commandstats | grep -E "(get|set|append|incr)"
```

## Performance Optimization

### String Size Management
```bash
# Check sizes of different string types
redis-cli MEMORY USAGE policy:AUTO-100001
redis-cli MEMORY USAGE customer:CUST001
redis-cli MEMORY USAGE activity:CUST001:log

# Compare storage efficiency
redis-cli SET test:json '{"name":"John","age":39,"email":"john@example.com"}'
redis-cli SET test:delimited "John|39|john@example.com"
redis-cli MEMORY USAGE test:json
redis-cli MEMORY USAGE test:delimited
```

### Batch Operations Testing
```bash
# Test individual vs batch operations
echo "Individual operations:"
time redis-cli eval "
for i=1,100 do
  redis.call('GET', 'policy:AUTO-100001')
end
" 0

echo "Batch operations:"
time redis-cli eval "
local keys = {}
for i=1,100 do
  table.insert(keys, 'policy:AUTO-100001')
end
redis.call('MGET', unpack(keys))
" 0
```

### Memory Usage Analysis
```bash
# Analyze memory usage by data type
redis-cli --bigkeys

# Check specific key memory usage
redis-cli MEMORY USAGE policy:AUTO-100001
redis-cli MEMORY USAGE customer:CUST001
redis-cli MEMORY USAGE premium:AUTO-100001

# Memory usage summary
redis-cli INFO memory | grep -E "used_memory_human|used_memory_peak_human"
```

## Data Validation

### String Content Validation
```bash
# Check string format
redis-cli GET customer:CUST001
redis-cli STRLEN customer:CUST001

# Validate numeric strings
redis-cli GET premium:AUTO-100001
redis-cli INCR test:validate:numeric  # Test if value can be incremented

# Check for empty or null values
redis-cli EXISTS policy:AUTO-100001
redis-cli GET policy:AUTO-100001
```

### Key Consistency Checks
```bash
# Verify related keys exist
redis-cli EXISTS policy:AUTO-100001
redis-cli EXISTS premium:AUTO-100001
redis-cli EXISTS customer:CUST001

# Check key relationships
redis-cli GET policy:AUTO-100001:customer
redis-cli EXISTS customer:CUST001

# Validate counters
redis-cli GET policy:counter:auto
redis-cli KEYS policy:AUTO-*
```

## Error Recovery

### Corrupted Data Recovery
```bash
# Backup current data state
redis-cli SAVE

# Check for corrupted keys
redis-cli KEYS "*" | while read key; do
  redis-cli TYPE "$key" >/dev/null || echo "Corrupted key: $key"
done

# Restore from known good state
redis-cli FLUSHALL
./scripts/load-insurance-string-data.sh
```

### Transaction Rollback Simulation
```bash
# Test transaction failure handling
redis-cli MULTI
redis-cli SET test:transaction:1 "value1"
redis-cli INCR test:transaction:counter
redis-cli SET test:transaction:2 "value2"
redis-cli DISCARD  # Cancel transaction

# Verify no changes were made
redis-cli GET test:transaction:1
redis-cli GET test:transaction:2
redis-cli GET test:transaction:counter
```

## Getting Help

If you encounter issues not covered here:

1. **Check Redis logs:** `docker logs redis-insurance-lab3`
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
