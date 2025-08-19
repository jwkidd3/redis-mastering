# Lab 4: Key Management & TTL Strategies

**Duration:** 45 minutes  
**Objective:** Master advanced key organization patterns for business entities and implement sophisticated TTL strategies for quotes, sessions, and temporary data using remote Redis host connections

## 🎯 Learning Objectives

By the end of this lab, you will be able to:
- Connect to Redis instances using remote host parameters
- Design and implement business-specific key naming conventions
- Create hierarchical key patterns for policy, customer, and claims organization
- Implement sophisticated quote expiration management with TTL strategies
- Build customer session management and cleanup automation
- Monitor key expiration patterns and optimize memory usage
- Apply key organization best practices for large-scale business databases

---

## Part 1: Remote Redis Connection & Key Organization (15 minutes)

### Step 1: Environment Setup with Remote Host Connection

**Important:** This lab uses a remote Redis instance instead of localhost. Replace `REDIS_HOST` and `REDIS_PORT` with the actual values provided by your instructor.

```bash
# Set your Redis connection parameters (replace with actual values)
export REDIS_HOST="your-redis-host.com"  # Replace with actual host
export REDIS_PORT="6379"                  # Replace with actual port
export REDIS_PASSWORD=""                  # Replace if password required

# Test connection to remote Redis instance
redis-cli -h $REDIS_HOST -p $REDIS_PORT ping

# If password is required:
# redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD ping

# Clear any existing data (be careful in shared environments!)
redis-cli -h $REDIS_HOST -p $REDIS_PORT FLUSHDB

# Load sample data for key management exercises
./scripts/load-key-management-data.sh
```

**Redis Insight Connection:**
1. Open Redis Insight
2. Add new database connection:
   - Host: `$REDIS_HOST`
   - Port: `$REDIS_PORT` 
   - Password: `$REDIS_PASSWORD` (if required)
   - Alias: "Lab 4 - Key Management"
3. Verify connection shows green status

### Step 2: Hierarchical Key Design for Business Entities

Business systems require well-organized key patterns for efficient management. All commands will use the remote host:

```bash
# Connect to Redis CLI with remote host
redis-cli -h $REDIS_HOST -p $REDIS_PORT

# === POLICY KEY HIERARCHY ===
# Pattern: policy:{type}:{number}:{attribute}
# Examples:
SET policy:auto:100001:details "2020 Toyota Camry - John Smith - $1,200 premium"
SET policy:auto:100001:customer "CUST001"
SET policy:auto:100001:status "active"
SET policy:auto:100001:premium "1200.00"

SET policy:home:200001:details "123 Main St - $350,000 coverage - $850 premium"
SET policy:home:200001:customer "CUST002"
SET policy:home:200001:status "active"
SET policy:home:200001:coverage "350000"

SET policy:life:300001:details "$500,000 Term Life - Alice Johnson - $45/month"
SET policy:life:300001:customer "CUST003"
SET policy:life:300001:status "pending"
SET policy:life:300001:beneficiary "spouse"

# === CUSTOMER KEY HIERARCHY ===
# Pattern: customer:{id}:{attribute}
SET customer:CUST001:name "John Smith"
SET customer:CUST001:email "john.smith@example.com"
SET customer:CUST001:phone "555-0101"
SET customer:CUST001:tier "premium"

SET customer:CUST002:name "Sarah Wilson"
SET customer:CUST002:email "sarah.wilson@example.com"
SET customer:CUST002:phone "555-0102"
SET customer:CUST002:tier "standard"

SET customer:CUST003:name "Alice Johnson"
SET customer:CUST003:email "alice.johnson@example.com"
SET customer:CUST003:phone "555-0103"
SET customer:CUST003:tier "premium"

# === CLAIMS KEY HIERARCHY ===
# Pattern: claim:{id}:{attribute}
SET claim:CL001:policy "policy:auto:100001"
SET claim:CL001:amount "2500.00"
SET claim:CL001:status "processing"
SET claim:CL001:date "2024-01-15"

SET claim:CL002:policy "policy:home:200001"
SET claim:CL002:amount "8500.00"
SET claim:CL002:status "approved"
SET claim:CL002:date "2024-01-10"

# === AGENT KEY HIERARCHY ===
# Pattern: agent:{id}:{attribute}
SET agent:AG001:name "Mike Thompson"
SET agent:AG001:territory "Northeast"
SET agent:AG001:specialty "auto"
SET agent:AG001:phone "555-0201"

SET agent:AG002:name "Lisa Chen"
SET agent:AG002:territory "West Coast"
SET agent:AG002:specialty "home"
SET agent:AG002:phone "555-0202"
```

