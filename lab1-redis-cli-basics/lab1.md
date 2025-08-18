# Lab 1: Redis Environment & CLI Basics

**Duration:** 45 minutes  
**Objective:** Master Redis environment setup and CLI navigation for policy management applications

## 🎯 Learning Objectives

By the end of this lab, you will be able to:
- Navigate the Docker Redis environment for enterprise workloads
- Use Redis Insight GUI with policy and customer data
- Execute basic Redis CLI commands with business entities
- Understand RESP protocol communication for transactional operations
- Monitor business transactions in real-time
- Perform basic troubleshooting for production connectivity

---

## Part 1: Environment Setup & Sample Data (15 minutes)

### Step 1: Verify Docker Redis Environment

First, let's verify that Redis is running and set up enterprise-specific configuration:

```bash
# Check if Redis container is running
docker ps | grep redis

# If not running, start Redis container optimized for business workloads
docker run -d --name redis-lab \
  -p 6379:6379 \
  -v $(pwd)/sample-data:/data \
  redis:7-alpine redis-server --maxmemory 256mb --maxmemory-policy allkeys-lru

# Check Redis container logs
docker logs redis-lab
```

**Expected Output:**
```
Redis server v=7.2.0 sha=00000000:0 malloc=jemalloc-5.3.0 bits=64 build=c6e4fbeede1c73c5
Server initialized
Ready to accept connections tcp
```

### Step 2: Test Basic CLI Connectivity

```bash
# Test Redis CLI connection
redis-cli ping

# Should return: PONG
```

If you get "Could not connect", ensure Docker container is running on port 6379.

### Step 3: Load Sample Insurance Data

Let's populate Redis with sample insurance data for our exercises:

```bash
# Connect to Redis CLI
redis-cli

# Load sample insurance entities
SET policy:INS001 "Auto Insurance Policy - Toyota Camry"
SET policy:INS002 "Home Insurance Policy - 123 Main St"
SET policy:INS003 "Life Insurance Policy - Term 20Y"

SET customer:CUST001 "John Smith - DOB:1985-03-15 - Phone:555-0123"
SET customer:CUST002 "Jane Doe - DOB:1990-07-22 - Phone:555-0456"
SET customer:CUST003 "Bob Johnson - DOB:1978-11-08 - Phone:555-0789"

SET claim:CLM001 "Auto Accident - Claim Amount: $2,500 - Status: Processing"
SET claim:CLM002 "Water Damage - Claim Amount: $8,200 - Status: Approved"
SET claim:CLM003 "Theft - Claim Amount: $1,800 - Status: Under Review"

# Verify data loaded
KEYS *
DBSIZE
```

### Step 4: Launch and Configure Redis Insight

1. **Launch Redis Insight** from your desktop applications or start menu
2. If this is your first time, you'll see the welcome screen
3. Click **"Add Redis Database"**
4. Configure connection:
   - **Host:** localhost
   - **Port:** 6379
   - **Database Alias:** Insurance Redis Lab
5. Click **"Add Redis Database"**
6. Verify connection shows green status and you can see the insurance data

### Step 5: Explore Redis Insight with Insurance Data

Navigate through Redis Insight's sections with our insurance data:

