#!/bin/bash

echo "🏢 Loading Insurance Production Sample Data"
echo "=========================================="

# Check if Redis connection parameters are set
if [ -z "$REDIS_HOST" ]; then
    echo "⚠️  Please set REDIS_HOST environment variable"
    exit 1
fi

HOST=${REDIS_HOST}
PORT=${REDIS_PORT:-6379}
PASSWORD_PARAM=""
if [ -n "$REDIS_PASSWORD" ]; then
    PASSWORD_PARAM="-a $REDIS_PASSWORD"
fi

echo "📊 Loading insurance policies..."
redis-cli -h $HOST -p $PORT $PASSWORD_PARAM SET policy:P001 "Auto Insurance - Premium: $1200/year"
redis-cli -h $HOST -p $PORT $PASSWORD_PARAM SET policy:P002 "Home Insurance - Premium: $800/year"
redis-cli -h $HOST -p $PORT $PASSWORD_PARAM SET policy:P003 "Life Insurance - Premium: $2400/year"

echo "👥 Loading customer profiles..."
redis-cli -h $HOST -p $PORT $PASSWORD_PARAM HSET customer:C001 name "Alice Johnson" email "alice@email.com" phone "555-0101" policy_count 2
redis-cli -h $HOST -p $PORT $PASSWORD_PARAM HSET customer:C002 name "Bob Smith" email "bob@email.com" phone "555-0102" policy_count 1
redis-cli -h $HOST -p $PORT $PASSWORD_PARAM HSET customer:C003 name "Carol Davis" email "carol@email.com" phone "555-0103" policy_count 3

echo "📋 Loading active claims..."
redis-cli -h $HOST -p $PORT $PASSWORD_PARAM HSET claim:CL001 policy_id "P001" customer_id "C001" amount 5000 status "under_review"
redis-cli -h $HOST -p $PORT $PASSWORD_PARAM HSET claim:CL002 policy_id "P002" customer_id "C003" amount 15000 status "approved"

echo "🔢 Setting up counters and analytics..."
redis-cli -h $HOST -p $PORT $PASSWORD_PARAM SET analytics:total_policies 3
redis-cli -h $HOST -p $PORT $PASSWORD_PARAM SET analytics:total_customers 3
redis-cli -h $HOST -p $PORT $PASSWORD_PARAM SET analytics:active_claims 2
redis-cli -h $HOST -p $PORT $PASSWORD_PARAM SET analytics:total_premium_volume 4400

echo "⏰ Setting TTL for temporary data..."
redis-cli -h $HOST -p $PORT $PASSWORD_PARAM SETEX session:S001 3600 "customer_id:C001"
redis-cli -h $HOST -p $PORT $PASSWORD_PARAM SETEX quote:Q001 1800 "auto_quote_customer_C002"

echo "🏷️ Creating test sets and sorted sets..."
redis-cli -h $HOST -p $PORT $PASSWORD_PARAM SADD policy_types "auto" "home" "life" "health"
redis-cli -h $HOST -p $PORT $PASSWORD_PARAM ZADD premium_leaderboard 1200 "P001" 800 "P002" 2400 "P003"

echo ""
echo "✅ Insurance production sample data loaded successfully!"
echo "📊 Data summary:"
redis-cli -h $HOST -p $PORT $PASSWORD_PARAM DBSIZE
echo ""
echo "🔍 Sample data verification:"
echo "Policies:" $(redis-cli -h $HOST -p $PORT $PASSWORD_PARAM KEYS "policy:*" | wc -l)
echo "Customers:" $(redis-cli -h $HOST -p $PORT $PASSWORD_PARAM KEYS "customer:*" | wc -l)
echo "Claims:" $(redis-cli -h $HOST -p $PORT $PASSWORD_PARAM KEYS "claim:*" | wc -l)
echo "Analytics:" $(redis-cli -h $HOST -p $PORT $PASSWORD_PARAM KEYS "analytics:*" | wc -l)
