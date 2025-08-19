# Lab 3: Data Operations with Strings

**Duration:** 45 minutes  
**Objective:** Master advanced string operations for policy numbers, customer IDs, premium calculations, and data management

## 🎯 Learning Objectives

By the end of this lab, you will be able to:
- Implement policy number generation and validation using Redis strings
- Perform atomic premium calculations with string numeric operations
- Manage customer data efficiently with string concatenation and manipulation
- Build document processing workflows with string operations
- Optimize batch operations for policy updates and customer management
- Implement race condition prevention for financial calculations

---

## Part 1: Environment Setup & Basic String Operations (10 minutes)

### Step 1: Environment Setup

```bash
# Start Redis container
docker run -d --name redis-lab3 \
  -p 6379:6379 \
  redis:7-alpine redis-server --maxmemory 512mb --maxmemory-policy allkeys-lru

# Verify connection
redis-cli ping

# Load sample data
./scripts/load-sample-data.sh
```

### Step 2: Connect Using Redis Insight

1. Open Redis Insight
2. Connect to `localhost:6379` (or your remote host)
3. Navigate to the CLI tab within Redis Insight
4. Verify connection: `ping`

### Step 3: Basic String Operations

**Exercise 3.1: Policy Number Storage and Retrieval**

```bash
# Using Redis Insight CLI - Store basic policy information
SET policy:AUTO-100001 "customer_id:CUST001|premium:1200|status:active|created:2024-08-18"
SET policy:HOME-200001 "customer_id:CUST002|premium:800|status:active|created:2024-08-18"  
SET policy:LIFE-300001 "customer_id:CUST003|premium:500|status:active|created:2024-08-18"

# Retrieve policy information
GET policy:AUTO-100001
GET policy:HOME-200001
GET policy:LIFE-300001

# Check if policies exist
EXISTS policy:AUTO-100001
EXISTS policy:AUTO-999999    # Should return 0

# Get multiple policies at once (batch operation)
MGET policy:AUTO-100001 policy:HOME-200001 policy:LIFE-300001
```

**Exercise 3.2: String Length and Memory Analysis**

```bash
# Check string lengths
STRLEN policy:AUTO-100001
STRLEN policy:HOME-200001
STRLEN policy:LIFE-300001

# Analyze memory usage (if supported)
MEMORY USAGE policy:AUTO-100001
```

---

## Part 2: Atomic Numeric Operations & Premium Calculations (15 minutes)

### Step 4: Policy Counter Management

**Exercise 3.3: Atomic Policy Number Generation**

```bash
# Initialize policy counters for different types
SET policy:counter:auto 100000
SET policy:counter:home 200000  
SET policy:counter:life 300000

# Generate new policy numbers atomically (thread-safe)
INCR policy:counter:auto     # Returns: 100001
INCR policy:counter:auto     # Returns: 100002
INCR policy:counter:home     # Returns: 200001
INCR policy:counter:life     # Returns: 300001

# Check current counter values
MGET policy:counter:auto policy:counter:home policy:counter:life

# Reset a counter if needed
SET policy:counter:auto 100005
INCR policy:counter:auto     # Returns: 100006
```

### Step 5: Premium Calculations

**Exercise 3.4: Atomic Premium Management**

```bash
# Initialize premium amounts for policies
SET premium:AUTO-100001 1200
SET premium:AUTO-100002 1350
SET premium:HOME-200001 800
SET premium:LIFE-300001 500

# Apply risk adjustment increases (atomic operations prevent race conditions)
INCRBY premium:AUTO-100001 150    # Risk factor increase
INCRBY premium:HOME-200001 75     # Location risk adjustment
INCRBY premium:LIFE-300001 25     # Age factor adjustment

# Apply discounts (atomic decreases)
DECRBY premium:AUTO-100001 100    # Good driver discount
DECRBY premium:HOME-200001 50     # Security system discount
DECRBY premium:LIFE-300001 25     # Non-smoker discount

# Check final premium amounts
MGET premium:AUTO-100001 premium:AUTO-100002 premium:HOME-200001 premium:LIFE-300001
```

**Exercise 3.5: Multi-Policy Customer Calculations**

```bash
# Calculate total premiums for customer CUST001 (has multiple policies)
SET premium:AUTO-100001 1250
SET premium:HOME-200002 825
SET premium:LIFE-300002 475

# Simulate customer payment processing
SET payment:CUST001:total 0
INCRBY payment:CUST001:total 1250  # Auto premium
INCRBY payment:CUST001:total 825   # Home premium  
INCRBY payment:CUST001:total 475   # Life premium

GET payment:CUST001:total          # Should show 2550

# Apply multi-policy discount
DECRBY payment:CUST001:total 255   # 10% multi-policy discount
GET payment:CUST001:total          # Should show 2295
```

