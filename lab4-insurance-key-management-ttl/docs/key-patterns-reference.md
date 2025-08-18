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
