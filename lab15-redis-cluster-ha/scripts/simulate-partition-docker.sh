#!/bin/bash

echo "========================================"
echo "Simulating Network Partition (Docker)"
echo "========================================"
echo ""
echo "This will simulate a network partition by disconnecting containers"
echo "Press Ctrl+C to restore network connectivity"
echo ""

# Store original network
ORIGINAL_NETWORK="lab15-redis-cluster-ha_redis-cluster-net"

# Function to create partition using Docker network isolation
create_partition() {
    echo "Creating network partition using Docker networks..."
    echo "Isolating nodes 1-3 from nodes 4-6..."
    
    # Create two separate networks for the partition
    docker network create partition-group-1 --driver bridge --subnet 172.22.1.0/24 2>/dev/null || true
    docker network create partition-group-2 --driver bridge --subnet 172.22.2.0/24 2>/dev/null || true
    
    # Disconnect all nodes from original network
    for i in {1..6}; do
        echo "  Disconnecting redis-node-$i from original network..."
        docker network disconnect $ORIGINAL_NETWORK redis-node-$i 2>/dev/null || true
    done
    
    # Connect Group 1 (nodes 1-3) to partition-group-1
    echo "  Creating partition group 1 (nodes 1-3)..."
    for i in {1..3}; do
        docker network connect partition-group-1 redis-node-$i 2>/dev/null || true
    done
    
    # Connect Group 2 (nodes 4-6) to partition-group-2  
    echo "  Creating partition group 2 (nodes 4-6)..."
    for i in {4..6}; do
        docker network connect partition-group-2 redis-node-$i 2>/dev/null || true
    done
    
    echo ""
    echo "✓ Network partition created using Docker networks"
    echo ""
    echo "Partition details:"
    echo "  Group 1 (network: partition-group-1): nodes 1, 2, 3"
    echo "  Group 2 (network: partition-group-2): nodes 4, 5, 6"
    echo "  Groups CANNOT communicate with each other"
    echo ""
}

# Function to heal partition
heal_partition() {
    echo ""
    echo "Healing network partition..."
    
    # Disconnect all nodes from partition networks
    for i in {1..6}; do
        echo "  Reconnecting redis-node-$i to original network..."
        docker network disconnect partition-group-1 redis-node-$i 2>/dev/null || true
        docker network disconnect partition-group-2 redis-node-$i 2>/dev/null || true
        
        # Reconnect to original network
        docker network connect $ORIGINAL_NETWORK redis-node-$i 2>/dev/null || true
    done
    
    # Clean up partition networks
    docker network rm partition-group-1 2>/dev/null || true
    docker network rm partition-group-2 2>/dev/null || true
    
    echo "✓ Network partition healed"
    echo "All nodes reconnected to original cluster network"
}

# Trap Ctrl+C to heal partition before exit
trap heal_partition EXIT INT TERM

# Create the partition
create_partition

echo ""
echo "Monitoring cluster state during partition..."
echo "============================================"
echo ""

# Monitor loop
while true; do
    echo "$(date '+%H:%M:%S') - Cluster Status:"
    
    # Check cluster state from both partitions
    echo "  Partition 1 view (from node 1):"
    state1=$(docker exec redis-node-1 redis-cli -p 9000 cluster info 2>/dev/null | grep cluster_state | cut -d: -f2 | tr -d '\r' || echo "unreachable")
    nodes1=$(docker exec redis-node-1 redis-cli -p 9000 cluster info 2>/dev/null | grep cluster_known_nodes | cut -d: -f2 | tr -d '\r' || echo "?")
    echo "    State: $state1, Known nodes: $nodes1"
    
    echo "  Partition 2 view (from node 4):"
    state2=$(docker exec redis-node-4 redis-cli -p 9003 cluster info 2>/dev/null | grep cluster_state | cut -d: -f2 | tr -d '\r' || echo "unreachable")
    nodes2=$(docker exec redis-node-4 redis-cli -p 9003 cluster info 2>/dev/null | grep cluster_known_nodes | cut -d: -f2 | tr -d '\r' || echo "?")
    echo "    State: $state2, Known nodes: $nodes2"
    
    echo ""
    sleep 5
done