### Step 3: Key Pattern Discovery and Analysis

```bash
# Discover all policy keys
KEYS policy:*

# Get all auto policies specifically
KEYS policy:auto:*

# Find customer attributes for a specific customer
KEYS customer:CUST001:*

# Production-safe pattern scanning (use instead of KEYS in production)
SCAN 0 MATCH "policy:auto:*" COUNT 10
SCAN 0 MATCH "customer:*" COUNT 10
SCAN 0 MATCH "claim:*" COUNT 10

# Count keys by pattern
EVAL "return #redis.call('KEYS', 'policy:*')" 0
EVAL "return #redis.call('KEYS', 'customer:*')" 0
EVAL "return #redis.call('KEYS', 'claim:*')" 0

# Verify key relationships
GET policy:auto:100001:customer
EXISTS customer:CUST001:name

# Check database size and patterns
DBSIZE
```

**Redis Insight Verification:**
1. Open Redis Insight and connect to your database
2. Go to Browser tab
3. Observe the hierarchical key structure
4. Use the CLI within Redis Insight to run the same commands

---

## Part 2: Quote Management with TTL Strategies (15 minutes)

### Step 4: Business-Appropriate TTL for Different Quote Types

Different types of quotes require different expiration times based on business requirements:

```bash
# Ensure you're connected to the remote Redis instance
redis-cli -h $REDIS_HOST -p $REDIS_PORT

# === AUTO QUOTES (5-minute TTL) ===
# Quick decision needed for competitive auto market
SETEX quote:auto:Q001 300 "2020 Honda Civic - 25-year-old driver - $145/month"
SETEX quote:auto:Q002 300 "2019 BMW 330i - 35-year-old driver - $195/month"
SETEX quote:auto:Q003 300 "2021 Ford F-150 - 45-year-old driver - $165/month"

# === HOME QUOTES (10-minute TTL) ===
# More time needed for property evaluation
SETEX quote:home:H001 600 "Single family home - $350,000 coverage - $850/year"
SETEX quote:home:H002 600 "Condominium - $200,000 coverage - $450/year"
SETEX quote:home:H003 600 "Townhouse - $275,000 coverage - $625/year"

# === LIFE QUOTES (30-minute TTL) ===
# Extended time for medical considerations and beneficiary decisions
SETEX quote:life:L001 1800 "$250,000 Term Life - 30-year-old - $25/month"
SETEX quote:life:L002 1800 "$500,000 Term Life - 40-year-old - $55/month"
SETEX quote:life:L003 1800 "$100,000 Whole Life - 25-year-old - $85/month"

# Check quote TTL values
TTL quote:auto:Q001
TTL quote:home:H001
TTL quote:life:L001

# Monitor quote expiration
# (Wait 60 seconds and check again to see TTL countdown)
sleep 60
TTL quote:auto:Q001
TTL quote:home:H001
TTL quote:life:L001
```

### Step 5: Session Management with TTL

