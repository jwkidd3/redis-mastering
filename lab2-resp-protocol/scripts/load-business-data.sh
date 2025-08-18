#!/bin/bash

echo "📊 Loading business sample data for RESP protocol analysis..."

redis-cli << 'REDIS_COMMANDS'
# Clear existing data
FLUSHALL

# === POLICIES ===
SET policy:AUTO:1001 "Type:Auto|Premium:1200|Status:Active|Customer:C001"
SET policy:AUTO:1002 "Type:Auto|Premium:1400|Status:Active|Customer:C002"
SET policy:AUTO:1003 "Type:Auto|Premium:950|Status:Active|Customer:C003"
SET policy:HOME:2001 "Type:Home|Premium:800|Status:Active|Customer:C001"
SET policy:HOME:2002 "Type:Home|Premium:1100|Status:Pending|Customer:C004"
SET policy:LIFE:3001 "Type:Life|Premium:450|Status:Active|Customer:C002"

# === CUSTOMERS ===
HMSET customer:C001 name "John Smith" email "john@example.com" phone "555-0101" risk_score 750
HMSET customer:C002 name "Jane Doe" email "jane@example.com" phone "555-0102" risk_score 680
HMSET customer:C003 name "Bob Johnson" email "bob@example.com" phone "555-0103" risk_score 820
HMSET customer:C004 name "Alice Brown" email "alice@example.com" phone "555-0104" risk_score 700

# === CLAIMS ===
HMSET claim:CLM:AUTO:2024:001 policy "AUTO:1001" amount 2500 status "pending" date "2024-08-01"
HMSET claim:CLM:HOME:2024:001 policy "HOME:2001" amount 5000 status "approved" date "2024-08-05"
HMSET claim:CLM:AUTO:2024:002 policy "AUTO:1002" amount 1200 status "processing" date "2024-08-10"

# === QUEUES ===
LPUSH claims:pending "CLM:AUTO:2024:003"
LPUSH claims:pending "CLM:HOME:2024:002"
LPUSH notifications:queue "Policy AUTO:1003 renewal due"
LPUSH notifications:queue "Claim CLM:AUTO:2024:001 requires review"

# === COUNTERS ===
SET metrics:daily:policies_created 0
SET metrics:daily:claims_filed 0
SET metrics:daily:customers_active 0
INCR metrics:daily:policies_created
INCR metrics:daily:policies_created
INCR metrics:daily:claims_filed

# === SETS ===
SADD policies:active "AUTO:1001" "AUTO:1002" "AUTO:1003" "HOME:2001" "LIFE:3001"
SADD policies:pending "HOME:2002"
SADD customers:premium "C001" "C003"

# === SORTED SETS ===
ZADD risk:scores 750 "C001" 680 "C002" 820 "C003" 700 "C004"
ZADD premium:amounts 1200 "AUTO:1001" 1400 "AUTO:1002" 950 "AUTO:1003" 800 "HOME:2001"

# === TTL EXAMPLES ===
SETEX quote:temporary:Q001 300 "Auto Quote: $1050/year"
SETEX session:web:S12345 1800 "user:C001|ip:192.168.1.100"

INFO keyspace
REDIS_COMMANDS

echo "✅ Business data loaded successfully!"
echo ""
echo "📊 Data Summary:"
redis-cli DBSIZE
echo ""
echo "Sample keys by type:"
echo "Policies: $(redis-cli KEYS 'policy:*' | wc -l)"
echo "Customers: $(redis-cli KEYS 'customer:*' | wc -l)"
echo "Claims: $(redis-cli KEYS 'claim:*' | wc -l)"
echo "Metrics: $(redis-cli KEYS 'metrics:*' | wc -l)"
