# Lab 5: Advanced CLI Operations & Monitoring

**Duration:** 45 minutes  
**Objective:** Master advanced Redis CLI features, implement comprehensive monitoring, and use production-grade operations

## 🎯 Learning Objectives

By the end of this lab, you will be able to:
- Execute advanced CLI operations for production systems
- Implement comprehensive monitoring and alerting
- Use Redis Insight for advanced analysis and troubleshooting
- Create automation scripts for operational tasks
- Perform capacity planning and performance optimization
- Master production troubleshooting techniques

---

## Part 1: Advanced CLI Scripting & Automation (15 minutes)

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

### Step 2: Advanced Key Management Operations

Execute these advanced CLI operations to understand pattern-based key management:

```bash
# Pattern-based key scanning
redis-cli SCAN 0 MATCH "customer:*" COUNT 10
redis-cli SCAN 0 MATCH "policy:*" COUNT 10
redis-cli SCAN 0 MATCH "session:*" COUNT 10

# Key analysis and statistics
redis-cli --bigkeys
redis-cli INFO keyspace
redis-cli DBSIZE

# Memory usage analysis
redis-cli MEMORY USAGE customer:1001
redis-cli MEMORY USAGE policy:POL001
redis-cli MEMORY STATS
```

### Step 3: Bulk Operations with Pipelining

```bash
# Create bulk operations file
cat > bulk-operations.txt << 'BULK'
SET bulk:customer:001 "Customer A"
SET bulk:customer:002 "Customer B"
SET bulk:customer:003 "Customer C"
HSET bulk:policy:001 type "auto" premium "1200"
HSET bulk:policy:002 type "home" premium "800"
HSET bulk:policy:003 type "life" premium "2400"
SADD bulk:premium:customers 001 003
SADD bulk:standard:customers 002
ZADD bulk:scores 850 001 720 002 900 003
LPUSH bulk:queue:processing "item1" "item2" "item3"
BULK

# Execute bulk operations with pipelining
cat bulk-operations.txt | redis-cli --pipe

# Verify bulk operations
redis-cli KEYS "bulk:*"
redis-cli HGETALL bulk:policy:001
redis-cli SMEMBERS bulk:premium:customers
redis-cli ZRANGE bulk:scores 0 -1 WITHSCORES
```

### Step 4: Lua Scripting for Atomic Operations

```bash
# Complex atomic operation using Lua
redis-cli EVAL "
local customers = redis.call('SMEMBERS', 'customers:premium')
local total_policies = 0
for i=1,#customers do
    local policies = redis.call('KEYS', 'policy:*')
    for j=1,#policies do
        local customer_id = redis.call('HGET', policies[j], 'customer_id')
        if customer_id == customers[i] then
            total_policies = total_policies + 1
        end
    end
end
return total_policies
" 0

# Batch update script
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

---

## Part 2: Production Monitoring & Health Checks (15 minutes)

### Step 5: Real-time Monitoring Dashboard

```bash
# Start production monitoring
./scripts/production-monitor.sh
```

The monitoring script provides:
- Real-time memory usage
- Client connections
- Operations per second
- Cache hit ratios
- Key expiration tracking
- Slow operation detection

### Step 6: Performance Analysis

```bash
# Run comprehensive performance analysis
./scripts/performance-analysis.sh

# View performance benchmarks
cat analysis/performance-report.txt

# Check for performance bottlenecks
redis-cli SLOWLOG GET 10
redis-cli INFO stats | grep ops_per_sec
redis-cli INFO replication
```

### Step 7: Memory and Capacity Analysis

```bash
# Generate capacity planning report
./scripts/capacity-planning.sh

# View memory usage breakdown
redis-cli INFO memory
redis-cli MEMORY DOCTOR

# Analyze data distribution
redis-cli --bigkeys --i 0.1
```

### Step 8: Redis Insight Analysis

1. **Open Redis Insight** and connect to `localhost:6379`

2. **Memory Analysis:**
   - Navigate to Memory Analysis tab
   - Identify largest keys and data types
   - Analyze memory usage patterns

3. **Command Execution:**
   - Use the CLI within Redis Insight
   - Execute monitoring commands
   - Compare with command-line results

4. **Key Browser:**
   - Browse the loaded dataset
   - Examine data structures
   - Verify TTL settings

---

## Part 3: Operational Automation & Troubleshooting (10 minutes)

### Step 9: Automated Health Checks

```bash
# Run comprehensive health report
./scripts/health-report.sh

# View health status
cat analysis/health-report.txt

