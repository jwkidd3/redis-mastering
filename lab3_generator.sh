#!/bin/bash

# Lab 3 Content Generator Script
# Generates complete content and code for Lab 3: Insurance Data Operations with Strings
# Duration: 45 minutes
# Focus: Advanced string operations for policy numbers, customer IDs, and premium calculations (NO JAVASCRIPT)

set -e

LAB_DIR="lab3-insurance-string-operations"
LAB_NUMBER="3"
LAB_TITLE="Insurance Data Operations with Strings"
LAB_DURATION="45"

echo "🚀 Generating Lab ${LAB_NUMBER}: ${LAB_TITLE}"
echo "📅 Duration: ${LAB_DURATION} minutes"
echo "🎯 Focus: Advanced string operations for policy management and premium calculations"
echo ""

# Create lab directory structure
mkdir -p ${LAB_DIR}
cd ${LAB_DIR}

echo "📁 Creating lab directory structure..."
mkdir -p {scripts,docs,examples,sample-data,performance-tests}

# Create main lab instructions markdown file
echo "📋 Creating lab3.md..."
cat > lab3.md << 'EOF'
# Lab 3: Insurance Data Operations with Strings

**Duration:** 45 minutes  
**Objective:** Master advanced string operations for policy numbers, customer IDs, premium calculations, and insurance data management

## 🎯 Learning Objectives

By the end of this lab, you will be able to:
- Implement policy number generation and validation using Redis strings
- Perform atomic premium calculations with string numeric operations
- Manage customer data efficiently with string concatenation and manipulation
- Build insurance document processing workflows with string operations
- Optimize batch operations for policy updates and customer management
- Implement race condition prevention for insurance financial calculations

---

## Part 1: Policy Number Management & Generation (15 minutes)

### Step 1: Environment Setup with Insurance Data

```bash
# Start Redis with optimized configuration for insurance workloads
docker run -d --name redis-insurance-lab3 \
  -p 6379:6379 \
  -v $(pwd)/sample-data:/data \
  redis:7-alpine redis-server --maxmemory 512mb --maxmemory-policy allkeys-lru

# Verify connection
redis-cli ping

# Load insurance sample data
./scripts/load-insurance-string-data.sh
```

### Step 2: Policy Number Generation System

Insurance companies require structured policy numbers for tracking and compliance:

```redis
# Connect to Redis CLI
redis-cli

# Policy number generation with atomic counters
SET policy:counter:auto 100000
SET policy:counter:home 200000
SET policy:counter:life 300000

# Generate new policy numbers atomically
INCR policy:counter:auto
INCR policy:counter:home
INCR policy:counter:life

# Format policy numbers with prefixes
SET policy:last_auto_number "AUTO-100001"
SET policy:last_home_number "HOME-200001"
SET policy:last_life_number "LIFE-300001"

# Verify policy number generation
GET policy:counter:auto
GET policy:last_auto_number
```

### Step 3: Policy Data Storage and Retrieval

```redis
# Store comprehensive policy information
SET policy:AUTO-100001 "Policy Type: Auto | Customer: CUST001 | Vehicle: 2020 Toyota Camry | Premium: $1,200 | Status: Active | Issue Date: 2024-08-18"

SET policy:HOME-200001 "Policy Type: Home | Customer: CUST002 | Property: 123 Main St, Dallas TX | Premium: $800 | Status: Active | Issue Date: 2024-08-18"

SET policy:LIFE-300001 "Policy Type: Life | Customer: CUST003 | Coverage: $500,000 Term 20Y | Premium: $420 | Status: Active | Issue Date: 2024-08-18"

# Policy information extraction
GET policy:AUTO-100001
STRLEN policy:AUTO-100001

# Check policy existence for customer service
EXISTS policy:AUTO-100001
EXISTS policy:AUTO-999999

# Policy type verification
TYPE policy:AUTO-100001
```

### Step 4: Policy Number Validation and Lookup

```redis
# Pattern-based policy lookup
KEYS policy:AUTO-*
KEYS policy:HOME-*
KEYS policy:LIFE-*

# Validate policy number format (production would use SCAN)
KEYS policy:*-100001

# Policy status checking
SET policy:AUTO-100001:status "ACTIVE"
SET policy:HOME-200001:status "SUSPENDED"
SET policy:LIFE-300001:status "PENDING_REVIEW"

# Retrieve policy status
GET policy:AUTO-100001:status
MGET policy:AUTO-100001:status policy:HOME-200001:status policy:LIFE-300001:status
```

**Business Context:**
- Policy numbers must be unique and sequential for audit compliance
- Atomic increments prevent duplicate policy numbers in concurrent environments
- Structured storage enables efficient customer service lookups

---

## Part 2: Premium Calculations and Financial Operations (15 minutes)

### Step 1: Premium Storage and Atomic Updates

```redis
# Initial premium setup for policies
SET premium:AUTO-100001 1200
SET premium:HOME-200001 800
SET premium:LIFE-300001 420

# Customer payment tracking
SET customer:CUST001:balance 0
SET customer:CUST002:balance 0
SET customer:CUST003:balance 0

# Premium adjustments based on risk assessment
INCRBY premium:AUTO-100001 150    # Increased due to traffic violations
DECRBY premium:HOME-200001 50     # Discount for security system
INCRBY premium:LIFE-300001 25     # Age adjustment

# Verify premium updates
MGET premium:AUTO-100001 premium:HOME-200001 premium:LIFE-300001
```

### Step 2: Payment Processing and Balance Management

```redis
# Customer premium payments (atomic operations prevent race conditions)
INCRBY customer:CUST001:balance 1350    # Auto premium payment
INCRBY customer:CUST002:balance 750     # Home premium payment
INCRBY customer:CUST003:balance 445     # Life premium payment

# Calculate outstanding balances
GET customer:CUST001:balance
GET premium:AUTO-100001

# Payment verification for customer CUST001
SET customer:CUST001:paid_amount 1350
SET customer:CUST001:owed_amount 1350
GET customer:CUST001:paid_amount
GET customer:CUST001:owed_amount

# Mark payment status
SET payment:AUTO-100001:status "PAID"
SET payment:HOME-200001:status "PAID"
SET payment:LIFE-300001:status "PAID"
```

### Step 3: Daily Financial Metrics and Reporting

```redis
# Daily revenue tracking
SET revenue:daily:2024-08-18 0
INCRBY revenue:daily:2024-08-18 1350    # Auto premium collected
INCRBY revenue:daily:2024-08-18 750     # Home premium collected
INCRBY revenue:daily:2024-08-18 445     # Life premium collected

# Check daily totals
GET revenue:daily:2024-08-18

# Monthly revenue accumulation
SET revenue:monthly:2024-08 0
INCRBY revenue:monthly:2024-08 2545     # Add daily total

# Premium type breakdown
SET revenue:auto:2024-08-18 0
SET revenue:home:2024-08-18 0
SET revenue:life:2024-08-18 0

INCRBY revenue:auto:2024-08-18 1350
INCRBY revenue:home:2024-08-18 750
INCRBY revenue:life:2024-08-18 445

# View breakdown
MGET revenue:auto:2024-08-18 revenue:home:2024-08-18 revenue:life:2024-08-18
```

### Step 4: Claims Impact on Premiums

