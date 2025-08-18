#!/bin/bash

echo "Loading sample customer and policy data..."

redis-cli << 'REDIS_EOF'
# Clear existing data
FLUSHDB

# Create sample customers
HMSET customer:CUST001:profile \
  name "John Smith" \
  email "john.smith@email.com" \
  phone "555-0123" \
  age "35" \
  address "123 Main St, Dallas, TX" \
  created_at "2024-01-15T10:00:00Z" \
  status "ACTIVE"

HMSET customer:CUST002:profile \
  name "Sarah Johnson" \
  email "sarah.j@email.com" \
  phone "555-0124" \
  age "42" \
  address "456 Oak Ave, Dallas, TX" \
  created_at "2023-06-20T10:00:00Z" \
  status "ACTIVE"

# Set customer preferences
HMSET customer:CUST001:preferences \
  communication "email" \
  paperless "true" \
  auto_renewal "true"

HMSET customer:CUST002:preferences \
  communication "sms" \
  paperless "false" \
  auto_renewal "true"

# Create sample policies
HMSET policy:auto:AUTO-000001:details \
  policy_number "AUTO-000001" \
  customer_id "CUST001" \
  type "auto" \
  status "ACTIVE" \
  premium "1200" \
  coverage_amount "50000" \
  deductible "500" \
  start_date "2024-01-15T10:00:00Z" \
  end_date "2025-01-15T10:00:00Z"

HMSET policy:auto:AUTO-000001:attributes \
  vehicle_make "Toyota" \
  vehicle_model "Camry" \
  vehicle_year "2020" \
  vin "1HGBH41JXMN109186"

HMSET policy:home:HOME-000001:details \
  policy_number "HOME-000001" \
  customer_id "CUST002" \
  type "home" \
  status "ACTIVE" \
  premium "1800" \
  coverage_amount "500000" \
  deductible "1000" \
  start_date "2023-06-20T10:00:00Z" \
  end_date "2024-06-20T10:00:00Z"

HMSET policy:home:HOME-000001:attributes \
  property_address "456 Oak Ave, Dallas, TX" \
  property_type "Single Family" \
  year_built "2005" \
  square_feet "2500"

# Link policies to customers
SADD customer:CUST001:policies "AUTO-000001"
SADD customer:CUST002:policies "HOME-000001"

# Add to indices
SADD customers:active "CUST001" "CUST002"
SADD policies:auto:active "AUTO-000001"
SADD policies:home:active "HOME-000001"

# Add to sorted sets
ZADD customers:by_date 1705318800000 "CUST001" 1687260000000 "CUST002"
ZADD policies:by_premium 1200 "AUTO-000001" 1800 "HOME-000001"

echo "Sample data loaded successfully!"
echo "Customers: 2"
echo "Policies: 2"
DBSIZE
REDIS_EOF