```bash
# === CUSTOMER SESSION MANAGEMENT ===
# Pattern: session:{type}:{id}:{device}

# Customer portal sessions (30-minute TTL for security balance)
SETEX session:customer:CUST001:portal 1800 "authenticated_2024-01-15_10:30"
SETEX session:customer:CUST002:portal 1800 "authenticated_2024-01-15_10:45"
SETEX session:customer:CUST003:portal 1800 "authenticated_2024-01-15_11:00"

# Mobile app sessions (2-hour TTL for convenience)
SETEX session:customer:CUST001:mobile 7200 "mobile_token_abc123"
SETEX session:customer:CUST002:mobile 7200 "mobile_token_def456"

# === AGENT SESSION MANAGEMENT ===
# Agent workstation sessions (8-hour TTL for full work day)
SETEX session:agent:AG001:workstation 28800 "agent_session_active"
SETEX session:agent:AG002:workstation 28800 "agent_session_active"

# Agent mobile sessions (4-hour TTL for field work)
SETEX session:agent:AG001:mobile 14400 "field_session_active"
SETEX session:agent:AG002:mobile 14400 "field_session_active"

# Check session status
TTL session:customer:CUST001:portal
TTL session:agent:AG001:workstation

# List all active sessions
KEYS session:*

# Check specific session patterns
KEYS session:customer:*
KEYS session:agent:*
```

### Step 6: Temporary Data Management

```bash
# === DAILY METRICS (24-hour TTL) ===
SETEX metrics:daily:2024-01-15:quotes_generated 86400 "47"
SETEX metrics:daily:2024-01-15:policies_sold 86400 "12"
SETEX metrics:daily:2024-01-15:claims_processed 86400 "8"

# === WEEKLY REPORTS (7-day TTL) ===
SETEX report:weekly:2024-W03:sales_summary 604800 "policies: 85, premium: $45,200"
SETEX report:weekly:2024-W03:claims_summary 604800 "claims: 23, payout: $67,500"

# === MONTHLY DATA (30-day TTL) ===
SETEX analytics:monthly:2024-01:conversion_rate 2592000 "12.5%"
SETEX analytics:monthly:2024-01:customer_acquisition 2592000 "156"

# === SECURITY EVENTS (Variable TTL) ===
# Failed login attempts (15-minute lockout)
SETEX security:failed_login:CUST001 900 "attempt_count:3"

# Password reset tokens (10-minute TTL)
SETEX security:password_reset:CUST002:token_xyz789 600 "reset_pending"

# Account lockouts (30-minute TTL)
SETEX security:lockout:CUST003 1800 "locked_too_many_attempts"

# Check temporal data TTL
TTL metrics:daily:2024-01-15:quotes_generated
TTL report:weekly:2024-W03:sales_summary
TTL analytics:monthly:2024-01:conversion_rate
TTL security:failed_login:CUST001
```

**Redis Insight TTL Monitoring:**
1. In Redis Insight, go to Browser tab
2. Find keys with TTL (they show expiration time)
3. Use the CLI tab within Redis Insight to run TTL commands
4. Observe keys disappearing as they expire

---

## Part 3: Advanced TTL Monitoring and Optimization (15 minutes)

### Step 7: TTL Monitoring and Analysis with Remote Host

```bash
# Create monitoring script for remote host
./monitoring-tools/key-ttl-monitor.sh $REDIS_HOST $REDIS_PORT

# Check all keys with TTL information
echo "=== QUOTE TTL STATUS ==="
for key in $(redis-cli -h $REDIS_HOST -p $REDIS_PORT KEYS "quote:*"); do
    ttl=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT TTL "$key")
    echo "$key: $ttl seconds remaining"
done

# Check which keys will expire soon (next 60 seconds)
echo "=== KEYS EXPIRING SOON ==="
for key in $(redis-cli -h $REDIS_HOST -p $REDIS_PORT KEYS "*"); do
    ttl=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT TTL "$key")
    if [ "$ttl" -gt 0 ] && [ "$ttl" -lt 60 ]; then
        echo "WARNING: $key expires in $ttl seconds"
    fi
done

# Memory usage analysis on remote host
redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO memory | grep used_memory_human
redis-cli -h $REDIS_HOST -p $REDIS_PORT --bigkeys

# Check keyspace distribution
redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO keyspace
```

### Step 8: TTL Extension and Management

