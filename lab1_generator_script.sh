#!/bin/bash

# Lab 1 Content Generator Script
# Generates complete content and code for Lab 1: Redis Environment & CLI for Insurance Systems
# Duration: 45 minutes
# Focus: Docker setup, Redis Insight, CLI commands, RESP protocol (NO JAVASCRIPT)

set -e

LAB_DIR="lab1-redis-cli-basics"
LAB_NUMBER="1"
LAB_TITLE="Redis Environment & CLI Basics"
LAB_DURATION="45"

echo "🚀 Generating Lab ${LAB_NUMBER}: ${LAB_TITLE}"
echo "📅 Duration: ${LAB_DURATION} minutes"
echo "🎯 Focus: Redis CLI, Redis Insight, and core data operations"
echo ""

# Create lab directory structure
mkdir -p ${LAB_DIR}
cd ${LAB_DIR}

echo "📁 Creating lab directory structure..."
mkdir -p {scripts,docs,examples,sample-data}

# Create main lab instructions markdown file
echo "📋 Creating lab1.md..."
cat > lab1.md << 'EOF'
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
EOF

# Create sample data loading script
echo "📊 Creating scripts/load-insurance-sample-data.sh..."
cat > scripts/load-insurance-sample-data.sh << 'EOF'
#!/bin/bash

# Insurance Sample Data Loader
# Loads comprehensive insurance data for Redis CLI practice

echo "🏢 Loading Insurance Sample Data into Redis..."

redis-cli << 'REDIS_EOF'
# Clear existing data
FLUSHALL

# === INSURANCE POLICIES ===
SET policy:INS001 "Auto Insurance - Toyota Camry 2020 - Customer: CUST001 - Premium: $1,200/year"
SET policy:INS002 "Home Insurance - 123 Main St - Customer: CUST002 - Premium: $800/year"  
SET policy:INS003 "Life Insurance - Term 20Y 500K - Customer: CUST003 - Premium: $420/year"
SET policy:INS004 "Auto Insurance - Honda Civic 2019 - Customer: CUST001 - Premium: $950/year"
SET policy:INS005 "Renters Insurance - Downtown Apt - Customer: CUST004 - Premium: $200/year"

# === CUSTOMERS ===
SET customer:CUST001 "John Smith - DOB: 1985-03-15 - Phone: 555-0123 - Email: john.smith@email.com"
SET customer:CUST002 "Jane Doe - DOB: 1990-07-22 - Phone: 555-0456 - Email: jane.doe@email.com"
SET customer:CUST003 "Bob Johnson - DOB: 1978-11-08 - Phone: 555-0789 - Email: bob.johnson@email.com"
SET customer:CUST004 "Alice Brown - DOB: 1995-09-12 - Phone: 555-0321 - Email: alice.brown@email.com"

# === CLAIMS ===
SET claim:CLM001 "Auto Accident - Policy: INS001 - Amount: $2,500 - Status: Processing - Date: 2024-08-15"
SET claim:CLM002 "Water Damage - Policy: INS002 - Amount: $8,200 - Status: Approved - Date: 2024-08-10"
SET claim:CLM003 "Theft - Policy: INS005 - Amount: $1,800 - Status: Under Review - Date: 2024-08-12"
SET claim:CLM004 "Hail Damage - Policy: INS001 - Amount: $3,200 - Status: Denied - Date: 2024-08-08"

# === AGENTS ===
SET agent:AG001 "Michael Davis - Policies Sold: 23 - Commission: $15,200 - Region: North"
SET agent:AG002 "Sarah Wilson - Policies Sold: 31 - Commission: $22,400 - Region: South"
SET agent:AG003 "Tom Miller - Policies Sold: 19 - Commission: $12,800 - Region: East"
SET agent:AG004 "Lisa Chen - Policies Sold: 27 - Commission: $18,900 - Region: West"

