#!/bin/bash

# Lab 4 Content Generator Script
# Generates complete content and code for Lab 4: Insurance Key Management & TTL Strategies
# Duration: 45 minutes
# Focus: Advanced key organization, quote expiration, session management (NO JAVASCRIPT)

set -e

LAB_DIR="lab4-insurance-key-management-ttl"
LAB_NUMBER="4"
LAB_TITLE="Insurance Key Management & TTL Strategies"
LAB_DURATION="45"

echo "🚀 Generating Lab ${LAB_NUMBER}: ${LAB_TITLE}"
echo "📅 Duration: ${LAB_DURATION} minutes"
echo "🎯 Focus: Advanced key organization patterns and TTL-based expiration strategies"
echo ""

# Create lab directory structure
mkdir -p ${LAB_DIR}
cd ${LAB_DIR}

echo "📁 Creating lab directory structure..."
mkdir -p {scripts,docs,examples,sample-data,key-patterns,monitoring-tools}

# Create main lab instructions markdown file
echo "📋 Creating lab4.md..."
cat > lab4.md << 'EOF'
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
EOF

# Create sample data loading script
echo "📊 Creating scripts/load-key-management-data.sh..."
cat > scripts/load-key-management-data.sh << 'EOF'
#!/bin/bash

# Insurance Key Management Sample Data Loader
# Comprehensive data for key organization and TTL management exercises

echo "🗝️ Loading Insurance Key Management Sample Data..."

redis-cli << 'REDIS_EOF'
# Clear existing data
FLUSHALL

# === HIERARCHICAL POLICY KEYS ===
# Auto Policies
SET policy:auto:100001:details "2020 Toyota Camry LE - John Smith - $1,200 premium - Full Coverage"
SET policy:auto:100001:status "ACTIVE"
SET policy:auto:100001:premium 1200
SET policy:auto:100001:customer "CUST001"
SET policy:auto:100001:agent "AG001"
SET policy:auto:100001:effective_date "2024-01-15"
SET policy:auto:100001:expiration_date "2025-01-15"

SET policy:auto:100002:details "2019 Honda Civic LX - Alice Brown - $950 premium - Full Coverage"
SET policy:auto:100002:status "ACTIVE"
SET policy:auto:100002:premium 950
SET policy:auto:100002:customer "CUST004"
SET policy:auto:100002:agent "AG002"
SET policy:auto:100002:effective_date "2024-03-01"
SET policy:auto:100002:expiration_date "2025-03-01"

# Home Policies
SET policy:home:200001:details "123 Main St Dallas TX - Jane Doe - $800 premium - Full Replacement"
SET policy:home:200001:status "ACTIVE"
SET policy:home:200001:premium 800
SET policy:home:200001:customer "CUST002"
SET policy:home:200001:agent "AG001"
SET policy:home:200001:effective_date "2024-02-10"
SET policy:home:200001:expiration_date "2025-02-10"

SET policy:home:200002:details "456 Oak Ave Dallas TX - Charlie Wilson - $650 premium - Actual Cash Value"
SET policy:home:200002:status "ACTIVE"
SET policy:home:200002:premium 650
SET policy:home:200002:customer "CUST005"
SET policy:home:200002:agent "AG003"
SET policy:home:200002:effective_date "2024-04-01"
SET policy:home:200002:expiration_date "2025-04-01"

# Life Policies
SET policy:life:300001:details "$500K Term 20Y - Bob Johnson - $420 premium - Medical Exam Required"
SET policy:life:300001:status "ACTIVE"
SET policy:life:300001:premium 420
SET policy:life:300001:customer "CUST003"
SET policy:life:300001:agent "AG002"
SET policy:life:300001:effective_date "2024-01-20"
SET policy:life:300001:expiration_date "2044-01-20"

SET policy:life:300002:details "$250K Term 10Y - Diana Rodriguez - $180 premium - No Medical Exam"
SET policy:life:300002:status "PENDING_MEDICAL_REVIEW"
SET policy:life:300002:premium 180
SET policy:life:300002:customer "CUST006"
SET policy:life:300002:agent "AG001"
SET policy:life:300002:effective_date "2024-08-16"
SET policy:life:300002:expiration_date "2034-08-16"

# === HIERARCHICAL CUSTOMER KEYS ===
SET customer:CUST001:profile "John Smith|DOB:1985-03-15|Phone:555-0123|Email:john.smith@email.com"
SET customer:CUST001:address "456 Oak St, Dallas TX 75201"
SET customer:CUST001:risk_score 750
SET customer:CUST001:credit_score 720
SET customer:CUST001:customer_since "2018-05-20"
SET customer:CUST001:communication_preference "email"
SET customer:CUST001:marketing_opt_in "yes"

SET customer:CUST002:profile "Jane Doe|DOB:1990-07-22|Phone:555-0456|Email:jane.doe@email.com"
SET customer:CUST002:address "789 Pine Ave, Dallas TX 75202"
SET customer:CUST002:risk_score 820
SET customer:CUST002:credit_score 780
SET customer:CUST002:customer_since "2020-03-15"
SET customer:CUST002:communication_preference "phone"
SET customer:CUST002:marketing_opt_in "no"

SET customer:CUST003:profile "Bob Johnson|DOB:1978-11-08|Phone:555-0789|Email:bob.johnson@email.com"
SET customer:CUST003:address "321 Elm St, Dallas TX 75203"
SET customer:CUST003:risk_score 680
SET customer:CUST003:credit_score 650
SET customer:CUST003:customer_since "2019-09-10"
SET customer:CUST003:communication_preference "mail"
SET customer:CUST003:marketing_opt_in "yes"

SET customer:CUST004:profile "Alice Brown|DOB:1995-09-12|Phone:555-0321|Email:alice.brown@email.com"
SET customer:CUST004:address "654 Maple Dr, Dallas TX 75204"
SET customer:CUST004:risk_score 720
SET customer:CUST004:credit_score 740
SET customer:CUST004:customer_since "2021-01-08"
SET customer:CUST004:communication_preference "email"
SET customer:CUST004:marketing_opt_in "yes"

SET customer:CUST005:profile "Charlie Wilson|DOB:1982-12-03|Phone:555-0654|Email:charlie.wilson@email.com"
SET customer:CUST005:address "987 Cedar Ln, Dallas TX 75205"
SET customer:CUST005:risk_score 790
SET customer:CUST005:credit_score 800
SET customer:CUST005:customer_since "2017-11-22"
SET customer:CUST005:communication_preference "email"
SET customer:CUST005:marketing_opt_in "no"

SET customer:CUST006:profile "Diana Rodriguez|DOB:1988-04-18|Phone:555-0987|Email:diana.rodriguez@email.com"
SET customer:CUST006:address "147 Birch Way, Dallas TX 75206"
SET customer:CUST006:risk_score 710
SET customer:CUST006:credit_score 690
SET customer:CUST006:customer_since "2022-06-14"
SET customer:CUST006:communication_preference "phone"
SET customer:CUST006:marketing_opt_in "yes"

# === HIERARCHICAL CLAIMS KEYS ===
SET claim:CLM001:details "Auto Accident - Policy: auto:100001 - Amount: $2,500 - Date: 2024-08-15"
SET claim:CLM001:status "PROCESSING"
SET claim:CLM001:amount 2500
SET claim:CLM001:adjuster "ADJ001"
SET claim:CLM001:filed_date "2024-08-15"
SET claim:CLM001:policy "auto:100001"
SET claim:CLM001:customer "CUST001"

SET claim:CLM002:details "Water Damage - Policy: home:200001 - Amount: $8,200 - Date: 2024-08-10"
SET claim:CLM002:status "APPROVED"
SET claim:CLM002:amount 8200
SET claim:CLM002:adjuster "ADJ002"
SET claim:CLM002:filed_date "2024-08-10"
SET claim:CLM002:policy "home:200001"
SET claim:CLM002:customer "CUST002"

# === AGENT HIERARCHY ===
SET agent:AG001:profile "Michael Davis|Branch:Dallas|Region:North|Phone:555-1001"
SET agent:AG001:performance "policies_sold:23|commission:15200|rating:4.8"
SET agent:AG001:customers "CUST001,CUST002,CUST006"