- **Overview Tab:** View database statistics and memory usage
- **Browser Tab:** Browse insurance policies, customers, and claims
- **Workbench Tab:** Use the built-in CLI (we'll use this extensively)
- **Analysis Tab:** Analyze memory usage patterns of insurance data

---

## Part 2: Policy and Customer Data Operations with CLI (20 minutes)

### Step 1: Policy Management Operations

Open **two terminals**:
- Terminal 1: Regular redis-cli
- Terminal 2: `redis-cli monitor` (to observe RESP protocol)

In Terminal 1, execute these commands while observing Terminal 2:

```redis
# Policy retrieval and verification
GET policy:POL001
EXISTS policy:POL001
TYPE policy:POL001

# Policy information analysis
STRLEN policy:POL001

# Create new policy with expiration (temporary quote)
SETEX quote:TEMP001 300 "Auto Quote - Honda Civic - Premium: $1,200/year"
TTL quote:TEMP001

# Check quote status after a few seconds
TTL quote:TEMP001
GET quote:TEMP001
```

**Business Context:** 
- Policies are permanent data requiring persistent storage
- Quotes are temporary with TTL expiration (5 minutes = 300 seconds)
- Policy retrieval must be fast for customer service operations

### Step 2: Customer and Claims Counter Operations

```redis
# Customer interaction counters
SET customer:CUST001:login_count 0
INCR customer:CUST001:login_count
INCR customer:CUST001:login_count
GET customer:CUST001:login_count

# Claims processing counters
SET claims:daily_submissions 45
INCR claims:daily_submissions
INCRBY claims:daily_submissions 3
GET claims:daily_submissions

# Premium calculation updates
SET policy:POL001:premium 1200
INCRBY policy:POL001:premium 50
GET policy:POL001:premium
```

**Business Context:**
- Login counters track customer engagement
- Daily claims submissions help with workload management
- Premium adjustments happen frequently based on risk assessment

### Step 3: Batch Operations for Business Data

```redis
# Batch policy retrieval (common for customer portal)
MGET policy:POL001 policy:POL002 policy:POL003

# Batch customer information update
MSET customer:CUST001:last_login "2024-08-18" customer:CUST002:last_login "2024-08-17" customer:CUST003:last_login "2024-08-16"

# Verify batch updates
MGET customer:CUST001:last_login customer:CUST002:last_login customer:CUST003:last_login
```

**Business Context:**
- Customer portals often need multiple policy details simultaneously
- Batch operations improve performance for dashboard loading
- Last login tracking helps with security and customer service

### Step 4: Business Entity Key Pattern Operations

```redis
# Find all policies
KEYS policy:*

# Find all customers
KEYS customer:*

# Find all claims
KEYS claim:*

# Find specific customer data
KEYS customer:CUST001:*

# Use SCAN for production-safe pattern matching
SCAN 0 MATCH policy:* COUNT 10
```

**⚠️ Production Note:** KEYS command blocks Redis and should be avoided in production. Use SCAN instead.

---

## Part 3: Redis Insight Workbench & Monitoring (10 minutes)

### Step 1: Using Redis Insight Workbench

1. Open Redis Insight application
2. Navigate to **"Workbench"** tab
3. Use the integrated CLI to execute the following insurance scenarios:

```redis
# Create agent performance data
SET agent:AG001:policies_sold 23
SET agent:AG002:policies_sold 31
SET agent:AG003:policies_sold 19

# Check all agent performance
KEYS agent:*:policies_sold
MGET agent:AG001:policies_sold agent:AG002:policies_sold agent:AG003:policies_sold

# Create claims processing queue simulation
LPUSH claims:processing "CLM004:Auto:$3200" "CLM005:Home:$5800" "CLM006:Life:$75000"
LLEN claims:processing
LRANGE claims:processing 0 -1
```

### Step 2: Memory Analysis for Insurance Data

1. In Redis Insight, navigate to **"Analysis"** tab
2. Click **"Memory Analysis"** to analyze our business data
3. Observe memory usage patterns:
   - String data for policies and customers
   - Counter data for metrics
   - List data for claims processing

### Step 3: Real-time Monitoring

1. In Terminal 2 (monitor mode), observe RESP protocol for:

```redis
# Execute in Terminal 1 while monitoring Terminal 2
SET claim:CLM007 "Property Damage - Amount: $4,500 - Priority: High"
GET claim:CLM007
INCR daily:claim_count
EXPIRE claim:CLM007 86400
```

**Observe in Monitor:**
- RESP command format for business data
- Protocol efficiency for high-volume operations
- Real-time transaction monitoring capabilities

---

## 🏆 Challenge Exercises (Optional - if time permits)

### Challenge 1: Quote Expiration System

Create a temporary quote system with different expiration times:

```redis
# 5-minute auto quote
SETEX quote:AUTO:Q001 300 "Toyota Prius - Premium: $950/year"

# 10-minute home quote  
SETEX quote:HOME:Q001 600 "Condo Policy - Premium: $600/year"

# 30-minute life quote (more complex, needs more time)
SETEX quote:LIFE:Q001 1800 "Term Life 500K - Premium: $35/month"

# Monitor expiration times
TTL quote:AUTO:Q001
TTL quote:HOME:Q001  
TTL quote:LIFE:Q001
```

### Challenge 2: Claims Priority Management

```redis
# Set claims with priority indicators
SET claim:CLM008:priority "HIGH:Fire Damage:$25000"
SET claim:CLM009:priority "MEDIUM:Fender Bender:$1200"
SET claim:CLM010:priority "LOW:Windshield Chip:$200"

# Use pattern matching to find high-priority claims
KEYS claim:*:priority
```

### Challenge 3: Daily Business Metrics

```redis
# Create daily metrics tracking
SET metrics:2024-08-18:new_policies 12
SET metrics:2024-08-18:claims_filed 8
SET metrics:2024-08-18:quotes_generated 45

# Calculate daily totals
INCRBY metrics:2024-08-18:premium_collected 15000
GET metrics:2024-08-18:premium_collected
```

---

## 📚 Key Takeaways

✅ **Redis Environment**: Successfully set up and verified Docker Redis for business workloads  
✅ **Business Data Modeling**: Learned key patterns for policies, customers, and claims  
✅ **CLI Mastery**: Executed essential Redis CLI commands with business data  
✅ **RESP Protocol**: Observed Redis protocol communication for business operations  
✅ **Redis Insight**: Explored GUI tools for business data management and monitoring  
✅ **Performance Awareness**: Understanding of TTL, counters, and batch operations for enterprise systems

## 🔗 Next Steps

In **Lab 2: RESP Protocol for Business Data Processing**, you'll dive deeper into:
- Advanced RESP protocol analysis for business transactions
- Protocol-level debugging for system performance
- Real-time monitoring of data operations
- Business-specific protocol optimization patterns

---

## 📖 Additional Resources

- [Redis Commands Reference](https://redis.io/commands)
- [RESP Protocol Specification](https://redis.io/docs/reference/protocol-spec/)
- [Redis Insight Documentation](https://redis.io/docs/stack/insight/)
- [Redis Best Practices for Financial Services](https://redis.io/docs/stack/compliance/)

## 🔧 Troubleshooting

**Connection Issues:**
```bash
# Check if Redis is running
docker ps | grep redis

# Restart Redis container if needed
docker restart redis-insurance

# Check Redis logs
docker logs redis-insurance
```

**Data Issues:**
```bash
# Clear all data if needed to restart lab
redis-cli FLUSHALL

# Reload sample data using the script
./scripts/load-insurance-sample-data.sh
```

**Redis Insight Issues:**
- Ensure Redis Insight is connected to localhost:6379
- Refresh the connection if data doesn't appear
- Check firewall settings if connection fails
