#!/bin/bash

echo "Loading sample monitoring data into Redis..."

redis-cli <<REDIS_EOF
# Clear existing data
FLUSHDB

# Sample policy data
SET policy:AUTO:1001 '{"type":"AUTO","premium":1200,"status":"active","customer":"C001"}'
SET policy:HOME:2001 '{"type":"HOME","premium":1500,"status":"active","customer":"C002"}'
SET policy:LIFE:3001 '{"type":"LIFE","premium":800,"status":"active","customer":"C003"}'

# Sample claims queue
LPUSH claims:pending '{"id":"CLM001","type":"AUTO","amount":5000,"priority":"high"}'
LPUSH claims:pending '{"id":"CLM002","type":"HOME","amount":15000,"priority":"normal"}'
LPUSH claims:pending '{"id":"CLM003","type":"LIFE","amount":100000,"priority":"high"}'
LPUSH claims:pending '{"id":"CLM004","type":"AUTO","amount":3000,"priority":"low"}'
LPUSH claims:pending '{"id":"CLM005","type":"HOME","amount":8000,"priority":"normal"}'

# Sample sessions
SET session:user001 '{"userId":"U001","loginTime":"2024-08-18T10:00:00Z","lastActivity":"2024-08-18T10:30:00Z"}'
SET session:user002 '{"userId":"U002","loginTime":"2024-08-18T09:45:00Z","lastActivity":"2024-08-18T10:25:00Z"}'
SET session:user003 '{"userId":"U003","loginTime":"2024-08-18T10:15:00Z","lastActivity":"2024-08-18T10:35:00Z"}'

# Set TTL on sessions
EXPIRE session:user001 3600
EXPIRE session:user002 3600
EXPIRE session:user003 3600

# Initialize metrics
SET metrics:policy:lookups:minute 0
SET metrics:claims:submissions:minute 0

echo "Sample monitoring data loaded successfully!"
echo ""
echo "Data Summary:"
echo "============="
echo "Policies: 3"
echo "Pending Claims: 5"
echo "Active Sessions: 3"
echo ""
echo "Database Size:"
DBSIZE

REDIS_EOF

chmod +x scripts/load-sample-data.sh

echo "✅ Sample data loaded for monitoring"
