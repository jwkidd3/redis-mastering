# Redis Insight Commands for Lab 10

## Using Redis Insight Command Line

### 1. Monitor Cache Activity
```bash
# Monitor real-time commands
MONITOR

# View cache statistics
INFO memory
INFO stats

# Check key patterns
KEYS policy:*
KEYS customer:*
KEYS quote:*
```

### 2. Analyze Cache Performance
```bash
# Check TTL for keys
TTL policy:12345
TTL customer:1001

# View key details
TYPE policy:12345
OBJECT ENCODING policy:12345
MEMORY USAGE policy:12345

# Check pipeline performance
PIPELINE
SET test:1 "value1"
SET test:2 "value2"
GET test:1
EXEC
```

### 3. Cache Invalidation Testing
```bash
# Test pattern matching
KEYS policy:*
DEL policy:12345
KEYS customer:*

# Test expiration
EXPIRE policy:12346 60
TTL policy:12346

# Test multi-key operations
MSET policy:1 "data1" policy:2 "data2"
MGET policy:1 policy:2
DEL policy:1 policy:2
```

### 4. Memory Analysis
```bash
# Memory usage by pattern
EVAL "
local keys = redis.call('KEYS', ARGV[1])
local total = 0
for i=1,#keys do
    total = total + redis.call('MEMORY', 'USAGE', keys[i])
end
return total
" 0 "policy:*"

# Check memory efficiency
MEMORY USAGE policy:12345 SAMPLES 5
MEMORY PURGE
```

### 5. Performance Monitoring
```bash
# Latency monitoring
LATENCY LATEST
LATENCY HISTORY command

# Slow query analysis
SLOWLOG GET 10
SLOWLOG RESET

# Client connections
CLIENT LIST
CLIENT INFO
```

### 6. Advanced Debugging
```bash
# Debug specific keys
DEBUG OBJECT policy:12345

# Check replication
INFO replication

# Analyze command stats
INFO commandstats

# Reset stats for clean testing
CONFIG RESETSTAT
```

## Redis Insight GUI Features

### 1. Memory Analysis Tab
- View memory usage by key pattern
- Analyze key distribution
- Monitor memory efficiency

### 2. Slow Log Viewer
- Track slow queries
- Analyze performance bottlenecks
- Optimize query patterns

### 3. CLI Integration
- Use built-in command line
- Execute monitoring commands
- Real-time command execution

### 4. Key Browser
- Navigate cache hierarchy
- View key TTLs and types
- Bulk operations on keys

### 5. Performance Profiler
- Real-time performance metrics
- Command latency analysis
- Throughput monitoring
