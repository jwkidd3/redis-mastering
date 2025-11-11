# Lab 3: Data Operations with Strings

**Duration:** 45 minutes
**Focus:** Advanced string operations for data management in Redis Insight Workbench
**Prerequisites:** Lab 2 completed, Redis Insight connected

## 🎯 Learning Objectives

- Master policy number generation with atomic counters
- Perform atomic premium calculations
- Manage customer data with string operations
- Build document assembly workflows
- Optimize batch operations
- Prevent race conditions in financial calculations
- Use Redis Insight Browser to visualize string data

## 🚀 Quick Start

### Step 1: Ensure Redis is Running

**Windows:**
```cmd
cd scripts
start-redis.bat
```

**Mac/Linux:**
```bash
docker run -d -p 6379:6379 --name redis redis/redis-stack:latest
```

### Step 2: Open Redis Insight Workbench

1. Open Redis Insight
2. Connect to your database
3. Click **"Workbench"** tab
4. You're ready to run commands!

### Step 3: Test Connection

**In Workbench, run:**
```redis
PING
```
Expected response: `PONG`

## Part 1: Policy Number Generation

### Atomic Counters

**In Workbench, run these commands:**

```redis
// Create policy number generators
INCR policy:counter:auto
INCR policy:counter:home
INCR policy:counter:life

// Generate formatted policy numbers
INCR policy:counter:auto
// Use result: AUTO-000001
```

💡 **Why Atomic?** INCR is atomic - multiple clients can increment safely without race conditions. Perfect for generating unique policy numbers!

### Store Policy Data

```redis
// Create policies
SET policy:AUTO-000001 "John Smith - Full Coverage"
SET policy:HOME-000001 "Jane Doe - Homeowners"
SET policy:LIFE-000001 "Bob Johnson - Term Life"

// Retrieve policies
GET policy:AUTO-000001
```

### Visualize in Browser

1. Switch to **Browser** tab
2. Search for `policy:*`
3. See all your policies listed
4. Click on `policy:AUTO-000001` to view the value
5. Notice the counter keys (`policy:counter:auto`) showing the current count

## Part 2: Premium Calculations

### Atomic Financial Operations

**In Workbench, run these commands:**

```redis
// Initialize premiums
SET premium:AUTO-000001 1000
SET premium:HOME-000001 800

// Risk adjustments (atomic)
INCRBY premium:AUTO-000001 150
INCRBY premium:HOME-000001 50

// Apply discounts
DECRBY premium:AUTO-000001 100

// Get final premium
GET premium:AUTO-000001
```

**Expected result:** `1050` (1000 + 150 - 100)

💡 **Financial Safety:** INCRBY and DECRBY are atomic operations. Multiple agents can adjust premiums concurrently without corrupting the data - critical for financial systems!

### Monitor Changes in Real-Time

1. Keep **Browser** tab open while running commands
2. Click the refresh icon to see premium values update
3. Watch the atomic operations take effect
4. No need to switch between terminal and GUI!

## Part 3: Customer Data Management

### String Manipulation

**In Workbench, run these commands:**

```redis
// Create customer profiles
SET customer:C001 "John Smith"
SET customer:C002 "Jane Doe"

// Append additional data
APPEND customer:C001 " | Risk Score: 750"
APPEND customer:C001 " | Age: 35"

// Check string length
STRLEN customer:C001

// Get full profile
GET customer:C001
```

**Expected output:** `"John Smith | Risk Score: 750 | Age: 35"`

### Batch Operations

```redis
// Set multiple customers at once
MSET customer:C003 "Bob" customer:C004 "Alice" customer:C005 "Charlie"

// Get multiple customers at once
MGET customer:C003 customer:C004 customer:C005
```

💡 **Performance Tip:** MSET and MGET execute in a single network round trip. Setting 100 keys with MSET is 100x faster than 100 individual SET commands!

### Compare Performance with Profiler

1. Open **Profiler** in Redis Insight (left sidebar)
2. Click **"Start"**
3. Run individual SETs in Workbench:
   ```redis
   SET test:1 "value1"
   SET test:2 "value2"
   SET test:3 "value3"
   ```
4. Run batch MSET:
   ```redis
   MSET test:4 "value4" test:5 "value5" test:6 "value6"
   ```
5. Click **"Stop"** in Profiler
6. Compare: 3 separate timestamps vs. 1 timestamp - see the difference!

## Part 4: Document Assembly

