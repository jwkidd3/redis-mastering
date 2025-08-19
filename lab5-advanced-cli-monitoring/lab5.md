# Lab 5: Advanced CLI Operations & Monitoring

**Duration:** 45 minutes  
**Objective:** Master advanced Redis CLI features and production operations

## 🐧 WSL Ubuntu Setup (Run First!)

**If you're using WSL Ubuntu, run this first to avoid "file not found" errors:**

```bash
# Install required packages
sudo apt update
sudo apt install -y redis-tools bc

# Fix script permissions and line endings
find . -name "*.sh" -exec chmod +x {} \;
find . -name "*.sh" -exec sed -i 's/\r$//' {} \;

# Test Redis tools
redis-cli --version
```

## 🎯 Learning Objectives

By the end of this lab, you will be able to:
- Execute advanced CLI operations for production systems
- Implement comprehensive monitoring and alerting
- Use Redis Insight for advanced analysis and troubleshooting
- Create automation scripts for operational tasks
- Perform capacity planning and performance optimization

---

## Part 1: Environment Setup (10 minutes)

### Step 1: Start Redis

```bash
# Start Redis container with persistence
docker run -d --name redis-lab5 \
  -p 6379:6379 \
  -v redis-lab5-data:/data \
  redis:7-alpine redis-server --appendonly yes

# Wait for Redis to start
sleep 3

# Verify Redis is running
redis-cli ping
```

### Step 2: Load Sample Data

```bash
# Load comprehensive sample data
./scripts/load-production-data.sh

# Verify data loaded
redis-cli DBSIZE
```

---

## Part 2: Advanced CLI Operations (15 minutes)

### Step 1: Pattern-Based Key Operations

```redis
# Pattern-based operations
KEYS policy:*
SCAN 0 MATCH customer:* COUNT 100

# Advanced key analysis
redis-cli --scan --pattern "claim:*" | wc -l

# Memory analysis by pattern
redis-cli --bigkeys
```

### Step 2: Advanced Data Operations

```redis
# Complex data operations with Lua
EVAL "return redis.call('keys', 'session:*')" 0

# Atomic batch operations
MULTI
HINCRBY analytics:daily claims_processed 1
HINCRBY analytics:daily policies_created 3
ZADD leaderboard:agents 150 "agent:001"
EXEC

# Advanced set operations
SUNIONSTORE all_customers customers:premium customers:standard
SINTERSTORE high_value_auto customers:premium policies:auto

# Complex sorted set queries
ZRANGEBYSCORE risk_scores 700 900 WITHSCORES LIMIT 0 10
```

### Step 3: Redis Insight Analysis

**Open Redis Insight and connect to localhost:6379**

1. **Memory Analysis:**
   - Navigate to Analysis → Memory Analysis
   - Run analysis on all keys
   - Identify largest key patterns

2. **Key Pattern Analysis:**
   - Use Browser to examine key hierarchies
   - Filter by patterns: `policy:*`, `customer:*`, `claim:*`

3. **Query Performance:**
   - Use Profiler to monitor real-time commands
   - Execute operations and observe performance

---

## Part 3: Production Monitoring (15 minutes)

### Step 1: Real-time Monitoring

```bash
# Start comprehensive monitoring (new terminal)
./scripts/production-monitor.sh

# Run performance benchmark (another terminal)
redis-benchmark -h localhost -p 6379 -c 50 -n 10000
```

### Step 2: Advanced INFO Analysis

```redis
# Comprehensive server information
INFO all

# Specific sections
INFO memory
INFO stats
INFO clients
INFO commandstats

# Client connection analysis
CLIENT LIST
```

### Step 3: Performance Analysis

```bash
# Run performance analysis
./scripts/performance-analysis.sh

# Check slow operations
redis-cli SLOWLOG GET 10

# Monitor cache hit ratio
redis-cli info stats | grep keyspace
```

---

## Part 4: Operational Excellence (5 minutes)

### Step 1: Health Monitoring

```bash
# Generate health report
./scripts/health-report.sh

# Check alert status
./scripts/check-alerts.sh
```

### Step 2: Capacity Planning

```bash
# Run capacity analysis
./scripts/capacity-planning.sh

# Review recommendations
cat analysis/capacity-report-*.txt
```

---

## 📋 Lab Summary

You have successfully completed Lab 5! You've mastered:

✅ **Advanced CLI Operations** - Complex scripting and automation  
✅ **Production Monitoring** - Real-time health and performance tracking  
✅ **Redis Insight Mastery** - Advanced analysis and troubleshooting  
✅ **Operational Excellence** - Maintenance and capacity planning  

## 🏆 Day 1 Completion

**Congratulations!** You now have comprehensive Redis CLI expertise. Ready for JavaScript integration in Day 2! 🚀

---

**Excellent work completing Day 1! Ready to move on to JavaScript integration?**
