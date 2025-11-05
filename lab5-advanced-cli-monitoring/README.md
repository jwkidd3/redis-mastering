# Lab 5: Advanced CLI Operations & Monitoring

**Duration:** 45 minutes
**Focus:** Production monitoring, performance analysis, and automation
**Prerequisites:** Lab 4 completed, Docker running

## 🎯 Learning Objectives

- Execute advanced CLI operations
- Implement monitoring and alerting
- Use Redis Insight for analysis
- Perform capacity planning
- Master troubleshooting techniques

## Part 1: Advanced CLI Operations

### Step 1: Environment Setup

```bash
# Start Redis container with persistence
docker run -d --name redis-lab5 \
  -p 6379:6379 \
  -v redis-lab5-data:/data \
  redis:7-alpine redis-server --appendonly yes

# Verify Redis is running
redis-cli ping

# Load comprehensive sample data
./scripts/load-production-data.sh
```

### Step 2: Pattern-Based Key Management

```bash
# Scan keys by pattern (production-safe)
redis-cli SCAN 0 MATCH "customer:*" COUNT 10

# Key statistics
redis-cli --bigkeys
redis-cli INFO keyspace
redis-cli DBSIZE

# Memory analysis
redis-cli MEMORY USAGE customer:1001
redis-cli MEMORY STATS
```

### Step 3: Bulk Operations

```bash
# Create bulk operations file
cat > bulk-ops.txt << 'EOF'
SET bulk:c:001 "Customer A"
SET bulk:c:002 "Customer B"
HSET bulk:policy:001 type "auto" premium "1200"
SADD bulk:premium:customers 001 003
ZADD bulk:scores 850 001 720 002 900 003
EOF

# Execute with pipelining
cat bulk-ops.txt | redis-cli --pipe

# Verify
redis-cli KEYS "bulk:*"
```

### Step 4: Lua Scripting

```bash
# Extend session TTLs atomically
redis-cli EVAL "
local keys = redis.call('KEYS', 'session:*')
local updated = 0
for i=1,#keys do
    local ttl = redis.call('TTL', keys[i])
    if ttl > 0 and ttl < 3600 then
        redis.call('EXPIRE', keys[i], 7200)
        updated = updated + 1
    end
end
return updated
" 0
```

See: `scripts/lua-examples.sh` for more Lua scripts

## Part 2: Production Monitoring

### Step 5: Real-Time Monitoring

```bash
# Start monitoring
./scripts/monitor-performance.sh
```

Monitors: memory, connections, ops/sec, cache hits, slow queries

### Step 6: Performance Analysis

```bash
# Run analysis
./scripts/analyze-memory.sh

# Check bottlenecks
redis-cli SLOWLOG GET 10
redis-cli INFO stats | grep ops_per_sec
redis-cli INFO memory

# Memory analysis
redis-cli MEMORY DOCTOR
redis-cli --bigkeys --i 0.1
```

### Step 7: Redis Insight

1. Open Redis Insight: `http://localhost:8001`
2. Connect to `localhost:6379`
3. Navigate to:
   - **Memory Analysis:** Identify largest keys
   - **CLI:** Execute monitoring commands
   - **Key Browser:** Examine data structures

## Part 3: Troubleshooting

### Step 8: Common Troubleshooting Scenarios

```bash
# High memory usage
redis-cli INFO memory | grep used_memory
redis-cli --bigkeys | head -20

# Slow operations
redis-cli CONFIG SET slowlog-log-slower-than 10000
redis-cli SLOWLOG GET 5

# Connection issues
redis-cli INFO clients
redis-cli CLIENT LIST
redis-cli CONFIG GET "maxclients"

# Persistence issues
redis-cli LASTSAVE
redis-cli INFO persistence
docker logs redis-lab5 | tail -20
```

### Step 9: Capacity Planning

```bash
# Resource usage
redis-cli INFO cpu
redis-cli INFO memory | grep peak_memory

# Data distribution
redis-cli EVAL "
local stats = {}
stats.total_keys = redis.call('DBSIZE')
stats.customers = #redis.call('KEYS', 'customer:*')
stats.policies = #redis.call('KEYS', 'policy:*')
return cjson.encode(stats)
" 0
```

## 🎓 Exercises

### Exercise 1: Performance Audit
1. Run monitoring for 5 minutes
2. Identify slowest operations
3. Analyze memory usage patterns
4. Document optimization opportunities

### Exercise 2: Troubleshooting
Simulate and resolve:
- High memory usage
- Slow queries
- Connection limits
- Persistence failures

### Exercise 3: Automation
Create script that:
1. Checks Redis health
2. Reports memory usage
3. Lists slow queries
4. Sends alerts if thresholds exceeded

## 📋 Key Commands

```bash
SCAN cursor MATCH pattern      # Pattern-based iteration
--bigkeys                       # Find largest keys
EVAL script numkeys [key...]   # Execute Lua script
SLOWLOG GET count              # View slow queries
INFO section                   # Server statistics
CLIENT LIST                    # Connection list
MEMORY USAGE key               # Key memory usage
MEMORY STATS                   # Memory statistics
```

## 💡 Best Practices

1. **Use SCAN, not KEYS:** Production-safe iteration
2. **Monitor continuously:** Catch issues early
3. **Set slow log threshold:** Identify bottlenecks
4. **Track memory usage:** Prevent OOM errors
5. **Use Lua for atomic ops:** Ensure consistency

## ✅ Lab Completion Checklist

- [ ] Executed pattern-based key operations
- [ ] Performed bulk operations with pipelining
- [ ] Created Lua scripts for atomic operations
- [ ] Monitored performance metrics
- [ ] Analyzed memory usage with Redis Insight
- [ ] Troubleshot common scenarios
- [ ] Created capacity planning reports

**Estimated time:** 45 minutes

## 📚 Additional Resources

- **Redis Commands:** `https://redis.io/commands/`
- **Redis Insight:** `https://redis.io/docs/stack/insight/`
- **Lua Scripting:** `https://redis.io/docs/manual/programmability/eval-intro/`
- **Monitoring:** `https://redis.io/docs/management/optimization/`
