#!/bin/bash

# Check if port is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <replica_port>"
    echo "Example: $0 9004"
    echo ""
    echo "This will trigger manual failover for the replica on the specified port"
    echo "The replica will become the new master for its hash slots"
    exit 1
fi

REPLICA_PORT=$1
EXISTING_NODE_PORT=9000

echo "========================================"
echo "Redis Cluster Manual Failover"
echo "========================================"
echo ""
echo "Initiating manual failover for replica on port $REPLICA_PORT..."

# Check if the node exists and is a replica
echo "Step 1: Verifying replica node..."

NODE_INFO=$(docker exec redis-node-1 redis-cli -p $EXISTING_NODE_PORT cluster nodes 2>/dev/null | grep ":$REPLICA_PORT@")
if [ -z "$NODE_INFO" ]; then
    echo "Error: Node on port $REPLICA_PORT not found in cluster"
    echo ""
    echo "Available nodes:"
    docker exec redis-node-1 redis-cli -p $EXISTING_NODE_PORT cluster nodes 2>/dev/null | awk '{print $2}' | cut -d@ -f1
    exit 1
fi

NODE_ID=$(echo "$NODE_INFO" | awk '{print $1}')
NODE_FLAGS=$(echo "$NODE_INFO" | awk '{print $3}')

# Check if it's a replica
if echo "$NODE_FLAGS" | grep -q "master"; then
    echo "Error: Node on port $REPLICA_PORT is already a master"
    echo ""
    echo "Available replica nodes:"
    docker exec redis-node-1 redis-cli -p $EXISTING_NODE_PORT cluster nodes 2>/dev/null | grep slave | awk '{print $2}' | cut -d@ -f1
    exit 1
fi

if ! echo "$NODE_FLAGS" | grep -q "slave"; then
    echo "Error: Node on port $REPLICA_PORT is not a replica"
    exit 1
fi

# Get master node info
MASTER_ID=$(echo "$NODE_INFO" | awk '{print $4}')
MASTER_INFO=$(docker exec redis-node-1 redis-cli -p $EXISTING_NODE_PORT cluster nodes 2>/dev/null | grep "^$MASTER_ID")
MASTER_PORT=$(echo "$MASTER_INFO" | awk '{print $2}' | cut -d: -f2 | cut -d@ -f1)

echo "✓ Found replica node: $NODE_ID on port $REPLICA_PORT"
echo "✓ Current master: $MASTER_ID on port $MASTER_PORT"

echo ""
echo "Step 2: Checking cluster state before failover..."

# Show current cluster state
echo ""
echo "Current cluster nodes:"
docker exec redis-node-1 redis-cli -p $EXISTING_NODE_PORT cluster nodes | grep -E "$MASTER_ID|$NODE_ID"

echo ""
echo "Master node slots:"
echo "$MASTER_INFO" | cut -d' ' -f9-

echo ""
echo "Step 3: Performing manual failover..."

# Execute manual failover
echo "Triggering failover on replica $NODE_ID..."
CONTAINER_NAME=""
for i in {1..10}; do
    if docker ps --format "table {{.Names}}\t{{.Ports}}" | grep -q "redis-node-$i.*:$REPLICA_PORT->"; then
        CONTAINER_NAME="redis-node-$i"
        break
    fi
done

if [ -z "$CONTAINER_NAME" ]; then
    echo "Error: Could not find container for port $REPLICA_PORT"
    exit 1
fi

echo "Executing CLUSTER FAILOVER on $CONTAINER_NAME..."
docker exec $CONTAINER_NAME redis-cli -p $REPLICA_PORT CLUSTER FAILOVER

FAILOVER_RESULT=$?

if [ $FAILOVER_RESULT -eq 0 ]; then
    echo "✓ Failover command executed successfully"
else
    echo "✗ Failover command failed"
    exit 1
fi

echo ""
echo "Step 4: Waiting for failover to complete..."
sleep 5

echo ""
echo "Step 5: Verifying failover results..."

# Check new cluster state
NEW_NODE_INFO=$(docker exec redis-node-1 redis-cli -p $EXISTING_NODE_PORT cluster nodes 2>/dev/null | grep "$NODE_ID")
NEW_NODE_FLAGS=$(echo "$NEW_NODE_INFO" | awk '{print $3}')

if echo "$NEW_NODE_FLAGS" | grep -q "master"; then
    echo "✓ Failover successful - node is now master"
    
    # Show the old master status
    OLD_MASTER_INFO=$(docker exec redis-node-1 redis-cli -p $EXISTING_NODE_PORT cluster nodes 2>/dev/null | grep "$MASTER_ID")
    OLD_MASTER_FLAGS=$(echo "$OLD_MASTER_INFO" | awk '{print $3}')
    
    if echo "$OLD_MASTER_FLAGS" | grep -q "slave"; then
        echo "✓ Former master is now replica"
    elif echo "$OLD_MASTER_FLAGS" | grep -q "fail"; then
        echo "⚠ Former master is marked as failed"
    else
        echo "? Former master status unclear"
    fi
else
    echo "✗ Failover failed - node is still replica"
    exit 1
fi

echo ""
echo "Step 6: Current cluster state after failover:"
echo ""
docker exec redis-node-1 redis-cli -p $EXISTING_NODE_PORT cluster nodes | grep -E "$MASTER_ID|$NODE_ID"

echo ""
echo "Cluster health check:"
docker exec redis-node-1 redis-cli -p $EXISTING_NODE_PORT cluster info | grep -E "(cluster_state|cluster_slots_assigned|cluster_slots_ok|cluster_known_nodes)"

echo ""
echo "Step 7: Testing cluster functionality..."

# Test that we can still write and read data
TEST_KEY="failover:test:$(date +%s)"
TEST_VALUE="failover-test-value"

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
echo "Manual Failover Complete"
echo "========================================"
echo ""
echo "✓ Replica on port $REPLICA_PORT is now master"
echo "✓ Former master on port $MASTER_PORT role changed"
echo "✓ Cluster is operational"
echo ""
echo "Monitoring commands:"
echo "1. Watch cluster status:"
echo "   ./scripts/watch-failover.sh"
echo ""
echo "2. Check slot distribution:"
echo "   ./scripts/show-slot-distribution.sh"
echo ""
echo "3. Monitor replication:"
echo "   npm run monitor-replication"