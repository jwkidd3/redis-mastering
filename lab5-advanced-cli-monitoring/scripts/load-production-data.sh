#!/bin/bash

# Production Data Loader for Lab 5
set -e

echo "🚀 Loading production dataset..."

# Test Redis connection
if ! redis-cli ping > /dev/null 2>&1; then
    echo "❌ Redis connection failed"
    exit 1
fi

echo "✅ Redis connection verified"
redis-cli FLUSHDB

echo "📊 Loading Customer Data..."
redis-cli HSET customer:001 name "Sarah Johnson" email "sarah.j@email.com" status "active" risk_score "850"
redis-cli HSET customer:002 name "Michael Chen" email "m.chen@email.com" status "active" risk_score "720"
redis-cli HSET customer:003 name "Emma Rodriguez" email "e.rodriguez@email.com" status "suspended" risk_score "680"
redis-cli HSET customer:004 name "David Kim" email "d.kim@email.com" status "active" risk_score "900"
redis-cli HSET customer:005 name "Lisa Thompson" email "l.thompson@email.com" status "pending" risk_score "780"

echo "🏠 Loading Policy Data..."
redis-cli HSET policy:auto:001 customer_id "001" type "auto" premium "1200" status "active"
redis-cli HSET policy:home:001 customer_id "001" type "home" premium "800" status "active"
redis-cli HSET policy:auto:002 customer_id "002" type "auto" premium "1100" status "active"
redis-cli HSET policy:life:001 customer_id "003" type "life" premium "2400" status "suspended"
redis-cli HSET policy:auto:003 customer_id "004" type "auto" premium "1300" status "active"
redis-cli HSET policy:home:002 customer_id "005" type "home" premium "950" status "pending"

echo "🔍 Loading Claims Data..."
redis-cli HSET claim:001 policy_id "auto:001" amount "2500" status "processing"
redis-cli HSET claim:002 policy_id "home:001" amount "5000" status "approved"
redis-cli HSET claim:003 policy_id "auto:002" amount "1200" status "pending"
redis-cli HSET claim:004 policy_id "auto:003" amount "3200" status "investigating"

echo "📈 Loading Analytics Data..."
redis-cli SET analytics:daily:policies_created 12
redis-cli SET analytics:daily:claims_filed 8
redis-cli SET analytics:monthly:revenue 125000

echo "🏆 Loading Performance Data..."
redis-cli ZADD leaderboard:agents 850 "agent:001"
redis-cli ZADD leaderboard:agents 920 "agent:002"
redis-cli ZADD leaderboard:agents 780 "agent:003"

redis-cli ZADD risk_scores 850 "customer:001"
redis-cli ZADD risk_scores 720 "customer:002"
redis-cli ZADD risk_scores 680 "customer:003"
redis-cli ZADD risk_scores 900 "customer:004"
redis-cli ZADD risk_scores 780 "customer:005"

echo "🎯 Loading Customer Segments..."
redis-cli SADD customers:premium "001" "004"
redis-cli SADD customers:standard "002" "005"
redis-cli SADD customers:risk "003"

redis-cli SADD policies:auto "auto:001" "auto:002" "auto:003"
redis-cli SADD policies:home "home:001" "home:002"
redis-cli SADD policies:life "life:001"

echo ""
echo "✅ Production dataset loaded successfully!"
echo "📊 Total keys: $(redis-cli DBSIZE)"
echo "🔍 Open Redis Insight and connect to localhost:6379"
