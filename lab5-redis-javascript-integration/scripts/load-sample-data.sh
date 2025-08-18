#!/bin/bash

# Load sample data for Lab 5
echo "Loading sample data for Lab 5..."

redis-cli << 'REDIS'
# Clear existing data
FLUSHDB

# Create sample customers
HSET customer:1001 name "Alice Johnson" email "alice@example.com" tier "premium"
HSET customer:1002 name "Bob Smith" email "bob@example.com" tier "standard"
HSET customer:1003 name "Carol White" email "carol@example.com" tier "premium"

# Create sample products
HSET product:P001 name "Widget A" price "29.99" stock "150"
HSET product:P002 name "Widget B" price "49.99" stock "75"
HSET product:P003 name "Widget C" price "19.99" stock "200"

# Create sample orders
LPUSH orders:pending "ORD-2024-001"
LPUSH orders:pending "ORD-2024-002"
LPUSH orders:processing "ORD-2024-003"

# Create sets for categories
SADD customers:premium 1001 1003
SADD customers:standard 1002

# Create sorted set for customer scores
ZADD customer:scores 850 1001 720 1002 900 1003

# Create sample stream data
XADD events:customer * action "login" customer_id "1001" timestamp "1704067200"
XADD events:customer * action "purchase" customer_id "1002" amount "49.99"
XADD events:customer * action "logout" customer_id "1001" timestamp "1704070800"

# Set some TTL examples
SET session:abc123 "user:1001" EX 3600
SET cache:product:P001 "{\"name\":\"Widget A\",\"price\":29.99}" EX 300

# Display summary
echo "Sample data loaded:"
echo "  - Customers: 3"
echo "  - Products: 3"
echo "  - Orders: 3"
echo "  - Events: 3"
echo "  - Sessions: 1 (with TTL)"
echo "  - Cache entries: 1 (with TTL)"

INFO keyspace
REDIS

echo "✅ Sample data loaded successfully!"
