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
