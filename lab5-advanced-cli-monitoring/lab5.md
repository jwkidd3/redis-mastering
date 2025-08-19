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

Execute these advanced CLI operations:

```redis
# Pattern-based operations
KEYS policy:*
SCAN 0 MATCH customer:* COUNT 100

# Advanced key analysis
redis-cli --scan --pattern "claim:*" | wc -l

# Bulk operations with pipeline
redis-cli --pipe < scripts/bulk-operations.txt

# Key migration and export
redis-cli --rdb dump.rdb

# Memory analysis by pattern
redis-cli --memkeys --memkeys-samples 1000
```

### Step 3: Advanced Data Operations

```redis
# Complex data operations
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

### Step 4: Redis Insight Advanced Analysis

**Open Redis Insight and connect to localhost:6379**

1. **Memory Analysis:**
   - Navigate to Analysis → Memory Analysis
   - Run analysis on all keys
   - Identify largest key patterns
   - Review memory distribution by data type

2. **Key Pattern Analysis:**
   - Use Browser to examine key hierarchies
   - Filter by patterns: `policy:*`, `customer:*`, `claim:*`
   - Analyze TTL distribution across key types

3. **Query Performance:**
   - Use Profiler to monitor real-time commands
   - Execute slow operations and observe impact
   - Identify optimization opportunities

---

## Part 2: Production Monitoring & Health Checks (15 minutes)

### Step 1: Real-time Monitoring Setup

```bash
# Terminal 1: Start comprehensive monitoring
./scripts/production-monitor.sh

# Terminal 2: Performance benchmarking
redis-benchmark -h localhost -p 6379 -c 50 -n 10000

# Terminal 3: Memory monitoring
watch -n 2 'redis-cli info memory | grep used_memory'
```

### Step 2: Advanced INFO Analysis

```redis
# Comprehensive server information
INFO all

# Specific sections analysis
INFO replication
INFO persistence
INFO stats
INFO commandstats
INFO clients
INFO memory

# Client connection analysis
CLIENT LIST
CLIENT INFO

# Command statistics
INFO commandstats | grep cmdstat
```

### Step 3: Performance Metrics Collection

Execute the monitoring script and analyze:

```bash
# Run the performance analysis
./scripts/performance-analysis.sh

# Check slow log
redis-cli SLOWLOG GET 10

# Monitor hit ratio
redis-cli info stats | grep keyspace

# Check memory fragmentation
redis-cli info memory | grep fragmentation
```

### Step 4: Redis Insight Production Dashboard

**In Redis Insight:**

1. **Overview Tab:**
   - Monitor memory usage trends
   - Check connected clients
   - Review command throughput

2. **Profiler Tab:**
   - Monitor live command execution
   - Identify slow operations
   - Track command patterns

3. **Memory Analysis:**
   - Analyze memory usage by key type
   - Identify memory optimization opportunities
   - Track largest keys and patterns

---

## Part 3: Operational Automation & Troubleshooting (10 minutes)

### Step 1: Automated Maintenance Scripts

```bash
# Daily maintenance automation
./scripts/daily-maintenance.sh

# Memory optimization
./scripts/memory-optimization.sh

# Data integrity verification
./scripts/data-integrity-check.sh
```

### Step 2: Advanced Troubleshooting

```redis
# Connection troubleshooting
redis-cli --latency -h localhost -p 6379

# Memory leak detection
redis-cli --bigkeys

# Performance bottleneck analysis
redis-cli --latency-history -h localhost -p 6379

# Client tracking
CLIENT TRACKING ON
```

### Step 3: Capacity Planning Analysis

Execute capacity planning analysis:

```bash
# Generate capacity report
./scripts/capacity-planning.sh

# Analyze growth trends
./analysis/trend-analysis.sh

# Generate recommendations
./scripts/optimization-recommendations.sh
```

### Step 4: Alert System Setup

```bash
# Configure monitoring alerts
./scripts/setup-alerts.sh

# Test alert thresholds
./scripts/test-alerts.sh

# Review alert logs
tail -f monitoring/alerts.log
```

---

## Part 4: Advanced Analysis & Reporting (5 minutes)

### Step 1: Generate Comprehensive Reports

```bash
# System health report
./scripts/health-report.sh > analysis/health-$(date +%Y%m%d).txt

# Performance analysis report
./scripts/performance-report.sh > analysis/performance-$(date +%Y%m%d).txt

# Capacity planning report
./scripts/capacity-report.sh > analysis/capacity-$(date +%Y%m%d).txt
```

### Step 2: Redis Insight Final Analysis

**In Redis Insight:**

1. **Export Analysis Results:**
   - Save memory analysis results
   - Export key distribution data
   - Download performance metrics

2. **Documentation Review:**
   - Review all created keys and their purposes
   - Verify data structure choices
   - Confirm TTL strategies

3. **Production Readiness Check:**
   - Verify monitoring is operational
   - Confirm alerts are configured
   - Review backup procedures

---

## 📋 Lab Summary

You have successfully completed Lab 5! You've mastered:

✅ **Advanced CLI Operations:** Complex scripting and automation for production  
✅ **Comprehensive Monitoring:** Real-time health checks and performance tracking  
✅ **Redis Insight Mastery:** Advanced analysis and troubleshooting capabilities  
✅ **Production Operations:** Maintenance automation and capacity planning  
✅ **Operational Excellence:** Alert systems and troubleshooting workflows  

## 🏆 Day 1 Completion

**Congratulations!** You now have comprehensive Redis CLI expertise and production monitoring skills. Ready for JavaScript integration in Day 2! 🚀

### ✅ Day 1 Labs Completed:
1. **Lab 1:** Redis Environment & CLI Basics
2. **Lab 2:** RESP Protocol Analysis  
3. **Lab 3:** Data Operations with Strings
4. **Lab 4:** Key Management & TTL Strategies
5. **Lab 5:** Advanced CLI Operations & Monitoring ← **Current**

### 🚀 Next: Day 2 - JavaScript Integration
- **Lab 6:** JavaScript Redis Client Setup
- **Lab 7:** Customer Profiles & Policy Management with Hashes
- **Lab 8:** Claims Processing Queues with Lists
- **Lab 9:** Analytics with Sets and Sorted Sets
- **Lab 10:** Advanced Caching Patterns

### 🎓 Skills Achieved in Day 1:
- ✅ Redis architecture understanding
- ✅ RESP protocol expertise
- ✅ CLI mastery for all data types
- ✅ Key management and TTL strategies
- ✅ Advanced monitoring and operations
- ✅ Production troubleshooting skills
- ✅ Redis Insight proficiency

---

**Excellent work completing Day 1! Ready to move on to JavaScript integration?**