```redis
# Claims affecting future premiums
SET claims:impact:AUTO-100001 0
INCRBY claims:impact:AUTO-100001 200    # First claim impact
INCRBY claims:impact:AUTO-100001 150    # Second claim impact

# Calculate adjusted premium for renewal
GET premium:AUTO-100001
GET claims:impact:AUTO-100001

# Premium adjustment for next term
SET premium:AUTO-100001:next_term 1500
INCRBY premium:AUTO-100001:next_term 350    # Claims adjustment

GET premium:AUTO-100001:next_term
```

**Business Context:**
- Atomic operations ensure financial data consistency under concurrent load
- Separate tracking of payments, balances, and adjustments aids audit compliance
- Daily and monthly metrics support business intelligence and reporting

---

## Part 3: Customer Data Management and Document Processing (15 minutes)

### Step 1: Customer Profile Management

```redis
# Comprehensive customer data storage
SET customer:CUST001 "Name: John Smith | DOB: 1985-03-15 | Phone: 555-0123 | Email: john.smith@email.com | Address: 456 Oak St, Dallas TX 75201"

SET customer:CUST002 "Name: Jane Doe | DOB: 1990-07-22 | Phone: 555-0456 | Email: jane.doe@email.com | Address: 789 Pine Ave, Dallas TX 75202"

SET customer:CUST003 "Name: Bob Johnson | DOB: 1978-11-08 | Phone: 555-0789 | Email: bob.johnson@email.com | Address: 321 Elm St, Dallas TX 75203"

# Customer profile retrieval
GET customer:CUST001
STRLEN customer:CUST001

# Customer data manipulation for updates
APPEND customer:CUST001 " | Risk Score: 750 | Preferred Contact: Email"
GET customer:CUST001
```

### Step 2: Document Fragment Management

```redis
# Insurance document fragments for efficient storage
SET doc:AUTO-100001:coverage "Comprehensive Coverage: Collision ($500 deductible), Comprehensive ($250 deductible), Liability (100/300/50)"

SET doc:AUTO-100001:exclusions "Exclusions: Racing, Commercial Use, Intentional Damage, War, Nuclear Hazard"

SET doc:AUTO-100001:terms "Terms: 6-month policy period, Automatic renewal, 30-day notice for cancellation"

# Document assembly through concatenation
APPEND doc:AUTO-100001:full_policy "POLICY NUMBER: AUTO-100001\n\n"
APPEND doc:AUTO-100001:full_policy "COVERAGE: "
GET doc:AUTO-100001:coverage
APPEND doc:AUTO-100001:full_policy "\n\nEXCLUSIONS: "
GET doc:AUTO-100001:exclusions
APPEND doc:AUTO-100001:full_policy "\n\nTERMS: "
GET doc:AUTO-100001:terms

# View assembled document
GET doc:AUTO-100001:full_policy
STRLEN doc:AUTO-100001:full_policy
```

### Step 3: Customer Activity and Communication Logs

```redis
# Customer interaction logging with timestamps
SET activity:CUST001:log ""
APPEND activity:CUST001:log "2024-08-18T09:15:00Z - Policy inquiry via phone\n"
APPEND activity:CUST001:log "2024-08-18T09:30:00Z - Premium payment processed\n"
APPEND activity:CUST001:log "2024-08-18T10:45:00Z - Policy documents emailed\n"

# Communication preferences and history
SET communication:CUST001 "Preferred: Email | Frequency: Quarterly | Last Contact: 2024-08-18 | Method: Email"

# Append new communication events
APPEND communication:CUST001 " | 2024-08-18T14:30:00Z - Renewal notice sent via email"

# View complete communication history
GET communication:CUST001
GET activity:CUST001:log
```

### Step 4: Batch Customer Operations

```redis
# Batch customer data retrieval for dashboard
MGET customer:CUST001 customer:CUST002 customer:CUST003

# Batch premium lookup for customer portfolio
MGET premium:AUTO-100001 premium:HOME-200001 premium:LIFE-300001

# Batch policy status check
MGET policy:AUTO-100001:status policy:HOME-200001:status policy:LIFE-300001:status

# Customer risk score updates
MSET risk:score:CUST001 750 risk:score:CUST002 820 risk:score:CUST003 680

# Verify batch updates
MGET risk:score:CUST001 risk:score:CUST002 risk:score:CUST003

# Batch last login tracking
MSET customer:CUST001:last_login "2024-08-18T14:30:00Z" customer:CUST002:last_login "2024-08-17T16:45:00Z" customer:CUST003:last_login "2024-08-16T11:20:00Z"
```

**Business Context:**
- String manipulation enables flexible document assembly without complex storage
- Activity logging provides audit trails required for insurance compliance
- Batch operations optimize performance for customer service dashboards

---

## 🏆 Challenge Exercises (Optional - if time permits)

### Challenge 1: Advanced Policy Number System

Implement a sophisticated policy numbering system with validation:

```redis
# Policy number with check digits and location codes
SET location:code:dallas "DAL"
SET location:code:houston "HOU"
SET location:code:austin "AUS"

# Generate location-specific policy numbers
INCR counter:policy:DAL:auto
INCR counter:policy:HOU:home
INCR counter:policy:AUS:life

# Format: LOC-TYPE-NNNNNN-C (location-type-number-checkdigit)
SET policy:DAL-AUTO-100001-7 "Auto Policy issued in Dallas office"
SET policy:HOU-HOME-200001-3 "Home Policy issued in Houston office"
SET policy:AUS-LIFE-300001-9 "Life Policy issued in Austin office"

# Validation lookup
EXISTS policy:DAL-AUTO-100001-7
KEYS policy:DAL-*
KEYS policy:*-AUTO-*
```

### Challenge 2: Dynamic Premium Calculation System

```redis
# Base rates by policy type and location
SET rate:base:auto:DAL 800
SET rate:base:home:DAL 600
SET rate:base:life:DAL 300

# Risk multipliers
SET multiplier:age:25-35 1.0
SET multiplier:age:36-45 1.1
SET multiplier:age:46-55 1.2

# Calculate premium for new customer
GET rate:base:auto:DAL
GET multiplier:age:36-45

# Manual calculation demo (in real app, this would be done in application code)
SET temp:calc:base 800
SET temp:calc:multiplier 110  # 1.1 * 100 for integer math
# Premium = base * multiplier / 100
SET calculated:premium:AUTO-100002 880

GET calculated:premium:AUTO-100002
```

### Challenge 3: Customer Communication Automation

```redis
# Template storage
SET template:renewal:email "Dear {customer_name}, Your policy {policy_number} is due for renewal. Current premium: ${premium}. Please contact us to renew."

SET template:payment:reminder "Dear {customer_name}, Your payment of ${amount} for policy {policy_number} is overdue. Please remit payment immediately."

# Customer communication queue
LPUSH comm:queue:email "CUST001:renewal:AUTO-100001"
LPUSH comm:queue:email "CUST002:payment:HOME-200001"

# Communication status tracking
SET comm:status:CUST001:renewal "pending"
SET comm:status:CUST002:payment "pending"

# Process communication queue
RPOP comm:queue:email
SET comm:status:CUST001:renewal "sent"
APPEND activity:CUST001:log "2024-08-18T15:00:00Z - Renewal notice sent\n"
```

---

## 📚 Key Takeaways

