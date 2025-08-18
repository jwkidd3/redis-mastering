# Lab 4: Insurance Key Management & TTL Strategies

**Duration:** 45 minutes  
**Objective:** Master advanced key organization patterns for insurance entities and implement sophisticated TTL strategies for quotes, sessions, and temporary data

## 🎯 Learning Objectives

By the end of this lab, you will be able to:
- Design and implement insurance-specific key naming conventions
- Create hierarchical key patterns for policy, customer, and claims organization
- Implement sophisticated quote expiration management with TTL strategies
- Build customer session management and cleanup automation
- Monitor key expiration patterns and optimize memory usage
- Apply key organization best practices for large-scale insurance databases

---

## Part 1: Insurance Key Naming Conventions & Organization (15 minutes)

### Step 1: Environment Setup with Key Management Focus

```bash
# Start Redis with optimized configuration for key management
docker run -d --name redis-insurance-lab4 \
  -p 6379:6379 \
  -v $(pwd)/sample-data:/data \
  redis:7-alpine redis-server --maxmemory 512mb --maxmemory-policy allkeys-lru --save 60 1

# Verify connection and clear any existing data
redis-cli ping
redis-cli FLUSHALL

# Load insurance key management sample data
./scripts/load-key-management-data.sh
```

### Step 2: Hierarchical Key Design for Insurance Entities

Insurance systems require well-organized key patterns for efficient management:

```redis
# Connect to Redis CLI
redis-cli

# === POLICY KEY HIERARCHY ===
# Pattern: policy:{type}:{number}:{attribute}
# Examples:
SET policy:auto:100001:details "2020 Toyota Camry - John Smith - $1,200 premium"
SET policy:auto:100001:status "ACTIVE"
SET policy:auto:100001:premium 1200
SET policy:auto:100001:customer "CUST001"
SET policy:auto:100001:agent "AG001"

SET policy:home:200001:details "123 Main St - Jane Doe - $800 premium"
SET policy:home:200001:status "ACTIVE"
SET policy:home:200001:premium 800
SET policy:home:200001:customer "CUST002"

SET policy:life:300001:details "$500K Term 20Y - Bob Johnson - $420 premium"
SET policy:life:300001:status "ACTIVE"
SET policy:life:300001:premium 420
SET policy:life:300001:customer "CUST003"

# === CUSTOMER KEY HIERARCHY ===
# Pattern: customer:{id}:{attribute}
SET customer:CUST001:profile "John Smith|1985-03-15|555-0123|john.smith@email.com"
SET customer:CUST001:address "456 Oak St, Dallas TX 75201"
SET customer:CUST001:risk_score 750
SET customer:CUST001:credit_score 720
SET customer:CUST001:customer_since "2018-05-20"

SET customer:CUST002:profile "Jane Doe|1990-07-22|555-0456|jane.doe@email.com"
SET customer:CUST002:address "789 Pine Ave, Dallas TX 75202"
SET customer:CUST002:risk_score 820
SET customer:CUST002:credit_score 780

# === CLAIMS KEY HIERARCHY ===
# Pattern: claim:{id}:{attribute}
SET claim:CLM001:details "Auto Accident - Policy: auto:100001 - Amount: $2,500"
SET claim:CLM001:status "PROCESSING"
SET claim:CLM001:amount 2500
SET claim:CLM001:adjuster "ADJ001"
SET claim:CLM001:filed_date "2024-08-18"

SET claim:CLM002:details "Water Damage - Policy: home:200001 - Amount: $8,200"
SET claim:CLM002:status "APPROVED"
SET claim:CLM002:amount 8200
SET claim:CLM002:adjuster "ADJ002"
```

### Step 3: Key Pattern Navigation and Discovery

```redis
# Policy pattern exploration
KEYS policy:*
KEYS policy:auto:*
KEYS policy:auto:100001:*

# Customer pattern exploration
KEYS customer:*
KEYS customer:CUST001:*

# Claims pattern exploration
KEYS claim:*
KEYS claim:CLM001:*

# Cross-entity relationship discovery
GET policy:auto:100001:customer
KEYS customer:CUST001:*

# Production-safe pattern scanning
SCAN 0 MATCH policy:auto:* COUNT 10
SCAN 0 MATCH customer:* COUNT 10
```

### Step 4: Key Organization Validation

