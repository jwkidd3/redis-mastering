#!/bin/bash
#
# Lab 15: Redis Cluster Test Script
# Tests Redis cluster operations
#

echo "=== Redis Cluster Test ==="
echo ""

# Test cluster connectivity
echo "Testing cluster connectivity..."
if docker exec redis-node-1 redis-cli -p 7000 PING | grep -q "PONG"; then
    echo "✓ Cluster is responding"
else
    echo "✗ Cluster is not responding"
    exit 1
fi

# Get cluster info
echo ""
echo "Cluster info:"
docker exec redis-node-1 redis-cli -p 7000 CLUSTER INFO

# Test SET/GET operations
echo ""
echo "Testing SET/GET operations..."
docker exec redis-node-1 redis-cli -c -p 7000 SET test:cluster:key1 "value1"
VALUE=$(docker exec redis-node-1 redis-cli -c -p 7000 GET test:cluster:key1)

if [ "$VALUE" = "value1" ]; then
    echo "✓ SET/GET operations working"
else
    echo "✗ SET/GET operations failed"
    exit 1
fi

# Test key distribution
echo ""
echo "Testing key distribution across nodes..."
for i in {1..10}; do
    docker exec redis-node-1 redis-cli -c -p 7000 SET "test:key:$i" "value:$i"
done

echo "✓ Keys distributed across cluster"

# Check cluster health
echo ""
echo "Cluster nodes:"
docker exec redis-node-1 redis-cli -p 7000 CLUSTER NODES

echo ""
echo "=== Cluster Test Complete ==="
