#!/bin/bash
#
# Lab 15: Redis Cluster Setup Script
# Sets up a 6-node Redis cluster (3 masters + 3 replicas)
#

echo "=== Redis Cluster Setup ==="
echo ""

# Check if docker-compose is running
if ! docker-compose ps | grep -q "redis"; then
    echo "Starting Redis cluster with docker-compose..."
    docker-compose up -d
    sleep 5
fi

echo "Waiting for Redis nodes to be ready..."
sleep 10

# Create the cluster
echo "Creating Redis cluster..."
docker exec redis-node-1 redis-cli --cluster create \
    redis-node-1:7000 \
    redis-node-2:7001 \
    redis-node-3:7002 \
    redis-node-4:7003 \
    redis-node-5:7004 \
    redis-node-6:7005 \
    --cluster-replicas 1 \
    --cluster-yes

echo ""
echo "=== Cluster Setup Complete ==="
echo ""
echo "Cluster nodes:"
docker exec redis-node-1 redis-cli -p 7000 CLUSTER NODES

echo ""
echo "Cluster info:"
docker exec redis-node-1 redis-cli -p 7000 CLUSTER INFO

echo ""
echo "To connect to the cluster:"
echo "  redis-cli -c -p 7000"