SET agent:AG002:profile "Sarah Wilson|Branch:Dallas|Region:South|Phone:555-1002"
SET agent:AG002:performance "policies_sold:31|commission:22400|rating:4.9"
SET agent:AG002:customers "CUST003,CUST004"

SET agent:AG003:profile "Tom Miller|Branch:Dallas|Region:East|Phone:555-1003"
SET agent:AG003:performance "policies_sold:19|commission:12800|rating:4.6"
SET agent:AG003:customers "CUST005"

# === OFFICE NAMESPACE ORGANIZATION ===
SET office:dallas:address "1234 Main St, Dallas TX 75201"
SET office:dallas:manager "MGR001"
SET office:dallas:phone "555-2000"
SET office:dallas:agents "AG001,AG002,AG003"

SET office:houston:address "5678 Post Oak Blvd, Houston TX 77027"
SET office:houston:manager "MGR002"
SET office:houston:phone "555-2100"
SET office:houston:agents "AG004,AG005"

# === QUOTES WITH BUSINESS-APPROPRIATE TTL ===
# Auto quotes (5-minute TTL)
SETEX quote:auto:Q001 300 "Honda Civic 2023 - Customer: CUST007 - Premium: $950/year - Agent: AG001"
SETEX quote:auto:Q002 300 "Toyota Prius 2022 - Customer: CUST008 - Premium: $880/year - Agent: AG002"
SETEX quote:auto:Q003 300 "Ford F-150 2023 - Customer: CUST009 - Premium: $1,400/year - Agent: AG003"

# Home quotes (10-minute TTL)
SETEX quote:home:Q001 600 "Suburban Home 2200sqft - Customer: CUST010 - Premium: $1,200/year - Agent: AG001"
SETEX quote:home:Q002 600 "Condo 1400sqft - Customer: CUST011 - Premium: $650/year - Agent: AG002"

# Life quotes (30-minute TTL)
SETEX quote:life:Q001 1800 "Term Life $500K 20Y - Customer: CUST012 - Premium: $45/month - Agent: AG002"
SETEX quote:life:Q002 1800 "Whole Life $250K - Customer: CUST013 - Premium: $180/month - Agent: AG001"

# === SESSION MANAGEMENT WITH TTL ===
# Customer portal sessions (30-minute TTL)
SETEX session:customer:CUST001:portal 1800 "authenticated|login_time:2024-08-18T10:30:00Z|last_activity:2024-08-18T10:30:00Z"
SETEX session:customer:CUST002:portal 1800 "authenticated|login_time:2024-08-18T09:45:00Z|last_activity:2024-08-18T10:15:00Z"

# Agent sessions (8-hour TTL)
SETEX session:agent:AG001:workstation 28800 "authenticated|login_time:2024-08-18T08:00:00Z|branch:dallas"
SETEX session:agent:AG002:workstation 28800 "authenticated|login_time:2024-08-18T08:15:00Z|branch:dallas"

# Mobile app sessions (2-hour TTL)
SETEX session:mobile:CUST001:device123 7200 "authenticated|device:iPhone12|app_version:2.1.0"
SETEX session:mobile:CUST002:device456 7200 "authenticated|device:Samsung_S21|app_version:2.1.0"

# === TEMPORAL METRICS WITH TTL ===
# Daily metrics (24-hour TTL)
SETEX metrics:daily:2024-08-18:policies_sold 86400 "8"
SETEX metrics:daily:2024-08-18:revenue 86400 "15600"
SETEX metrics:daily:2024-08-18:claims_filed 86400 "3"
SETEX metrics:daily:2024-08-18:quotes_generated 86400 "24"

# Weekly metrics (7-day TTL)
SETEX metrics:weekly:2024-W33:policies_sold 604800 "52"
SETEX metrics:weekly:2024-W33:revenue 604800 "98400"
SETEX metrics:weekly:2024-W33:claims_filed 604800 "18"

# Monthly metrics (30-day TTL)
SETEX metrics:monthly:2024-08:policies_sold 2592000 "156"
SETEX metrics:monthly:2024-08:revenue 2592000 "312000"
SETEX metrics:monthly:2024-08:claims_filed 2592000 "45"

# === SECURITY FEATURES WITH TTL ===
# Failed login tracking (5-minute TTL)
SETEX security:failed_logins:CUST001 300 "0"
SETEX security:failed_logins:CUST002 300 "1"

# Password reset tokens (15-minute TTL)
SETEX security:password_reset:CUST001:token123 900 "valid|issued:2024-08-18T10:30:00Z"

# API rate limiting (1-minute TTL)
SETEX ratelimit:api:quote:IP192.168.1.100 60 "5"
SETEX ratelimit:api:quote:IP192.168.1.101 60 "3"

REDIS_EOF

