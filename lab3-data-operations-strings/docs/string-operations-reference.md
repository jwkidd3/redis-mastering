# Redis String Operations Reference
## Data Management Focus

This reference covers Redis string commands optimized for data processing, policy management, and customer operations.

## Core String Commands

### Basic Storage Operations

| Command | Syntax | Purpose | Example |
|---------|--------|---------|---------|
| `SET` | `SET key value` | Store string value | `SET policy:AUTO-100001 "data"` |
| `GET` | `GET key` | Retrieve string value | `GET policy:AUTO-100001` |
| `MSET` | `MSET key1 val1 key2 val2` | Set multiple strings | `MSET premium:AUTO-100001 1200 premium:HOME-200001 800` |
| `MGET` | `MGET key1 key2 key3` | Get multiple strings | `MGET policy:AUTO-100001 policy:HOME-200001` |
| `EXISTS` | `EXISTS key` | Check if key exists | `EXISTS policy:AUTO-100001` |
| `DEL` | `DEL key [key ...]` | Delete keys | `DEL policy:AUTO-100001` |

### String Manipulation

| Command | Syntax | Purpose | Example |
|---------|--------|---------|---------|
| `APPEND` | `APPEND key value` | Append to string | `APPEND customer:CUST001 " \| Risk: 750"` |
| `STRLEN` | `STRLEN key` | Get string length | `STRLEN customer:CUST001` |
| `GETRANGE` | `GETRANGE key start end` | Get substring | `GETRANGE policy:AUTO-100001 0 10` |
| `SETRANGE` | `SETRANGE key offset value` | Replace part of string | `SETRANGE policy:AUTO-100001 50 "updated"` |

### Numeric Operations (Atomic)

| Command | Syntax | Purpose | Example |
|---------|--------|---------|---------|
| `INCR` | `INCR key` | Increment by 1 | `INCR policy:counter:auto` |
| `INCRBY` | `INCRBY key increment` | Increment by amount | `INCRBY premium:AUTO-100001 150` |
| `DECR` | `DECR key` | Decrement by 1 | `DECR inventory:forms` |
| `DECRBY` | `DECRBY key decrement` | Decrement by amount | `DECRBY premium:AUTO-100001 100` |
| `INCRBYFLOAT` | `INCRBYFLOAT key increment` | Increment by float | `INCRBYFLOAT rate:interest 0.025` |

## Data-Specific Patterns

### Policy Number Generation

```bash
# Initialize counters
SET policy:counter:auto 100000
SET policy:counter:home 200000
SET policy:counter:life 300000

# Generate unique policy numbers
INCR policy:counter:auto        # Returns: 100001
INCR policy:counter:home        # Returns: 200001

# Store policy with formatted number
SET policy:AUTO-100001 "customer_id:CUST001|premium:1200|status:active"
```

### Premium Calculations (Race-Condition Safe)

```bash
# Initial premium
SET premium:AUTO-100001 1200

# Apply adjustments atomically
INCRBY premium:AUTO-100001 150    # Risk factor increase
DECRBY premium:AUTO-100001 100    # Good driver discount
INCRBY premium:AUTO-100001 25     # Processing fee

# Final premium calculation result
GET premium:AUTO-100001           # Returns: 1275
```

### Customer Profile Management

```bash
# Base customer profile
SET customer:CUST001 "John Smith | Age: 35 | Location: Dallas, TX"

# Dynamic profile building
APPEND customer:CUST001 " | Risk Score: 750"
APPEND customer:CUST001 " | Credit Score: 780"
APPEND customer:CUST001 " | Driving Record: Clean"

# Complete profile retrieval
GET customer:CUST001
```

### Document Assembly

```bash
# Document header
SET doc:AUTO-100001:header "AUTO POLICY\nPolicy: AUTO-100001\n"

# Coverage details
SET doc:AUTO-100001:coverage "Liability: $100,000/$300,000\n"
APPEND doc:AUTO-100001:coverage "Collision: $500 deductible\n"
APPEND doc:AUTO-100001:coverage "Comprehensive: $250 deductible\n"

# Retrieve complete sections
GET doc:AUTO-100001:header
GET doc:AUTO-100001:coverage
```

## Performance Optimization Patterns

### Batch Operations

```bash
# Instead of multiple SET commands
SET policy:AUTO-100001 "data1"
SET policy:AUTO-100002 "data2"
SET policy:AUTO-100003 "data3"

# Use MSET for better performance
MSET policy:AUTO-100001 "data1" policy:AUTO-100002 "data2" policy:AUTO-100003 "data3"

# Instead of multiple GET commands
GET policy:AUTO-100001
GET policy:AUTO-100002  
GET policy:AUTO-100003

# Use MGET for better performance
MGET policy:AUTO-100001 policy:AUTO-100002 policy:AUTO-100003
```

### Memory Optimization

```bash
# Monitor string memory usage
MEMORY USAGE customer:CUST001
STRLEN customer:CUST001

# Check total memory statistics
INFO memory

# Analyze large keys
--bigkeys
```

## Transaction Safety

### Atomic Multi-Step Operations

```bash
# Atomic policy creation
MULTI
INCR policy:counter:auto
SET policy:AUTO-100003 "customer_id:CUST004|premium:1400"
SET premium:AUTO-100003 1400
EXEC

# Transaction rollback on error
MULTI
INCR policy:counter:auto
SET policy:AUTO-100004 "invalid_data"
DISCARD  # Cancel entire transaction
```

### Race Condition Prevention

```bash
# Safe concurrent premium updates
INCRBY premium:AUTO-100001 100   # Atomic operation
INCRBY premium:AUTO-100001 50    # Another atomic operation
DECRBY premium:AUTO-100001 25    # Atomic discount

# Result is predictable regardless of execution order
GET premium:AUTO-100001
```

## Best Practices Summary

1. **Use atomic operations** (INCR, INCRBY, DECRBY) for financial calculations
2. **Implement batch operations** (MGET, MSET) for better performance
3. **Structure keys logically** with consistent naming patterns
4. **Use transactions** (MULTI/EXEC) for complex multi-step operations
5. **Monitor memory usage** with STRLEN and MEMORY USAGE commands
6. **Validate key existence** with EXISTS before operations
7. **Handle errors gracefully** with proper type checking
8. **Track performance** with SLOWLOG and latency monitoring

This reference provides the foundation for efficient string operations in Redis for data management applications.
