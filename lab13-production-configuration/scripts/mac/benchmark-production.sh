#!/bin/bash

echo "📈 Redis Production Performance Benchmark"
echo "========================================"

HOST=${REDIS_HOST:-localhost}
PORT=${REDIS_PORT:-6379}
PASSWORD_PARAM=""
if [ -n "$REDIS_PASSWORD" ]; then
    PASSWORD_PARAM="-a $REDIS_PASSWORD"
fi

echo "🎯 Running basic performance tests..."

# Basic benchmark with insurance-like operations
echo ""
echo "📝 Testing SET operations (insurance policy creation)..."
redis-cli -h $HOST -p $PORT $PASSWORD_PARAM eval "
for i=1,1000 do
    redis.call('SET', 'benchmark:policy:' .. i, 'Policy data for customer ' .. i)
end
return 'OK'
" 0

echo "📖 Testing GET operations (policy retrieval)..."
redis-cli -h $HOST -p $PORT $PASSWORD_PARAM eval "
for i=1,1000 do
    redis.call('GET', 'benchmark:policy:' .. i)
end
return 'OK'
" 0

echo "🏗️ Testing HSET operations (customer profiles)..."
redis-cli -h $HOST -p $PORT $PASSWORD_PARAM eval "
for i=1,1000 do
    redis.call('HSET', 'benchmark:customer:' .. i, 'name', 'Customer ' .. i, 'email', 'customer' .. i .. '@insurance.com')
end
return 'OK'
" 0

echo "🔍 Testing HGET operations (customer data retrieval)..."
redis-cli -h $HOST -p $PORT $PASSWORD_PARAM eval "
for i=1,1000 do
    redis.call('HGET', 'benchmark:customer:' .. i, 'name')
end
return 'OK'
" 0

# Cleanup benchmark data
echo ""
echo "🧹 Cleaning up benchmark data..."
redis-cli -h $HOST -p $PORT $PASSWORD_PARAM eval "
local keys = redis.call('KEYS', 'benchmark:*')
for i=1,#keys do
    redis.call('DEL', keys[i])
end
return #keys
" 0

echo ""
echo "📊 Performance metrics summary:"
redis-cli -h $HOST -p $PORT $PASSWORD_PARAM INFO stats | grep -E "(total_commands_processed|total_connections_received|keyspace_hits|keyspace_misses)"

echo ""
echo "⚡ Latency check:"
redis-cli -h $HOST -p $PORT $PASSWORD_PARAM --latency-history -i 1 &
LATENCY_PID=$!
sleep 5
kill $LATENCY_PID 2>/dev/null

echo ""
echo "✅ Benchmark completed!"