```redis
# Verify key relationships and consistency
GET policy:auto:100001:customer          # Should return CUST001
EXISTS customer:CUST001:profile          # Should return 1
GET policy:auto:100001:premium           # Should return 1200

# Check data type consistency
TYPE policy:auto:100001:details          # Should be string
TYPE policy:auto:100001:premium          # Should be string (but numeric)
TYPE customer:CUST001:risk_score         # Should be string (but numeric)

# Validate key naming conventions
KEYS policy:*:*:*                        # All policy keys should follow pattern
KEYS customer:*:*                        # All customer keys should follow pattern
KEYS claim:*:*                           # All claim keys should follow pattern
```

**Business Context:**
- Hierarchical keys enable efficient entity management and relationship tracking
- Consistent naming conventions support automated operations and monitoring
- Pattern-based organization facilitates customer service and reporting operations

---

## Part 2: Quote Expiration Management with TTL Strategies (15 minutes)

### Step 1: Quote Generation with Business-Appropriate TTL

Different quote types require different expiration strategies:

```redis
# === AUTO INSURANCE QUOTES (5-minute TTL) ===
# Quick decisions expected, short expiration
SETEX quote:auto:Q001 300 "Honda Civic 2023 - Customer: CUST004 - Premium: $950/year - Agent: AG001"
SETEX quote:auto:Q002 300 "Toyota Prius 2022 - Customer: CUST005 - Premium: $880/year - Agent: AG002"

# Check auto quote TTL
TTL quote:auto:Q001
TTL quote:auto:Q002

# === HOME INSURANCE QUOTES (10-minute TTL) ===
# More complex decisions, medium expiration
SETEX quote:home:Q001 600 "Suburban Home 2200sqft - Customer: CUST006 - Premium: $1,200/year - Agent: AG001"
SETEX quote:home:Q002 600 "Condo 1400sqft - Customer: CUST007 - Premium: $650/year - Agent: AG003"

# === LIFE INSURANCE QUOTES (30-minute TTL) ===
# Complex underwriting decisions, longer expiration
SETEX quote:life:Q001 1800 "Term Life $500K 20Y - Customer: CUST008 - Premium: $45/month - Agent: AG002"
SETEX quote:life:Q002 1800 "Whole Life $250K - Customer: CUST009 - Premium: $180/month - Agent: AG001"

# Monitor quote expiration countdown
TTL quote:auto:Q001
TTL quote:home:Q001
TTL quote:life:Q001
```

### Step 2: Advanced Quote Management Patterns

```redis
# === QUOTE METADATA WITH TTL ===
# Store quote details separately with same TTL
SETEX quote:auto:Q001:customer 300 "CUST004"
SETEX quote:auto:Q001:agent 300 "AG001"
SETEX quote:auto:Q001:vehicle 300 "Honda Civic 2023"
SETEX quote:auto:Q001:premium 300 "950"

# === QUOTE STATUS TRACKING ===
SETEX quote:auto:Q001:status 300 "ACTIVE"
SETEX quote:auto:Q001:created 300 "2024-08-18T10:30:00Z"

# === QUOTE EXTENSION CAPABILITIES ===
# Extend quote expiration for customer convenience
EXPIRE quote:auto:Q001 600                # Extend to 10 minutes
EXPIRE quote:auto:Q001:customer 600
EXPIRE quote:auto:Q001:agent 600
EXPIRE quote:auto:Q001:vehicle 600
EXPIRE quote:auto:Q001:premium 600
EXPIRE quote:auto:Q001:status 600

# Verify extension
TTL quote:auto:Q001
MGET quote:auto:Q001 quote:auto:Q001:customer quote:auto:Q001:premium

# === QUOTE CONVERSION TRACKING ===
# When quote converts to policy, remove TTL and preserve
PERSIST quote:auto:Q001:converted
SET quote:auto:Q001:converted_to_policy "auto:100003"
SET quote:auto:Q001:conversion_date "2024-08-18T10:45:00Z"
```

### Step 3: Session Management with TTL

```redis
# === CUSTOMER SESSION MANAGEMENT ===
# Customer portal sessions (30-minute TTL)
SETEX session:customer:CUST001:portal 1800 "authenticated|login_time:2024-08-18T10:30:00Z|last_activity:2024-08-18T10:30:00Z"

# Agent session management (8-hour TTL for work day)
SETEX session:agent:AG001:workstation 28800 "authenticated|login_time:2024-08-18T08:00:00Z|branch:dallas"

# Mobile app sessions (2-hour TTL)
SETEX session:mobile:CUST001:device123 7200 "authenticated|device:iPhone12|app_version:2.1.0"

# === SESSION ACTIVITY TRACKING ===
# Update session activity (refresh TTL)
SET session:customer:CUST001:portal "authenticated|login_time:2024-08-18T10:30:00Z|last_activity:2024-08-18T10:45:00Z" EX 1800

# Session cleanup verification
TTL session:customer:CUST001:portal
TTL session:agent:AG001:workstation
TTL session:mobile:CUST001:device123

# === SESSION SECURITY FEATURES ===
# Failed login attempt tracking (5-minute TTL)
SETEX security:failed_logins:CUST001 300 "1"
INCR security:failed_logins:CUST001
GET security:failed_logins:CUST001

# Password reset tokens (15-minute TTL)
SETEX security:password_reset:CUST001:token123 900 "valid|issued:2024-08-18T10:30:00Z"
```