---

## Part 3: Advanced String Manipulation & Document Processing (15 minutes)

### Step 6: Customer Profile Management

**Exercise 3.6: Dynamic Customer Profile Building**

```bash
# Create base customer profiles
SET customer:CUST001 "John Smith | Age: 35 | Location: Dallas, TX"
SET customer:CUST002 "Sarah Johnson | Age: 42 | Location: Houston, TX"
SET customer:CUST003 "Michael Brown | Age: 28 | Location: Austin, TX"

# Append additional profile information dynamically
APPEND customer:CUST001 " | Risk Score: 750"
APPEND customer:CUST001 " | Credit Score: 780"
APPEND customer:CUST001 " | Driving Record: Clean"

APPEND customer:CUST002 " | Risk Score: 820"
APPEND customer:CUST002 " | Credit Score: 750"
APPEND customer:CUST002 " | Home Value: $350,000"

APPEND customer:CUST003 " | Risk Score: 680"
APPEND customer:CUST003 " | Health Status: Excellent"
APPEND customer:CUST003 " | Beneficiary: Spouse"

# Retrieve complete customer profiles
GET customer:CUST001
GET customer:CUST002
GET customer:CUST003

# Check profile sizes
STRLEN customer:CUST001
STRLEN customer:CUST002
STRLEN customer:CUST003
```

**Exercise 3.7: Batch Customer Operations**

```bash
# Batch retrieve multiple customer profiles
MGET customer:CUST001 customer:CUST002 customer:CUST003

# Set multiple customer preferences at once
MSET communication:CUST001 "Email Preferred" communication:CUST002 "Phone Preferred" communication:CUST003 "Mail Preferred"

# Retrieve customer communication preferences
MGET communication:CUST001 communication:CUST002 communication:CUST003
```

### Step 7: Document Assembly and Template Processing

**Exercise 3.8: Policy Document Generation**

```bash
# Create document fragments for policy assembly
SET doc:AUTO-100001:header "AUTO POLICY\nPolicy Number: AUTO-100001\nEffective Date: 2024-08-18\n"

APPEND doc:AUTO-100001:header "Policyholder: John Smith\nVehicle: 2022 Honda Accord\n\n"

SET doc:AUTO-100001:coverage "COVERAGE DETAILS:\n"
APPEND doc:AUTO-100001:coverage "Liability: $100,000/$300,000\n"
APPEND doc:AUTO-100001:coverage "Collision: $500 deductible\n"
APPEND doc:AUTO-100001:coverage "Comprehensive: $250 deductible\n\n"

SET doc:AUTO-100001:terms "TERMS AND CONDITIONS:\n"
APPEND doc:AUTO-100001:terms "Policy Term: 6 months\n"
APPEND doc:AUTO-100001:terms "Premium: $1,250\n"
APPEND doc:AUTO-100001:terms "Payment Method: Monthly\n\n"

# Retrieve complete document sections
GET doc:AUTO-100001:header
GET doc:AUTO-100001:coverage
GET doc:AUTO-100001:terms

# Check document section sizes
STRLEN doc:AUTO-100001:header
STRLEN doc:AUTO-100001:coverage
STRLEN doc:AUTO-100001:terms
```

**Exercise 3.9: Email Template and Communication Processing**

```bash
# Create email templates with dynamic content
SET email:template:welcome "Dear {{CUSTOMER_NAME}},\n\nWelcome to our family!"
APPEND email:template:welcome "\n\nYour policy {{POLICY_NUMBER}} is now active."
APPEND email:template:welcome "\n\nPremium: ${{PREMIUM_AMOUNT}}"
APPEND email:template:welcome "\n\nThank you for choosing us!\n\nBest regards,\nTeam"

# Create personalized emails by replacing templates
SET email:CUST001:welcome "Dear John Smith,\n\nWelcome to our family!"
APPEND email:CUST001:welcome "\n\nYour policy AUTO-100001 is now active."
APPEND email:CUST001:welcome "\n\nPremium: $1,250"
APPEND email:CUST001:welcome "\n\nThank you for choosing us!\n\nBest regards,\nTeam"

# Store communication log
SET activity:CUST001:log "2024-08-18T09:15:00Z - Policy inquiry via phone"
APPEND activity:CUST001:log " | 2024-08-18T09:30:00Z - Premium payment processed"
APPEND activity:CUST001:log " | 2024-08-18T10:45:00Z - Policy documents emailed"

# Retrieve complete communication templates and logs
GET email:template:welcome
GET email:CUST001:welcome
GET activity:CUST001:log
```

