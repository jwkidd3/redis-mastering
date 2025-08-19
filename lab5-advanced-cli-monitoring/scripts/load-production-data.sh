#!/bin/bash

# Production Data Loader for Lab 5
# Loads comprehensive dataset for advanced CLI operations and monitoring

set -e

echo "🚀 Loading comprehensive production dataset..."

# Test Redis connection
if ! redis-cli ping > /dev/null 2>&1; then
    echo "❌ Redis connection failed. Please check Redis server."
    exit 1
fi

echo "✅ Redis connection verified"

# Clear existing data for clean start
redis-cli FLUSHDB

echo "📊 Loading Customer Data..."
# Customer data with comprehensive attributes
redis-cli HSET customer:001 name "Sarah Johnson" email "sarah.j@email.com" phone "555-0101" status "active" risk_score "850" created "2024-01-15" last_contact "2024-08-10"
redis-cli HSET customer:002 name "Michael Chen" email "m.chen@email.com" phone "555-0102" status "active" risk_score "720" created "2024-02-20" last_contact "2024-08-12"
redis-cli HSET customer:003 name "Emma Rodriguez" email "e.rodriguez@email.com" phone "555-0103" status "suspended" risk_score "680" created "2024-03-10" last_contact "2024-07-25"
redis-cli HSET customer:004 name "David Kim" email "d.kim@email.com" phone "555-0104" status "active" risk_score "900" created "2024-01-05" last_contact "2024-08-15"
redis-cli HSET customer:005 name "Lisa Thompson" email "l.thompson@email.com" phone "555-0105" status "pending" risk_score "780" created "2024-07-30" last_contact "2024-08-18"

echo "🏠 Loading Policy Data..."
# Comprehensive policy data
redis-cli HSET policy:auto:001 customer_id "001" type "auto" premium "1200" coverage "full" deductible "500" status "active" start_date "2024-01-20" end_date "2025-01-20"
redis-cli HSET policy:home:001 customer_id "001" type "home" premium "800" coverage "comprehensive" deductible "1000" status "active" start_date "2024-02-01" end_date "2025-02-01"
redis-cli HSET policy:auto:002 customer_id "002" type "auto" premium "1100" coverage "liability" deductible "750" status "active" start_date "2024-03-01" end_date "2025-03-01"
redis-cli HSET policy:life:001 customer_id "003" type "life" premium "2400" coverage "term" deductible "0" status "suspended" start_date "2024-04-01" end_date "2025-04-01"
redis-cli HSET policy:auto:003 customer_id "004" type "auto" premium "1300" coverage "full" deductible "250" status "active" start_date "2024-05-01" end_date "2025-05-01"
redis-cli HSET policy:home:002 customer_id "005" type "home" premium "950" coverage "basic" deductible "1500" status "pending" start_date "2024-08-01" end_date "2025-08-01"

echo "🔍 Loading Claims Data..."
# Claims with processing states
redis-cli HSET claim:001 policy_id "auto:001" amount "2500" status "processing" created "2024-08-01" adjuster "adj:001" estimated_payout "2200"
redis-cli HSET claim:002 policy_id "home:001" amount "5000" status "approved" created "2024-07-15" adjuster "adj:002" estimated_payout "4500"
redis-cli HSET claim:003 policy_id "auto:002" amount "1200" status "pending" created "2024-08-10" adjuster "adj:001" estimated_payout "1000"
redis-cli HSET claim:004 policy_id "auto:003" amount "3200" status "investigating" created "2024-08-12" adjuster "adj:003" estimated_payout "0"

echo "👥 Loading Agent Data..."
# Agent performance data
redis-cli HSET agent:001 name "Robert Wilson" email "r.wilson@company.com" policies_sold "45" claims_handled "23" rating "4.8" department "auto"
redis-cli HSET agent:002 name "Jennifer Lee" email "j.lee@company.com" policies_sold "38" claims_handled "31" rating "4.9" department "home"
redis-cli HSET agent:003 name "Mark Davis" email "m.davis@company.com" policies_sold "52" claims_handled "19" rating "4.7" department "life"

echo "💰 Loading Quote Data with TTL..."
# Active quotes with expiration
redis-cli SETEX quote:temp:001 3600 '{"customer_id":"006","type":"auto","premium":1150,"valid_until":"2024-08-20"}'
redis-cli SETEX quote:temp:002 7200 '{"customer_id":"007","type":"home","premium":890,"valid_until":"2024-08-21"}'
redis-cli SETEX quote:temp:003 1800 '{"customer_id":"008","type":"life","premium":2100,"valid_until":"2024-08-19"}'