# === TEMPORARY QUOTES (with TTL) ===
SETEX quote:AUTO:Q001 300 "Honda Pilot 2023 - Estimated Premium: $1,350/year - Valid: 5 minutes"
SETEX quote:HOME:Q001 600 "Suburban Home - Estimated Premium: $1,200/year - Valid: 10 minutes"
SETEX quote:LIFE:Q001 1800 "Term Life 750K - Estimated Premium: $65/month - Valid: 30 minutes"

# === COUNTERS ===
SET daily:policies_created 8
SET daily:claims_submitted 12
SET daily:quotes_generated 45
SET daily:customer_logins 127

# === CUSTOMER METRICS ===
SET customer:CUST001:login_count 15
SET customer:CUST002:login_count 8
SET customer:CUST003:login_count 22
SET customer:CUST004:login_count 3

# === POLICY METRICS ===
SET policy:INS001:claims_count 2
SET policy:INS002:claims_count 1
SET policy:INS003:claims_count 0
SET policy:INS004:claims_count 0
SET policy:INS005:claims_count 1

# === PREMIUM TRACKING ===
SET premium:collected:2024-08-18 25600
SET premium:collected:2024-08-17 31200
SET premium:collected:2024-08-16 28900

REDIS_EOF

echo "✅ Insurance sample data loaded successfully!"
echo ""
echo "📊 Data Summary:"
redis-cli << 'REDIS_EOF'
ECHO "Policies:"
KEYS policy:*
ECHO ""
ECHO "Customers:" 
KEYS customer:*
ECHO ""
ECHO "Claims:"
KEYS claim:*
ECHO ""
ECHO "Agents:"
KEYS agent:*
ECHO ""
ECHO "Active Quotes:"
KEYS quote:*
ECHO ""
ECHO "Database Size:"
DBSIZE
REDIS_EOF

echo ""
echo "🎯 Ready for Lab 1 exercises!"
EOF

chmod +x scripts/load-insurance-sample-data.sh

# Create Redis configuration for insurance workloads
echo "⚙️ Creating redis-insurance.conf..."
cat > redis-insurance.conf << 'EOF'
# Redis Configuration for Insurance Applications
# Optimized for policy management, claims processing, and customer data

# === MEMORY CONFIGURATION ===
maxmemory 256mb
maxmemory-policy allkeys-lru

# === PERSISTENCE CONFIGURATION ===
# Save snapshots for insurance data protection
save 900 1     # Save if at least 1 key changed in 900 seconds
save 300 10    # Save if at least 10 keys changed in 300 seconds  
save 60 10000  # Save if at least 10000 keys changed in 60 seconds

# === NETWORK CONFIGURATION ===
bind 127.0.0.1
port 6379
timeout 0
tcp-keepalive 300

# === LOGGING ===
loglevel notice
logfile ""

# === CLIENT CONNECTION ===
# Allow sufficient connections for insurance portal users
maxclients 10000

# === PERFORMANCE TUNING ===
# Optimize for insurance data access patterns
hash-max-ziplist-entries 512
hash-max-ziplist-value 64
list-max-ziplist-size -2
set-max-intset-entries 512
zset-max-ziplist-entries 128
zset-max-ziplist-value 64

# === SECURITY ===
# Basic security for insurance data
# requirepass your_insurance_redis_password_here
# rename-command FLUSHDB ""
# rename-command FLUSHALL ""
EOF

# Create troubleshooting guide
echo "🔧 Creating docs/troubleshooting.md..."
cat > docs/troubleshooting.md << 'EOF'
# Lab 1 Troubleshooting Guide

## Common Issues and Solutions

### 1. Redis Connection Failed

**Problem:** `Could not connect to Redis at 127.0.0.1:6379: Connection refused`

**Solutions:**
```bash
# Check if Docker is running
docker --version

# Check if Redis container is running
docker ps | grep redis

# Start Redis container if not running
docker run -d --name redis-insurance -p 6379:6379 redis:7-alpine

# Check container logs
docker logs redis-insurance
```

