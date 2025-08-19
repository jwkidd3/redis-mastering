#!/bin/bash

# Getting Started Examples for Lab 1
# Replace HOSTNAME and PORT with your actual server details

HOSTNAME="redis-server.training.com"
PORT="6379"
PASSWORD=""  # Add password if required

echo "🚀 Redis Lab 1 - Getting Started Examples"
echo "==========================================="

echo "Testing connection..."
if [ -n "$PASSWORD" ]; then
    redis-cli -h $HOSTNAME -p $PORT -a $PASSWORD PING
else
    redis-cli -h $HOSTNAME -p $PORT PING
fi

echo ""
echo "📊 Server Information:"
redis-cli -h $HOSTNAME -p $PORT INFO server | head -5

echo ""
echo "🔢 Database Size:"
redis-cli -h $HOSTNAME -p $PORT DBSIZE

echo ""
echo "📝 Creating sample data..."
redis-cli -h $HOSTNAME -p $PORT SET lab1:welcome "Hello from Lab 1"
redis-cli -h $HOSTNAME -p $PORT SET lab1:counter 0
redis-cli -h $HOSTNAME -p $PORT INCR lab1:counter

echo ""
echo "📖 Reading sample data:"
redis-cli -h $HOSTNAME -p $PORT GET lab1:welcome
redis-cli -h $HOSTNAME -p $PORT GET lab1:counter

echo ""
echo "⏰ Setting expiration:"
redis-cli -h $HOSTNAME -p $PORT SETEX lab1:temp 30 "This expires in 30 seconds"
redis-cli -h $HOSTNAME -p $PORT TTL lab1:temp

echo ""
echo "🔍 Listing lab1 keys:"
redis-cli -h $HOSTNAME -p $PORT KEYS "lab1:*"

echo ""
echo "✅ Lab 1 examples complete!"
echo "💡 Remember to replace HOSTNAME and PORT with your actual server details"
