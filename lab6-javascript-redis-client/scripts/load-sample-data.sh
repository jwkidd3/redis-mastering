#!/bin/bash

echo "🚀 Loading JavaScript Lab Sample Data..."
echo "====================================="

# Connect to Redis and load business data
redis-cli << 'REDIS_EOF'

# Clear any existing lab data
DEL customer:CUST001 customer:CUST002 customer:CUST003
DEL inventory:PROD001:stock inventory:PROD002:stock inventory:PROD003:stock inventory:PROD004:stock

# Sample customer data
SET customer:CUST001 '{"name":"John Smith","email":"john.smith@example.com","tier":"premium","accountBalance":5000}' EX 3600
SET customer:CUST002 '{"name":"Jane Doe","email":"jane.doe@example.com","tier":"standard","accountBalance":2500}' EX 3600
SET customer:CUST003 '{"name":"Bob Johnson","email":"bob.johnson@example.com","tier":"premium","accountBalance":7500}' EX 3600

# Sample inventory data
SET inventory:PROD001:stock 100
SET inventory:PROD002:stock 50
SET inventory:PROD003:stock 5
SET inventory:PROD004:stock 200

# Sample product details (using hashes)
HSET product:PROD001 name "Widget A" price 29.99 category "electronics"
HSET product:PROD002 name "Gadget B" price 49.99 category "electronics"
HSET product:PROD003 name "Tool C" price 19.99 category "hardware"
HSET product:PROD004 name "Device D" price 99.99 category "electronics"

# Sample order queue (using lists)
LPUSH orders:pending '{"orderId":"ORD001","customerId":"CUST001","total":149.95}'
LPUSH orders:pending '{"orderId":"ORD002","customerId":"CUST002","total":79.99}'
LPUSH orders:pending '{"orderId":"ORD003","customerId":"CUST003","total":229.95}'

# Sample metrics (using sorted sets)
ZADD sales:daily:20240818 150.00 "PROD001"
ZADD sales:daily:20240818 200.00 "PROD002"
ZADD sales:daily:20240818 75.00 "PROD003"
ZADD sales:daily:20240818 500.00 "PROD004"

echo "Sample data loaded successfully!"
echo ""
echo "Data Summary:"
echo "============="
echo "Customers: 3"
KEYS customer:*
echo ""
echo "Products: 4"
KEYS product:*
echo ""
echo "Inventory: 4 items"
KEYS inventory:*
echo ""
echo "Pending Orders: 3"
LLEN orders:pending
echo ""
echo "Database Size:"
DBSIZE

REDIS_EOF

echo ""
echo "✅ JavaScript lab data loaded successfully!"
