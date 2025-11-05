#!/bin/bash

echo "========================================"
echo "Redis Cluster Rebalancing"
echo "========================================"
echo ""

EXISTING_NODE_PORT=9000

echo "Step 1: Checking current cluster status..."
echo ""

# Display current cluster state
echo "Current cluster nodes:"
docker exec redis-node-1 redis-cli -p $EXISTING_NODE_PORT cluster nodes

echo ""
echo "Current slot distribution:"
./scripts/show-slot-distribution.sh

echo ""
echo "Step 2: Initiating cluster rebalance..."
echo ""

# Get list of master nodes with their addresses
MASTERS=$(docker exec redis-node-1 redis-cli -p $EXISTING_NODE_PORT cluster nodes | grep master | grep -v fail | awk '{print $2}' | cut -d@ -f1)
MASTER_COUNT=$(echo "$MASTERS" | wc -l | tr -d ' ')

echo "Found $MASTER_COUNT master nodes:"
echo "$MASTERS"
echo ""

if [ "$MASTER_COUNT" -lt 2 ]; then
    echo "Error: Need at least 2 master nodes to rebalance"
    exit 1
fi

# Ask for confirmation
echo "This will rebalance hash slots evenly across all $MASTER_COUNT master nodes."
echo "Each master will get approximately $((16384 / MASTER_COUNT)) slots."
echo ""
read -p "Do you want to proceed? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Rebalancing cancelled."
    exit 0
fi

echo ""
echo "Step 3: Performing automatic rebalance..."

# Perform the rebalance using redis-cli
docker exec redis-node-1 redis-cli --cluster rebalance 127.0.0.1:$EXISTING_NODE_PORT --cluster-use-empty-masters

REBALANCE_EXIT_CODE=$?

echo ""
if [ $REBALANCE_EXIT_CODE -eq 0 ]; then
    echo "✓ Cluster rebalancing completed successfully"
else
    echo "✗ Cluster rebalancing failed"
    echo ""
    echo "You can try manual rebalancing:"
    echo "1. Check which nodes need slots:"
    echo "   docker exec redis-node-1 redis-cli -p $EXISTING_NODE_PORT cluster nodes"
    echo ""
    echo "2. Manually reshard slots:"
    echo "   docker exec -it redis-node-1 redis-cli --cluster reshard 127.0.0.1:$EXISTING_NODE_PORT"
    exit 1
fi

echo ""
echo "Step 4: Waiting for rebalancing to stabilize..."
sleep 10

echo ""
echo "Step 5: Verifying rebalanced cluster..."
echo ""

# Show new slot distribution
echo "New slot distribution:"
./scripts/show-slot-distribution.sh

echo ""
echo "Cluster health check:"
docker exec redis-node-1 redis-cli -p $EXISTING_NODE_PORT cluster info | grep -E "(cluster_state|cluster_slots_assigned|cluster_slots_ok|cluster_known_nodes)"

echo ""
echo "Step 6: Testing cluster functionality..."

# Test that we can write and read data
TEST_KEY="rebalance:test:$(date +%s)"
TEST_VALUE="rebalance-test-value"

echo "Writing test key: $TEST_KEY"
docker exec redis-node-1 redis-cli -p $EXISTING_NODE_PORT set "$TEST_KEY" "$TEST_VALUE" > /dev/null

if [ $? -eq 0 ]; then
    echo "✓ Write operation successful"
    
    # Try to read it back
    RETRIEVED_VALUE=$(docker exec redis-node-1 redis-cli -p $EXISTING_NODE_PORT get "$TEST_KEY")
    if [ "$RETRIEVED_VALUE" = "$TEST_VALUE" ]; then
        echo "✓ Read operation successful"
        
        # Clean up test key
        docker exec redis-node-1 redis-cli -p $EXISTING_NODE_PORT del "$TEST_KEY" > /dev/null
        echo "✓ Cleanup successful"
    else
        echo "✗ Read operation failed"
    fi
else
    echo "✗ Write operation failed"
fi

echo ""
echo "========================================"
echo "Cluster Rebalancing Complete"
echo "========================================"
echo ""
echo "Summary:"
echo "- Hash slots have been redistributed evenly"
echo "- Each master now handles ~$((16384 / MASTER_COUNT)) slots"
echo "- Cluster is ready for normal operations"
echo ""
echo "Monitoring commands:"
echo "1. Watch slot distribution:"
echo "   ./scripts/show-slot-distribution.sh"
echo ""
echo "2. Monitor cluster health:"
echo "   ./scripts/watch-failover.sh"
echo ""
echo "3. Test cluster performance:"
echo "   npm run test-sharding"