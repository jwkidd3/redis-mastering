# Lab 4: Key Management & TTL

**Duration:** 45 minutes
**Focus:** Key organization patterns and TTL strategies
**Prerequisites:** Lab 3 completed (String operations)

## 🎯 Learning Objectives

- Design hierarchical key naming conventions
- Implement TTL for quotes, sessions, and temporary data
- Monitor key expiration and memory usage
- Build session management with automatic cleanup

## 📁 Project Structure

```
lab4-key-management-ttl/
├── README.md                         # This file
├── scripts/
│   └── load-key-management-data.sh  # Sample data loader
├── docs/
│   └── key-patterns.md              # Key naming best practices
└── monitoring-tools/
    └── key-ttl-monitor.sh           # TTL monitoring script
```

## 🚀 Quick Start

### 1. Test Connection

```bash
redis-cli ping
```

### 2. Load Sample Data

```bash
./scripts/load-key-management-data.sh
```

## Part 1: Key Naming Conventions

### Hierarchical Key Design

Use colon-separated patterns for organization:

```bash
# Pattern: entity:type:id:attribute

# Policy keys
SET policy:auto:100001:status "active"
SET policy:auto:100001:premium "1200.00"
SET policy:home:200001:status "active"
SET policy:life:300001:status "pending"

# Customer keys
SET customer:C001:name "John Smith"
SET customer:C001:email "john@example.com"
SET customer:C001:tier "premium"

# Claims keys
SET claim:CLM001:status "submitted"
SET claim:CLM001:amount "5000"
SET claim:CLM001:policy "policy:auto:100001"
```

### Search by Pattern

```bash
# Find all auto policies
KEYS policy:auto:*

# Find all customer data
KEYS customer:*

# Find specific customer's data
KEYS customer:C001:*

# Count keys by pattern
redis-cli --scan --pattern "policy:*" | wc -l
```

### Best Practices

- Use lowercase with colons: `customer:123:email`
- Be consistent: Always use same order (`entity:id:attribute`)
- Avoid special characters
- Keep keys under 100 characters
- Use meaningful prefixes

## Part 2: TTL Management

### Set Expiration

```bash
# Set TTL when creating key (SETEX)
SETEX quote:Q12345 3600 '{"coverage":"100k", "premium":"50"}'

# Add TTL to existing key
SET session:user123 "session-data"
EXPIRE session:user123 1800

# TTL in milliseconds
PEXPIRE temp:data 5000
```

### Check TTL

```bash
# Check remaining time (seconds)
TTL quote:Q12345

# Check in milliseconds
PTTL quote:Q12345

# Check if key has TTL
TTL mykey
# Returns:
# -2 = key doesn't exist
# -1 = key exists but no TTL
# positive number = seconds remaining
```

### Remove Expiration

```bash
# Make key permanent
PERSIST session:user123

# Verify (should return -1)
TTL session:user123
```

### Update Expiration

```bash
# Reset TTL
EXPIRE session:user123 3600

# Add more time
redis-cli SET mykey "value"
redis-cli EXPIRE mykey 100
# Later add 50 more seconds
redis-cli EXPIRE mykey 150
```

## Part 3: Quote Management System

### Create Quote with TTL

```bash
# Quotes expire after 24 hours (86400 seconds)
SETEX quote:Q001 86400 '{"type":"auto","premium":"1200"}'
SETEX quote:Q002 86400 '{"type":"home","premium":"850"}'
SETEX quote:Q003 86400 '{"type":"life","premium":"45"}'
```

### Check Quote Status

```bash
# How long until quote expires?
TTL quote:Q001

# Is quote still valid?
EXISTS quote:Q001
```

### Extend Quote Expiration

```bash
# Extend by another 24 hours
EXPIRE quote:Q001 86400
```

### Cleanup Expired Quotes

```bash
# Redis automatically removes expired keys
# Check remaining quotes
KEYS quote:*
```

## Part 4: Session Management

### Create User Session

```bash
# Session expires after 30 minutes (1800 seconds)
SETEX session:user:alice 1800 '{"userId":"alice","role":"admin","loginTime":"2024-01-01T10:00:00Z"}'
SETEX session:user:bob 1800 '{"userId":"bob","role":"user","loginTime":"2024-01-01T10:05:00Z"}'
```

### Renew Session

```bash
# User activity - extend session
EXPIRE session:user:alice 1800
```

### Check Session

```bash
# Is session valid?
EXISTS session:user:alice

# Get session data
GET session:user:alice

# How much time left?
TTL session:user:alice
```

### Session Monitoring

```bash
# Count active sessions
redis-cli --scan --pattern "session:*" | wc -l

# Find sessions expiring soon (< 5 minutes)
# Use monitoring script
./monitoring-tools/key-ttl-monitor.sh session:* 300
```

## Part 5: Temporary Data Management

### Cache with TTL

