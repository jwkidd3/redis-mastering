#!/bin/bash

echo "========================================"
echo "Initializing Redis Cluster"
echo "========================================"

# Reset all nodes first if they have existing data or cluster config
echo "Resetting any existing cluster configuration..."
for i in 1 2 3 4 5 6; do
    port=$((8999 + i))
    docker exec redis-node-$i redis-cli -p $port FLUSHALL > /dev/null 2>&1
    docker exec redis-node-$i redis-cli -p $port CLUSTER RESET > /dev/null 2>&1
done
echo "✓ Cluster configuration reset"

# Wait for all Redis nodes to be ready
echo ""
echo "Waiting for Redis nodes to start..."
for port in 9000 9001 9002 9003 9004 9005; do
    while ! docker exec redis-node-$((port-8999)) redis-cli -p $port ping > /dev/null 2>&1; do
        echo "Waiting for Redis node on port $port..."
        sleep 2
    done
    echo "✓ Redis node on port $port is ready"
done

echo ""
echo "Creating Redis Cluster with 3 masters and 3 replicas..."
echo ""

# Create the cluster
# Using --cluster-replicas 1 means each master will have one replica
docker exec redis-node-1 redis-cli --cluster create \
    redis-node-1:9000 \
    redis-node-2:9001 \
    redis-node-3:9002 \
    redis-node-4:9003 \
    redis-node-5:9004 \
    redis-node-6:9005 \
    --cluster-replicas 1 \
    --cluster-yes

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Cluster created successfully!"
    echo ""
    
    # Display cluster info
    echo "Cluster Information:"
    echo "===================="
    docker exec redis-node-1 redis-cli -p 9000 cluster info
    
    echo ""
    echo "Cluster Nodes:"
    echo "=============="
    docker exec redis-node-1 redis-cli -p 9000 cluster nodes
    
    echo ""
    echo "Slot Distribution:"
    echo "=================="
    docker exec redis-node-1 redis-cli -p 9000 cluster slots
else
    echo "✗ Failed to create cluster"
    exit 1
fi

echo ""
echo "========================================"
echo "Redis Cluster initialization complete!"
echo "========================================"