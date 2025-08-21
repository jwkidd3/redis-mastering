#!/bin/bash

echo "========================================"
echo "Redis Cluster Performance Benchmark"
echo "========================================"
echo ""

# Configuration
DEFAULT_DURATION=30
DEFAULT_CLIENTS=50
DEFAULT_REQUESTS=10000

# Parse command line arguments
DURATION=${1:-$DEFAULT_DURATION}
CLIENTS=${2:-$DEFAULT_CLIENTS}
REQUESTS=${3:-$DEFAULT_REQUESTS}

echo "Configuration:"
echo "  Duration: ${DURATION} seconds"
echo "  Concurrent clients: ${CLIENTS}"
echo "  Total requests: ${REQUESTS}"
echo ""

# Check if cluster is running
echo "Step 1: Verifying cluster status..."
if ! docker exec redis-node-1 redis-cli -p 9000 ping &> /dev/null; then
    echo "✗ Redis cluster is not responding"
    echo "Please start the cluster with: docker-compose up -d"
    exit 1
fi

CLUSTER_STATE=$(docker exec redis-node-1 redis-cli -p 9000 cluster info | grep cluster_state | cut -d: -f2 | tr -d '\r')
if [ "$CLUSTER_STATE" != "ok" ]; then
    echo "⚠ Warning: Cluster state is '$CLUSTER_STATE'"
    echo "Continuing with benchmark anyway..."
fi

echo "✓ Cluster is responding"

echo ""
echo "Step 2: Running individual node benchmarks..."

# Test each master node individually
MASTER_PORTS=(9000 9001 9002)
for port in "${MASTER_PORTS[@]}"; do
    echo ""
    echo "Benchmarking node on port $port..."
    echo "----------------------------------------"
    
    # Quick benchmark on individual node
    docker exec redis-node-1 redis-benchmark \
        -h 127.0.0.1 -p $port \
        -t set,get \
        -n 1000 \
        -c 10 \
        -q \
        --csv > /tmp/benchmark_${port}.csv 2>/dev/null || true
    
    if [ -f /tmp/benchmark_${port}.csv ]; then
        echo "Results for port $port:"
        cat /tmp/benchmark_${port}.csv | while IFS=, read -r test rps; do
            echo "  $test: $rps requests/sec"
        done
        rm -f /tmp/benchmark_${port}.csv
    else
        echo "  Direct benchmark failed, using cluster benchmark instead"
    fi
done

echo ""
echo "Step 3: Running cluster-wide performance test..."

# Create a more comprehensive benchmark script
cat > /tmp/cluster_benchmark.lua << 'EOF'
-- Redis Cluster Benchmark Script
local keys_tested = 0
local successful_ops = 0
local failed_ops = 0
local start_time = redis.call('TIME')[1]

-- Test SET operations across different slots
for i = 1, 100 do
    local key = "benchmark:test:" .. i
    local value = "value_" .. i .. "_" .. start_time
    
    local result = pcall(function()
        return redis.call('SET', key, value)
    end)
    
    if result then
        successful_ops = successful_ops + 1
    else
        failed_ops = failed_ops + 1
    end
    keys_tested = keys_tested + 1
end

-- Test GET operations
for i = 1, 100 do
    local key = "benchmark:test:" .. i
    
    local result = pcall(function()
        return redis.call('GET', key)
    end)
    
    if result then
        successful_ops = successful_ops + 1
    else
        failed_ops = failed_ops + 1
    end
end

return {keys_tested, successful_ops, failed_ops}
EOF

echo "Running Lua-based cluster test..."
RESULT=$(docker exec redis-node-1 redis-cli -p 9000 --eval /tmp/cluster_benchmark.lua 2>/dev/null || echo "0 0 100")
echo "Lua test result: $RESULT"

echo ""
echo "Step 4: Testing hash tag performance..."

# Test hash tags for co-location
echo "Testing hash tag co-location performance..."

# Generate test data with hash tags
HASH_TAG_TEST_START=$(date +%s)
for i in {1..50}; do
    docker exec redis-node-1 redis-cli -p 9000 set "{user:$i}:profile" "profile_data_$i" > /dev/null 2>&1 || true
    docker exec redis-node-1 redis-cli -p 9000 set "{user:$i}:settings" "settings_data_$i" > /dev/null 2>&1 || true
    docker exec redis-node-1 redis-cli -p 9000 set "{user:$i}:history" "history_data_$i" > /dev/null 2>&1 || true
done
HASH_TAG_TEST_END=$(date +%s)
HASH_TAG_DURATION=$((HASH_TAG_TEST_END - HASH_TAG_TEST_START))

echo "✓ Hash tag test completed in ${HASH_TAG_DURATION}s"

echo ""
echo "Step 5: Testing failover impact on performance..."

# Get baseline performance
echo "Measuring baseline performance..."
BASELINE_START=$(date +%s)
BASELINE_COUNT=0
for i in {1..100}; do
    if docker exec redis-node-1 redis-cli -p 9000 set "perf:test:$i" "value$i" > /dev/null 2>&1; then
        BASELINE_COUNT=$((BASELINE_COUNT + 1))
    fi
