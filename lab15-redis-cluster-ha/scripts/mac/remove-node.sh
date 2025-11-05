#!/bin/bash

# Check if port is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <port>"
    echo "Example: $0 9006"
    echo ""
    echo "This will safely remove a node from the cluster"
    echo "For master nodes, slots will be migrated to other masters first"
    exit 1
fi

TARGET_PORT=$1
EXISTING_NODE_PORT=9000

echo "========================================"
echo "Redis Cluster Node Removal"
echo "========================================"
echo ""
echo "Removing node on port $TARGET_PORT..."

# Check if the target node exists in the cluster
echo "Step 1: Verifying target node exists in cluster..."

NODE_INFO=$(docker exec redis-node-1 redis-cli -p $EXISTING_NODE_PORT cluster nodes 2>/dev/null | grep ":$TARGET_PORT@")
if [ -z "$NODE_INFO" ]; then
    echo "Error: Node on port $TARGET_PORT not found in cluster"
    echo ""
    echo "Available nodes:"
    docker exec redis-node-1 redis-cli -p $EXISTING_NODE_PORT cluster nodes 2>/dev/null | awk '{print $2}' | cut -d@ -f1
    exit 1
fi

NODE_ID=$(echo "$NODE_INFO" | awk '{print $1}')
NODE_FLAGS=$(echo "$NODE_INFO" | awk '{print $3}')
NODE_ROLE="replica"

if echo "$NODE_FLAGS" | grep -q "master"; then
    NODE_ROLE="master"
fi

echo "✓ Found $NODE_ROLE node: $NODE_ID on port $TARGET_PORT"

# Check if it's the last master
if [ "$NODE_ROLE" = "master" ]; then
    MASTER_COUNT=$(docker exec redis-node-1 redis-cli -p $EXISTING_NODE_PORT cluster nodes 2>/dev/null | grep master | grep -v fail | wc -l)
    if [ "$MASTER_COUNT" -le 3 ]; then
        echo ""
        echo "⚠ Warning: Removing this master will leave only $((MASTER_COUNT - 1)) masters"
        echo "Minimum recommended masters for HA: 3"
        echo ""
        read -p "Do you want to proceed? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Node removal cancelled."
            exit 0
        fi
    fi
fi

if [ "$NODE_ROLE" = "master" ]; then
    echo ""
    echo "Step 2: Checking slots assigned to master node..."
    
    # Get slots assigned to this master
    SLOTS=$(echo "$NODE_INFO" | cut -d' ' -f9-)
    if [ "$SLOTS" != "-" ] && [ -n "$SLOTS" ]; then
        echo "Master has assigned slots: $SLOTS"
        echo ""
        echo "Step 3: Migrating slots to other masters..."
        
        # Use redis-cli reshard to move all slots away from this node
        echo "Initiating slot migration..."
        docker exec redis-node-1 redis-cli --cluster reshard 127.0.0.1:$EXISTING_NODE_PORT \
            --cluster-from $NODE_ID \
            --cluster-to-all \
            --cluster-slots 16384 \
            --cluster-yes
            
        if [ $? -ne 0 ]; then
            echo "✗ Failed to migrate slots"
            echo ""
            echo "Manual slot migration required:"
            echo "1. Run: docker exec -it redis-node-1 redis-cli --cluster reshard 127.0.0.1:$EXISTING_NODE_PORT"
            echo "2. Choose source node: $NODE_ID"
            echo "3. Move all slots to other masters"
            exit 1
        fi
        
        echo "✓ Slots migrated successfully"
        
        # Wait for migration to complete
        echo "Waiting for migration to stabilize..."
        sleep 5
        
        # Verify no slots remain
        REMAINING_SLOTS=$(docker exec redis-node-1 redis-cli -p $EXISTING_NODE_PORT cluster nodes 2>/dev/null | grep "$NODE_ID" | cut -d' ' -f9-)
        if [ "$REMAINING_SLOTS" != "-" ] && [ -n "$REMAINING_SLOTS" ]; then
            echo "✗ Some slots still assigned to node: $REMAINING_SLOTS"
            echo "Please migrate remaining slots manually before removing node"
            exit 1
        fi
    else
        echo "✓ Master has no assigned slots"
    fi
else
    echo ""
    echo "Step 2: Replica node - no slot migration needed"
fi

echo ""
echo "Step $((NODE_ROLE == "master" ? 4 : 3)): Removing node from cluster..."

# Remove the node from cluster
docker exec redis-node-1 redis-cli --cluster del-node 127.0.0.1:$EXISTING_NODE_PORT $NODE_ID

if [ $? -eq 0 ]; then
    echo "✓ Node removed from cluster successfully"
else
    echo "✗ Failed to remove node from cluster"
    exit 1
fi

echo ""
echo "Step $((NODE_ROLE == "master" ? 5 : 4)): Stopping and removing container..."

# Find container name based on port
CONTAINER_NAME=""
for i in {1..10}; do
    if docker ps -a --format "table {{.Names}}\t{{.Ports}}" | grep -q "redis-node-$i.*:$TARGET_PORT->"; then
        CONTAINER_NAME="redis-node-$i"
        break
    fi
done

if [ -n "$CONTAINER_NAME" ]; then
    echo "Stopping container: $CONTAINER_NAME"
    docker stop $CONTAINER_NAME
    
    echo "Removing container: $CONTAINER_NAME"
    docker rm $CONTAINER_NAME
    
    # Remove volume
    echo "Removing volume: redis-node-$i-data"
    docker volume rm "redis-node-$i-data" 2>/dev/null || true
    
    # Remove config file
    if [ -f "config/redis-node-$i.conf" ]; then
        echo "Removing config file: config/redis-node-$i.conf"
        rm "config/redis-node-$i.conf"
    fi
    
    echo "✓ Container and associated resources removed"
else
    echo "⚠ Container not found for port $TARGET_PORT"
    echo "You may need to manually stop and remove the container"
fi

echo ""
echo "Step $((NODE_ROLE == "master" ? 6 : 5)): Verifying cluster state..."

# Display current cluster state
echo ""
echo "Current cluster nodes:"
docker exec redis-node-1 redis-cli -p $EXISTING_NODE_PORT cluster nodes

echo ""
echo "Cluster info:"
docker exec redis-node-1 redis-cli -p $EXISTING_NODE_PORT cluster info | grep -E "(cluster_state|cluster_slots_assigned|cluster_slots_ok|cluster_known_nodes)"

echo ""
echo "========================================"
echo "Node Removal Complete"
echo "========================================"
echo ""
echo "✓ Node on port $TARGET_PORT removed successfully"
echo "✓ Cluster state updated"

if [ "$NODE_ROLE" = "master" ]; then
    echo "✓ Slots redistributed to remaining masters"
fi

echo ""
echo "Post-removal actions:"
echo "1. Check cluster health:"
echo "   ./scripts/show-slot-distribution.sh"
echo ""
echo "2. Monitor cluster:"
echo "   ./scripts/watch-failover.sh"
echo ""
echo "3. Rebalance if needed:"
echo "   ./scripts/rebalance-cluster.sh"