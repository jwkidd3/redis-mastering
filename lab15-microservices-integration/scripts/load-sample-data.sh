#!/bin/bash

echo "📦 Loading sample data for Microservices Lab..."

# Load sample data into Redis
redis-cli <<'REDIS_EOF'
# Clear existing data
FLUSHDB

# Sample policies
HSET policy:POL001 id POL001 type AUTO customerId CUST001 premium 1200 coverage 100000 status active
HSET policy:POL002 id POL002 type HOME customerId CUST002 premium 800 coverage 250000 status active
HSET policy:POL003 id POL003 type LIFE customerId CUST003 premium 500 coverage 500000 status active

# Sample customers
HSET customer:CUST001 id CUST001 name "John Doe" email "john@example.com" tier premium
HSET customer:CUST002 id CUST002 name "Jane Smith" email "jane@example.com" tier standard
HSET customer:CUST003 id CUST003 name "Bob Johnson" email "bob@example.com" tier basic

# Sample claims
LPUSH claims:queue '{"id":"CLM001","policyId":"POL001","amount":1500,"status":"pending"}'
LPUSH claims:queue '{"id":"CLM002","policyId":"POL002","amount":3000,"status":"pending"}'

# Service registry entries (will be overwritten by services)
HSET service:registry policyService "localhost:3001" claimsService "localhost:3002"

# Configuration
SET config:cache:ttl 300
SET config:queue:timeout 30

echo "Sample data loaded successfully!"
echo ""
echo "Data Summary:"
echo "============="
echo "Policies loaded: 3"
KEYS policy:*
echo ""
echo "Customers loaded: 3"
KEYS customer:*
echo ""
echo "Claims in queue:"
LLEN claims:queue

REDIS_EOF

echo ""
echo "✅ Sample data loaded successfully!"