### Step 4: TTL Monitoring and Management

```redis
# === TTL ANALYSIS AND MONITORING ===
# Check remaining time on critical quotes
TTL quote:auto:Q001
TTL quote:home:Q001
TTL quote:life:Q001

# Monitor session expiration
TTL session:customer:CUST001:portal
TTL session:agent:AG001:workstation

# === KEYS WITHOUT TTL (PERSISTENT DATA) ===
# Verify persistent keys don't have TTL
TTL policy:auto:100001:details           # Should return -1 (no TTL)
TTL customer:CUST001:profile             # Should return -1 (no TTL)
TTL claim:CLM001:status                  # Should return -1 (no TTL)

# === TTL PATTERN ANALYSIS ===
# Find all keys with TTL
EVAL "
local keys = {}
local all_keys = redis.call('KEYS', '*')
for i, key in ipairs(all_keys) do
  local ttl = redis.call('TTL', key)
  if ttl > 0 then
    table.insert(keys, key .. ':' .. ttl)
  end
end
return keys
" 0

# === EXPIRED KEY CLEANUP MONITORING ===
# Redis handles expired key cleanup automatically
# Monitor memory usage to verify cleanup is working
INFO memory
```

**Business Context:**
- Quote TTL reflects business decision timeframes and customer behavior
- Session management ensures security and resource optimization
- TTL monitoring prevents data leaks and optimizes memory usage

---

## Part 3: Advanced Key Management and Memory Optimization (15 minutes)

### Step 1: Key Namespace Organization

```redis
# === BUSINESS UNIT SEPARATION ===
# Dallas office keys
SET office:dallas:policy:auto:100001 "Dallas auto policy data"
SET office:dallas:agent:AG001:performance "policies_sold:25|commission:18500"
SET office:dallas:revenue:daily:2024-08-18 0

# Houston office keys
SET office:houston:policy:auto:200001 "Houston auto policy data"
SET office:houston:agent:AG002:performance "policies_sold:31|commission:22400"
SET office:houston:revenue:daily:2024-08-18 0

# === ENVIRONMENT SEPARATION ===
# Production environment
SET prod:policy:auto:100001:status "ACTIVE"
SET prod:customer:CUST001:verified "true"

# Development environment keys (with shorter TTL for cleanup)
SETEX dev:policy:auto:100001:status 3600 "TESTING"
SETEX dev:customer:CUST001:verified 3600 "false"

# === TEMPORAL KEY ORGANIZATION ===
# Daily keys with automatic cleanup
SETEX metrics:daily:2024-08-18:policies_sold 86400 "0"
SETEX metrics:daily:2024-08-18:revenue 86400 "0"
SETEX metrics:daily:2024-08-18:claims_filed 86400 "0"

# Weekly keys (7-day TTL)
SETEX metrics:weekly:2024-W33:policies_sold 604800 "0"
SETEX metrics:weekly:2024-W33:revenue 604800 "0"

# Monthly keys (30-day TTL)
SETEX metrics:monthly:2024-08:policies_sold 2592000 "0"
SETEX metrics:monthly:2024-08:revenue 2592000 "0"
```

### Step 2: Key Lifecycle Management

```redis
# === POLICY LIFECYCLE TTL MANAGEMENT ===
# New policy application (24-hour review period)
SETEX application:auto:APP001 86400 "Customer: CUST010 | Vehicle: 2023 BMW X5 | Status: PENDING_REVIEW"

# Underwriting review (48-hour TTL)
SETEX underwriting:review:APP001 172800 "Assigned to UW001 | Risk Assessment: PENDING"

# Policy approval (convert to permanent)
SET policy:auto:100004:details "2023 BMW X5 - Customer: CUST010 - Premium: $1,800"
DEL application:auto:APP001                  # Remove temporary application
DEL underwriting:review:APP001               # Remove temporary review

# === CLAIMS LIFECYCLE MANAGEMENT ===
# Initial claim report (7-day TTL for follow-up)
SETEX claim:temp:CLM003 604800 "Auto Accident - Initial Report - Customer: CUST001 - Estimated: $3,500"

# Claims investigation (30-day TTL)
SETEX investigation:CLM003 2592000 "Adjuster: ADJ001 | Photos: 12 | Witness Statements: 2"

# Claim approval (convert to permanent record)
SET claim:CLM003:details "Auto Accident - Policy: auto:100001 - Amount: $3,200 - Status: APPROVED"
SET claim:CLM003:amount 3200
SET claim:CLM003:status "APPROVED"
DEL claim:temp:CLM003                        # Remove temporary claim
PERSIST investigation:CLM003                 # Keep investigation as permanent record
```