### 2. Redis Insight Connection Issues

**Problem:** Redis Insight cannot connect to localhost:6379

**Solutions:**
1. Verify Redis is running: `redis-cli ping`
2. Check port is accessible: `netstat -an | grep 6379`
3. Restart Redis Insight application
4. Try connecting to `127.0.0.1` instead of `localhost`

### 3. Data Not Loading

**Problem:** Sample insurance data not visible in CLI or Redis Insight

**Solutions:**
```bash
# Reload sample data
./scripts/load-insurance-sample-data.sh

# Verify data loaded
redis-cli KEYS "*"
redis-cli DBSIZE

# Check specific keys
redis-cli GET policy:INS001
```

### 4. TTL/Expiration Issues

**Problem:** Quotes expire too quickly or don't expire

**Solutions:**
```bash
# Check remaining TTL
redis-cli TTL quote:AUTO:Q001

# Create new quote with longer TTL
redis-cli SETEX quote:TEST001 600 "Test quote - 10 minutes"

# Monitor TTL countdown
watch "redis-cli TTL quote:TEST001"
```

### 5. Performance Issues

**Problem:** Commands running slowly

**Solutions:**
```bash
# Check Redis performance
redis-cli INFO stats

# Monitor command execution
redis-cli monitor

# Check memory usage
redis-cli INFO memory

# Use SCAN instead of KEYS for large datasets
redis-cli SCAN 0 MATCH policy:* COUNT 10
```

### 6. Docker Issues

**Problem:** Docker container won't start or keeps stopping

**Solutions:**
```bash
# Remove existing container
docker rm -f redis-insurance

# Start with verbose logging
docker run -d --name redis-insurance -p 6379:6379 redis:7-alpine redis-server --loglevel verbose

# Check detailed logs
docker logs -f redis-insurance

# Check Docker resource usage
docker stats redis-insurance
```

## Getting Help

If you encounter issues not covered here:

1. **Check Redis logs:** `docker logs redis-insurance`
2. **Verify network connectivity:** `telnet localhost 6379`
3. **Test basic commands:** `redis-cli ping`
4. **Restart services:** Docker Desktop, Redis Insight
5. **Ask instructor** for assistance

## Useful Commands for Debugging

```bash
# Complete environment check
redis-cli ping
redis-cli INFO server
redis-cli DBSIZE
redis-cli KEYS "*" | head -10

# Performance monitoring
redis-cli INFO stats | grep instantaneous
redis-cli INFO memory | grep used_memory_human

# Connection monitoring
redis-cli INFO clients
```
EOF

# Create README
echo "📚 Creating README.md..."
cat > README.md << 'EOF'
# Lab 1: Redis Environment & CLI for Insurance Systems

**Duration:** 45 minutes  
**Focus:** Redis CLI, Redis Insight, and insurance data operations  
**Industry:** Insurance applications and workflows

## 📁 Project Structure

```
lab1-redis-insurance-cli/
├── lab1.md                           # Complete lab instructions (START HERE)
├── redis-insurance.conf              # Redis config optimized for insurance
├── scripts/
│   └── load-insurance-sample-data.sh # Insurance sample data loader
├── docs/
│   └── troubleshooting.md            # Troubleshooting guide
├── examples/                         # CLI command examples
├── insurance-data/                   # Sample insurance datasets
└── README.md                         # This file
```

## 🚀 Quick Start

1. **Read Instructions:** Open `lab1.md` for complete lab guidance
2. **Start Redis:** `docker run -d --name redis-insurance -p 6379:6379 redis:7-alpine`
3. **Load Sample Data:** `./scripts/load-insurance-sample-data.sh`
4. **Test Connection:** `redis-cli ping`
5. **Open Redis Insight:** Launch from applications menu

## 🏢 Insurance Data Focus

This lab uses realistic insurance industry data:

- **Policies:** Auto, Home, Life, Renters insurance
- **Customers:** Customer profiles with contact information
- **Claims:** Various claim types with status tracking
- **Agents:** Agent performance and commission data
- **Quotes:** Temporary quotes with realistic TTL expiration
- **Metrics:** Daily counters for business operations

## 🎯 Lab Objectives

✅ Master Redis CLI navigation with insurance data  
✅ Understand RESP protocol for insurance operations  
✅ Use Redis Insight for insurance data visualization  
✅ Implement key patterns for insurance entities  
✅ Practice TTL management for quotes and sessions  
✅ Monitor performance for insurance workloads

## 📝 Key Insurance Patterns Covered

- **Policy Management:** `policy:INS001`, `policy:INS002`
- **Customer Data:** `customer:CUST001`, `customer:CUST002`
- **Claims Processing:** `claim:CLM001`, `claim:CLM002`
- **Agent Tracking:** `agent:AG001`, `agent:AG002`
- **Quote Expiration:** `quote:AUTO:Q001` (with TTL)
- **Business Metrics:** `daily:policies_created`, `premium:collected`

## 🔧 Commands Quick Reference

```bash
# Environment Setup
docker run -d --name redis-insurance -p 6379:6379 redis:7-alpine
./scripts/load-insurance-sample-data.sh

# Basic Operations
redis-cli ping
redis-cli KEYS policy:*
redis-cli GET policy:INS001
redis-cli INCR daily:policies_created

# Monitoring
redis-cli monitor
redis-cli INFO memory
redis-cli DBSIZE
```

## 🆘 Troubleshooting

**Connection Issues:**
```bash
# Check Redis status
docker ps | grep redis
redis-cli ping

# Restart if needed
docker restart redis-insurance
```

**Data Issues:**
```bash
# Reload sample data
./scripts/load-insurance-sample-data.sh

# Verify data
redis-cli KEYS "*" | wc -l
```

**Detailed troubleshooting:** See `docs/troubleshooting.md`

## 🎓 Learning Path

This lab is part of the Redis for Insurance series:

1. **Lab 1:** Environment & CLI Basics ← *You are here*
2. **Lab 2:** RESP Protocol for Insurance Data
3. **Lab 3:** Insurance Data Operations with Strings
4. **Lab 4:** Insurance Key Management & TTL
5. **Lab 5:** Advanced CLI Operations for Insurance

---

**Ready to start?** Open `lab1.md` and begin exploring Redis with insurance data! 🚀
EOF

# Create CLI examples
echo "⚡ Creating examples/insurance-cli-examples.txt..."
cat > examples/insurance-cli-examples.txt << 'EOF'
# Insurance Redis CLI Examples
# Copy and paste these commands into redis-cli for practice

# === POLICY OPERATIONS ===
# View all policies
KEYS policy:*

# Get specific policy details
GET policy:INS001
GET policy:INS002

# Check if policy exists
EXISTS policy:INS999

# Get policy data type
TYPE policy:INS001

# === CUSTOMER OPERATIONS ===
# Customer information retrieval
GET customer:CUST001
MGET customer:CUST001 customer:CUST002 customer:CUST003

# Customer login tracking
INCR customer:CUST001:login_count
GET customer:CUST001:login_count

# === CLAIMS PROCESSING ===
# View all claims
KEYS claim:*

# Claim status checking
GET claim:CLM001
GET claim:CLM002

# Claims counter management
SET daily:claims_submitted 0
INCR daily:claims_submitted
INCRBY daily:claims_submitted 5

# === QUOTE MANAGEMENT ===
# Create temporary quotes with expiration
SETEX quote:AUTO:Q100 300 "BMW X5 - Premium: $1,800/year"
SETEX quote:HOME:Q200 600 "Beach House - Premium: $2,500/year"

# Check quote expiration
TTL quote:AUTO:Q100
TTL quote:HOME:Q200