---

## Part 4: Performance & Advanced Operations (5 minutes)

### Step 8: Performance Optimization

**Exercise 3.10: Individual vs Batch Operations Performance**

```bash
# Test individual operations
TIME SET test:individual:1 "value1"
TIME SET test:individual:2 "value2"  
TIME SET test:individual:3 "value3"
TIME SET test:individual:4 "value4"
TIME SET test:individual:5 "value5"

# Test batch operations (compare performance)
TIME MSET test:batch:1 "value1" test:batch:2 "value2" test:batch:3 "value3" test:batch:4 "value4" test:batch:5 "value5"

# Compare retrieval performance
TIME MGET test:individual:1 test:individual:2 test:individual:3 test:individual:4 test:individual:5
TIME MGET test:batch:1 test:batch:2 test:batch:3 test:batch:4 test:batch:5

# Clean up test data
DEL test:individual:1 test:individual:2 test:individual:3 test:individual:4 test:individual:5
DEL test:batch:1 test:batch:2 test:batch:3 test:batch:4 test:batch:5
```

**Exercise 3.11: Transaction Safety and Error Handling**

```bash
# Implement atomic policy creation with transactions
MULTI
INCR policy:counter:auto
SET policy:AUTO-100003 "customer_id:CUST004|premium:1400|status:pending"
SET premium:AUTO-100003 1400
SET policy:AUTO-100003:customer "CUST004"
EXEC

# Verify transaction results
GET policy:counter:auto
GET policy:AUTO-100003
GET premium:AUTO-100003
GET policy:AUTO-100003:customer

# Test transaction rollback on error
MULTI
INCR policy:counter:auto
SET policy:AUTO-100004 "customer_id:CUST005|premium:1500|status:pending"
DISCARD                   # Cancel entire transaction

# Verify no changes were made
GET policy:counter:auto   # Should still be previous value
EXISTS policy:AUTO-100004 # Should return 0
```

---

## 🏆 Lab Summary and Key Takeaways

### What You've Accomplished

✅ **Policy Management:** Implemented atomic policy number generation and validation  
✅ **Financial Operations:** Performed race-condition-safe premium calculations  
✅ **Customer Data:** Built efficient profile management with string manipulation  
✅ **Document Processing:** Created dynamic document assembly workflows  
✅ **Performance Optimization:** Compared individual vs batch operations  
✅ **Transaction Safety:** Implemented atomic operations and rollback scenarios

### Key Redis String Commands Mastered

| Command | Purpose | Example |
|---------|---------|---------|
| `SET` | Store string values | `SET policy:AUTO-100001 "data"` |
| `GET` | Retrieve string values | `GET policy:AUTO-100001` |
| `MSET` | Set multiple strings | `MSET key1 "val1" key2 "val2"` |
| `MGET` | Get multiple strings | `MGET key1 key2 key3` |
| `INCR` | Increment numeric string | `INCR policy:counter:auto` |
| `INCRBY` | Increment by amount | `INCRBY premium:AUTO-100001 150` |
| `DECRBY` | Decrement by amount | `DECRBY premium:AUTO-100001 100` |
| `APPEND` | Append to string | `APPEND customer:CUST001 " \| Risk: 750"` |
| `STRLEN` | Get string length | `STRLEN customer:CUST001` |
| `EXISTS` | Check key existence | `EXISTS policy:AUTO-100001` |

### Performance Best Practices

1. **Use MGET/MSET** for batch operations instead of multiple GET/SET commands
2. **Implement atomic operations** with INCR/INCRBY/DECRBY for financial calculations
3. **Use transactions (MULTI/EXEC)** for complex multi-step operations
4. **Monitor string sizes** with STRLEN and MEMORY USAGE commands
5. **Structure keys logically** for efficient pattern matching and retrieval

### Real-World Applications

- **Policy Number Generation:** Atomic counters ensure unique policy IDs
- **Premium Calculations:** Race-condition-safe financial operations
- **Customer Profiles:** Dynamic profile building with string concatenation
- **Document Assembly:** Template-based document generation
- **Activity Logging:** Audit trail management with string operations
- **Revenue Tracking:** Real-time financial reporting and metrics

---

## 🚀 Next Steps

- **Lab 4:** Key Management & TTL Strategies
- **Lab 5:** Advanced CLI Operations & Monitoring
- **Lab 6:** JavaScript Redis Client Integration

**Duration:** 45 minutes ✅  
**Completed:** String Operations for Data Management
