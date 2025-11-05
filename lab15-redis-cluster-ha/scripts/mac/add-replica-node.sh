#!/bin/bash

# Check if ports are provided
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 <replica_port> <master_port>"
    echo "Example: $0 9007 9006"
    echo ""
    echo "This will create a new replica node on <replica_port> that replicates the master on <master_port>"
    exit 1
fi

REPLICA_PORT=$1
MASTER_PORT=$2
REPLICA_NODE_NUM=$((REPLICA_PORT - 8999))
EXISTING_NODE_PORT=9000

echo "========================================"
echo "Adding New Replica Node"
echo "========================================"
echo ""
echo "Adding new replica node on port $REPLICA_PORT for master on port $MASTER_PORT..."

# Validate port range
if [ "$REPLICA_PORT" -lt 9006 ] || [ "$REPLICA_PORT" -gt 9010 ]; then
    echo "Error: Replica port should be in range 9006-9010 for new nodes"
    exit 1
fi

# Check if port is already in use
if lsof -i :$REPLICA_PORT > /dev/null 2>&1; then
    echo "Error: Port $REPLICA_PORT is already in use"
    exit 1
fi

# Check if master port exists in cluster
echo "Verifying master node exists..."
MASTER_EXISTS=$(docker exec redis-node-1 redis-cli -p $EXISTING_NODE_PORT cluster nodes 2>/dev/null | grep ":$MASTER_PORT@" | grep master)
if [ -z "$MASTER_EXISTS" ]; then
    echo "Error: Master node on port $MASTER_PORT not found in cluster"
    echo "Available master nodes:"
    docker exec redis-node-1 redis-cli -p $EXISTING_NODE_PORT cluster nodes 2>/dev/null | grep master | awk '{print $2}' | cut -d: -f2 | cut -d@ -f1
    exit 1
fi

# Get master node ID
MASTER_NODE_ID=$(echo "$MASTER_EXISTS" | awk '{print $1}')
echo "✓ Found master node: $MASTER_NODE_ID on port $MASTER_PORT"

echo ""
echo "Step 1: Creating Redis configuration for new replica..."

# Create config directory if it doesn't exist
mkdir -p config

# Create configuration file for new replica
cat > config/redis-node-$REPLICA_NODE_NUM.conf << EOF
port $REPLICA_PORT
bind 0.0.0.0
protected-mode no
cluster-enabled yes
cluster-config-file nodes-$REPLICA_PORT.conf
cluster-node-timeout 5000
appendonly yes
appendfilename "appendonly-$REPLICA_PORT.aof"
dbfilename dump-$REPLICA_PORT.rdb
dir /data
loglevel notice
logfile "/data/redis-$REPLICA_PORT.log"

# Performance tuning
maxmemory 800mb
maxmemory-policy allkeys-lru

# Cluster specific settings
cluster-replica-validity-factor 10
cluster-migration-barrier 1
cluster-require-full-coverage no
cluster-allow-reads-when-down no
EOF

echo "✓ Configuration created: config/redis-node-$REPLICA_NODE_NUM.conf"

echo ""
echo "Step 2: Starting new Redis container..."

# Start new Redis container
docker run -d \
    --name redis-node-$REPLICA_NODE_NUM \
    --network lab15-redis-cluster-ha_redis-cluster-net \
    -p $REPLICA_PORT:$REPLICA_PORT \
    -v "$(pwd)/config/redis-node-$REPLICA_NODE_NUM.conf:/usr/local/etc/redis/redis.conf" \
    -v "redis-node-$REPLICA_NODE_NUM-data:/data" \
    --memory=1g \
    redis:7-alpine redis-server /usr/local/etc/redis/redis.conf

if [ $? -eq 0 ]; then
    echo "✓ Container redis-node-$REPLICA_NODE_NUM started successfully"
else
    echo "✗ Failed to start container"
    exit 1
fi

echo ""
echo "Step 3: Waiting for Redis node to be ready..."
sleep 5

# Wait for the new node to be ready
for i in {1..30}; do
    if docker exec redis-node-$REPLICA_NODE_NUM redis-cli -p $REPLICA_PORT ping > /dev/null 2>&1; then
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
echo "Step 4: Adding replica node to cluster..."

# Add the new node to the cluster as a replica
docker exec redis-node-1 redis-cli --cluster add-node \
    127.0.0.1:$REPLICA_PORT \
    127.0.0.1:$EXISTING_NODE_PORT \
    --cluster-slave \
    --cluster-master-id $MASTER_NODE_ID

if [ $? -eq 0 ]; then
    echo "✓ Replica node added to cluster successfully"
else
    echo "✗ Failed to add replica node to cluster"
    exit 1
fi

echo ""
echo "Step 5: Verifying replica relationship..."
sleep 3

# Check if replica is properly connected
REPLICA_STATUS=$(docker exec redis-node-$REPLICA_NODE_NUM redis-cli -p $REPLICA_PORT info replication | grep role:slave)
if [ -n "$REPLICA_STATUS" ]; then
    echo "✓ Node is operating as a replica"
    
    # Show replication info
    echo ""
    echo "Replication details:"
    docker exec redis-node-$REPLICA_NODE_NUM redis-cli -p $REPLICA_PORT info replication | grep -E "(role|master_host|master_port|master_link_status)"
else
    echo "⚠ Warning: Node may not be properly configured as replica"
fi

echo ""
echo "Step 6: Current cluster status:"
docker exec redis-node-1 redis-cli -p $EXISTING_NODE_PORT cluster nodes | grep -E ":$MASTER_PORT@|:$REPLICA_PORT@"

echo ""
echo "========================================"
echo "Replica Node Addition Complete"
echo "========================================"
echo ""
echo "✓ New replica node added on port $REPLICA_PORT"
echo "✓ Replicating master on port $MASTER_PORT"
echo ""
echo "Verification commands:"
echo "1. Check cluster status:"
echo "   docker exec redis-node-1 redis-cli -p $EXISTING_NODE_PORT cluster nodes"
echo ""
echo "2. Monitor replication:"
echo "   npm run monitor-replication"
echo ""
echo "3. Test failover:"
echo "   ./scripts/simulate-node-failure.sh single-master"