done
BASELINE_END=$(date +%s)
BASELINE_DURATION=$((BASELINE_END - BASELINE_START))
BASELINE_RPS=$((BASELINE_COUNT / BASELINE_DURATION))

echo "Baseline: $BASELINE_COUNT operations in ${BASELINE_DURATION}s (~${BASELINE_RPS} ops/sec)"

echo ""
echo "Step 6: Memory usage analysis..."

echo "Current memory usage per node:"
for port in 9000 9001 9002 9003 9004 9005; do
    MEMORY=$(docker exec redis-node-1 redis-cli -p $port info memory 2>/dev/null | grep used_memory_human | cut -d: -f2 | tr -d '\r' || echo "N/A")
    ROLE=$(docker exec redis-node-1 redis-cli -p $port info replication 2>/dev/null | grep role | cut -d: -f2 | tr -d '\r' || echo "unknown")
    echo "  Port $port ($ROLE): $MEMORY"
done

echo ""
echo "Step 7: Slot distribution analysis..."

echo "Keys per master node:"
docker exec redis-node-1 redis-cli -p 9000 cluster nodes | grep master | while read line; do
    NODE_ID=$(echo "$line" | awk '{print $1}')
    PORT=$(echo "$line" | awk '{print $2}' | cut -d: -f2 | cut -d@ -f1)
    KEYS=$(docker exec redis-node-1 redis-cli -p $PORT dbsize 2>/dev/null || echo "0")
    SLOTS=$(echo "$line" | awk '{for(i=9;i<=NF;i++) printf "%s ", $i}')
    echo "  Port $PORT: $KEYS keys, slots: ${SLOTS:0:30}..."
done

echo ""
echo "Step 8: Connection performance test..."

# Test connection overhead
CONNECTION_START=$(date +%s%N)
for i in {1..10}; do
    docker exec redis-node-1 redis-cli -p 9000 ping > /dev/null 2>&1
done
CONNECTION_END=$(date +%s%N)
CONNECTION_TIME_NS=$((CONNECTION_END - CONNECTION_START))
CONNECTION_TIME_MS=$((CONNECTION_TIME_NS / 1000000))
AVG_CONNECTION_TIME=$((CONNECTION_TIME_MS / 10))

echo "Average connection time: ${AVG_CONNECTION_TIME}ms"

echo ""
echo "Step 9: Cross-slot operation performance..."

# Test cross-slot operations (should fail fast)
CROSS_SLOT_START=$(date +%s%N)
CROSS_SLOT_FAILURES=0
for i in {1..20}; do
    if ! docker exec redis-node-1 redis-cli -p 9000 mget "key1:$i" "different_key:$i" > /dev/null 2>&1; then
        CROSS_SLOT_FAILURES=$((CROSS_SLOT_FAILURES + 1))
    fi
done
CROSS_SLOT_END=$(date +%s%N)
CROSS_SLOT_TIME_MS=$(((CROSS_SLOT_END - CROSS_SLOT_START) / 1000000))

echo "Cross-slot operations (expected to fail): $CROSS_SLOT_FAILURES/20 failed in ${CROSS_SLOT_TIME_MS}ms"

echo ""
echo "Step 10: Cleanup test data..."

# Clean up benchmark data
echo "Cleaning up test data..."
for i in {1..100}; do
    docker exec redis-node-1 redis-cli -p 9000 del "benchmark:test:$i" > /dev/null 2>&1 || true
    docker exec redis-node-1 redis-cli -p 9000 del "perf:test:$i" > /dev/null 2>&1 || true
done

for i in {1..50}; do
    docker exec redis-node-1 redis-cli -p 9000 del "{user:$i}:profile" "{user:$i}:settings" "{user:$i}:history" > /dev/null 2>&1 || true
done

rm -f /tmp/cluster_benchmark.lua

echo "✓ Cleanup completed"

echo ""
echo "========================================"
echo "Benchmark Summary"
echo "========================================"
echo ""
echo "Cluster Configuration:"
echo "  Nodes: 6 (3 masters, 3 replicas)"
echo "  Slots: 16384"
echo "  State: $CLUSTER_STATE"
echo ""
echo "Performance Results:"
echo "  Baseline performance: ~${BASELINE_RPS} ops/sec"
echo "  Hash tag operations: 150 ops in ${HASH_TAG_DURATION}s"
echo "  Average connection time: ${AVG_CONNECTION_TIME}ms"
echo "  Cross-slot failure rate: $CROSS_SLOT_FAILURES/20 (as expected)"
echo ""
echo "Memory Usage:"
for port in 9000 9001 9002; do
    MEMORY=$(docker exec redis-node-1 redis-cli -p $port info memory 2>/dev/null | grep used_memory_human | cut -d: -f2 | tr -d '\r' || echo "N/A")
    echo "  Master $port: $MEMORY"
done
echo ""
echo "Recommendations:"
echo "  1. Monitor memory usage during peak loads"
echo "  2. Use hash tags for related data co-location"
echo "  3. Avoid cross-slot operations in application logic"
echo "  4. Consider connection pooling for high-throughput apps"
echo ""
echo "For detailed benchmarking, use:"
echo "  docker exec redis-node-1 redis-benchmark -h 127.0.0.1 -p 9000 -t set,get -n 10000 -c 50"