### Build Policy Documents

**In Workbench, run these commands:**

```redis
// Create document sections
SET doc:AUTO-001:header "AUTO POLICY DOCUMENT"
SET doc:AUTO-001:coverage "Full Coverage"
SET doc:AUTO-001:terms "12 months"

// Append to document
APPEND doc:AUTO-001:full "POLICY: AUTO-000001\n"
APPEND doc:AUTO-001:full "COVERAGE: Full Coverage\n"
APPEND doc:AUTO-001:full "PREMIUM: $1200\n"

// Get assembled document
GET doc:AUTO-001:full
```

**Expected output:**
```
POLICY: AUTO-000001
COVERAGE: Full Coverage
PREMIUM: $1200
```

### View Document Structure in Browser

1. Switch to **Browser** tab
2. Search for `doc:AUTO-001:*`
3. See all document components:
   - `doc:AUTO-001:header`
   - `doc:AUTO-001:coverage`
   - `doc:AUTO-001:terms`
   - `doc:AUTO-001:full` (assembled version)
4. Click each key to inspect individual sections

## Part 5: Financial Tracking

### Daily Revenue Tracking

**In Workbench, run these commands:**

```redis
// Track daily revenue (atomic)
INCRBY revenue:daily:2024-11-10 1200
INCRBY revenue:daily:2024-11-10 800
INCRBY revenue:daily:2024-11-10 2500

// Get daily total
GET revenue:daily:2024-11-10

// Track by policy type
INCRBY revenue:auto:2024-11-10 1200
INCRBY revenue:home:2024-11-10 800
```

**Expected daily total:** `4500` (1200 + 800 + 2500)

💡 **Real-World Use Case:** This pattern is perfect for financial systems where multiple services add revenue concurrently. INCRBY ensures no money gets lost due to race conditions!

### Track Revenue Over Time

```redis
// Track revenue for multiple days
INCRBY revenue:daily:2024-11-08 3200
INCRBY revenue:daily:2024-11-09 4100
INCRBY revenue:daily:2024-11-10 4500

// Get week's revenue
MGET revenue:daily:2024-11-08 revenue:daily:2024-11-09 revenue:daily:2024-11-10
```

### Visualize Revenue in Browser

1. Switch to **Browser** tab
2. Search for `revenue:*`
3. See all revenue keys organized by date and type
4. Click each key to see total values
5. Use the search to filter by specific dates or policy types

## 🎓 Exercises

Complete these exercises in **Redis Insight Workbench**:

### Exercise 1: Policy System

**Goal:** Generate and manage 20 policy numbers

```redis
// 1. Generate 20 policy numbers (auto, home, life)
INCR policy:counter:auto
INCR policy:counter:auto
// ... repeat for different types

// 2. Store policy data using MSET
MSET policy:AUTO-000001 "Customer A - Coverage" policy:AUTO-000002 "Customer B - Coverage"

// 3. Retrieve multiple policies
MGET policy:AUTO-000001 policy:AUTO-000002 policy:HOME-000001

// 4. Check counters to count total by type
GET policy:counter:auto
GET policy:counter:home
GET policy:counter:life
```

**Verify in Browser:** Switch to Browser tab and search for `policy:*`

---

### Exercise 2: Premium Calculator

**Goal:** Calculate adjusted premiums for 10 policies

```redis
// 1. Create 10 policies with initial premiums
MSET premium:AUTO-001 1000 premium:AUTO-002 1200 premium:HOME-001 800 premium:HOME-002 900

// 2. Apply risk adjustments (atomic)
INCRBY premium:AUTO-001 100  // +10%
INCRBY premium:AUTO-002 360  // +30%

// 3. Apply discounts
DECRBY premium:AUTO-001 50   // -5%
DECRBY premium:AUTO-002 180  // -15%

// 4. Calculate total premiums
MGET premium:AUTO-001 premium:AUTO-002 premium:HOME-001 premium:HOME-002
```

**Challenge:** Use Profiler to verify all operations are atomic!

---

### Exercise 3: Customer Profiles

**Goal:** Build and analyze customer profiles

```redis
// 1. Create 15 customer profiles
MSET customer:C001 "John" customer:C002 "Jane" customer:C003 "Bob"

// 2. Append risk scores
APPEND customer:C001 " | Risk: 750"
APPEND customer:C002 " | Risk: 820"

// 3. Append ages
APPEND customer:C001 " | Age: 35"
APPEND customer:C002 " | Age: 42"

// 4. Find longest profile
STRLEN customer:C001
STRLEN customer:C002
STRLEN customer:C003
```

