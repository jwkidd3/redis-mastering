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
