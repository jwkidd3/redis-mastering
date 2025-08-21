#!/bin/bash

echo "========================================"
echo "Simulating Network Partition"
echo "========================================"
echo ""
echo "This will simulate a network partition between cluster nodes"
echo "Press Ctrl+C to restore network connectivity"
echo ""

# Function to create partition
create_partition() {
    echo "Creating network partition..."
    echo "Isolating nodes 1-3 from nodes 4-6..."
    
    # Block communication between the two groups
    # Group 1: redis-node-1, redis-node-2, redis-node-3
    # Group 2: redis-node-4, redis-node-5, redis-node-6
    
    for i in 1 2 3; do
        for j in 4 5 6; do
            # Block traffic from node i to node j
            docker exec redis-node-$i iptables -A OUTPUT -d redis-node-$j -j DROP 2>/dev/null || true
            docker exec redis-node-$i iptables -A INPUT -s redis-node-$j -j DROP 2>/dev/null || true
        done
    done
    
    for i in 4 5 6; do
        for j in 1 2 3; do
            # Block traffic from node i to node j
            docker exec redis-node-$i iptables -A OUTPUT -d redis-node-$j -j DROP 2>/dev/null || true
            docker exec redis-node-$i iptables -A INPUT -s redis-node-$j -j DROP 2>/dev/null || true
        done
    done
    
    echo "✓ Network partition created"
    echo ""
    echo "Partition details:"
    echo "  Group 1 (can communicate): nodes 1, 2, 3"
    echo "  Group 2 (can communicate): nodes 4, 5, 6"
    echo "  Groups CANNOT communicate with each other"
}

# Function to heal partition
heal_partition() {
    echo ""
    echo "Healing network partition..."
    
    # Clear all iptables rules
    for i in 1 2 3 4 5 6; do
        docker exec redis-node-$i iptables -F 2>/dev/null || true
    done
    
    echo "✓ Network partition healed"
    echo "All nodes can now communicate"
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