**Tip:** Use Browser tab to visually compare profile lengths!

---

### Exercise 4: Revenue Tracking

**Goal:** Track revenue across 5 days

```redis
// 1-2. Simulate policy sales and track daily revenue
INCRBY revenue:daily:2024-11-06 1200
INCRBY revenue:daily:2024-11-06 800
INCRBY revenue:daily:2024-11-07 1500
// ... continue for 5 days

// 3. Track revenue by policy type
INCRBY revenue:auto:2024-11-06 1200
INCRBY revenue:home:2024-11-06 800

// 4. Calculate 5-day total
MGET revenue:daily:2024-11-06 revenue:daily:2024-11-07 revenue:daily:2024-11-08 revenue:daily:2024-11-09 revenue:daily:2024-11-10
```

**Bonus:** Create a simple script in Workbench to calculate the sum!

---

## 📋 Key Commands Reference

**Run these in Redis Insight Workbench:**

### Counters (Atomic Operations)
```redis
INCR key                    // Atomic increment by 1
INCRBY key amount          // Increment by specific amount
DECRBY key amount          // Decrement by specific amount
```

### String Operations
```redis
SET key value              // Set string value
GET key                    // Get string value
APPEND key value           // Append to existing string
STRLEN key                 // Get string length
```

### Batch Operations (Performance Optimized)
```redis
MSET key1 val1 key2 val2   // Set multiple keys (one round trip)
MGET key1 key2 key3        // Get multiple keys (one round trip)
```

💡 **Pro Tip:** All commands above are available with autocomplete in Redis Insight Workbench - just start typing and press Tab!

---

## 💡 Best Practices

1. **Use INCR/INCRBY for financial operations**
   - Atomic operations prevent race conditions
   - Perfect for policy numbers, premium calculations, revenue tracking
   - No risk of data corruption from concurrent access

2. **Use MSET/MGET for batch operations**
   - Much faster than individual commands
   - One network round trip vs. many
   - Use Profiler to verify performance improvements

3. **Use meaningful hierarchical keys**
   - Pattern: `entity:type:id` (e.g., `policy:AUTO-000001`)
   - Makes data easy to find in Browser tab
   - Enables pattern matching with KEYS or SCAN

4. **Leverage Redis Insight features**
   - **Workbench:** Execute commands with autocomplete
   - **Browser:** Visualize data structure and relationships
   - **Profiler:** Monitor performance and verify atomicity

---

## ✅ Lab Completion Checklist

- [ ] Opened Redis Insight and connected to database
- [ ] Ran all commands in Workbench (not terminal)
- [ ] Generated policy numbers with atomic counters
- [ ] Performed atomic premium calculations
- [ ] Managed customer data with APPEND
- [ ] Assembled documents with multiple operations
- [ ] Tracked revenue with atomic operations
- [ ] Used batch operations (MSET/MGET)
- [ ] Used Profiler to compare performance
- [ ] Explored data in Browser tab
- [ ] Completed all 4 exercises

**Estimated time:** 45 minutes

---

## 🔍 Redis Insight Features Used in This Lab

| Feature | Purpose | When Used |
|---------|---------|-----------|
| **Workbench** | Execute all Redis commands | All parts and exercises |
| **Browser** | Visualize keys and values | Viewing policies, customers, revenue |
| **Profiler** | Compare batch vs. individual operations | Performance testing in Part 3 |
| **Autocomplete** | Faster command entry | Throughout the lab |

---

## 📚 Additional Resources

- **Redis String Commands:** https://redis.io/commands/?group=string
- **Atomic Operations:** https://redis.io/docs/manual/transactions/
- **Redis Insight Documentation:** https://redis.io/docs/stack/insight/

---

## 💡 Key Takeaways

1. **Atomic operations are critical** for financial and counting operations
2. **Batch commands (MSET/MGET)** dramatically improve performance
3. **Redis Insight Workbench** provides a better experience than terminal CLI
4. **APPEND is powerful** for building strings incrementally
5. **Hierarchical key naming** makes data organization intuitive
6. **Profiler helps verify** that optimizations actually work

---

## ⏭️ Next Steps

**Lab 4:** Advanced data operations with Lists, Sets, and more complex string patterns.

Ready to continue? Open Lab 4's README.md in Redis Insight!
