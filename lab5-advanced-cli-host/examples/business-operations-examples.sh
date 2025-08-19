#!/bin/bash

# Business Operations Examples with Host Parameters
# Replace localhost:6379 with your actual Redis server details

HOST="localhost"
PORT="6379"

echo "=== Business Operations Examples ==="
echo "===================================="
echo "Using Redis server: $HOST:$PORT"
echo ""

echo "1. Customer Management:"
echo "   Creating customer profile..."
redis-cli -h $HOST -p $PORT HSET customer:DEMO name "Demo Customer"
redis-cli -h $HOST -p $PORT HSET customer:DEMO email "demo@example.com"
redis-cli -h $HOST -p $PORT HSET customer:DEMO tier "standard"

echo "   Retrieving customer profile:"
redis-cli -h $HOST -p $PORT HGETALL customer:DEMO

echo ""
echo "2. Order Processing:"
echo "   Adding orders to queue..."
redis-cli -h $HOST -p $PORT LPUSH demo:orders "ORDER-001"
redis-cli -h $HOST -p $PORT LPUSH demo:orders "ORDER-002"

echo "   Checking queue status:"
echo "   Queue length: $(redis-cli -h $HOST -p $PORT LLEN demo:orders)"
echo "   Queue contents:"
redis-cli -h $HOST -p $PORT LRANGE demo:orders 0 -1

echo ""
echo "3. Analytics:"
echo "   Adding customer scores..."
redis-cli -h $HOST -p $PORT ZADD demo:scores 100 "customer1" 150 "customer2" 200 "customer3"

echo "   Top customers:"
redis-cli -h $HOST -p $PORT ZREVRANGE demo:scores 0 2 WITHSCORES

echo ""
echo "4. Session Management:"
echo "   Creating session with expiration..."
redis-cli -h $HOST -p $PORT SETEX demo:session:abc123 300 "user:demo"

echo "   Checking session TTL:"
redis-cli -h $HOST -p $PORT TTL demo:session:abc123

echo ""
echo "5. Cleanup:"
redis-cli -h $HOST -p $PORT DEL customer:DEMO
redis-cli -h $HOST -p $PORT DEL demo:orders
redis-cli -h $HOST -p $PORT DEL demo:scores
redis-cli -h $HOST -p $PORT DEL demo:session:abc123

echo "✅ Business operations examples completed"
echo "💡 Modify HOST and PORT variables at the top of this script for different servers"
