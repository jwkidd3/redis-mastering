# Lab 3: Data Operations with Strings

**Duration:** 45 minutes
**Focus:** Advanced string operations for data management
**Prerequisites:** Lab 2 completed

## 🎯 Learning Objectives

- Master policy number generation with atomic counters
- Perform atomic premium calculations
- Manage customer data with string operations
- Build document assembly workflows
- Optimize batch operations
- Prevent race conditions in financial calculations

## 🚀 Quick Start

### Step 1: Start Redis

```bash
docker run -d --name redis-lab3 -p 6379:6379 redis:7-alpine
```

### Step 2: Load Sample Data

```bash
./scripts/load-sample-data.sh
```

### Step 3: Test Connection

```bash
redis-cli ping
# Expected: PONG
```

## Part 1: Policy Number Generation

### Atomic Counters

```bash
# Create policy number generators
redis-cli INCR policy:counter:auto
redis-cli INCR policy:counter:home
redis-cli INCR policy:counter:life

# Generate formatted policy numbers
redis-cli INCR policy:counter:auto
# Use result: AUTO-000001
```

### Store Policy Data

```bash
# Create policies
redis-cli SET policy:AUTO-000001 "John Smith - Full Coverage"
redis-cli SET policy:HOME-000001 "Jane Doe - Homeowners"
redis-cli SET policy:LIFE-000001 "Bob Johnson - Term Life"

# Retrieve policies
redis-cli GET policy:AUTO-000001
```

## Part 2: Premium Calculations

### Atomic Financial Operations

```bash
# Initialize premiums
redis-cli SET premium:AUTO-000001 1000
redis-cli SET premium:HOME-000001 800

# Risk adjustments (atomic)
redis-cli INCRBY premium:AUTO-000001 150
redis-cli INCRBY premium:HOME-000001 50

# Apply discounts
redis-cli DECRBY premium:AUTO-000001 100

# Get final premium
redis-cli GET premium:AUTO-000001
```

## Part 3: Customer Data Management

### String Manipulation

```bash
# Create customer profiles
redis-cli SET customer:C001 "John Smith"
redis-cli SET customer:C002 "Jane Doe"

# Append additional data
redis-cli APPEND customer:C001 " | Risk Score: 750"
redis-cli APPEND customer:C001 " | Age: 35"

# Check string length
redis-cli STRLEN customer:C001

# Get full profile
redis-cli GET customer:C001
```

### Batch Operations

```bash
# Set multiple customers at once
redis-cli MSET customer:C003 "Bob" customer:C004 "Alice" customer:C005 "Charlie"

# Get multiple customers at once
redis-cli MGET customer:C003 customer:C004 customer:C005
```

## Part 4: Document Assembly

### Build Policy Documents

```bash
# Create document sections
redis-cli SET doc:AUTO-001:header "AUTO POLICY DOCUMENT"
redis-cli SET doc:AUTO-001:coverage "Full Coverage"
redis-cli SET doc:AUTO-001:terms "12 months"

# Append to document
redis-cli APPEND doc:AUTO-001:full "POLICY: AUTO-000001\n"
redis-cli APPEND doc:AUTO-001:full "COVERAGE: Full Coverage\n"
redis-cli APPEND doc:AUTO-001:full "PREMIUM: $1200\n"

# Get assembled document
redis-cli GET doc:AUTO-001:full
```

## Part 5: Financial Tracking

### Daily Revenue Tracking

```bash
# Track daily revenue (atomic)
redis-cli INCRBY revenue:daily:2024-11-04 1200
redis-cli INCRBY revenue:daily:2024-11-04 800
redis-cli INCRBY revenue:daily:2024-11-04 2500

# Get daily total
redis-cli GET revenue:daily:2024-11-04

# Track by policy type
redis-cli INCRBY revenue:auto:2024-11-04 1200
redis-cli INCRBY revenue:home:2024-11-04 800
```

## 🎓 Exercises

### Exercise 1: Policy System

1. Generate 20 policy numbers (auto, home, life)
2. Store policy data for each
3. Retrieve policies using MGET
4. Count total policies by type

### Exercise 2: Premium Calculator

1. Create 10 policies with initial premiums
2. Apply risk adjustments (+10% to +30%)
3. Apply discounts (-5% to -15%)
4. Calculate total premiums

### Exercise 3: Customer Profiles

1. Create 15 customer profiles
2. Append risk scores to each
3. Append ages to each
4. Find longest profile using STRLEN

### Exercise 4: Revenue Tracking

1. Simulate 100 policy sales across 5 days
2. Track daily revenue
3. Track revenue by policy type
4. Calculate 5-day total

## 📋 Key Commands

```bash
# Counters
INCR key                 # Atomic increment
INCRBY key amount       # Increment by amount
DECRBY key amount       # Decrement by amount

# String operations
SET key value           # Set string
GET key                # Get string
APPEND key value        # Append to string
STRLEN key             # String length

# Batch operations
MSET key1 val1 key2 val2   # Set multiple
MGET key1 key2 key3        # Get multiple
```

## 💡 Best Practices

1. **Use INCR/INCRBY:** For atomic counters and financial operations
2. **Use MSET/MGET:** For batch operations (much faster)
3. **Atomic operations:** Prevent race conditions
4. **Meaningful keys:** Use hierarchical naming (entity:type:id)

## ✅ Lab Completion Checklist

- [ ] Generated policy numbers with atomic counters
- [ ] Performed atomic premium calculations
- [ ] Managed customer data with APPEND
- [ ] Assembled documents with multiple operations
- [ ] Tracked revenue with atomic operations
- [ ] Used batch operations (MSET/MGET)

**Estimated time:** 45 minutes

## 📚 Additional Resources

- **String Commands:** `https://redis.io/commands/?group=string`
- **Atomic Operations:** `https://redis.io/docs/manual/transactions/`
