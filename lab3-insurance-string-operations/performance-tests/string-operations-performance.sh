#!/bin/bash

# String Operations Performance Testing Script
# Tests various string operation patterns for insurance data

echo "⚡ Starting String Operations Performance Tests..."

# Test 1: Policy Number Generation Performance
echo "🧪 Test 1: Policy Number Generation Performance"
time redis-cli eval "
for i=1,1000 do
  redis.call('INCR', 'perf:policy:counter')
  redis.call('SET', 'perf:policy:' .. i, 'Policy data for policy number ' .. i)
end
return 'Generated 1000 policies'
" 0

# Test 2: Premium Calculation Performance
echo "🧪 Test 2: Premium Calculation Performance (1000 operations)"
time redis-cli eval "
for i=1,1000 do
  redis.call('SET', 'perf:premium:' .. i, 1000)
  redis.call('INCRBY', 'perf:premium:' .. i, i)
end
return 'Processed 1000 premium calculations'
" 0

# Test 3: Customer Data Retrieval Performance
echo "🧪 Test 3: Customer Data Retrieval Performance"
time redis-cli eval "
local results = {}
for i=1,100 do
  local key = 'customer:CUST00' .. (i % 6 + 1)
  local data = redis.call('GET', key)
  table.insert(results, data)
end
return #results .. ' customer records retrieved'
" 0

# Test 4: Batch vs Individual Operations
echo "🧪 Test 4: Individual GET Operations (100 calls)"
time redis-cli eval "
for i=1,100 do
  redis.call('GET', 'policy:AUTO-100001')
end
return 'Individual operations completed'
" 0

echo "🧪 Test 4: Batch MGET Operations (same data)"
time redis-cli eval "
local keys = {}
for i=1,100 do
  table.insert(keys, 'policy:AUTO-100001')
end
local result = redis.call('MGET', unpack(keys))
return 'Batch operations completed: ' .. #result
" 0

# Test 5: String Concatenation Performance
echo "🧪 Test 5: String Concatenation Performance"
time redis-cli eval "
for i=1,100 do
  redis.call('SET', 'perf:doc:' .. i, 'Initial document content')
  redis.call('APPEND', 'perf:doc:' .. i, ' | Additional content section 1')
  redis.call('APPEND', 'perf:doc:' .. i, ' | Additional content section 2')
  redis.call('APPEND', 'perf:doc:' .. i, ' | Final content section')
end
return 'Document assembly completed'
" 0

# Test 6: Memory Usage Analysis
echo "🧪 Test 6: Memory Usage Analysis"
redis-cli eval "
-- Check memory usage of different string sizes
redis.call('SET', 'memory:test:small', 'Small string')
redis.call('SET', 'memory:test:medium', string.rep('Medium string content ', 50))
redis.call('SET', 'memory:test:large', string.rep('Large string content with more data ', 200))
return 'Memory test strings created'
" 0

echo "Memory usage for different string sizes:"
redis-cli MEMORY USAGE memory:test:small
redis-cli MEMORY USAGE memory:test:medium
redis-cli MEMORY USAGE memory:test:large

# Cleanup performance test data
echo "🧹 Cleaning up performance test data..."
redis-cli eval "
local keys = redis.call('KEYS', 'perf:*')
if #keys > 0 then
  redis.call('DEL', unpack(keys))
end
keys = redis.call('KEYS', 'memory:test:*')
if #keys > 0 then
  redis.call('DEL', unpack(keys))
end
return 'Cleanup completed'
" 0

echo "✅ Performance testing completed!"
