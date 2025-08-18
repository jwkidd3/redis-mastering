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