echo "🔐 Loading Session Data..."
# User sessions with various TTL
redis-cli SETEX session:user001 900 '{"user_id":"001","role":"customer","login_time":"2024-08-19T10:30:00Z"}'
redis-cli SETEX session:user002 1800 '{"user_id":"002","role":"agent","login_time":"2024-08-19T09:15:00Z"}'
redis-cli SETEX session:admin001 3600 '{"user_id":"admin001","role":"admin","login_time":"2024-08-19T08:00:00Z"}'
redis-cli SETEX session:user003 600 '{"user_id":"003","role":"customer","login_time":"2024-08-19T11:45:00Z"}'
redis-cli SETEX session:user004 2400 '{"user_id":"004","role":"agent","login_time":"2024-08-19T07:30:00Z"}'

echo "📈 Loading Analytics Data..."
# Daily counters
redis-cli SET analytics:daily:policies_created 12
redis-cli SET analytics:daily:claims_filed 8
redis-cli SET analytics:daily:quotes_generated 25
redis-cli SET analytics:daily:customer_registrations 5

# Monthly totals
redis-cli SET analytics:monthly:revenue 125000
redis-cli SET analytics:monthly:new_customers 67
redis-cli SET analytics:monthly:claims_paid 89000

echo "🏆 Loading Performance Data..."
# Performance scoring with sorted sets
redis-cli ZADD leaderboard:agents 850 "agent:001"
redis-cli ZADD leaderboard:agents 920 "agent:002"
redis-cli ZADD leaderboard:agents 780 "agent:003"

redis-cli ZADD risk_scores 850 "customer:001"
redis-cli ZADD risk_scores 720 "customer:002"
redis-cli ZADD risk_scores 680 "customer:003"
redis-cli ZADD risk_scores 900 "customer:004"
redis-cli ZADD risk_scores 780 "customer:005"

echo "📋 Loading Processing Queues..."
# Claims processing queue
redis-cli LPUSH queue:claims:processing "claim:001" "claim:003" "claim:004"
redis-cli LPUSH queue:claims:approved "claim:002"

# Policy renewal queue
redis-cli LPUSH queue:renewals:due "policy:auto:001" "policy:home:001"
redis-cli LPUSH queue:renewals:pending "policy:auto:002"

echo "🎯 Loading Customer Segments..."
# Customer categorization sets
redis-cli SADD customers:premium "001" "004"
redis-cli SADD customers:standard "002" "005"
redis-cli SADD customers:risk "003"

redis-cli SADD policies:auto "auto:001" "auto:002" "auto:003"
redis-cli SADD policies:home "home:001" "home:002"
redis-cli SADD policies:life "life:001"

echo "💾 Loading Cache Data..."
# Frequently accessed cache entries
redis-cli SETEX cache:customer:001:profile 300 '{"name":"Sarah Johnson","risk":"low","policies":2}'
redis-cli SETEX cache:policy:rates:auto 1800 '{"base":800,"premium":1200,"luxury":1800}'
redis-cli SETEX cache:weather:claims:forecast 900 '{"risk_level":"moderate","expected_claims":5}'

echo "🔄 Setting up Time Series Data..."
# Time-stamped events for analysis
redis-cli ZADD events:logins $(date -d "1 hour ago" +%s) "user:001"
redis-cli ZADD events:logins $(date -d "2 hours ago" +%s) "user:002"
redis-cli ZADD events:logins $(date -d "30 minutes ago" +%s) "user:003"
redis-cli ZADD events:logins $(date +%s) "user:004"

redis-cli ZADD events:claims $(date -d "3 days ago" +%s) "claim:001"
redis-cli ZADD events:claims $(date -d "1 week ago" +%s) "claim:002"
redis-cli ZADD events:claims $(date -d "2 days ago" +%s) "claim:003"
redis-cli ZADD events:claims $(date -d "1 day ago" +%s) "claim:004"

echo ""
echo "✅ Production dataset loaded successfully!"
echo ""
echo "📊 Dataset Summary:"
echo "   • 5 Customers with detailed profiles and risk scoring"
echo "   • 6 Policies (auto, home, life) with comprehensive coverage details"
echo "   • 4 Claims in various processing states"
echo "   • 3 Agents with performance metrics"
echo "   • 3 Quotes with business-appropriate TTL"
echo "   • 5 Sessions with varied expiration times"
echo "   • Analytics counters and time series data"
echo "   • Cache entries with TTL management"
echo "   • Processing queues for claims and policies"
echo ""
echo "🎯 Ready for advanced CLI operations and monitoring!"
echo "🔍 Open Redis Insight and connect to localhost:6379 to explore the data"