### Step 3: Memory Usage Monitoring and Optimization

```redis
# === KEY SIZE ANALYSIS ===
# Check memory usage of different key patterns
MEMORY USAGE policy:auto:100001:details
MEMORY USAGE customer:CUST001:profile
MEMORY USAGE quote:auto:Q001

# === KEY COUNT BY PATTERN ===
EVAL "
local patterns = {'policy:*', 'customer:*', 'claim:*', 'quote:*', 'session:*'}
local counts = {}
for i, pattern in ipairs(patterns) do
  local keys = redis.call('KEYS', pattern)
  table.insert(counts, pattern .. ':' .. #keys)
end
return counts
" 0

# === TTL DISTRIBUTION ANALYSIS ===
EVAL "
local ttl_ranges = {300, 600, 1800, 3600, 86400}
local ttl_names = {'5min', '10min', '30min', '1hr', '1day'}
local counts = {}

for i, range in ipairs(ttl_ranges) do
  local count = 0
  local keys = redis.call('KEYS', '*')
  for j, key in ipairs(keys) do
    local ttl = redis.call('TTL', key)
    if ttl > 0 and ttl <= range then
      count = count + 1
    end
  end
  table.insert(counts, ttl_names[i] .. ':' .. count)
end
return counts
" 0

# === MEMORY OPTIMIZATION PATTERNS ===
# Use hashes for structured data instead of multiple string keys
HMSET policy:structured:auto:100001 type "auto" customer "CUST001" premium 1200 agent "AG001" status "ACTIVE"

# Compare memory usage
MEMORY USAGE policy:auto:100001:details
MEMORY USAGE policy:structured:auto:100001

# Use sets for relationship tracking
SADD customer:CUST001:policies "auto:100001" "home:200001"
SADD agent:AG001:customers "CUST001" "CUST002" "CUST003"

# Check set memory efficiency
MEMORY USAGE customer:CUST001:policies
MEMORY USAGE agent:AG001:customers
```

### Step 4: Production Key Management Best Practices

```redis
# === KEY EXPIRATION MONITORING ===
# Set up key expiration notifications (if keyspace notifications enabled)
CONFIG SET notify-keyspace-events Ex

# Monitor key expiration events in separate terminal:
# redis-cli --csv psubscribe '__keyevent@0__:expired'

# === BATCH KEY OPERATIONS ===
# Bulk TTL updates for quote extensions
EVAL "
local quotes = redis.call('KEYS', 'quote:auto:*')
local extended = 0
for i, key in ipairs(quotes) do
  local ttl = redis.call('TTL', key)
  if ttl > 0 and ttl < 60 then
    redis.call('EXPIRE', key, 300)
    extended = extended + 1
  end
end
return 'Extended ' .. extended .. ' quotes'
" 0

# === KEY CLEANUP OPERATIONS ===
# Remove expired test keys
EVAL "
local test_keys = redis.call('KEYS', 'test:*')
local deleted = 0
for i, key in ipairs(test_keys) do
  redis.call('DEL', key)
  deleted = deleted + 1
end
return 'Deleted ' .. deleted .. ' test keys'
" 0

# === KEY BACKUP PATTERNS ===
# Create key backup with TTL
SET backup:policy:auto:100001:details "backup_data" EX 2592000  # 30-day backup
SET backup:timestamp "2024-08-18T15:00:00Z"

# Verify backup exists
EXISTS backup:policy:auto:100001:details
TTL backup:policy:auto:100001:details
```

**Business Context:**
- Namespace organization enables multi-tenant and multi-environment deployments
- Lifecycle management ensures data transitions properly between business states
- Memory optimization supports large-scale insurance database operations

---

## 🏆 Challenge Exercises (Optional - if time permits)

### Challenge 1: Dynamic Quote Pricing with TTL

Implement a dynamic pricing system where quotes have different TTL based on risk:

```redis
# High-risk customers get shorter quote validity (3 minutes)
SETEX quote:auto:Q003 180 "High-risk driver - Ford Mustang - Premium: $2,500/year"
SET quote:auto:Q003:risk_level "HIGH"

# Medium-risk customers get standard validity (5 minutes)
SETEX quote:auto:Q004 300 "Medium-risk driver - Honda Accord - Premium: $1,200/year"
SET quote:auto:Q004:risk_level "MEDIUM"

# Low-risk customers get extended validity (10 minutes)
SETEX quote:auto:Q005 600 "Low-risk driver - Toyota Camry - Premium: $900/year"
SET quote:auto:Q005:risk_level "LOW"

# Monitor risk-based TTL patterns
TTL quote:auto:Q003
TTL quote:auto:Q004
TTL quote:auto:Q005
```

### Challenge 2: Advanced Session Security

```redis
# Implement progressive session timeouts based on activity
SETEX session:customer:CUST001:active 1800 "high_activity"      # 30 min for active users
SETEX session:customer:CUST002:idle 600 "low_activity"          # 10 min for idle users

# Failed login lockout with escalating TTL
SETEX lockout:customer:CUST001:attempt1 300 "1_failure"         # 5 min first lockout
SETEX lockout:customer:CUST001:attempt2 900 "2_failures"        # 15 min second lockout
SETEX lockout:customer:CUST001:attempt3 3600 "3_failures"       # 1 hour third lockout

# Monitor lockout status
TTL lockout:customer:CUST001:attempt1
EXISTS lockout:customer:CUST001:attempt2
```

### Challenge 3: Automated Key Cleanup System

```redis
# Create temporary data with various TTL for cleanup testing
SETEX temp:quote:cleanup:Q001 60 "Short-term quote"
SETEX temp:session:cleanup:S001 120 "Medium-term session"  
SETEX temp:cache:cleanup:C001 180 "Longer-term cache"

# Implement cleanup monitoring
EVAL "
local cleanup_stats = {}
local patterns = {'temp:quote:*', 'temp:session:*', 'temp:cache:*'}

for i, pattern in ipairs(patterns) do
  local keys = redis.call('KEYS', pattern)
  local expiring_soon = 0
  
  for j, key in ipairs(keys) do
    local ttl = redis.call('TTL', key)
    if ttl > 0 and ttl < 30 then
      expiring_soon = expiring_soon + 1
    end
  end
  
  table.insert(cleanup_stats, pattern .. '_expiring_soon:' .. expiring_soon)
end

return cleanup_stats
" 0
```

---

## 📚 Key Takeaways

✅ **Key Organization**: Mastered hierarchical key naming conventions for insurance entities  
✅ **TTL Management**: Implemented business-appropriate expiration strategies for quotes and sessions  
✅ **Memory Optimization**: Applied key organization patterns for efficient memory usage  
✅ **Lifecycle Management**: Built key transition patterns for business process workflows  
✅ **Production Patterns**: Learned monitoring and cleanup strategies for large-scale deployments  
✅ **Security Integration**: Applied TTL for session management and security features

## 🔗 Next Steps

In **Lab 5: Advanced CLI Operations for Insurance Monitoring**, you'll build on this foundation:
- Advanced CLI scripting for insurance data automation
- Real-time monitoring for claims processing and policy updates
- Performance benchmarking for insurance transaction volumes
- Production monitoring best practices for insurance systems
- Automated alerting for business-critical operations

---

## 📖 Additional Resources

- [Redis Key Naming Best Practices](https://redis.io/docs/manual/keyspace/)
- [Redis TTL and Expiration Guide](https://redis.io/commands/expire/)
- [Memory Optimization Strategies](https://redis.io/docs/management/optimization/memory-optimization/)
- [Keyspace Notifications](https://redis.io/docs/manual/keyspace-notifications/)

## 🔧 Troubleshooting

**TTL Issues:**
```bash
# Check TTL configuration
redis-cli CONFIG GET "maxmemory*"

# Verify TTL behavior
redis-cli SETEX test:ttl 10 "test"
redis-cli TTL test:ttl

# Monitor key expiration
redis-cli CONFIG SET notify-keyspace-events Ex
redis-cli PSUBSCRIBE '__keyevent@0__:expired'
```

**Key Pattern Issues:**
```bash
# Validate key patterns
redis-cli KEYS "policy:*" | head -5
redis-cli SCAN 0 MATCH "customer:*" COUNT 10

# Check key relationships
redis-cli GET policy:auto:100001:customer
redis-cli EXISTS customer:CUST001:profile
```

**Memory Usage:**
```bash
# Monitor memory patterns
redis-cli INFO memory | grep used_memory_human
redis-cli --bigkeys | grep string
redis-cli MEMORY USAGE policy:auto:100001:details
```
