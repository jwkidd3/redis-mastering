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