# === AGENT PERFORMANCE ===
# Agent data retrieval
GET agent:AG001
KEYS agent:*

# Performance counters
SET agent:AG001:policies_sold 25
INCR agent:AG001:policies_sold

# === PREMIUM CALCULATIONS ===
# Premium tracking
SET policy:INS001:premium 1200
INCRBY policy:INS001:premium 100
GET policy:INS001:premium

# Daily premium collection
SET premium:collected:today 0
INCRBY premium:collected:today 1200
INCRBY premium:collected:today 800
GET premium:collected:today

# === BATCH OPERATIONS ===
# Multiple policy lookup (customer portal scenario)
MGET policy:INS001 policy:INS002 policy:INS003

# Batch customer updates
MSET customer:CUST001:last_login "2024-08-18" customer:CUST002:last_login "2024-08-18"

# === PATTERN MATCHING ===
# Find customer-specific data
KEYS customer:CUST001:*

# Find all quotes
KEYS quote:*

# Production-safe scanning
SCAN 0 MATCH policy:* COUNT 10

# === MONITORING & DEBUG ===
# Database information
DBSIZE
INFO memory
INFO stats

# Key information
STRLEN policy:INS001
TTL quote:AUTO:Q100
EXISTS policy:INS999

# === CLEANUP OPERATIONS ===
# Remove expired quotes
DEL quote:AUTO:Q100

# Remove test data
DEL test:*

# Clear specific pattern (be careful!)
# EVAL "return redis.call('del', unpack(redis.call('keys', ARGV[1])))" 0 test:*
EOF

# Create .gitignore
cat > .gitignore << 'EOF'
# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Log files
*.log

# Backup files
*.bak
*.backup

# Temporary files
*.tmp
*.temp

# Docker volumes
/data/

# IDE files
.vscode/
.idea/
*.swp
*.swo

# Environment files
.env
.env.local
EOF

echo ""
echo "📂 Project structure created:"
echo "   ${LAB_DIR}/"
echo "   ├── lab1.md                           📋 START HERE - Complete lab guide"
echo "   ├── redis-insurance.conf              ⚙️ Redis config for insurance"
echo "   ├── scripts/"
echo "   │   └── load-insurance-sample-data.sh 📊 Insurance sample data loader"
echo "   ├── docs/"
echo "   │   └── troubleshooting.md            🔧 Troubleshooting guide"
echo "   ├── examples/"
echo "   │   └── insurance-cli-examples.txt    ⚡ CLI command examples"
echo "   ├── insurance-data/                   📁 Sample data directory"
echo "   ├── README.md                         📖 Project documentation"
echo "   └── .gitignore                        🚫 Git ignore rules"
echo ""
echo "🎯 NEXT STEPS:"
echo "   1. cd ${LAB_DIR}"
echo "   2. code .                              # Open in VS Code"
echo "   3. Read lab1.md                       # Follow complete lab guide"
echo "   4. docker run -d --name redis-insurance -p 6379:6379 redis:7-alpine"
echo "   5. ./scripts/load-insurance-sample-data.sh"
echo ""
echo "🏢 INSURANCE DATA LOADED:"
echo "   📄 Policies (5): INS001-INS005"
echo "   👥 Customers (4): CUST001-CUST004"
echo "   📋 Claims (4): CLM001-CLM004"
echo "   👨‍💼 Agents (4): AG001-AG004"
echo "   💰 Quotes (3): AUTO, HOME, LIFE with TTL"
echo "   📊 Metrics: Daily counters and performance data"
echo ""
echo "🔗 REDIS INSIGHT:"
echo "   🌐 Launch Redis Insight from applications menu"
echo "   🔌 Connect to localhost:6379"
echo "   📊 Explore insurance data in Browser and Workbench"
echo ""
echo "🎉 READY TO START LAB 1!"
echo "   Open lab1.md for the complete 45-minute insurance-focused Redis experience!"