# Check for common issues
redis-cli INFO server | grep redis_version
redis-cli CONFIG GET "*timeout*"
redis-cli INFO persistence
```

### Step 10: Alert System Configuration

```bash
# Setup monitoring alerts
./scripts/setup-alerts.sh

# Test alert system
./scripts/test-alerts.sh

# Check alert configuration
cat monitoring/alert-config.conf

# View alert logs
tail -f monitoring/alerts.log
```

### Step 11: Troubleshooting Scenarios

Practice troubleshooting common production issues:

```bash
# Scenario 1: High memory usage
redis-cli INFO memory | grep used_memory
redis-cli --bigkeys | head -20

# Scenario 2: Slow operations
redis-cli CONFIG SET slowlog-log-slower-than 10000
redis-cli SLOWLOG RESET
# Generate some load, then check
redis-cli SLOWLOG GET 5

# Scenario 3: Connection issues
redis-cli INFO clients
redis-cli CLIENT LIST
redis-cli CONFIG GET "maxclients"

# Scenario 4: Persistence issues
redis-cli LASTSAVE
redis-cli INFO persistence
docker logs redis-lab5 | tail -20
```

---

## Part 4: Advanced Analysis & Reporting (5 minutes)

### Step 12: Generate Production Reports

```bash
# Create comprehensive operational report
./scripts/generate-report.sh

# View the operational summary
cat analysis/operational-summary.txt
```

### Step 13: Capacity Planning Analysis

Review the capacity planning insights:

```bash
# View growth projections
cat analysis/capacity-report.txt

# Check current resource usage
redis-cli INFO cpu
redis-cli INFO memory | grep peak_memory

# Analyze data patterns
redis-cli EVAL "
local stats = {}
stats.total_keys = redis.call('DBSIZE')
stats.customers = #redis.call('KEYS', 'customer:*')
stats.policies = #redis.call('KEYS', 'policy:*')
stats.sessions = #redis.call('KEYS', 'session:*')
stats.claims = #redis.call('KEYS', 'claim:*')
return cjson.encode(stats)
" 0
```

---

## 🏆 Lab 5 Completion

### ✅ What You've Accomplished

- **Advanced CLI Mastery:** Pattern-based operations, bulk processing, Lua scripting
- **Production Monitoring:** Real-time dashboards, performance analysis, capacity planning
- **Operational Excellence:** Health checks, alert systems, troubleshooting procedures
- **Redis Insight Proficiency:** Memory analysis, performance monitoring, data exploration
- **Automation Skills:** Scripted operations, automated reporting, maintenance procedures

### 📊 Key Metrics Achieved

- Monitored production-scale dataset (50+ keys across multiple data types)
- Implemented comprehensive alerting (memory, performance, availability)
- Executed advanced CLI operations (scripting, pipelining, pattern matching)
- Created automated operational procedures
- Mastered Redis Insight for production analysis

### 🚀 Production Readiness

You now have the skills to:
- Operate Redis in production environments
- Monitor and troubleshoot performance issues
- Implement automated operational procedures
- Plan for capacity and growth
- Use advanced CLI features effectively

---

## 🎯 Day 1 Completion

**Congratulations!** You've completed all Day 1 labs:

### ✅ Day 1 Labs Completed:
1. **Lab 1:** Redis Environment & CLI Basics
2. **Lab 2:** RESP Protocol Analysis  
3. **Lab 3:** Data Operations with Strings
4. **Lab 4:** Key Management & TTL Strategies
5. **Lab 5:** Advanced CLI Operations & Monitoring ← **Current**

### 🚀 Next: Day 2 - JavaScript Integration
- **Lab 6:** JavaScript Redis Client
- **Lab 7:** Customer Profiles & Policy Management with Hashes
- **Lab 8:** Claims Processing Queues with Lists
- **Lab 9:** Analytics with Sets and Sorted Sets
- **Lab 10:** Advanced Caching Patterns

---

**Excellent work mastering Redis CLI operations!** You're ready for JavaScript integration in Day 2.

## 📚 Additional Resources

### Commands Used in This Lab
- `SCAN` - Pattern-based key iteration
- `--bigkeys` - Memory usage analysis
- `EVAL` - Lua script execution
- `SLOWLOG` - Performance monitoring
- `INFO` - Server statistics
- `CLIENT LIST` - Connection analysis
- `MEMORY` - Memory analysis commands

### Redis Insight Features
- Memory Analysis dashboard
- CLI integration
- Performance monitoring
- Key browser and editor
- Real-time metrics

### Production Best Practices
- Regular health monitoring
- Automated alert systems
- Capacity planning procedures
- Performance optimization
- Operational documentation
