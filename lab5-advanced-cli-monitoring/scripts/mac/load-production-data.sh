#!/bin/bash

# Load comprehensive production-like data for Lab 5
echo "📊 Loading production data for Lab 5 monitoring..."

# Redis connection configuration
REDIS_HOST=${REDIS_HOST:-localhost}
REDIS_PORT=${REDIS_PORT:-6379}
REDIS_PASSWORD=${REDIS_PASSWORD:-}

# Build Redis CLI command with connection parameters
REDIS_CLI_CMD="redis-cli -h $REDIS_HOST -p $REDIS_PORT"
if [ -n "$REDIS_PASSWORD" ]; then
    REDIS_CLI_CMD="$REDIS_CLI_CMD -a $REDIS_PASSWORD"
fi

echo "🔗 Connecting to Redis at $REDIS_HOST:$REDIS_PORT"

$REDIS_CLI_CMD << 'REDIS'
# Clear existing data
FLUSHDB

# Customer data with detailed profiles
HSET customer:1001 name "Alice Johnson" email "alice@example.com" tier "premium" risk_score "850" state "CA" join_date "2023-01-15"
HSET customer:1002 name "Bob Smith" email "bob@example.com" tier "standard" risk_score "720" state "TX" join_date "2023-02-20"
HSET customer:1003 name "Carol White" email "carol@example.com" tier "premium" risk_score "900" state "NY" join_date "2023-03-10"
HSET customer:1004 name "David Brown" email "david@example.com" tier "standard" risk_score "680" state "FL" join_date "2023-03-25"
HSET customer:1005 name "Eva Garcia" email "eva@example.com" tier "premium" risk_score "820" state "CA" join_date "2023-04-12"

# Policy data with coverage details
HSET policy:POL001 customer_id "1001" type "auto" premium "1200" deductible "500" status "active" state "CA"
HSET policy:POL002 customer_id "1001" type "home" premium "800" deductible "1000" status "active" state "CA"
HSET policy:POL003 customer_id "1002" type "auto" premium "900" deductible "250" status "active" state "TX"
HSET policy:POL004 customer_id "1003" type "life" premium "2400" deductible "0" status "active" state "NY"
HSET policy:POL005 customer_id "1004" type "auto" premium "1100" deductible "500" status "pending" state "FL"
HSET policy:POL006 customer_id "1005" type "home" premium "1500" deductible "1000" status "active" state "CA"

# Claims data with processing status
HSET claim:CLM001 policy_id "POL001" amount "3500" status "processing" adjuster "adj_001" filed_date "2024-08-01"
HSET claim:CLM002 policy_id "POL002" amount "8000" status "approved" adjuster "adj_002" filed_date "2024-07-15"
HSET claim:CLM003 policy_id "POL003" amount "1200" status "investigating" adjuster "adj_001" filed_date "2024-08-10"
HSET claim:CLM004 policy_id "POL004" amount "25000" status "pending" adjuster "adj_003" filed_date "2024-08-05"

# Agent performance data
HSET agent:001 name "John Agent" policies_sold "45" total_premium "54000" rating "4.8" region "west"
HSET agent:002 name "Jane Agent" policies_sold "62" total_premium "78000" rating "4.9" region "east"
HSET agent:003 name "Mike Agent" policies_sold "38" total_premium "42000" rating "4.6" region "central"

# Quote data with TTL (expires in different times)
SET quote:Q001 "{\"customer_id\":\"1006\",\"type\":\"auto\",\"premium\":950}" EX 3600
SET quote:Q002 "{\"customer_id\":\"1007\",\"type\":\"home\",\"premium\":1200}" EX 7200
SET quote:Q003 "{\"customer_id\":\"1008\",\"type\":\"life\",\"premium\":2000}" EX 1800

# Session data with various TTLs
SET session:sess_001 "customer:1001" EX 7200
SET session:sess_002 "customer:1002" EX 3600
SET session:sess_003 "agent:001" EX 14400
SET session:sess_004 "customer:1003" EX 7200
SET session:sess_005 "agent:002" EX 10800

# Customer tier sets
SADD customers:premium 1001 1003 1005
SADD customers:standard 1002 1004

# Policy type sets
SADD policies:auto POL001 POL003 POL005
SADD policies:home POL002 POL006
SADD policies:life POL004

# Risk scoring sorted set
ZADD risk_scores 850 1001 720 1002 900 1003 680 1004 820 1005

# Agent performance leaderboard
ZADD agent_leaderboard 78000 "agent:002" 54000 "agent:001" 42000 "agent:003"

# Regional performance
ZADD performance:west 54000 "agent:001"
ZADD performance:east 78000 "agent:002"
ZADD performance:central 42000 "agent:003"

# Cache data with TTL
SET cache:dashboard:summary "{\"total_policies\":6,\"active_claims\":4,\"premium_total\":7400}" EX 300
SET cache:customer:1001:profile "{\"name\":\"Alice Johnson\",\"policies\":2,\"premium\":2000}" EX 600

# Analytics counters
HINCRBY analytics:daily policies_created 6
HINCRBY analytics:daily claims_filed 4
HINCRBY analytics:daily quotes_generated 3
HINCRBY analytics:daily sessions_created 5

# Time series data simulation
ZADD timeseries:logins $(date -d '1 hour ago' +%s) "customer:1001"
ZADD timeseries:logins $(date -d '2 hours ago' +%s) "customer:1002"
ZADD timeseries:logins $(date -d '30 minutes ago' +%s) "customer:1003"

# Large data simulation for memory testing
HSET large_data:customers:bulk field1 "$(printf 'x%.0s' {1..1000})"
HSET large_data:customers:bulk field2 "$(printf 'y%.0s' {1..1000})"
HSET large_data:customers:bulk field3 "$(printf 'z%.0s' {1..1000})"

# List data for queue simulation
LPUSH queue:claims_processing "CLM001" "CLM003" "CLM004"
LPUSH queue:policy_approvals "POL005"
LPUSH queue:quote_processing "Q001" "Q002" "Q003"

echo "✅ Production data loaded successfully!"
echo ""
echo "📊 Data Summary:"
echo "   • Customers: 5 (3 premium, 2 standard)"
echo "   • Policies: 6 (3 auto, 2 home, 1 life)"
echo "   • Claims: 4 (various statuses)"
echo "   • Agents: 3 with performance data"
echo "   • Quotes: 3 (with TTL expiration)"
echo "   • Sessions: 5 (with various TTL)"
echo "   • Analytics: Daily counters initialized"
echo "   • Cache: 2 entries with TTL"
echo "   • Queues: 3 processing queues"
echo "   • Time Series: Login tracking data"
echo ""

INFO keyspace
DBSIZE
REDIS

echo ""
echo "🎯 Production environment ready for Lab 5!"
echo "📊 Connected to Redis at $REDIS_HOST:$REDIS_PORT"