echo "✅ Insurance key management sample data loaded successfully!"
echo ""
echo "📊 Data Summary:"
redis-cli << 'REDIS_EOF'
ECHO "=== POLICY KEYS BY TYPE ==="
EVAL "
local types = {'auto', 'home', 'life'}
for i, type in ipairs(types) do
  local keys = redis.call('KEYS', 'policy:' .. type .. ':*')
  redis.call('ECHO', type .. ' policies: ' .. #keys)
end
" 0

ECHO ""
ECHO "=== CUSTOMER KEYS ==="
EVAL "
local keys = redis.call('KEYS', 'customer:*')
redis.call('ECHO', 'Total customer keys: ' .. #keys)
" 0

ECHO ""
ECHO "=== ACTIVE QUOTES WITH TTL ==="
EVAL "
local quotes = redis.call('KEYS', 'quote:*')
local active = 0
for i, key in ipairs(quotes) do
  local ttl = redis.call('TTL', key)
  if ttl > 0 then
    active = active + 1
  end
end
redis.call('ECHO', 'Active quotes: ' .. active)
" 0

ECHO ""
ECHO "=== ACTIVE SESSIONS WITH TTL ==="
EVAL "
local sessions = redis.call('KEYS', 'session:*')
local active = 0
for i, key in ipairs(sessions) do
  local ttl = redis.call('TTL', key)
  if ttl > 0 then
    active = active + 1
  end
end
redis.call('ECHO', 'Active sessions: ' .. active)
" 0

ECHO ""
ECHO "Database Size:"
DBSIZE
REDIS_EOF

echo ""
echo "🎯 Ready for Lab 4 key management and TTL exercises!"
echo ""
echo "📋 Key Exercise Areas:"
echo "   • Hierarchical key organization for insurance entities"
echo "   • Business-appropriate TTL strategies for quotes and sessions"
echo "   • Key lifecycle management and transitions"
echo "   • Memory optimization through key organization"
echo "   • Production monitoring and cleanup patterns"
EOF

chmod +x scripts/load-key-management-data.sh

# Create key patterns reference
echo "📚 Creating docs/key-patterns-reference.md..."
cat > docs/key-patterns-reference.md << 'EOF'
# Insurance Key Patterns and TTL Reference Guide

## Hierarchical Key Naming Conventions

### Policy Keys
```
Pattern: policy:{type}:{number}:{attribute}
Examples:
- policy:auto:100001:details
- policy:auto:100001:status
- policy:auto:100001:premium
- policy:auto:100001:customer
- policy:home:200001:details
- policy:life:300001:beneficiaries
```

### Customer Keys
```
Pattern: customer:{id}:{attribute}
Examples:
- customer:CUST001:profile
- customer:CUST001:address
- customer:CUST001:risk_score
- customer:CUST001:policies
- customer:CUST001:communication_preference
```

### Claims Keys
```
Pattern: claim:{id}:{attribute}
Examples:
- claim:CLM001:details
- claim:CLM001:status
- claim:CLM001:amount
- claim:CLM001:adjuster
- claim:CLM001:timeline
```

### Agent Keys
```
Pattern: agent:{id}:{attribute}
Examples:
- agent:AG001:profile
- agent:AG001:performance
- agent:AG001:customers
- agent:AG001:commission
```

## TTL Strategies by Business Function

### Quote Management
```redis
# Auto Insurance Quotes (5-minute TTL)
# Quick decisions expected, competitive market
SETEX quote:auto:Q001 300 "quote_data"

# Home Insurance Quotes (10-minute TTL)  
# More complex decisions, property evaluation
SETEX quote:home:Q001 600 "quote_data"

# Life Insurance Quotes (30-minute TTL)
# Complex underwriting, medical considerations
SETEX quote:life:Q001 1800 "quote_data"

# Commercial Insurance Quotes (1-hour TTL)
# Complex risk assessment, multiple stakeholders
SETEX quote:commercial:Q001 3600 "quote_data"
```

### Session Management
```redis
# Customer Portal Sessions (30-minute TTL)
# Balance security with user convenience
SETEX session:customer:CUST001:portal 1800 "session_data"

# Agent Workstation Sessions (8-hour TTL)
# Full work day, high security environment
SETEX session:agent:AG001:workstation 28800 "session_data"

# Mobile App Sessions (2-hour TTL)
# Mobile usage patterns, security considerations
SETEX session:mobile:CUST001:device123 7200 "session_data"

# API Sessions (1-hour TTL)
# Programmatic access, shorter for security
SETEX session:api:client123:token456 3600 "session_data"
```

### Temporary Data
```redis
# Password Reset Tokens (15-minute TTL)
SETEX security:password_reset:CUST001:token123 900 "reset_data"

# Email Verification (24-hour TTL)
SETEX verification:email:CUST001:code456 86400 "verification_data"

# Two-Factor Auth Codes (5-minute TTL)
SETEX auth:2fa:CUST001:code789 300 "auth_code"

# API Rate Limiting (1-minute TTL)
SETEX ratelimit:api:quote:IP192.168.1.100 60 "request_count"
```

### Business Metrics
```redis
# Daily Metrics (24-hour TTL)
SETEX metrics:daily:2024-08-18:policies_sold 86400 "count"

# Weekly Metrics (7-day TTL)  
SETEX metrics:weekly:2024-W33:revenue 604800 "amount"

# Monthly Metrics (30-day TTL)
SETEX metrics:monthly:2024-08:claims_ratio 2592000 "percentage"

# Quarterly Metrics (90-day TTL)
SETEX metrics:quarterly:2024-Q3:growth 7776000 "percentage"
```

## Key Lifecycle Management

### Policy Lifecycle
```redis
# 1. Application Stage (24-hour review period)
SETEX application:auto:APP001 86400 "application_data"

# 2. Underwriting Stage (48-hour review)
SETEX underwriting:review:APP001 172800 "review_data"

# 3. Policy Approval (convert to permanent)
SET policy:auto:100001:details "permanent_policy_data"
DEL application:auto:APP001
DEL underwriting:review:APP001

# 4. Policy Renewal (temporary renewal data)
SETEX renewal:auto:100001:offer 1209600 "renewal_terms"  # 14 days
```

### Claims Lifecycle
```redis
# 1. Initial Report (7-day follow-up period)
SETEX claim:temp:CLM001 604800 "initial_report"

# 2. Investigation Period (30-day review)
SETEX investigation:CLM001 2592000 "investigation_data"

# 3. Claim Resolution (convert to permanent)
SET claim:CLM001:details "final_claim_data"
SET claim:CLM001:status "CLOSED"
DEL claim:temp:CLM001
PERSIST investigation:CLM001  # Keep investigation permanently
```

## Namespace Organization

### Multi-Office Organization
```redis
# Office-specific keys
office:dallas:policy:auto:100001
office:houston:policy:auto:200001
office:austin:policy:auto:300001

# Regional aggregation
region:north:revenue:2024-08-18
region:south:revenue:2024-08-18
```

### Environment Separation
```redis
# Production environment
prod:policy:auto:100001:status
prod:customer:CUST001:verified

# Development environment (with shorter TTL)
SETEX dev:policy:auto:100001:status 3600 "testing"
SETEX dev:customer:CUST001:verified 3600 "false"

# Staging environment
SETEX staging:policy:auto:100001:status 7200 "staging_data"
```

### Product Line Separation
```redis
# Personal lines
personal:auto:policy:100001
personal:home:policy:200001
personal:life:policy:300001

# Commercial lines
commercial:auto:fleet:F001
commercial:property:building:B001
commercial:liability:policy:L001
```

## Memory Optimization Patterns

### Structured vs Separate Keys
```redis
# Separate keys (more memory overhead)
SET policy:auto:100001:customer "CUST001"
SET policy:auto:100001:premium 1200
SET policy:auto:100001:status "ACTIVE"

# Hash structure (more memory efficient)
HMSET policy:auto:100001 customer "CUST001" premium 1200 status "ACTIVE"
```

### Key Compression Techniques
```redis
# Long descriptive keys
SET customer:CUST001:communication_preference:email:marketing_opt_in "yes"

# Compressed keys with legend
SET cust:CUST001:comm:email:mkt "yes"
SET legend:key_mappings "cust=customer,comm=communication_preference,mkt=marketing_opt_in"
```

## TTL Management Commands

### Setting TTL
```redis
# Set TTL at creation
SETEX key 3600 "value"
PSETEX key 3600000 "value"  # milliseconds

# Set TTL on existing key
EXPIRE key 3600
PEXPIRE key 3600000

# Set absolute expiration time
EXPIREAT key 1692360000
PEXPIREAT key 1692360000000
```

### Checking TTL
```redis
# Check remaining TTL
TTL key           # Returns seconds (-1 = no TTL, -2 = expired)
PTTL key          # Returns milliseconds

# Check if key exists
EXISTS key        # Returns 1 if exists, 0 if not
```

### Removing TTL
```redis
# Remove TTL (make key persistent)
PERSIST key

# Check if TTL was removed
TTL key           # Should return -1
```

## Advanced TTL Patterns

### Sliding Window TTL
```redis
# Refresh TTL on access
GET key
EXPIRE key 3600   # Reset TTL to 1 hour on each access
```

### Conditional TTL Extension
```redis
# Extend TTL only if it's expiring soon
EVAL "
local ttl = redis.call('TTL', KEYS[1])
if ttl > 0 and ttl < 60 then
  redis.call('EXPIRE', KEYS[1], 300)
  return 'extended'
else
  return 'not_extended'
end
" 1 quote:auto:Q001
```

### Batch TTL Operations
```redis
# Set TTL on multiple keys
EVAL "
local keys = redis.call('KEYS', ARGV[1])
for i, key in ipairs(keys) do
  redis.call('EXPIRE', key, ARGV[2])
end
return #keys .. ' keys updated'
" 0 "temp:*" 3600
```

## Monitoring and Alerting

### TTL Distribution Analysis
```redis
EVAL "
local ttl_ranges = {60, 300, 1800, 3600, 86400}
local range_names = {'1min', '5min', '30min', '1hr', '1day'}
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
  table.insert(counts, range_names[i] .. ':' .. count)
end
return counts
" 0
```

### Key Pattern Analysis
```redis
EVAL "
local patterns = {'policy:*', 'customer:*', 'quote:*', 'session:*'}
local stats = {}

for i, pattern in ipairs(patterns) do
  local keys = redis.call('KEYS', pattern)
  local with_ttl = 0
  local total_memory = 0
  
  for j, key in ipairs(keys) do
    local ttl = redis.call('TTL', key)
    if ttl > 0 then
      with_ttl = with_ttl + 1
    end
  end
  
  table.insert(stats, pattern .. ':total=' .. #keys .. ',with_ttl=' .. with_ttl)
end
return stats
" 0
```

This reference provides comprehensive guidance for implementing effective key management and TTL strategies in insurance applications using Redis.
EOF

# Create monitoring tools
echo "🔍 Creating monitoring-tools/key-ttl-monitor.sh..."
cat > monitoring-tools/key-ttl-monitor.sh << 'EOF'
#!/bin/bash

# Key TTL Monitoring Tool for Insurance Redis Deployments
# Monitors key patterns, TTL distribution, and expiration patterns

echo "🔍 Redis Key TTL Monitoring Tool"
echo "================================"

# Function to get TTL distribution
get_ttl_distribution() {
    echo "📊 TTL Distribution Analysis:"
    redis-cli EVAL "
    local ttl_ranges = {60, 300, 1800, 3600, 86400, 604800}
    local range_names = {'≤1min', '≤5min', '≤30min', '≤1hr', '≤1day', '≤1week'}
    local counts = {}
    local total_with_ttl = 0
    
    for i, range in ipairs(ttl_ranges) do
      local count = 0
      local keys = redis.call('KEYS', '*')
      for j, key in ipairs(keys) do
        local ttl = redis.call('TTL', key)
        if ttl > 0 and ttl <= range then
          count = count + 1
        end
      end
      table.insert(counts, range_names[i] .. ': ' .. count)
      if i == 1 then total_with_ttl = count end
    end
    
    -- Count total keys with TTL
    local all_keys = redis.call('KEYS', '*')
    local keys_with_ttl = 0
    for i, key in ipairs(all_keys) do
      local ttl = redis.call('TTL', key)
      if ttl > 0 then
        keys_with_ttl = keys_with_ttl + 1
      end
    end
    
    table.insert(counts, 'Total with TTL: ' .. keys_with_ttl)
    return counts
    " 0
}

# Function to analyze key patterns
analyze_key_patterns() {
    echo ""
    echo "🗝️ Key Pattern Analysis:"
    redis-cli EVAL "
    local patterns = {'policy:*', 'customer:*', 'claim:*', 'quote:*', 'session:*', 'metrics:*'}
    local stats = {}
    
    for i, pattern in ipairs(patterns) do
      local keys = redis.call('KEYS', pattern)
      local with_ttl = 0
      local without_ttl = 0
      local avg_ttl = 0
      local ttl_sum = 0
      
      for j, key in ipairs(keys) do
        local ttl = redis.call('TTL', key)
        if ttl > 0 then
          with_ttl = with_ttl + 1
          ttl_sum = ttl_sum + ttl
        elseif ttl == -1 then
          without_ttl = without_ttl + 1
        end
      end
      
      if with_ttl > 0 then
        avg_ttl = math.floor(ttl_sum / with_ttl)
      end
      
      table.insert(stats, pattern .. ' → Total:' .. #keys .. ' TTL:' .. with_ttl .. ' Persistent:' .. without_ttl .. ' AvgTTL:' .. avg_ttl .. 's')
    end
    return stats
    " 0
}

# Function to find expiring keys
find_expiring_keys() {
    echo ""
    echo "⏰ Keys Expiring Soon (< 60 seconds):"
    redis-cli EVAL "
    local expiring = {}
    local keys = redis.call('KEYS', '*')
    
    for i, key in ipairs(keys) do
      local ttl = redis.call('TTL', key)
      if ttl > 0 and ttl <= 60 then
        table.insert(expiring, key .. ' (TTL: ' .. ttl .. 's)')
      end
    end
    
    if #expiring == 0 then
      table.insert(expiring, 'No keys expiring in next 60 seconds')
    end
    
    return expiring
    " 0
}

# Function to check quote health
check_quote_health() {
    echo ""
    echo "💰 Quote System Health:"
    redis-cli EVAL "
    local quote_types = {'auto', 'home', 'life'}
    local stats = {}
    
    for i, qtype in ipairs(quote_types) do
      local pattern = 'quote:' .. qtype .. ':*'
      local keys = redis.call('KEYS', pattern)
      local active = 0
      local expiring_soon = 0
      
      for j, key in ipairs(keys) do
        local ttl = redis.call('TTL', key)
        if ttl > 0 then
          active = active + 1
          if ttl <= 120 then  -- expiring in 2 minutes
            expiring_soon = expiring_soon + 1
          end
        end
      end
      
      table.insert(stats, qtype .. ' quotes: ' .. active .. ' active, ' .. expiring_soon .. ' expiring soon')
    end
    return stats
    " 0
}

# Function to check session health
check_session_health() {
    echo ""
    echo "👤 Session System Health:"
    redis-cli EVAL "
    local session_types = {'customer', 'agent', 'mobile'}
    local stats = {}
    
    for i, stype in ipairs(session_types) do
      local pattern = 'session:' .. stype .. ':*'
      local keys = redis.call('KEYS', pattern)
      local active = 0
      local expiring_soon = 0
      
      for j, key in ipairs(keys) do
        local ttl = redis.call('TTL', key)
        if ttl > 0 then
          active = active + 1
          if ttl <= 300 then  -- expiring in 5 minutes
            expiring_soon = expiring_soon + 1
          end
        end
      end
      
      table.insert(stats, stype .. ' sessions: ' .. active .. ' active, ' .. expiring_soon .. ' expiring soon')
    end
    return stats
    " 0
}

# Function to show memory usage by key pattern
show_memory_usage() {
    echo ""
    echo "💾 Memory Usage by Key Pattern:"
    
    # Check if MEMORY USAGE command is available (Redis 4.0+)
    if redis-cli MEMORY USAGE nonexistent 2>/dev/null | grep -q "unknown command"; then
        echo "MEMORY USAGE command not available in this Redis version"
        return
    fi
    
    echo "Sample key memory usage:"
    
    # Check a few sample keys from each pattern
    for pattern in "policy:*" "customer:*" "quote:*" "session:*"; do
        key=$(redis-cli KEYS "$pattern" | head -1)
        if [ ! -z "$key" ]; then
            memory=$(redis-cli MEMORY USAGE "$key" 2>/dev/null || echo "N/A")
            echo "  $key: $memory bytes"
        fi
    done
}

# Main execution
main() {
    # Check if Redis is available
    if ! redis-cli ping >/dev/null 2>&1; then
        echo "❌ Redis server not available"
        exit 1
    fi
    
    echo "📡 Connected to Redis server"
    echo "🕐 $(date)"
    echo ""
    
    # Database info
    echo "📈 Database Statistics:"
    echo "  Total Keys: $(redis-cli DBSIZE)"
    echo "  Memory Used: $(redis-cli INFO memory | grep used_memory_human | cut -d: -f2 | tr -d '\r')"
    echo ""
    
    # Run monitoring functions
    get_ttl_distribution
    analyze_key_patterns
    find_expiring_keys
    check_quote_health
    check_session_health
    show_memory_usage
    
    echo ""
    echo "✅ Monitoring complete"
}

# Run with continuous monitoring if -w flag provided
if [ "$1" = "-w" ] || [ "$1" = "--watch" ]; then
    echo "👀 Starting continuous monitoring (Ctrl+C to stop)..."
    while true; do
        clear
        main
        echo ""
        echo "🔄 Refreshing in 30 seconds..."
        sleep 30
    done
else
    main
fi
EOF

chmod +x monitoring-tools/key-ttl-monitor.sh

# Create examples file
echo "📋 Creating examples/key-management-examples.md..."
cat > examples/key-management-examples.md << 'EOF'
# Insurance Key Management Examples

## Policy Key Organization Examples

### Auto Policy Complete Setup
```redis
# Create comprehensive auto policy with hierarchical keys
SET policy:auto:100001:details "2020 Toyota Camry LE - John Smith - $1,200 premium"
SET policy:auto:100001:status "ACTIVE"
SET policy:auto:100001:premium 1200
SET policy:auto:100001:customer "CUST001"
SET policy:auto:100001:agent "AG001"
SET policy:auto:100001:effective_date "2024-01-15"
SET policy:auto:100001:expiration_date "2025-01-15"
SET policy:auto:100001:vehicle_vin "1HGBH41JXMN109186"
SET policy:auto:100001:coverage_limits "100/300/50"
SET policy:auto:100001:deductible 500

# Verify policy structure
KEYS policy:auto:100001:*
MGET policy:auto:100001:customer policy:auto:100001:premium policy:auto:100001:status
```

### Home Policy with Address Hierarchy
```redis
# Create home policy with location-based organization
SET policy:home:200001:details "123 Main St Dallas TX - Jane Doe - $800 premium"
SET policy:home:200001:status "ACTIVE"
SET policy:home:200001:premium 800
SET policy:home:200001:customer "CUST002"
SET policy:home:200001:property_address "123 Main St, Dallas TX 75201"
SET policy:home:200001:property_value 350000
SET policy:home:200001:coverage_type "FULL_REPLACEMENT"
SET policy:home:200001:deductible 1000

# Location-based grouping
SET location:dallas:75201:policies "home:200001,auto:100001"
SET location:dallas:75201:risk_score 750
```

## Customer Relationship Management

### Complete Customer Profile Setup
```redis
# Primary customer information
SET customer:CUST001:profile "John Smith|DOB:1985-03-15|Phone:555-0123|Email:john.smith@email.com"
SET customer:CUST001:address "456 Oak St, Dallas TX 75201"
SET customer:CUST001:risk_score 750
SET customer:CUST001:credit_score 720
SET customer:CUST001:customer_since "2018-05-20"

# Customer preferences and settings
SET customer:CUST001:communication_preference "email"
SET customer:CUST001:marketing_opt_in "yes"
SET customer:CUST001:preferred_agent "AG001"
SET customer:CUST001:payment_method "AUTO_PAY"

# Customer policy relationships
SET customer:CUST001:policies "auto:100001,home:200001"
SET customer:CUST001:policy_count 2
SET customer:CUST001:total_premium 2000

# Customer activity tracking
SET customer:CUST001:last_login "2024-08-18T10:30:00Z"
SET customer:CUST001:login_count 147
SET customer:CUST001:last_payment "2024-08-01T15:30:00Z"
```

### Customer Segmentation and Analytics
```redis
# Risk-based customer segmentation
SADD segment:high_risk "CUST001" "CUST003" "CUST007"
SADD segment:medium_risk "CUST002" "CUST004" "CUST008"
SADD segment:low_risk "CUST005" "CUST006" "CUST009"

# Customer lifetime value tiers
SADD tier:platinum "CUST001" "CUST005"
SADD tier:gold "CUST002" "CUST004"
SADD tier:silver "CUST003" "CUST006"

# Multi-policy customers
SADD customer:multi_policy "CUST001" "CUST002" "CUST005"
```

## Quote Management with Business-Appropriate TTL

### Auto Insurance Quote Workflow
```redis
# Standard auto quote (5-minute TTL for competitive market)
SETEX quote:auto:Q001 300 "Honda Civic 2023 - Customer: CUST004 - Premium: $950/year"
SETEX quote:auto:Q001:customer 300 "CUST004"
SETEX quote:auto:Q001:vehicle 300 "Honda Civic 2023"
SETEX quote:auto:Q001:premium 300 "950"
SETEX quote:auto:Q001:agent 300 "AG001"
SETEX quote:auto:Q001:created 300 "2024-08-18T10:30:00Z"

# High-value auto quote (extended TTL for complex decisions)
SETEX quote:auto:Q002 900 "BMW X5 2023 - Customer: CUST010 - Premium: $2,500/year"
SETEX quote:auto:Q002:customer 900 "CUST010"
SETEX quote:auto:Q002:vehicle 900 "BMW X5 2023"
SETEX quote:auto:Q002:premium 900 "2500"
SETEX quote:auto:Q002:coverage_type 900 "PREMIUM"

# Monitor quote status
TTL quote:auto:Q001
TTL quote:auto:Q002
MGET quote:auto:Q001:customer quote:auto:Q001:premium
```

### Life Insurance Quote with Underwriting TTL
```redis
# Life insurance quote (30-minute TTL for medical considerations)
SETEX quote:life:Q001 1800 "Term Life $500K 20Y - Customer: CUST008 - Premium: $45/month"
SETEX quote:life:Q001:customer 1800 "CUST008"
SETEX quote:life:Q001:coverage_amount 1800 "500000"
SETEX quote:life:Q001:term_years 1800 "20"
SETEX quote:life:Q001:premium_monthly 1800 "45"
SETEX quote:life:Q001:medical_exam_required 1800 "yes"

# Underwriting assessment (longer TTL for complex review)
SETEX underwriting:assessment:Q001 3600 "Age: 35, Health: Good, Smoker: No, Risk: Low"
SETEX underwriting:medical_exam:Q001 7200 "Scheduled for 2024-08-20T09:00:00Z"

# Quote extension for customer convenience
EXPIRE quote:life:Q001 3600  # Extend to 1 hour
EXPIRE quote:life:Q001:customer 3600
EXPIRE quote:life:Q001:coverage_amount 3600
```

## Session Management Patterns

### Customer Portal Session Management
```redis
# Customer login session (30-minute TTL)
SETEX session:customer:CUST001:portal 1800 "authenticated|login_time:2024-08-18T10:30:00Z|ip:192.168.1.100"

# Session metadata
SETEX session:customer:CUST001:device 1800 "Chrome 115.0|Windows 10"
SETEX session:customer:CUST001:permissions 1800 "view_policies,make_payments,update_profile"
SETEX session:customer:CUST001:last_activity 1800 "2024-08-18T10:45:00Z"

# Session activity refresh (sliding window)
SET session:customer:CUST001:portal "authenticated|login_time:2024-08-18T10:30:00Z|last_activity:2024-08-18T10:50:00Z" EX 1800

# Multi-device session management
SETEX session:mobile:CUST001:device123 7200 "iPhone 12|iOS 15.0|app_version:2.1.0"
SETEX session:tablet:CUST001:device456 7200 "iPad Pro|iOS 15.0|app_version:2.1.0"
```

### Agent Workstation Session Management
```redis
# Agent workstation session (8-hour work day)
SETEX session:agent:AG001:workstation 28800 "authenticated|login_time:2024-08-18T08:00:00Z|branch:dallas"

# Agent permissions and capabilities
SETEX session:agent:AG001:permissions 28800 "create_quotes,bind_policies,process_claims,view_customer_data"
SETEX session:agent:AG001:branch_access 28800 "dallas,fort_worth"
SETEX session:agent:AG001:product_access 28800 "auto,home,life"

# Agent performance tracking during session
SETEX session:agent:AG001:quotes_today 28800 "8"
SETEX session:agent:AG001:policies_sold_today 28800 "3"
SETEX session:agent:AG001:customer_calls_today 28800 "12"
```

## Claims Processing Key Lifecycle

### Claims Submission and Processing Workflow
```redis
# Initial claim submission (7-day follow-up period)
SETEX claim:temp:CLM003 604800 "Auto Accident - Initial Report - Customer: CUST001 - Estimated: $3,500"
SETEX claim:temp:CLM003:reporter 604800 "CUST001"
SETEX claim:temp:CLM003:incident_date 604800 "2024-08-18T14:30:00Z"
SETEX claim:temp:CLM003:location 604800 "I-35 and Main St, Dallas TX"

# Claims assignment and investigation (30-day review period)
SETEX investigation:CLM003 2592000 "Adjuster: ADJ001 | Photos: 12 | Witness Statements: 2"
SETEX investigation:CLM003:adjuster 2592000 "ADJ001"
SETEX investigation:CLM003:status 2592000 "IN_PROGRESS"
SETEX investigation:CLM003:estimated_amount 2592000 "3200"

# Claim approval and conversion to permanent record
SET claim:CLM003:details "Auto Accident - Policy: auto:100001 - Amount: $3,200 - Status: APPROVED"
SET claim:CLM003:final_amount 3200
SET claim:CLM003:status "APPROVED"
SET claim:CLM003:approval_date "2024-08-25T16:00:00Z"

# Cleanup temporary data
DEL claim:temp:CLM003
DEL claim:temp:CLM003:reporter
DEL claim:temp:CLM003:incident_date
DEL claim:temp:CLM003:location

# Convert investigation to permanent record
PERSIST investigation:CLM003
PERSIST investigation:CLM003:adjuster
```

## Advanced TTL Patterns

### Dynamic TTL Based on Risk Assessment
```redis
# High-risk quote (shorter TTL)
SETEX quote:auto:Q010 180 "High-risk driver - Sports car - Premium: $3,500/year"
SET quote:auto:Q010:risk_level "HIGH"

# Medium-risk quote (standard TTL)
SETEX quote:auto:Q011 300 "Average driver - Sedan - Premium: $1,200/year"
SET quote:auto:Q011:risk_level "MEDIUM"

# Low-risk quote (extended TTL)
SETEX quote:auto:Q012 600 "Excellent driver - Economy car - Premium: $800/year"
SET quote:auto:Q012:risk_level "LOW"

# Monitor risk-based TTL patterns
TTL quote:auto:Q010
TTL quote:auto:Q011
TTL quote:auto:Q012
```

### Progressive Session Timeout
```redis
# Initial session (standard timeout)
SETEX session:customer:CUST001:activity_level 1800 "normal"

# High activity user (extended timeout)
SETEX session:customer:CUST002:activity_level 3600 "high"

# Idle user (reduced timeout)
SETEX session:customer:CUST003:activity_level 900 "idle"

# VIP customer (premium timeout)
SETEX session:customer:CUST004:activity_level 7200 "vip"
```

## Temporal Data Management

### Daily Business Metrics with Automatic Cleanup
```redis
# Today's metrics (24-hour TTL)
SETEX metrics:daily:2024-08-18:policies_sold 86400 "15"
SETEX metrics:daily:2024-08-18:revenue 86400 "28500"
SETEX metrics:daily:2024-08-18:claims_filed 86400 "7"
SETEX metrics:daily:2024-08-18:quotes_generated 86400 "42"

# Department-specific daily metrics
SETEX metrics:daily:2024-08-18:auto:policies_sold 86400 "8"
SETEX metrics:daily:2024-08-18:home:policies_sold 86400 "4"
SETEX metrics:daily:2024-08-18:life:policies_sold 86400 "3"

# Agent-specific daily metrics
SETEX metrics:daily:2024-08-18:agent:AG001:policies_sold 86400 "5"
SETEX metrics:daily:2024-08-18:agent:AG002:policies_sold 86400 "6"
SETEX metrics:daily:2024-08-18:agent:AG003:policies_sold 86400 "4"
```

### Weekly and Monthly Aggregations
```redis
# Weekly metrics (7-day TTL)
SETEX metrics:weekly:2024-W33:policies_sold 604800 "89"
SETEX metrics:weekly:2024-W33:revenue 604800 "167300"
SETEX metrics:weekly:2024-W33:customer_acquisition 604800 "23"

# Monthly metrics (30-day TTL)
SETEX metrics:monthly:2024-08:policies_sold 2592000 "245"
SETEX metrics:monthly:2024-08:revenue 2592000 "487600"
SETEX metrics:monthly:2024-08:claims_ratio 2592000 "0.15"

# Quarterly metrics (90-day TTL)
SETEX metrics:quarterly:2024-Q3:growth_rate 7776000 "12.5"
SETEX metrics:quarterly:2024-Q3:customer_retention 7776000 "94.2"
```

## Security and Compliance TTL Patterns

### Security Event Tracking
```redis
# Failed login attempts (5-minute lockout)
SETEX security:failed_logins:CUST001 300 "1"
INCR security:failed_logins:CUST001

# Escalating lockout (progressive TTL)
SETEX security:lockout:CUST001:level1 900 "3_attempts"    # 15 minutes
SETEX security:lockout:CUST001:level2 3600 "5_attempts"   # 1 hour
SETEX security:lockout:CUST001:level3 86400 "10_attempts" # 24 hours

# Password reset tokens (15-minute TTL)
SETEX security:password_reset:CUST001:token123 900 "valid|issued:2024-08-18T10:30:00Z"

# Two-factor authentication codes (5-minute TTL)
SETEX security:2fa:CUST001:code789 300 "123456"
```

### Compliance and Audit TTL
```redis
# Audit trail for policy changes (1-year retention)
SETEX audit:policy:auto:100001:change:20240818 31536000 "Premium updated from 1200 to 1350 by AG001"

# Customer data access logs (90-day retention)
SETEX audit:access:customer:CUST001:20240818 7776000 "Viewed by AG001 at 2024-08-18T10:30:00Z"

# Payment processing logs (7-year retention for compliance)
SET audit:payment:transaction:TXN001 "Customer: CUST001 | Amount: 1200 | Date: 2024-08-18"
EXPIRE audit:payment:transaction:TXN001 220752000  # 7 years

# Temporary compliance data (30-day review period)
SETEX compliance:review:policy:auto:100001 2592000 "Pending regulatory review"
```

## Performance Optimization Examples

### Memory-Efficient Key Organization
```redis
# Instead of multiple string keys:
SET policy:auto:100001:customer "CUST001"
SET policy:auto:100001:premium 1200
SET policy:auto:100001:status "ACTIVE"
SET policy:auto:100001:agent "AG001"

# Use hash for better memory efficiency:
HMSET policy:auto:100001 customer "CUST001" premium 1200 status "ACTIVE" agent "AG001"

# Compare memory usage
MEMORY USAGE policy:auto:100001:customer
MEMORY USAGE policy:auto:100001
```

### Batch TTL Management
```redis
# Extend TTL for all quotes about to expire
EVAL "
local quotes = redis.call('KEYS', 'quote:*')
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

# Cleanup expired test data
EVAL "
local test_keys = redis.call('KEYS', 'test:*')
local expired_keys = redis.call('KEYS', 'temp:*')
local all_cleanup = {}
for i, key in ipairs(test_keys) do table.insert(all_cleanup, key) end
for i, key in ipairs(expired_keys) do table.insert(all_cleanup, key) end
if #all_cleanup > 0 then
  redis.call('DEL', unpack(all_cleanup))
end
return 'Cleaned up ' .. #all_cleanup .. ' keys'
" 0
```

These examples demonstrate practical insurance key management patterns that balance performance, security, and business requirements while maintaining data organization and efficient memory usage.
EOF

# Create troubleshooting guide
echo "🔧 Creating docs/troubleshooting.md..."
cat > docs/troubleshooting.md << 'EOF'
# Lab 4 Troubleshooting Guide

## Common Issues and Solutions

### 1. TTL Not Working as Expected

**Problem:** Keys not expiring or TTL values incorrect

**Solutions:**
```bash
# Check current TTL
redis-cli TTL quote:auto:Q001

# Verify TTL was set correctly
redis-cli SETEX test:ttl 60 "test value"
redis-cli TTL test:ttl

# Check Redis time
redis-cli TIME

# Monitor TTL countdown
watch "redis-cli TTL quote:auto:Q001"

# Check if key expired
redis-cli EXISTS quote:auto:Q001  # Returns 0 if expired

# Verify TTL configuration
redis-cli CONFIG GET "maxmemory*"
```

### 2. Key Pattern Issues

**Problem:** Keys not following expected patterns or not found

**Solutions:**
```bash
# Verify key patterns exist
redis-cli KEYS "policy:*" | head -5
redis-cli KEYS "customer:*" | head -5

# Check specific key existence
redis-cli EXISTS policy:auto:100001:details
redis-cli EXISTS customer:CUST001:profile

# Use SCAN for production-safe pattern search
redis-cli SCAN 0 MATCH "policy:auto:*" COUNT 10

# Validate key structure
redis-cli TYPE policy:auto:100001:details
redis-cli GET policy:auto:100001:customer
```

### 3. Memory Usage Issues

**Problem:** High memory usage or inefficient key storage

**Solutions:**
```bash
# Check overall memory usage
redis-cli INFO memory | grep used_memory_human

# Analyze key memory usage (Redis 4.0+)
redis-cli MEMORY USAGE policy:auto:100001:details
redis-cli MEMORY USAGE customer:CUST001:profile

# Find large keys
redis-cli --bigkeys

# Check memory by key pattern
redis-cli EVAL "
local patterns = {'policy:*', 'customer:*', 'quote:*'}
local counts = {}
for i, pattern in ipairs(patterns) do
  local keys = redis.call('KEYS', pattern)
  table.insert(counts, pattern .. ': ' .. #keys .. ' keys')
end
return counts
" 0

# Monitor memory efficiency
redis-cli INFO memory | grep -E "used_memory_human|used_memory_peak_human"
```

### 4. Data Loading Script Issues

**Problem:** Sample data not loading properly

**Solutions:**
```bash
# Make script executable
chmod +x scripts/load-key-management-data.sh

# Run with verbose output
bash -x scripts/load-key-management-data.sh

# Check Redis connection
redis-cli ping

# Verify data loaded
redis-cli DBSIZE
redis-cli KEYS "*" | wc -l

# Check specific data types
redis-cli KEYS "policy:*" | wc -l
redis-cli KEYS "customer:*" | wc -l
redis-cli KEYS "quote:*" | wc -l

# Manual verification
redis-cli GET policy:auto:100001:details
redis-cli TTL quote:auto:Q001

# Clear and reload if needed
redis-cli FLUSHALL
./scripts/load-key-management-data.sh
```

### 5. TTL Monitoring Issues

**Problem:** Cannot monitor TTL properly or keys expiring unexpectedly

**Solutions:**
```bash
# Enable keyspace notifications for expiration events
redis-cli CONFIG SET notify-keyspace-events Ex

# Monitor expiration events
redis-cli PSUBSCRIBE '__keyevent@0__:expired' &

# Test expiration monitoring
redis-cli SETEX test:expire 5 "test value"
# Wait 5 seconds and check expiration event

# Check TTL distribution
./monitoring-tools/key-ttl-monitor.sh

# Manual TTL checking
redis-cli EVAL "
local keys = redis.call('KEYS', '*')
local with_ttl = 0
local without_ttl = 0
for i, key in ipairs(keys) do
  local ttl = redis.call('TTL', key)
  if ttl > 0 then
    with_ttl = with_ttl + 1
  elseif ttl == -1 then
    without_ttl = without_ttl + 1
  end
end
return 'With TTL: ' .. with_ttl .. ', Without TTL: ' .. without_ttl
" 0
```

### 6. Key Relationships Issues

**Problem:** Related keys not properly linked or inconsistent

**Solutions:**
```bash
# Verify key relationships
redis-cli GET policy:auto:100001:customer
redis-cli EXISTS customer:CUST001:profile

# Check cross-references
redis-cli MGET policy:auto:100001:customer customer:CUST001:policies

# Validate data consistency
redis-cli EVAL "
local policy_customer = redis.call('GET', 'policy:auto:100001:customer')
local customer_exists = redis.call('EXISTS', 'customer:' .. policy_customer .. ':profile')
return 'Policy customer: ' .. policy_customer .. ', Customer exists: ' .. customer_exists
" 0

# Find orphaned keys
redis-cli EVAL "
local policies = redis.call('KEYS', 'policy:*:customer')
local orphaned = {}
for i, key in ipairs(policies) do
  local customer_id = redis.call('GET', key)
  local customer_exists = redis.call('EXISTS', 'customer:' .. customer_id .. ':profile')
  if customer_exists == 0 then
    table.insert(orphaned, key .. ' -> ' .. customer_id)
  end
end
return orphaned
" 0
```

## Performance Optimization

### TTL Performance
```bash
# Test TTL performance with large datasets
time redis-cli EVAL "
for i=1,1000 do
  redis.call('SETEX', 'perf:test:' .. i, 300, 'test_value')
end
return 'Created 1000 keys with TTL'
" 0

# Monitor TTL operations
redis-cli monitor | grep -E "(SETEX|EXPIRE|TTL)"

# Check TTL distribution performance
time ./monitoring-tools/key-ttl-monitor.sh
```

### Memory Optimization
```bash
# Compare hash vs string memory usage
redis-cli HMSET test:hash:policy customer "CUST001" premium 1200 status "ACTIVE"
redis-cli SET test:string:policy:customer "CUST001"
redis-cli SET test:string:policy:premium 1200
redis-cli SET test:string:policy:status "ACTIVE"

redis-cli MEMORY USAGE test:hash:policy
redis-cli MEMORY USAGE test:string:policy:customer

# Cleanup test data
redis-cli DEL test:hash:policy test:string:policy:customer test:string:policy:premium test:string:policy:status
```

### Key Pattern Performance
```bash
# Test pattern scanning performance
time redis-cli KEYS "policy:*"
time redis-cli SCAN 0 MATCH "policy:*" COUNT 100

# Monitor key access patterns
redis-cli monitor | grep -E "(GET|SET|EXISTS)" | head -20
```

## Security and Compliance

### Session Security Issues
```bash
# Check session TTL values
redis-cli TTL session:customer:CUST001:portal
redis-cli TTL session:agent:AG001:workstation

# Verify session cleanup
redis-cli KEYS "session:*"
sleep 1
redis-cli KEYS "session:*"

# Test failed login lockout
redis-cli SETEX security:failed_logins:CUST001 300 "1"
redis-cli INCR security:failed_logins:CUST001
redis-cli GET security:failed_logins:CUST001
redis-cli TTL security:failed_logins:CUST001
```

### Data Retention Compliance
```bash
# Check compliance data TTL
redis-cli TTL audit:policy:auto:100001:change:20240818
redis-cli TTL audit:payment:transaction:TXN001

# Verify audit trail existence
redis-cli KEYS "audit:*"
redis-cli MGET audit:policy:auto:100001:change:20240818 audit:access:customer:CUST001:20240818
```

## Advanced Debugging

### Lua Script Debugging
```bash
# Test TTL analysis script
redis-cli EVAL "
local keys = redis.call('KEYS', 'quote:*')
local results = {}
for i, key in ipairs(keys) do
  local ttl = redis.call('TTL', key)
  table.insert(results, key .. ':' .. ttl)
end
return results
" 0

# Debug key relationship script
redis-cli EVAL "
local policy_keys = redis.call('KEYS', 'policy:*:customer')
local relationships = {}
for i, key in ipairs(policy_keys) do
  local customer = redis.call('GET', key)
  local customer_key = 'customer:' .. customer .. ':profile'
  local exists = redis.call('EXISTS', customer_key)
  table.insert(relationships, key .. ' -> ' .. customer .. ' (exists: ' .. exists .. ')')
end
return relationships
" 0
```

### Memory Usage Debugging
```bash
# Detailed memory analysis
redis-cli INFO memory | grep -E "used_memory|maxmemory|mem_fragmentation"

# Check for memory leaks
redis-cli EVAL "
local before = redis.call('INFO', 'memory')
for i=1,100 do
  redis.call('SETEX', 'temp:leak:' .. i, 10, 'test')
end
local after = redis.call('INFO', 'memory')
return 'Memory test completed'
" 0

# Monitor memory over time
watch "redis-cli INFO memory | grep used_memory_human"
```

## Getting Help

If you encounter issues not covered here:

1. **Check Redis logs:** `docker logs redis-insurance-lab4`
2. **Verify Redis configuration:** `redis-cli CONFIG GET "*"`
3. **Test basic connectivity:** `redis-cli ping`
4. **Check Docker status:** `docker ps | grep redis`
5. **Monitor operations:** `redis-cli monitor`
6. **Use monitoring tools:** `./monitoring-tools/key-ttl-monitor.sh`
7. **Ask instructor** for assistance

## Useful Debugging Commands

```bash
# Complete Redis status check
redis-cli INFO server
redis-cli INFO memory  
redis-cli INFO stats
redis-cli INFO keyspace

# TTL-specific debugging
redis-cli CONFIG GET "notify-keyspace-events"
redis-cli EVAL "return redis.call('TIME')" 0
redis-cli LASTSAVE

# Key management debugging
redis-cli DBSIZE
redis-cli KEYS "*" | wc -l
redis-cli SCAN 0 COUNT 1000 | wc -l

# Performance monitoring
redis-cli --latency-history -i 1 | head -10
redis-cli SLOWLOG GET 5
redis-cli CLIENT LIST | wc -l
```
EOF

# Create README
echo "📚 Creating README.md..."
cat > README.md << 'EOF'
# Lab 4: Insurance Key Management & TTL Strategies

**Duration:** 45 minutes  
**Focus:** Advanced key organization patterns and TTL-based expiration strategies  
**Industry:** Insurance key management and session optimization

## 📁 Project Structure

```
lab4-insurance-key-management-ttl/
├── lab4.md                              # Complete lab instructions (START HERE)
├── scripts/
│   └── load-key-management-data.sh      # Comprehensive key management sample data
├── docs/
│   ├── key-patterns-reference.md        # Insurance key patterns and TTL reference
│   └── troubleshooting.md               # Key management troubleshooting guide
├── examples/
│   └── key-management-examples.md       # Practical key management examples
├── monitoring-tools/
│   └── key-ttl-monitor.sh               # TTL monitoring and analysis tool
├── key-patterns/                        # Key organization templates
├── sample-data/                         # Sample data directory
└── README.md                            # This file
```

## 🚀 Quick Start

1. **Read Instructions:** Open `lab4.md` for complete lab guidance
2. **Start Redis:** `docker run -d --name redis-insurance-lab4 -p 6379:6379 redis:7-alpine`
3. **Load Sample Data:** `./scripts/load-key-management-data.sh`
4. **Test Connection:** `redis-cli ping`
5. **Monitor TTL:** `./monitoring-tools/key-ttl-monitor.sh`

## 🎯 Lab Objectives

✅ Design and implement insurance-specific key naming conventions  
✅ Create hierarchical key patterns for policy, customer, and claims organization  
✅ Implement sophisticated quote expiration management with TTL strategies  
✅ Build customer session management and cleanup automation  
✅ Monitor key expiration patterns and optimize memory usage  
✅ Apply key organization best practices for large-scale insurance databases

## 🗝️ Key Management Focus Areas

### **Hierarchical Key Organization:**
- **Policy Keys:** `policy:{type}:{number}:{attribute}`
- **Customer Keys:** `customer:{id}:{attribute}`
- **Claims Keys:** `claim:{id}:{attribute}`
- **Agent Keys:** `agent:{id}:{attribute}`

### **TTL Strategies by Business Function:**
- **Auto Quotes:** 5-minute TTL (quick decisions)
- **Home Quotes:** 10-minute TTL (property evaluation)
- **Life Quotes:** 30-minute TTL (medical considerations)
- **Customer Sessions:** 30-minute TTL (security balance)
- **Agent Sessions:** 8-hour TTL (work day duration)

### **Temporal Data Management:**
- **Daily Metrics:** 24-hour TTL with automatic cleanup
- **Weekly Reports:** 7-day TTL for business analysis
- **Monthly Data:** 30-day TTL for trend analysis
- **Security Events:** Variable TTL based on severity

## 🔧 Key Commands for Lab 4

```bash
# Hierarchical Key Creation
SET policy:auto:100001:details "policy_data"
SET policy:auto:100001:customer "CUST001"
SET customer:CUST001:profile "customer_data"

# TTL Management
SETEX quote:auto:Q001 300 "5-minute auto quote"
SETEX quote:home:Q001 600 "10-minute home quote"
SETEX quote:life:Q001 1800 "30-minute life quote"

# Session Management
SETEX session:customer:CUST001:portal 1800 "30-min session"
SETEX session:agent:AG001:workstation 28800 "8-hour session"

# TTL Monitoring
TTL quote:auto:Q001
KEYS policy:auto:*
SCAN 0 MATCH "customer:*" COUNT 10
```

## 📊 Sample Data Highlights

The lab includes comprehensive key management data:

- **Hierarchical Policies:** 6 policies with complete attribute breakdown
- **Customer Profiles:** 6 customers with full relationship mapping
- **Claims Data:** 2 claims with lifecycle progression examples
- **Active Quotes:** Multiple quote types with business-appropriate TTL
- **Session Management:** Customer, agent, and mobile sessions
- **Temporal Metrics:** Daily, weekly, and monthly data with TTL
- **Security Features:** Failed logins, password resets, and lockouts

## 🔍 Monitoring and Analysis

### TTL Distribution Monitoring
```bash
# Run comprehensive TTL analysis
./monitoring-tools/key-ttl-monitor.sh

# Continuous monitoring
./monitoring-tools/key-ttl-monitor.sh --watch

# Key pattern analysis
redis-cli KEYS "policy:*" | wc -l
redis-cli KEYS "quote:*" | wc -l
redis-cli KEYS "session:*" | wc -l
```

### Memory Optimization
```bash
# Check memory usage by pattern
redis-cli --bigkeys

# Compare storage methods
redis-cli MEMORY USAGE policy:auto:100001:details
redis-cli MEMORY USAGE customer:CUST001:profile

# Monitor memory trends
redis-cli INFO memory | grep used_memory_human
```

## 🆘 Troubleshooting

**TTL Issues:**
```bash
# Check TTL behavior
redis-cli SETEX test:ttl 60 "test"
redis-cli TTL test:ttl

# Monitor expiration events
redis-cli CONFIG SET notify-keyspace-events Ex
redis-cli PSUBSCRIBE '__keyevent@0__:expired'
```

**Key Pattern Issues:**
```bash
# Verify patterns
redis-cli KEYS "policy:*" | head -5
redis-cli SCAN 0 MATCH "customer:*" COUNT 10

# Check relationships
redis-cli GET policy:auto:100001:customer
redis-cli EXISTS customer:CUST001:profile
```

**Memory Usage:**
```bash
# Monitor memory
redis-cli INFO memory | grep used_memory_human
redis-cli --bigkeys | grep string
```

**Detailed troubleshooting:** See `docs/troubleshooting.md`

## 📚 Learning Resources

- **Key Patterns Reference:** `docs/key-patterns-reference.md`
- **Practical Examples:** `examples/key-management-examples.md`
- **TTL Monitoring Tool:** `monitoring-tools/key-ttl-monitor.sh`
- **Troubleshooting Guide:** `docs/troubleshooting.md`

## 🎓 Learning Path

This lab is part of the Redis mastery series:

1. **Lab 1:** Environment & CLI Basics
2. **Lab 2:** RESP Protocol Analysis
3. **Lab 3:** Insurance Data Operations with Strings
4. **Lab 4:** Key Management & TTL Strategies ← *You are here*
5. **Lab 5:** Advanced CLI Operations & Monitoring

## 🏆 Key Achievements

By completing this lab, you will have mastered:

- **Hierarchical Organization:** Insurance-specific key naming conventions
- **TTL Strategies:** Business-appropriate expiration management
- **Session Management:** Secure and efficient user session handling
- **Memory Optimization:** Efficient key organization for large datasets
- **Lifecycle Management:** Key transitions through business processes
- **Production Monitoring:** TTL analysis and key health monitoring

---

**Ready to start?** Open `lab4.md` and begin mastering Redis key management for insurance applications! 🚀
EOF

# Create .gitignore
cat > .gitignore << 'EOF'
# Monitoring output
*.log
monitoring-*.log
ttl-analysis-*.log

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
monitoring-results/
EOF

echo ""
echo "📂 Project structure created:"
echo "   ${LAB_DIR}/"
echo "   ├── lab4.md                              📋 START HERE - Complete lab guide"
echo "   ├── scripts/"
echo "   │   └── load-key-management-data.sh      📊 Comprehensive key management sample data"
echo "   ├── docs/"
echo "   │   ├── key-patterns-reference.md        📚 Insurance key patterns and TTL reference"
echo "   │   └── troubleshooting.md               🔧 Key management troubleshooting guide"
echo "   ├── examples/"
echo "   │   └── key-management-examples.md       📋 Practical key management examples"
echo "   ├── monitoring-tools/"
echo "   │   └── key-ttl-monitor.sh               🔍 TTL monitoring and analysis tool"
echo "   ├── key-patterns/                        📁 Key organization templates"
echo "   ├── sample-data/                         📁 Sample data directory"
echo "   ├── README.md                            📖 Project documentation"
echo "   └── .gitignore                           🚫 Git ignore rules"
echo ""
echo "🎯 NEXT STEPS:"
echo "   1. cd ${LAB_DIR}"
echo "   2. code .                                # Open in VS Code"
echo "   3. Read lab4.md                         # Follow complete lab guide"
echo "   4. docker run -d --name redis-insurance-lab4 -p 6379:6379 redis:7-alpine"
echo "   5. ./scripts/load-key-management-data.sh"
echo "   6. ./monitoring-tools/key-ttl-monitor.sh # Monitor TTL patterns"
echo ""
echo "🗝️ KEY MANAGEMENT & TTL FOCUS:"
echo "   📂 Hierarchical Organization: policy:{type}:{number}:{attribute}"
echo "   ⏰ Business TTL Strategies: Auto(5min), Home(10min), Life(30min)"
echo "   👤 Session Management: Customer(30min), Agent(8hr), Mobile(2hr)"
echo "   📊 Temporal Data: Daily(24hr), Weekly(7d), Monthly(30d) TTL"
echo "   🔒 Security Features: Failed logins, password resets, lockouts"
echo "   💾 Memory Optimization: Hash vs string patterns, namespace organization"
echo ""
echo "🔍 MONITORING CAPABILITIES:"
echo "   📈 TTL Distribution Analysis: Key expiration pattern tracking"
echo "   🎯 Key Pattern Health: Policy, customer, quote, session monitoring"
echo "   ⚠️  Expiration Alerts: Keys expiring soon identification"
echo "   📊 Memory Usage: Pattern-based memory analysis"
echo "   🔄 Continuous Monitoring: Real-time TTL and key health tracking"
echo ""
echo "🔧 KEY COMMANDS COVERED:"
echo "   SETEX quote:auto:Q001 300 \"5-min quote\"  # Business-appropriate TTL"
echo "   TTL quote:auto:Q001                       # Monitor expiration time"
echo "   KEYS policy:auto:*                        # Pattern-based discovery"
echo "   SCAN 0 MATCH \"customer:*\" COUNT 10        # Production-safe scanning"
echo "   EXPIRE session:customer:CUST001 1800      # Extend session TTL"
echo ""
echo "🎉 READY TO START LAB 4!"
echo "   Open lab4.md for the complete 45-minute key management and TTL mastery experience!"