✅ **Policy Management**: Mastered atomic policy number generation and structured storage  
✅ **Financial Operations**: Implemented race-condition-safe premium calculations and payment processing  
✅ **Customer Data**: Built efficient customer profile management with string manipulation  
✅ **Document Processing**: Created flexible document assembly using string concatenation  
✅ **Batch Operations**: Optimized multi-customer operations for performance  
✅ **Business Logic**: Applied insurance-specific patterns and compliance requirements

## 🔗 Next Steps

In **Lab 4: Insurance Key Management & TTL Strategies**, you'll expand on these concepts:
- Advanced key naming conventions for insurance entities
- Quote expiration management with sophisticated TTL strategies
- Customer session management and cleanup automation
- Performance optimization for large-scale insurance databases
- Memory management for customer and policy data

---

## 📖 Additional Resources

- [Redis String Commands Reference](https://redis.io/commands/?group=string)
- [Atomic Operations in Redis](https://redis.io/docs/interact/transactions/)
- [Redis Best Practices for Financial Services](https://redis.io/docs/stack/compliance/)
- [Performance Optimization Guide](https://redis.io/docs/management/optimization/)

## 🔧 Troubleshooting

**Atomic Operation Issues:**
```bash
# Verify atomic operations working correctly
redis-cli INCR test:counter
redis-cli INCR test:counter
redis-cli GET test:counter

# Check for race conditions
redis-cli MULTI
redis-cli INCR premium:test
redis-cli GET premium:test
redis-cli EXEC
```

**String Operation Problems:**
```bash
# Check string length limits
redis-cli STRLEN policy:AUTO-100001
redis-cli CONFIG GET proto-max-bulk-len

# Memory usage verification
redis-cli MEMORY USAGE customer:CUST001
```

**Performance Issues:**
```bash
# Monitor string operations
redis-cli monitor | grep -E "(SET|GET|INCR|APPEND)"

# Check memory efficiency
redis-cli INFO memory | grep used_memory_human
```
EOF

# Create sample data loading script
echo "📊 Creating scripts/load-insurance-string-data.sh..."
cat > scripts/load-insurance-string-data.sh << 'EOF'
#!/bin/bash

# Insurance String Operations Sample Data Loader
# Comprehensive data for string manipulation exercises

echo "🏢 Loading Insurance String Operations Sample Data..."

redis-cli << 'REDIS_EOF'
# Clear existing data
FLUSHALL

# === POLICY COUNTER INITIALIZATION ===
SET policy:counter:auto 100000
SET policy:counter:home 200000
SET policy:counter:life 300000

# === SAMPLE POLICIES WITH DETAILED STRING DATA ===
SET policy:AUTO-100001 "Policy Type: Auto | Customer: CUST001 | Vehicle: 2020 Toyota Camry LE | VIN: 1234567890ABCDEFG | Premium: $1,200 | Deductible: $500 | Coverage: Full | Status: Active | Issue Date: 2024-08-18 | Agent: AG001"

SET policy:AUTO-100002 "Policy Type: Auto | Customer: CUST004 | Vehicle: 2019 Honda Civic LX | VIN: ABCDEFG1234567890 | Premium: $950 | Deductible: $250 | Coverage: Full | Status: Active | Issue Date: 2024-08-15 | Agent: AG002"

SET policy:HOME-200001 "Policy Type: Home | Customer: CUST002 | Property: 123 Main St, Dallas TX 75201 | Square Feet: 2,200 | Premium: $800 | Deductible: $1,000 | Coverage: Full Replacement | Status: Active | Issue Date: 2024-08-10 | Agent: AG001"

SET policy:HOME-200002 "Policy Type: Home | Customer: CUST005 | Property: 456 Oak Ave, Dallas TX 75202 | Square Feet: 1,800 | Premium: $650 | Deductible: $500 | Coverage: Actual Cash Value | Status: Active | Issue Date: 2024-08-12 | Agent: AG003"

SET policy:LIFE-300001 "Policy Type: Life | Customer: CUST003 | Coverage: $500,000 Term 20Y | Premium: $420/year | Beneficiaries: 2 | Medical Exam: Required | Status: Active | Issue Date: 2024-08-05 | Agent: AG002"

SET policy:LIFE-300002 "Policy Type: Life | Customer: CUST006 | Coverage: $250,000 Term 10Y | Premium: $180/year | Beneficiaries: 1 | Medical Exam: Not Required | Status: Pending | Issue Date: 2024-08-16 | Agent: AG001"

# === CUSTOMER DETAILED PROFILES ===
SET customer:CUST001 "Name: John Smith | DOB: 1985-03-15 | SSN: ***-**-1234 | Phone: 555-0123 | Email: john.smith@email.com | Address: 456 Oak St, Dallas TX 75201 | Credit Score: 750 | Customer Since: 2018-05-20"

SET customer:CUST002 "Name: Jane Doe | DOB: 1990-07-22 | SSN: ***-**-5678 | Phone: 555-0456 | Email: jane.doe@email.com | Address: 789 Pine Ave, Dallas TX 75202 | Credit Score: 820 | Customer Since: 2020-03-15"

SET customer:CUST003 "Name: Bob Johnson | DOB: 1978-11-08 | SSN: ***-**-9012 | Phone: 555-0789 | Email: bob.johnson@email.com | Address: 321 Elm St, Dallas TX 75203 | Credit Score: 680 | Customer Since: 2019-09-10"

SET customer:CUST004 "Name: Alice Brown | DOB: 1995-09-12 | SSN: ***-**-3456 | Phone: 555-0321 | Email: alice.brown@email.com | Address: 654 Maple Dr, Dallas TX 75204 | Credit Score: 720 | Customer Since: 2021-01-08"

SET customer:CUST005 "Name: Charlie Wilson | DOB: 1982-12-03 | SSN: ***-**-7890 | Phone: 555-0654 | Email: charlie.wilson@email.com | Address: 987 Cedar Ln, Dallas TX 75205 | Credit Score: 790 | Customer Since: 2017-11-22"

SET customer:CUST006 "Name: Diana Rodriguez | DOB: 1988-04-18 | SSN: ***-**-2468 | Phone: 555-0987 | Email: diana.rodriguez@email.com | Address: 147 Birch Way, Dallas TX 75206 | Credit Score: 710 | Customer Since: 2022-06-14"

# === PREMIUM DATA ===
SET premium:AUTO-100001 1200
SET premium:AUTO-100002 950
SET premium:HOME-200001 800
SET premium:HOME-200002 650
SET premium:LIFE-300001 420
SET premium:LIFE-300002 180

# === CUSTOMER BALANCE TRACKING ===
SET customer:CUST001:balance 0
SET customer:CUST002:balance 0
SET customer:CUST003:balance 0
SET customer:CUST004:balance 0
SET customer:CUST005:balance 0
SET customer:CUST006:balance 0

# === POLICY STATUS TRACKING ===
SET policy:AUTO-100001:status "ACTIVE"
SET policy:AUTO-100002:status "ACTIVE"
SET policy:HOME-200001:status "ACTIVE"
SET policy:HOME-200002:status "ACTIVE"
SET policy:LIFE-300001:status "ACTIVE"
SET policy:LIFE-300002:status "PENDING_MEDICAL_REVIEW"

# === DOCUMENT FRAGMENTS ===
SET doc:AUTO-100001:coverage "Bodily Injury Liability: $100,000/$300,000 | Property Damage Liability: $50,000 | Comprehensive: $500 deductible | Collision: $500 deductible | Uninsured Motorist: $100,000/$300,000"

SET doc:AUTO-100001:exclusions "Racing or speed contests | Using vehicle for commercial purposes | Intentional damage | War or military action | Nuclear hazard | Vehicle modifications not reported"

SET doc:HOME-200001:coverage "Dwelling: $300,000 | Personal Property: $225,000 | Liability: $300,000 | Medical Payments: $5,000 | Loss of Use: $60,000 | Deductible: $1,000"

SET doc:LIFE-300001:coverage "Death Benefit: $500,000 | Term: 20 years | Level Premium | Convertible to permanent insurance | Accelerated Death Benefit Rider included"

# === ACTIVITY LOGS ===
SET activity:CUST001:log "2024-08-18T09:15:00Z - Policy inquiry via phone | 2024-08-18T09:30:00Z - Premium payment processed | 2024-08-18T10:45:00Z - Policy documents emailed"

SET activity:CUST002:log "2024-08-17T14:20:00Z - Online quote request | 2024-08-17T15:45:00Z - Policy purchased online | 2024-08-18T08:30:00Z - Welcome packet mailed"

SET activity:CUST003:log "2024-08-16T11:30:00Z - Beneficiary update request | 2024-08-16T11:45:00Z - Forms completed | 2024-08-17T16:20:00Z - Changes processed"

# === COMMUNICATION PREFERENCES ===
SET communication:CUST001 "Preferred: Email | Frequency: Quarterly | Last Contact: 2024-08-18 | Method: Email | Marketing Opt-in: Yes"

SET communication:CUST002 "Preferred: Phone | Frequency: Annual | Last Contact: 2024-08-17 | Method: Phone | Marketing Opt-in: No"

SET communication:CUST003 "Preferred: Mail | Frequency: Semi-Annual | Last Contact: 2024-08-16 | Method: Mail | Marketing Opt-in: Yes"

# === REVENUE TRACKING ===
SET revenue:daily:2024-08-18 0
SET revenue:monthly:2024-08 0
SET revenue:auto:2024-08-18 0
SET revenue:home:2024-08-18 0
SET revenue:life:2024-08-18 0

# === RISK SCORES ===
SET risk:score:CUST001 750
SET risk:score:CUST002 820
SET risk:score:CUST003 680
SET risk:score:CUST004 720
SET risk:score:CUST005 790
SET risk:score:CUST006 710

# === LOCATION CODES ===
SET location:code:dallas "DAL"
SET location:code:houston "HOU"
SET location:code:austin "AUS"
SET location:code:fort_worth "FTW"
SET location:code:san_antonio "SAT"

REDIS_EOF

echo "✅ Insurance string operations sample data loaded successfully!"
echo ""
echo "📊 Data Summary:"
redis-cli << 'REDIS_EOF'
ECHO "=== POLICY COUNTERS ==="
MGET policy:counter:auto policy:counter:home policy:counter:life
ECHO ""
ECHO "=== POLICIES ==="
KEYS policy:*-*
ECHO ""
ECHO "=== CUSTOMERS ==="
KEYS customer:CUST*
ECHO ""
ECHO "=== PREMIUMS ==="
KEYS premium:*
ECHO ""
ECHO "=== DOCUMENT FRAGMENTS ==="
KEYS doc:*
ECHO ""
ECHO "=== ACTIVITY LOGS ==="
KEYS activity:*
ECHO ""
ECHO "Database Size:"
DBSIZE
REDIS_EOF

echo ""
echo "🎯 Ready for Lab 3 string operations exercises!"
echo ""
echo "📋 Key Exercise Areas:"
echo "   • Policy number generation and management"
echo "   • Premium calculations with atomic operations"
echo "   • Customer profile manipulation and updates"
echo "   • Document assembly through string concatenation"
echo "   • Batch operations for customer data"
echo "   • Financial transaction processing"
EOF

chmod +x scripts/load-insurance-string-data.sh

# Create performance testing script
echo "⚡ Creating performance-tests/string-operations-performance.sh..."
cat > performance-tests/string-operations-performance.sh << 'EOF'
#!/bin/bash

# String Operations Performance Testing Script
# Tests various string operation patterns for insurance data

echo "⚡ Starting String Operations Performance Tests..."

# Test 1: Policy Number Generation Performance
echo "🧪 Test 1: Policy Number Generation Performance"
time redis-cli eval "
for i=1,1000 do
  redis.call('INCR', 'perf:policy:counter')
  redis.call('SET', 'perf:policy:' .. i, 'Policy data for policy number ' .. i)
end
return 'Generated 1000 policies'
" 0

# Test 2: Premium Calculation Performance
echo "🧪 Test 2: Premium Calculation Performance (1000 operations)"
time redis-cli eval "
for i=1,1000 do
  redis.call('SET', 'perf:premium:' .. i, 1000)
  redis.call('INCRBY', 'perf:premium:' .. i, i)
end
return 'Processed 1000 premium calculations'
" 0

# Test 3: Customer Data Retrieval Performance
echo "🧪 Test 3: Customer Data Retrieval Performance"
time redis-cli eval "
local results = {}
for i=1,100 do
  local key = 'customer:CUST00' .. (i % 6 + 1)
  local data = redis.call('GET', key)
  table.insert(results, data)
end
return #results .. ' customer records retrieved'
" 0

# Test 4: Batch vs Individual Operations
echo "🧪 Test 4: Individual GET Operations (100 calls)"
time redis-cli eval "
for i=1,100 do
  redis.call('GET', 'policy:AUTO-100001')
end
return 'Individual operations completed'
" 0

echo "🧪 Test 4: Batch MGET Operations (same data)"
time redis-cli eval "
local keys = {}
for i=1,100 do
  table.insert(keys, 'policy:AUTO-100001')
end
local result = redis.call('MGET', unpack(keys))
return 'Batch operations completed: ' .. #result
" 0

# Test 5: String Concatenation Performance
echo "🧪 Test 5: String Concatenation Performance"
time redis-cli eval "
for i=1,100 do
  redis.call('SET', 'perf:doc:' .. i, 'Initial document content')
  redis.call('APPEND', 'perf:doc:' .. i, ' | Additional content section 1')
  redis.call('APPEND', 'perf:doc:' .. i, ' | Additional content section 2')
  redis.call('APPEND', 'perf:doc:' .. i, ' | Final content section')
end
return 'Document assembly completed'
" 0

# Test 6: Memory Usage Analysis
echo "🧪 Test 6: Memory Usage Analysis"
redis-cli eval "
-- Check memory usage of different string sizes
redis.call('SET', 'memory:test:small', 'Small string')
redis.call('SET', 'memory:test:medium', string.rep('Medium string content ', 50))
redis.call('SET', 'memory:test:large', string.rep('Large string content with more data ', 200))
return 'Memory test strings created'
" 0

echo "Memory usage for different string sizes:"
redis-cli MEMORY USAGE memory:test:small
redis-cli MEMORY USAGE memory:test:medium
redis-cli MEMORY USAGE memory:test:large

# Cleanup performance test data
echo "🧹 Cleaning up performance test data..."
redis-cli eval "
local keys = redis.call('KEYS', 'perf:*')
if #keys > 0 then
  redis.call('DEL', unpack(keys))
end
keys = redis.call('KEYS', 'memory:test:*')
if #keys > 0 then
  redis.call('DEL', unpack(keys))
end
return 'Cleanup completed'
" 0

echo "✅ Performance testing completed!"
EOF

chmod +x performance-tests/string-operations-performance.sh

# Create string operations reference guide
echo "📚 Creating docs/string-operations-reference.md..."
cat > docs/string-operations-reference.md << 'EOF'
# Redis String Operations Reference for Insurance Applications

## Core String Commands

### Basic Operations
```redis
SET key value              # Set string value
GET key                    # Get string value
MSET key1 val1 key2 val2   # Set multiple strings
MGET key1 key2 key3        # Get multiple strings
EXISTS key                 # Check if key exists
DEL key                    # Delete key
STRLEN key                 # Get string length
TYPE key                   # Get key type
```

### Numeric Operations
```redis
INCR key                   # Increment by 1
DECR key                   # Decrement by 1
INCRBY key increment       # Increment by amount
DECRBY key decrement       # Decrement by amount
INCRBYFLOAT key increment  # Increment by float
```

### String Manipulation
```redis
APPEND key value           # Append to string
GETRANGE key start end     # Get substring
SETRANGE key offset value  # Set substring
```

### Conditional Operations
```redis
SETNX key value           # Set if not exists
SETEX key seconds value   # Set with expiration
PSETEX key milliseconds value  # Set with expiration (ms)
```

## Insurance-Specific Patterns

### 1. Policy Number Management

**Pattern: Sequential Policy Numbers**
```redis
# Initialize counters
SET policy:counter:auto 100000
SET policy:counter:home 200000
SET policy:counter:life 300000

# Generate new policy number
INCR policy:counter:auto           # Returns 100001
SET policy:AUTO-100001 "policy_data"

# Atomic policy creation
MULTI
INCR policy:counter:auto
SET policy:AUTO-{counter} "policy_data"
EXEC
```

**Pattern: Policy Validation**
```redis
# Check policy exists
EXISTS policy:AUTO-100001

# Validate policy number format
KEYS policy:AUTO-*
KEYS policy:HOME-*
```

### 2. Premium Calculations

**Pattern: Atomic Premium Updates**
```redis
# Initial premium
SET premium:AUTO-100001 1200

# Risk-based adjustments
INCRBY premium:AUTO-100001 150     # Traffic violation
DECRBY premium:AUTO-100001 50      # Good driver discount

# Percentage calculations (use integer math)
# For 10% increase: multiply by 110 then divide by 100
SET temp:premium 1200
INCRBY temp:premium 120            # 10% of 1200
```

**Pattern: Payment Processing**
```redis
# Customer balance management
SET customer:CUST001:balance 0
INCRBY customer:CUST001:balance 1200    # Payment received
DECRBY customer:CUST001:balance 1200    # Payment applied

# Atomic payment verification
MULTI
INCRBY customer:CUST001:paid 1200
SET payment:transaction:12345 "COMPLETED"
EXEC
```

### 3. Customer Data Management

**Pattern: Profile Storage**
```redis
# Structured customer data in single string
SET customer:CUST001 "Name: John Smith | DOB: 1985-03-15 | Phone: 555-0123 | Email: john@email.com"

# Profile updates through concatenation
APPEND customer:CUST001 " | Risk Score: 750"

# Separate fields for frequent access
SET customer:CUST001:name "John Smith"
SET customer:CUST001:email "john@email.com"
SET customer:CUST001:phone "555-0123"
```

**Pattern: Activity Logging**
```redis
# Initialize log
SET activity:CUST001 ""

# Add timestamped entries
APPEND activity:CUST001 "2024-08-18T09:15:00Z - Policy inquiry\n"
APPEND activity:CUST001 "2024-08-18T09:30:00Z - Premium payment\n"

# Retrieve full log
GET activity:CUST001
```

### 4. Document Management

**Pattern: Document Assembly**
```redis
# Store document fragments
SET doc:policy:header "POLICY NUMBER: {policy_number}\nISSUE DATE: {date}\n\n"
SET doc:policy:coverage "COVERAGE DETAILS:\n{coverage_text}\n\n"
SET doc:policy:terms "TERMS AND CONDITIONS:\n{terms_text}"

# Assemble complete document
SET doc:AUTO-100001:complete ""
APPEND doc:AUTO-100001:complete "POLICY NUMBER: AUTO-100001\n"
APPEND doc:AUTO-100001:complete "COVERAGE: Full Coverage Auto Policy\n"
APPEND doc:AUTO-100001:complete "PREMIUM: $1,200 annually"
```

### 5. Financial Reporting

**Pattern: Daily Revenue Tracking**
```redis
# Initialize daily counters
SET revenue:daily:2024-08-18 0
SET policies:sold:daily:2024-08-18 0

# Record transactions
INCRBY revenue:daily:2024-08-18 1200      # Auto premium
INCR policies:sold:daily:2024-08-18       # Policy count

# Category breakdown
INCRBY revenue:auto:2024-08-18 1200
INCRBY revenue:home:2024-08-18 800
INCRBY revenue:life:2024-08-18 420
```

## Performance Optimization

### 1. Batch Operations
```redis
# Instead of multiple GET calls
GET policy:AUTO-100001
GET policy:AUTO-100002  
GET policy:AUTO-100003

# Use batch operation
MGET policy:AUTO-100001 policy:AUTO-100002 policy:AUTO-100003

# Instead of multiple SET calls
SET customer:CUST001:status "active"
SET customer:CUST002:status "active"
SET customer:CUST003:status "active"

# Use batch operation
MSET customer:CUST001:status "active" customer:CUST002:status "active" customer:CUST003:status "active"
```

### 2. Memory Efficiency
```redis
# For small structured data, consider single string
SET policy:AUTO-100001 "type:auto|premium:1200|customer:CUST001"

# For frequently accessed fields, separate keys
SET policy:AUTO-100001:type "auto"
SET policy:AUTO-100001:premium 1200
SET policy:AUTO-100001:customer "CUST001"

# For large text data, consider compression at application level
```

### 3. Atomic Operations
```redis
# Use MULTI/EXEC for related operations
MULTI
INCR revenue:daily:2024-08-18
INCR policies:sold:2024-08-18
SET policy:AUTO-100001:status "active"
EXEC

# Use atomic numeric operations instead of GET/SET
# Instead of:
# GET counter
# SET counter (value + 1)
# Use:
INCR counter
```

## Common Patterns and Use Cases

### Quote Management
```redis
# Temporary quotes with expiration
SETEX quote:AUTO:Q001 600 "Honda Civic - Premium: $950"

# Quote tracking
INCR quotes:generated:daily
SET quote:AUTO:Q001:customer "CUST001"
```

### Session Management
```redis
# Customer sessions
SETEX session:customer:CUST001 1800 "session_data"

# Login tracking
INCR customer:CUST001:login_count
SET customer:CUST001:last_login "2024-08-18T10:30:00Z"
```

### Audit and Compliance
```redis
# Transaction logs
APPEND audit:transactions "2024-08-18T10:30:00Z|PAYMENT|CUST001|1200\n"

# Policy changes
APPEND audit:policy:AUTO-100001 "2024-08-18T10:30:00Z|PREMIUM_UPDATE|1200|1350\n"
```

### Risk Assessment
```redis
# Risk scores
SET risk:customer:CUST001 750
SET risk:policy:AUTO-100001 850

# Risk factors
APPEND risk:factors:CUST001 "age:39|credit:750|violations:0"
```

## Error Handling and Validation

### Key Existence Checks
```redis
# Before operations
EXISTS policy:AUTO-100001
TYPE policy:AUTO-100001

# Conditional operations
SETNX policy:AUTO-100001:lock "processing"
```

### Data Type Validation
```redis
# Ensure numeric operations on numbers
TYPE premium:AUTO-100001     # Should return "string" but value should be numeric
```

### Transaction Safety
```redis
# Use transactions for multi-step operations
MULTI
SET policy:AUTO-100001:status "suspended"
INCR policies:suspended:count
EXEC
```

This reference covers the essential string operations for insurance applications, focusing on practical patterns that ensure data consistency, performance, and compliance requirements.
EOF

# Create examples file
echo "📋 Creating examples/insurance-string-examples.md..."
cat > examples/insurance-string-examples.md << 'EOF'
# Insurance String Operations Examples

## Policy Management Examples

### Auto Policy Creation Workflow
```redis
# Step 1: Generate unique policy number
INCR policy:counter:auto                    # Returns 100001
SET policy:AUTO-100001 "Policy Type: Auto | Customer: CUST001 | Vehicle: 2020 Toyota Camry | Premium: $1,200 | Status: Active"

# Step 2: Set related data
SET premium:AUTO-100001 1200
SET policy:AUTO-100001:status "ACTIVE"
SET policy:AUTO-100001:customer "CUST001"

# Step 3: Update customer policy list
APPEND customer:CUST001:policies "AUTO-100001,"

# Verification
GET policy:AUTO-100001
EXISTS policy:AUTO-100001
STRLEN policy:AUTO-100001
```

### Policy Amendment Process
```redis
# Original policy
SET policy:AUTO-100001 "Type: Auto | Customer: CUST001 | Vehicle: 2020 Toyota Camry | Premium: $1,200"

# Add coverage details
APPEND policy:AUTO-100001 " | Coverage: Full | Deductible: $500"

# Update premium due to risk change
INCRBY premium:AUTO-100001 150              # Increase by $150

# Log the change
APPEND audit:policy:AUTO-100001 "2024-08-18T10:30:00Z - Premium increased $150 due to traffic violation\n"

# Verify changes
GET policy:AUTO-100001
GET premium:AUTO-100001
GET audit:policy:AUTO-100001
```

## Customer Management Examples

### Customer Registration Workflow
```redis
# Step 1: Generate customer ID
INCR customer:counter                       # Returns CUST001 equivalent

# Step 2: Store comprehensive profile
SET customer:CUST001 "Name: John Smith | DOB: 1985-03-15 | Phone: 555-0123 | Email: john.smith@email.com | Address: 456 Oak St, Dallas TX"

# Step 3: Initialize customer metrics
SET customer:CUST001:balance 0
SET customer:CUST001:login_count 0
SET customer:CUST001:policies ""

# Step 4: Set communication preferences
SET communication:CUST001 "Preferred: Email | Frequency: Quarterly | Marketing: Yes"

# Verification
GET customer:CUST001
MGET customer:CUST001:balance customer:CUST001:login_count
```

### Customer Profile Updates
```redis
# Update contact information
GETRANGE customer:CUST001 0 50              # Get current start of profile
SETRANGE customer:CUST001 60 "Phone: 555-9999"  # Update phone section

# Add risk assessment data
APPEND customer:CUST001 " | Credit Score: 750 | Risk Level: Low"

# Track profile changes
APPEND activity:CUST001 "2024-08-18T14:30:00Z - Contact information updated\n"
APPEND activity:CUST001 "2024-08-18T14:31:00Z - Risk assessment completed\n"

# View updated profile
GET customer:CUST001
GET activity:CUST001
```

## Premium and Payment Examples

### Premium Calculation Workflow
```redis
# Base premium setup
SET premium:base:auto 800
SET premium:base:home 600
SET premium:base:life 300

# Customer-specific factors
SET factor:age:CUST001 110                   # 10% increase for age (110%)
SET factor:credit:CUST001 95                 # 5% discount for good credit (95%)
SET factor:location:CUST001 105              # 5% increase for location (105%)

# Calculate final premium (base * factors / 10000)
# For auto: 800 * 110 * 95 * 105 / 10000 = 873
SET premium:calculated:AUTO-100001 873

# Round to nearest dollar and store
SET premium:AUTO-100001 873

# Track calculation
APPEND calculation:AUTO-100001 "Base: 800 | Age: 110% | Credit: 95% | Location: 105% | Final: 873\n"
```

### Payment Processing Workflow
```redis
# Customer makes payment
SET payment:transaction:TXN001 "Customer: CUST001 | Amount: 873 | Policy: AUTO-100001 | Date: 2024-08-18T15:00:00Z"

# Update customer balance
INCRBY customer:CUST001:balance 873

# Apply payment to policy
DECRBY customer:CUST001:balance 873
SET policy:AUTO-100001:paid_status "CURRENT"

# Update payment history
APPEND customer:CUST001:payments "2024-08-18T15:00:00Z|AUTO-100001|873|TXN001\n"

# Daily revenue tracking
INCRBY revenue:daily:2024-08-18 873
INCR payments:count:daily:2024-08-18

# Verification
GET customer:CUST001:balance               # Should be 0
GET revenue:daily:2024-08-18
GET payments:count:daily:2024-08-18
```

## Claims Processing Examples

### Claims Submission Workflow
```redis
# Generate claim number
INCR claims:counter                         # Returns CLM001 equivalent

# Store claim details
SET claim:CLM001 "Type: Auto | Policy: AUTO-100001 | Customer: CUST001 | Amount: $2,500 | Date: 2024-08-18 | Status: Submitted"

# Initialize claim tracking
SET claim:CLM001:status "SUBMITTED"
SET claim:CLM001:amount 2500
SET claim:CLM001:adjuster ""

# Add to processing queue
APPEND claims:processing:queue "CLM001|URGENT|2500|2024-08-18\n"

# Update policy claim history
APPEND policy:AUTO-100001:claims "CLM001|2024-08-18|2500|SUBMITTED\n"

# Customer notification
APPEND customer:CUST001:notifications "Claim CLM001 submitted successfully - We will contact you within 24 hours\n"
```

### Claims Processing Updates
```redis
# Assign adjuster
SET claim:CLM001:adjuster "ADJ001"
SETRANGE claim:CLM001:status 0 "ASSIGNED"

# Update claim with adjuster notes
APPEND claim:CLM001 " | Adjuster: ADJ001 | Notes: Initial review completed"

# Process status updates
APPEND claim:CLM001:timeline "2024-08-18T09:00:00Z - Claim submitted\n"
APPEND claim:CLM001:timeline "2024-08-18T11:30:00Z - Assigned to ADJ001\n"
APPEND claim:CLM001:timeline "2024-08-18T14:15:00Z - Initial review completed\n"

# Update daily metrics
INCR claims:assigned:daily:2024-08-18
INCRBY claims:amount:daily:2024-08-18 2500
```

## Document Assembly Examples

### Policy Document Generation
```redis
# Document templates
SET template:policy:header "INSURANCE POLICY\nPolicy Number: {policy_number}\nEffective Date: {date}\n\n"
SET template:policy:customer "POLICYHOLDER INFORMATION\nName: {customer_name}\nAddress: {customer_address}\n\n"
SET template:auto:coverage "COVERAGE DETAILS\nLiability: $100,000/$300,000\nCollision: $500 deductible\nComprehensive: $500 deductible\n\n"

# Assemble policy document for AUTO-100001
SET document:AUTO-100001 ""
APPEND document:AUTO-100001 "INSURANCE POLICY\nPolicy Number: AUTO-100001\nEffective Date: 2024-08-18\n\n"
APPEND document:AUTO-100001 "POLICYHOLDER INFORMATION\nName: John Smith\nAddress: 456 Oak St, Dallas TX\n\n"
APPEND document:AUTO-100001 "COVERAGE DETAILS\nLiability: $100,000/$300,000\nCollision: $500 deductible\nComprehensive: $500 deductible\n\n"
APPEND document:AUTO-100001 "PREMIUM: $1,200 annually\nDUE DATE: 2024-09-18"

# Check document length and content
STRLEN document:AUTO-100001
GET document:AUTO-100001
```

### Email Template Processing
```redis
# Email templates
SET email:template:welcome "Dear {customer_name},\n\nWelcome to our insurance family! Your policy {policy_number} is now active.\n\nPremium: ${premium}\nNext payment due: {due_date}\n\nThank you for choosing us!\n\nBest regards,\nInsurance Team"

# Customer-specific email generation
SET email:CUST001:welcome ""
APPEND email:CUST001:welcome "Dear John Smith,\n\n"
APPEND email:CUST001:welcome "Welcome to our insurance family! Your policy AUTO-100001 is now active.\n\n"
APPEND email:CUST001:welcome "Premium: $1,200\n"
APPEND email:CUST001:welcome "Next payment due: 2024-09-18\n\n"
APPEND email:CUST001:welcome "Thank you for choosing us!\n\nBest regards,\nInsurance Team"

# Email delivery tracking
SET email:CUST001:welcome:status "QUEUED"
APPEND email:delivery:log "2024-08-18T16:00:00Z|CUST001|welcome|QUEUED\n"
```

## Reporting and Analytics Examples

### Daily Business Metrics
```redis
# Initialize daily counters
SET metrics:daily:2024-08-18:new_policies 0
SET metrics:daily:2024-08-18:claims_submitted 0
SET metrics:daily:2024-08-18:revenue 0
SET metrics:daily:2024-08-18:payments_received 0

# Update throughout the day
INCR metrics:daily:2024-08-18:new_policies     # New policy created
INCR metrics:daily:2024-08-18:claims_submitted # Claim submitted
INCRBY metrics:daily:2024-08-18:revenue 1200   # Premium collected
INCR metrics:daily:2024-08-18:payments_received # Payment processed

# Category breakdowns
INCRBY metrics:auto:revenue:2024-08-18 1200
INCRBY metrics:home:revenue:2024-08-18 800
INCRBY metrics:life:revenue:2024-08-18 420

# End of day reporting
MGET metrics:daily:2024-08-18:new_policies metrics:daily:2024-08-18:claims_submitted metrics:daily:2024-08-18:revenue
```

### Customer Analytics
```redis
# Customer lifetime value calculation
SET customer:CUST001:total_premiums 0
INCRBY customer:CUST001:total_premiums 1200    # Auto policy
INCRBY customer:CUST001:total_premiums 800     # Home policy

# Customer engagement metrics
INCR customer:CUST001:login_count
SET customer:CUST001:last_login "2024-08-18T16:30:00Z"
APPEND customer:CUST001:engagement "login|2024-08-18T16:30:00Z|portal\n"

# Risk assessment updates
SET customer:CUST001:risk_score 750
SET customer:CUST001:risk_factors "age:39|credit:750|claims:0|violations:0"

# Customer segmentation
APPEND segment:high_value "CUST001|LTV:2000|Risk:750\n"
```

## Advanced String Patterns

### Batch Customer Operations
```redis
# Batch customer status updates
MSET customer:CUST001:status "active" customer:CUST002:status "active" customer:CUST003:status "active"

# Batch premium retrievals
MGET premium:AUTO-100001 premium:HOME-200001 premium:LIFE-300001

# Batch last login updates
MSET customer:CUST001:last_login "2024-08-18" customer:CUST002:last_login "2024-08-18" customer:CUST003:last_login "2024-08-18"
```

### Complex Document Assembly
```redis
# Multi-section document assembly
SET doc:comprehensive:AUTO-100001 ""

# Add header section
APPEND doc:comprehensive:AUTO-100001 "=== COMPREHENSIVE POLICY DOCUMENT ===\n"
APPEND doc:comprehensive:AUTO-100001 "Policy: AUTO-100001 | Customer: John Smith\n\n"

# Add coverage section
APPEND doc:comprehensive:AUTO-100001 "=== COVERAGE DETAILS ===\n"
GET doc:AUTO-100001:coverage                                    # Retrieve coverage text
APPEND doc:comprehensive:AUTO-100001 "\n\n"

# Add exclusions section
APPEND doc:comprehensive:AUTO-100001 "=== EXCLUSIONS ===\n"
GET doc:AUTO-100001:exclusions                                  # Retrieve exclusions text
APPEND doc:comprehensive:AUTO-100001 "\n\n"

# Add terms section
APPEND doc:comprehensive:AUTO-100001 "=== TERMS AND CONDITIONS ===\n"
GET doc:AUTO-100001:terms                                       # Retrieve terms text

# Final document length check
STRLEN doc:comprehensive:AUTO-100001
```

These examples demonstrate practical insurance string operations that maintain data consistency, support business workflows, and enable efficient customer service operations.
EOF

# Create troubleshooting guide
echo "🔧 Creating docs/troubleshooting.md..."
cat > docs/troubleshooting.md << 'EOF'
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
EOF

# Create README
echo "📚 Creating README.md..."
cat > README.md << 'EOF'
# Lab 3: Insurance Data Operations with Strings

**Duration:** 45 minutes  
**Focus:** Advanced string operations for policy management and premium calculations  
**Industry:** Insurance data processing and customer management workflows

## 📁 Project Structure

```
lab3-insurance-string-operations/
├── lab3.md                                # Complete lab instructions (START HERE)
├── scripts/
│   └── load-insurance-string-data.sh      # Comprehensive insurance data loader
├── docs/
│   ├── string-operations-reference.md     # Redis string operations reference
│   └── troubleshooting.md                 # String operations troubleshooting
├── examples/
│   └── insurance-string-examples.md       # Practical insurance string examples
├── performance-tests/
│   └── string-operations-performance.sh   # Performance testing scripts
├── sample-data/                           # Sample data directory
└── README.md                              # This file
```

## 🚀 Quick Start

1. **Read Instructions:** Open `lab3.md` for complete lab guidance
2. **Start Redis:** `docker run -d --name redis-insurance-lab3 -p 6379:6379 redis:7-alpine`
3. **Load Sample Data:** `./scripts/load-insurance-string-data.sh`
4. **Test Connection:** `redis-cli ping`
5. **Follow Lab Exercises:** Execute string operations for insurance data

## 🎯 Lab Objectives

✅ Master policy number generation and validation using Redis strings  
✅ Perform atomic premium calculations with string numeric operations  
✅ Manage customer data efficiently with string concatenation and manipulation  
✅ Build insurance document processing workflows with string operations  
✅ Optimize batch operations for policy updates and customer management  
✅ Implement race condition prevention for insurance financial calculations

## 🏢 Insurance Data Focus

This lab uses comprehensive insurance industry data optimized for string operations:

- **Policy Management:** Auto, Home, Life policy creation and updates
- **Customer Profiles:** Comprehensive customer information management
- **Premium Calculations:** Atomic financial operations and adjustments
- **Document Assembly:** Policy documents and email template processing
- **Activity Logging:** Customer interaction tracking and audit trails
- **Financial Reporting:** Daily revenue tracking and business metrics

## 🔧 Key String Operations Covered

```bash
# Policy Number Generation
INCR policy:counter:auto                    # Atomic counter
SET policy:AUTO-100001 "policy_data"        # Structured storage

# Premium Calculations  
INCRBY premium:AUTO-100001 150              # Risk adjustments
DECRBY premium:AUTO-100001 50               # Discounts

# Customer Data Management
APPEND customer:CUST001 " | Risk Score: 750" # Profile updates
MGET customer:CUST001 customer:CUST002      # Batch retrieval

# Document Assembly
APPEND document:AUTO-100001 "COVERAGE: Full Coverage Auto Policy\n"

# Financial Operations
INCRBY revenue:daily:2024-08-18 1200        # Revenue tracking
```

## 📊 Sample Data Highlights

The lab includes realistic insurance data:

- **6 Comprehensive Policies:** AUTO-100001, AUTO-100002, HOME-200001, HOME-200002, LIFE-300001, LIFE-300002
- **6 Customer Profiles:** CUST001-CUST006 with complete contact and risk information
- **Premium Data:** Individual premiums with atomic calculation support
- **Document Fragments:** Policy coverage, exclusions, and terms sections
- **Activity Logs:** Customer interaction tracking with timestamps
- **Financial Metrics:** Revenue tracking and business intelligence data

## ⚡ Performance Testing

Run performance tests to compare different string operation patterns:

```bash
# Execute performance test suite
./performance-tests/string-operations-performance.sh

# Individual vs batch operations comparison
# Policy number generation performance
# Premium calculation efficiency
# Memory usage analysis
```

## 🆘 Troubleshooting

**Atomic Operations:**
```bash
# Test atomic operations
redis-cli INCR test:counter
redis-cli MULTI
redis-cli INCR premium:test
redis-cli EXEC
```

**String Length Issues:**
```bash
# Check string sizes
redis-cli STRLEN policy:AUTO-100001
redis-cli MEMORY USAGE customer:CUST001
```

**Numeric Operations:**
```bash
# Verify numeric values
redis-cli GET premium:AUTO-100001
redis-cli INCR premium:AUTO-100001
```

**Detailed troubleshooting:** See `docs/troubleshooting.md`

## 📚 Learning Resources

- **String Operations Reference:** `docs/string-operations-reference.md`
- **Insurance Examples:** `examples/insurance-string-examples.md`
- **Performance Testing:** `performance-tests/string-operations-performance.sh`
- **Troubleshooting Guide:** `docs/troubleshooting.md`

## 🎓 Learning Path

This lab is part of the Redis mastery series:

1. **Lab 1:** Environment & CLI Basics
2. **Lab 2:** RESP Protocol Analysis
3. **Lab 3:** Insurance Data Operations with Strings ← *You are here*
4. **Lab 4:** Key Management & TTL Strategies
5. **Lab 5:** Advanced CLI Operations & Monitoring

## 🏆 Key Achievements

By completing this lab, you will have mastered:

- **Atomic Operations:** Race-condition-safe premium calculations
- **Policy Management:** Structured policy number generation and storage
- **Customer Data:** Efficient profile management with string manipulation
- **Document Processing:** Dynamic document assembly workflows
- **Financial Operations:** Daily revenue tracking and business metrics
- **Performance Optimization:** Batch operations vs individual commands

---

**Ready to start?** Open `lab3.md` and begin mastering Redis string operations for insurance applications! 🚀
EOF

# Create .gitignore
cat > .gitignore << 'EOF'
# Performance test output
*.log
performance-*.log
benchmark-*.log

# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

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

# Test output
test-results/
performance-results/
EOF

echo ""
echo "📂 Project structure created:"
echo "   ${LAB_DIR}/"
echo "   ├── lab3.md                                📋 START HERE - Complete lab guide"
echo "   ├── scripts/"
echo "   │   └── load-insurance-string-data.sh      📊 Comprehensive insurance data loader"
echo "   ├── docs/"
echo "   │   ├── string-operations-reference.md     📚 Redis string operations reference"
echo "   │   └── troubleshooting.md                 🔧 String operations troubleshooting"
echo "   ├── examples/"
echo "   │   └── insurance-string-examples.md       📋 Practical insurance string examples"
echo "   ├── performance-tests/"
echo "   │   └── string-operations-performance.sh   ⚡ Performance testing scripts"
echo "   ├── sample-data/                           📁 Sample data directory"
echo "   ├── README.md                              📖 Project documentation"
echo "   └── .gitignore                             🚫 Git ignore rules"
echo ""
echo "🎯 NEXT STEPS:"
echo "   1. cd ${LAB_DIR}"
echo "   2. code .                                  # Open in VS Code"
echo "   3. Read lab3.md                           # Follow complete lab guide"
echo "   4. docker run -d --name redis-insurance-lab3 -p 6379:6379 redis:7-alpine"
echo "   5. ./scripts/load-insurance-string-data.sh"
echo "   6. redis-cli                              # Start practicing string operations"
echo ""
echo "🏢 INSURANCE STRING OPERATIONS FOCUS:"
echo "   🔢 Policy Number Generation: Atomic counters and validation"
echo "   💰 Premium Calculations: Race-condition-safe financial operations"
echo "   👥 Customer Management: Profile updates and data manipulation"
echo "   📄 Document Assembly: Dynamic policy document creation"
echo "   📊 Activity Logging: Customer interaction tracking and audit trails"
echo "   📈 Financial Reporting: Daily revenue and business metrics"
echo ""
echo "⚡ PERFORMANCE TESTING:"
echo "   🧪 Policy number generation performance (1000 operations)"
echo "   💲 Premium calculation efficiency testing"
echo "   👤 Customer data retrieval benchmarks"
echo "   📝 Individual vs batch operations comparison"
echo "   🧠 Memory usage analysis for different string patterns"
echo ""
echo "🔧 KEY STRING OPERATIONS:"
echo "   SET policy:AUTO-100001 \"policy_data\"     # Structured storage"
echo "   INCR policy:counter:auto                   # Atomic counters"
echo "   INCRBY premium:AUTO-100001 150             # Financial calculations"
echo "   APPEND customer:CUST001 \" | Risk: 750\"    # Profile updates"
echo "   MGET policy:AUTO-* premium:AUTO-*          # Batch operations"
echo ""
echo "🎉 READY TO START LAB 3!"
echo "   Open lab3.md for the complete 45-minute insurance string operations experience!"