```bash
# Cache API response for 5 minutes
SETEX cache:weather:london 300 '{"temp":18,"conditions":"cloudy"}'

# Cache search results for 10 minutes
SETEX cache:search:term123 600 '[{"id":1},{"id":2}]'
```

### Rate Limiting

```bash
# Allow 100 API calls per hour
SET ratelimit:user:alice:2024-01-01-10 0
EXPIRE ratelimit:user:alice:2024-01-01-10 3600
INCR ratelimit:user:alice:2024-01-01-10

# Check remaining calls
GET ratelimit:user:alice:2024-01-01-10
```

### Temporary Locks

```bash
# Acquire lock for 30 seconds
SET lock:process:batch-001 "worker-1" NX EX 30

# Check if lock exists
EXISTS lock:process:batch-001

# Lock auto-releases after 30 seconds
```

## 🎓 Exercises

### Exercise 1: Policy Organization

Create keys for 20 policies (auto, home, life) with proper naming:

```bash
# Your solution
SET policy:auto:100001:status "active"
SET policy:auto:100001:premium "1200"
# ...continue pattern
```

### Exercise 2: Quote System

1. Create 10 quotes with 24-hour expiration
2. Check TTL for each quote
3. Extend 3 quotes by 12 hours
4. Wait 5 seconds and check which expired

### Exercise 3: Session Management

1. Create sessions for 5 users (30-minute TTL)
2. Renew 2 sessions
3. Check remaining TTL for all
4. Count active sessions

### Exercise 4: Memory Monitoring

1. Create 100 keys with various TTLs
2. Check memory usage with `INFO memory`
3. Wait for some to expire
4. Check memory again

## 📋 Key Redis Commands

```bash
# Set with expiration
SETEX key seconds value           # Set with TTL
PSETEX key milliseconds value     # Set with TTL (ms)

# Add expiration to existing key
EXPIRE key seconds                 # Add TTL
PEXPIRE key milliseconds          # Add TTL (ms)
EXPIREAT key timestamp            # Expire at Unix timestamp

# Check expiration
TTL key                           # Check TTL (seconds)
PTTL key                          # Check TTL (milliseconds)

# Remove expiration
PERSIST key                       # Make permanent

# Key operations
KEYS pattern                      # Find keys (avoid in production!)
SCAN cursor [MATCH pattern]       # Iterate keys (production-safe)
EXISTS key [key ...]              # Check if exists
DEL key [key ...]                 # Delete keys
TYPE key                          # Get key type
```

## 💡 Best Practices

### Key Naming

```bash
# ✅ Good
SET customer:123:email "user@example.com"
SET policy:auto:456:status "active"
SET cache:user:789:profile "{...}"

# ❌ Bad
SET "customer 123 email" "user@example.com"  # Spaces
SET CUSTOMER_123_EMAIL "user@example.com"    # Inconsistent
SET c123e "user@example.com"                 # Not descriptive
```

### TTL Strategy

```bash
# ✅ Good: Set TTL when creating
SETEX quote:Q001 86400 "data"

# ❌ Bad: Separate commands (race condition)
SET quote:Q001 "data"
EXPIRE quote:Q001 86400
```

### Memory Management

```bash
# ✅ Good: Use TTL for temporary data
SETEX cache:data 3600 "temporary"

# ❌ Bad: Manual cleanup required
SET cache:data "temporary"  # Never expires!
```

## 🔍 Monitoring

### Check Key Distribution

```bash
# Count keys by pattern
redis-cli --scan --pattern "policy:*" | wc -l
redis-cli --scan --pattern "customer:*" | wc -l
redis-cli --scan --pattern "session:*" | wc -l
```

### Memory Usage

```bash
# Total memory
redis-cli INFO memory | grep used_memory_human

# Memory per key
redis-cli --memkeys --memkeys-samples 100
```

### Expiration Stats

```bash
# Check expiration info
redis-cli INFO stats | grep expire
```

## ⚠️ Important Notes

1. **KEYS Command:** Avoid in production (blocks server). Use SCAN instead.
2. **TTL Precision:** Redis checks for expired keys lazily and periodically.
3. **Memory:** Expired keys consume memory until deleted.
4. **Persistence:** RDB/AOF save unexpired TTLs.

## ✅ Lab Completion Checklist

- [ ] Created hierarchical key structures for policies, customers, claims
- [ ] Implemented quote system with 24-hour TTL
- [ ] Built session management with 30-minute TTL
- [ ] Used EXPIRE, TTL, PERSIST commands
- [ ] Monitored key expiration patterns
- [ ] Understood lazy expiration behavior

**Estimated time:** 45 minutes

## 📚 Additional Resources

- **Redis Keys:** `https://redis.io/docs/manual/keyspace/`
- **Redis TTL:** `https://redis.io/commands/ttl/`
- **Key Patterns:** `docs/key-patterns.md`
