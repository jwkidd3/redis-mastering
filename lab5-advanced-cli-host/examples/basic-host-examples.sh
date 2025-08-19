#!/bin/bash

# Basic Host Parameter Examples
# Replace localhost:6379 with your actual Redis server details

echo "=== Basic Host Parameter Examples ==="
echo "====================================="

# Basic connection test
echo "1. Testing basic connection:"
echo "   Command: redis-cli -h localhost -p 6379 PING"
redis-cli -h localhost -p 6379 PING

echo ""
echo "2. Getting server information:"
echo "   Command: redis-cli -h localhost -p 6379 INFO server"
redis-cli -h localhost -p 6379 INFO server | head -5

echo ""
echo "3. Setting and getting a value:"
echo "   Command: redis-cli -h localhost -p 6379 SET example:key 'example value'"
redis-cli -h localhost -p 6379 SET example:key "example value"
echo "   Command: redis-cli -h localhost -p 6379 GET example:key"
redis-cli -h localhost -p 6379 GET example:key

echo ""
echo "4. Checking database size:"
echo "   Command: redis-cli -h localhost -p 6379 DBSIZE"
redis-cli -h localhost -p 6379 DBSIZE

echo ""
echo "5. Cleaning up example:"
echo "   Command: redis-cli -h localhost -p 6379 DEL example:key"
redis-cli -h localhost -p 6379 DEL example:key

echo ""
echo "✅ Basic examples completed"
echo "💡 Remember to replace 'localhost:6379' with your actual Redis server details"