```bash
# Connect to remote host for TTL management
redis-cli -h $REDIS_HOST -p $REDIS_PORT

# Extend session TTL when user is active
EXPIRE session:customer:CUST001:portal 1800

# Remove TTL (make key persistent)
PERSIST quote:life:L001

# Set TTL on existing key
EXPIRE customer:CUST001:name 3600

# Check if TTL was applied
TTL customer:CUST001:name

# Atomic TTL update with value change
SET session:customer:CUST001:last_activity "2024-01-15_11:30" EX 1800

# Batch TTL operations for session cleanup
# Note: Adjusted for remote host usage
redis-cli -h $REDIS_HOST -p $REDIS_PORT KEYS "session:customer:*" | while read key; do
    redis-cli -h $REDIS_HOST -p $REDIS_PORT EXPIRE "$key" 1800
done
```

### Step 9: Advanced Key Management Patterns

```bash
# === NAMESPACE ORGANIZATION ===
# Check memory usage by namespace on remote host
redis-cli -h $REDIS_HOST -p $REDIS_PORT --bigkeys | grep policy
redis-cli -h $REDIS_HOST -p $REDIS_PORT --bigkeys | grep customer
redis-cli -h $REDIS_HOST -p $REDIS_PORT --bigkeys | grep quote
redis-cli -h $REDIS_HOST -p $REDIS_PORT --bigkeys | grep session

# === KEY LIFECYCLE MANAGEMENT ===
# Create key with immediate expiration for testing
SET test:key "value" EX 5
TTL test:key
# Wait and verify expiration
sleep 6
EXISTS test:key

# === BATCH OPERATIONS FOR KEY MANAGEMENT ===
# Count keys by pattern
redis-cli -h $REDIS_HOST -p $REDIS_PORT EVAL "return #redis.call('KEYS', 'policy:auto:*')" 0
redis-cli -h $REDIS_HOST -p $REDIS_PORT EVAL "return #redis.call('KEYS', 'quote:*')" 0

# === MEMORY OPTIMIZATION COMPARISON ===
# Compare string storage vs hash storage for policies
# Current approach (individual strings):
redis-cli -h $REDIS_HOST -p $REDIS_PORT MEMORY USAGE policy:auto:100001:details
redis-cli -h $REDIS_HOST -p $REDIS_PORT MEMORY USAGE policy:auto:100001:customer
redis-cli -h $REDIS_HOST -p $REDIS_PORT MEMORY USAGE policy:auto:100001:status

# Alternative hash approach (for comparison):
HSET policy:auto:100001 details "2020 Toyota Camry - John Smith - $1,200 premium" customer "CUST001" status "active" premium "1200.00"
redis-cli -h $REDIS_HOST -p $REDIS_PORT MEMORY USAGE policy:auto:100001

echo "Individual strings memory usage:"
redis-cli -h $REDIS_HOST -p $REDIS_PORT MEMORY USAGE policy:auto:100001:details
echo "Hash memory usage:"
redis-cli -h $REDIS_HOST -p $REDIS_PORT MEMORY USAGE policy:auto:100001
```

### Step 10: Performance and Production Considerations

```bash
# === PRODUCTION-SAFE KEY SCANNING ON REMOTE HOST ===
# Never use KEYS in production - use SCAN instead
SCAN 0 MATCH "policy:*" COUNT 10

# Continue scanning with cursor from previous result
SCAN 10 MATCH "policy:*" COUNT 10

# === TTL EVENT MONITORING SETUP ===
# Enable TTL expiration notifications
CONFIG SET notify-keyspace-events Ex

# In another terminal, monitor expiration events:
# redis-cli -h $REDIS_HOST -p $REDIS_PORT PSUBSCRIBE '__keyevent@0__:expired'

# === PERFORMANCE METRICS ===
# Check command statistics
redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO commandstats | grep ttl
redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO commandstats | grep expire

# Monitor memory efficiency
redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO memory | grep fragmentation
redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO memory | grep used_memory_human

# === CLEANUP AND VERIFICATION ===
# Verify all expected keys exist
EXISTS policy:auto:100001:details
EXISTS customer:CUST001:name
EXISTS quote:auto:Q001
EXISTS session:customer:CUST001:portal

# Final key count and memory usage
DBSIZE
redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO memory | grep used_memory_human

# Exit Redis CLI
exit
```

