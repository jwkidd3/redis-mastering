#!/bin/bash

# Load sample data for Lab 5
echo "Loading sample data for Lab 5..."

# Clear existing data
echo "Clearing existing data..."
redis-cli FLUSHDB

# Create sample customers
echo "Creating sample customers..."
redis-cli HSET customer:1001 name "Alice Johnson" email "alice@example.com" tier "premium"
redis-cli HSET customer:1002 name "Bob Smith" email "bob@example.com" tier "standard"
redis-cli HSET customer:1003 name "Carol White" email "carol@example.com" tier "premium"

# Create sample products
echo "Creating sample products..."
redis-cli HSET product:P001 name "Widget A" price "29.99" stock "150"
redis-cli HSET product:P002 name "Widget B" price "49.99" stock "75"
redis-cli HSET product:P003 name "Widget C" price "19.99" stock "200"

# Create sample orders
echo "Creating sample orders..."
redis-cli LPUSH orders:pending "ORD-2024-001"
redis-cli LPUSH orders:pending "ORD-2024-002"
redis-cli LPUSH orders:processing "ORD-2024-003"

# Create sets for categories
echo "Creating customer category sets..."
redis-cli SADD customers:premium 1001 1003
redis-cli SADD customers:standard 1002

# Create sorted set for customer scores
echo "Creating customer scores..."
redis-cli ZADD customer:scores 850 1001 720 1002 900 1003

# Create sample stream data
echo "Creating sample stream events..."
redis-cli XADD events:customer "*" action "login" customer_id "1001" timestamp "1704067200"
redis-cli XADD events:customer "*" action "purchase" customer_id "1002" amount "49.99"
redis-cli XADD events:customer "*" action "logout" customer_id "1001" timestamp "1704070800"

# Set some TTL examples
echo "Creating session and cache data with TTL..."
redis-cli SET session:abc123 "user:1001" EX 3600
redis-cli SET cache:product:P001 '{"name":"Widget A","price":29.99}' EX 300

echo ""
echo "✅ Sample data loaded successfully!"
echo ""
echo "Data Summary:"
echo "============="
echo "Customers: $(redis-cli HLEN customer:1001 > /dev/null && echo "3" || echo "0")"
echo "Products: $(redis-cli HLEN product:P001 > /dev/null && echo "3" || echo "0")"
echo "Orders: $(redis-cli LLEN orders:pending)"
echo "Events: $(redis-cli XLEN events:customer)"
echo "Sessions: $(redis-cli EXISTS session:abc123)"
echo "Cache entries: $(redis-cli EXISTS cache:product:P001)"
echo ""
echo "Redis Database Info:"
redis-cli INFO keyspace

echo ""
echo "🎯 Ready to start Lab 5: Redis JavaScript Integration!"
echo ""
echo "Next steps:"
echo "1. Run: npm install"
echo "2. Run: npm run test-connection"
echo "3. Open Redis Insight and connect to localhost:6379"
echo "4. Start coding!"