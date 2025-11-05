#!/bin/bash

# Check if port is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <port>"
    echo "Example: $0 9006"
    exit 1
fi

NEW_PORT=$1
NEW_NODE_NUM=$((NEW_PORT - 8999))
EXISTING_NODE_PORT=9000

echo "========================================"
echo "Adding New Master Node"
echo "========================================"
echo ""
echo "Adding new master node on port $NEW_PORT..."

# Validate port range
if [ "$NEW_PORT" -lt 9006 ] || [ "$NEW_PORT" -gt 9010 ]; then
    echo "Error: Port should be in range 9006-9010 for new nodes"
    exit 1
fi

# Check if port is already in use
if lsof -i :$NEW_PORT > /dev/null 2>&1; then
    echo "Error: Port $NEW_PORT is already in use"
    exit 1
fi

echo "Step 1: Creating Redis configuration for new node..."

# Create config directory if it doesn't exist
mkdir -p config

# Create configuration file for new node
cat > config/redis-node-$NEW_NODE_NUM.conf << EOF
port $NEW_PORT
bind 0.0.0.0
protected-mode no
cluster-enabled yes
cluster-config-file nodes-$NEW_PORT.conf
cluster-node-timeout 5000
appendonly yes
appendfilename "appendonly-$NEW_PORT.aof"
dbfilename dump-$NEW_PORT.rdb
dir /data
loglevel notice
logfile "/data/redis-$NEW_PORT.log"

# Performance tuning
maxmemory 800mb
maxmemory-policy allkeys-lru

# Cluster specific settings
cluster-replica-validity-factor 10
cluster-migration-barrier 1
cluster-require-full-coverage no
cluster-allow-reads-when-down no
EOF

echo "✓ Configuration created: config/redis-node-$NEW_NODE_NUM.conf"

echo ""
echo "Step 2: Starting new Redis container..."

# Start new Redis container
docker run -d \
    --name redis-node-$NEW_NODE_NUM \
    --network lab15-redis-cluster-ha_redis-cluster-net \
    -p $NEW_PORT:$NEW_PORT \
    -v "$(pwd)/config/redis-node-$NEW_NODE_NUM.conf:/usr/local/etc/redis/redis.conf" \
    -v "redis-node-$NEW_NODE_NUM-data:/data" \
    --memory=1g \
    redis:7-alpine redis-server /usr/local/etc/redis/redis.conf

if [ $? -eq 0 ]; then
    echo "✓ Container redis-node-$NEW_NODE_NUM started successfully"
else
    echo "✗ Failed to start container"
    exit 1
fi

echo ""
echo "Step 3: Waiting for Redis node to be ready..."
sleep 5

# Wait for the new node to be ready
for i in {1..30}; do
    if docker exec redis-node-$NEW_NODE_NUM redis-cli -p $NEW_PORT ping > /dev/null 2>&1; then
        echo "✓ New Redis node is responding"
        break
    fi
    
    if [ $i -eq 30 ]; then
        echo "✗ Timeout: New Redis node is not responding"
        exit 1
    fi
    
    echo "  Waiting for node to be ready... ($i/30)"
    sleep 2
done

echo ""
echo "Step 4: Adding node to existing cluster..."

# Add the new node to the cluster as a master
docker exec redis-node-1 redis-cli --cluster add-node \
    127.0.0.1:$NEW_PORT \
    127.0.0.1:$EXISTING_NODE_PORT

if [ $? -eq 0 ]; then
    echo "✓ Node added to cluster successfully"
else
    echo "✗ Failed to add node to cluster"
    exit 1
fi

echo ""
echo "Step 5: Checking cluster status..."
sleep 3

# Display cluster nodes
echo "Current cluster nodes:"
docker exec redis-node-1 redis-cli -p $EXISTING_NODE_PORT cluster nodes

echo ""
echo "Step 6: Cluster info:"
docker exec redis-node-1 redis-cli -p $EXISTING_NODE_PORT cluster info

echo ""
echo "========================================"
echo "Master Node Addition Complete"
echo "========================================"
echo ""
echo "✓ New master node added on port $NEW_PORT"
echo ""
echo "Next steps:"
echo "1. Rebalance slots across all masters:"
echo "   ./scripts/rebalance-cluster.sh"
echo ""
echo "2. Add a replica for the new master:"
echo "   ./scripts/add-replica-node.sh <replica_port> $NEW_PORT"
echo ""
echo "3. Verify cluster health:"
echo "   docker exec redis-node-1 redis-cli -p $EXISTING_NODE_PORT cluster nodes"