**Redis Insight Final Review:**
1. Use Redis Insight to review all created keys
2. Check the TTL values in the browser
3. Run the CLI commands within Redis Insight
4. Export key patterns for documentation

---

## 🏆 Lab Completion Checklist

By the end of this lab, you should have successfully:

- ✅ **Connected to remote Redis instance** using host and port parameters
- ✅ **Implemented hierarchical key naming** for policies, customers, claims, and agents
- ✅ **Created business-appropriate TTL strategies** for auto (5min), home (10min), and life (30min) quotes
- ✅ **Established session management** with appropriate TTL for customer (30min) and agent (8hr) sessions  
- ✅ **Set up temporal data management** with daily (24hr), weekly (7d), and monthly (30d) TTL patterns
- ✅ **Implemented security features** with TTL for failed logins, password resets, and lockouts
- ✅ **Monitored key expiration patterns** and analyzed memory usage across different key types
- ✅ **Applied production-safe key discovery** using SCAN instead of KEYS
- ✅ **Compared storage strategies** between individual strings and hash-based approaches
- ✅ **Configured TTL event monitoring** for production alerting
- ✅ **Optimized memory usage** through strategic key organization and TTL policies

---

## 🔧 Key Commands Summary

**Remote Connection:**
```bash
redis-cli -h $REDIS_HOST -p $REDIS_PORT
redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD  # with auth
```

**Hierarchical Key Management:**
```bash
SET policy:{type}:{number}:{attribute} "value"
SET customer:{id}:{attribute} "value"
SET claim:{id}:{attribute} "value"
KEYS policy:auto:*
SCAN 0 MATCH "customer:*" COUNT 10
```

**TTL Strategies:**
```bash
SETEX quote:auto:Q001 300 "5-minute quote"
SETEX quote:home:H001 600 "10-minute quote"  
SETEX quote:life:L001 1800 "30-minute quote"
TTL quote:auto:Q001
EXPIRE session:customer:CUST001 1800
PERSIST quote:life:L001
```

**Session Management:**
```bash
SETEX session:customer:{id}:portal 1800 "session_data"
SETEX session:agent:{id}:workstation 28800 "agent_session"
KEYS session:*
TTL session:customer:CUST001:portal
```

**Monitoring and Analysis:**
```bash
redis-cli -h $REDIS_HOST -p $REDIS_PORT --bigkeys
redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO memory | grep used_memory_human
redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO keyspace
CONFIG SET notify-keyspace-events Ex
redis-cli -h $REDIS_HOST -p $REDIS_PORT PSUBSCRIBE '__keyevent@0__:expired'
```

---

## 🆘 Troubleshooting

**Connection Issues:**
- Verify Redis host and port: `redis-cli -h $REDIS_HOST -p $REDIS_PORT ping`
- Check firewall/network connectivity
- Confirm authentication if required: `redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD ping`

**TTL Not Working:**
- Verify TTL with: `TTL keyname`
- Check if key exists: `EXISTS keyname`
- Ensure correct syntax: `SETEX key seconds value`

**Key Pattern Issues:**
- Use `KEYS pattern` for development only
- Use `SCAN 0 MATCH pattern COUNT 10` for production
- Verify relationships: `GET policy:auto:100001:customer`

**Redis Insight Connection:**
- Double-check host, port, and password in Redis Insight
- Test connection from command line first
- Ensure Redis Insight can reach the remote host

**See `docs/troubleshooting.md` for detailed troubleshooting guidance.**

---

## 📚 Additional Resources

- **Key Patterns Reference:** `docs/key-patterns-reference.md`
- **Practical Examples:** `examples/key-management-examples.md`
- **TTL Monitoring Tool:** `monitoring-tools/key-ttl-monitor.sh`
- **Troubleshooting Guide:** `docs/troubleshooting.md`

**Next Lab:** Lab 5 - Advanced CLI Operations for Business Monitoring

