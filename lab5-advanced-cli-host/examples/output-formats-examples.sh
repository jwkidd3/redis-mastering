#!/bin/bash

# Output Format Examples with Host Parameters
# Replace localhost:6379 with your actual Redis server details

HOST="localhost" 
PORT="6379"

echo "=== Output Format Examples ==="
echo "=============================="
echo "Using Redis server: $HOST:$PORT"
echo ""

# Create sample data
echo "Creating sample data..."
redis-cli -h $HOST -p $PORT HSET demo:formats name "Demo User" age "30" city "New York"
redis-cli -h $HOST -p $PORT LPUSH demo:list "item1" "item2" "item3"

echo ""
echo "1. Default Format:"
echo "   Command: redis-cli -h $HOST -p $PORT HGETALL demo:formats"
redis-cli -h $HOST -p $PORT HGETALL demo:formats

echo ""
echo "2. CSV Format:"
echo "   Command: redis-cli -h $HOST -p $PORT --csv HGETALL demo:formats"
redis-cli -h $HOST -p $PORT --csv HGETALL demo:formats

echo ""
echo "3. Raw Format:"
echo "   Command: redis-cli -h $HOST -p $PORT --raw HGET demo:formats name"
redis-cli -h $HOST -p $PORT --raw HGET demo:formats name

echo ""
echo "4. List Operations - Different Formats:"
echo "   Default:"
redis-cli -h $HOST -p $PORT LRANGE demo:list 0 -1

echo "   CSV:"
redis-cli -h $HOST -p $PORT --csv LRANGE demo:list 0 -1

echo ""
echo "5. JSON Format (if supported):"
echo "   Command: redis-cli -h $HOST -p $PORT --json HGETALL demo:formats"
redis-cli -h $HOST -p $PORT --json HGETALL demo:formats 2>/dev/null || echo "   JSON format not supported in this Redis CLI version"

echo ""
echo "Cleanup:"
redis-cli -h $HOST -p $PORT DEL demo:formats demo:list

echo "✅ Output format examples completed"
echo "💡 Different formats are useful for scripts and data processing"
