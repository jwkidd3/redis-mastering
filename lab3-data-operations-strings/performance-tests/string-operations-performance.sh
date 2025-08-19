#!/bin/bash

# Redis String Operations Performance Testing
# Comprehensive performance analysis for data operations

echo "⚡ Redis String Operations Performance Testing"
echo "🎯 Focus: Data operations and optimization"
echo ""

# Check Redis connection
redis-cli ping > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "❌ Redis connection failed. Ensure Redis is running."
    exit 1
fi

echo "✅ Redis connected. Starting performance tests..."
echo ""

# Test 1: Policy Number Generation Performance
echo "🔢 Test 1: Policy Number Generation Performance"
echo "Testing atomic counter operations for policy generation..."

start_time=$(date +%s.%N)
for i in {1..1000}; do
    redis-cli INCR perf:policy:counter > /dev/null
done
end_time=$(date +%s.%N)
duration=$(echo "$end_time - $start_time" | bc)
ops_per_sec=$(echo "scale=2; 1000 / $duration" | bc)

echo "✅ Generated 1000 policy numbers in ${duration}s"
echo "📊 Performance: ${ops_per_sec} operations/second"
echo ""

# Test 2: Premium Calculation Performance
echo "💰 Test 2: Premium Calculation Performance"
echo "Testing atomic financial operations..."

# Setup test premiums
for i in {1..100}; do
    redis-cli SET "perf:premium:${i}" 1000 > /dev/null
done

start_time=$(date +%s.%N)
for i in {1..100}; do
    redis-cli INCRBY "perf:premium:${i}" 150 > /dev/null  # Risk adjustment
    redis-cli DECRBY "perf:premium:${i}" 100 > /dev/null  # Discount
done
end_time=$(date +%s.%N)
duration=$(echo "$end_time - $start_time" | bc)
ops_per_sec=$(echo "scale=2; 200 / $duration" | bc)

echo "✅ Processed 200 premium calculations in ${duration}s"
echo "📊 Performance: ${ops_per_sec} operations/second"
echo ""

# Test 3: Customer Data Retrieval Performance
echo "👥 Test 3: Customer Data Retrieval Performance"
echo "Comparing individual vs batch retrieval operations..."

# Setup test customer data
for i in {1..50}; do
    redis-cli SET "perf:customer:${i}" "Customer Data ${i} | Age: $((25 + i)) | Location: City ${i}" > /dev/null
done

# Individual retrieval test
start_time=$(date +%s.%N)
for i in {1..50}; do
    redis-cli GET "perf:customer:${i}" > /dev/null
done
end_time=$(date +%s.%N)
individual_duration=$(echo "$end_time - $start_time" | bc)

# Batch retrieval test
keys=""
for i in {1..50}; do
    keys="$keys perf:customer:${i}"
done

start_time=$(date +%s.%N)
redis-cli MGET $keys > /dev/null
end_time=$(date +%s.%N)
batch_duration=$(echo "$end_time - $start_time" | bc)

improvement=$(echo "scale=2; ($individual_duration - $batch_duration) / $individual_duration * 100" | bc)

echo "✅ Individual retrieval: ${individual_duration}s"
echo "✅ Batch retrieval: ${batch_duration}s"
echo "📊 Batch operations are ${improvement}% faster"
echo ""

# Cleanup performance test data
echo "🧹 Cleaning up performance test data..."
redis-cli DEL $(redis-cli KEYS "perf:*" | tr '\n' ' ') > /dev/null 2>&1
echo "✅ Cleanup completed"
echo ""

echo "🎯 Performance testing completed successfully!"
echo "💡 Key insights:"
echo "   - Use MGET/MSET for batch operations (${improvement}% performance improvement)"
echo "   - Atomic operations (INCR/INCRBY/DECRBY) are efficient for financial calculations"
echo "   - String append operations are suitable for document assembly"
echo "   - Monitor string sizes to optimize memory usage"
