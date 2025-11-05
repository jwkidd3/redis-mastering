#!/bin/bash

# Default values
NEW_REDIS_VERSION=${1:-"redis:7-alpine"}
UPGRADE_DELAY=${2:-30}

echo "========================================"
echo "Redis Cluster Rolling Upgrade"
echo "========================================"
echo ""

echo "Configuration:"
echo "  Target Redis version: $NEW_REDIS_VERSION"
echo "  Delay between upgrades: ${UPGRADE_DELAY}s"
echo ""

# Validate cluster is healthy before upgrade
echo "Step 1: Pre-upgrade health check..."

if ! docker exec redis-node-1 redis-cli -p 9000 ping &> /dev/null; then
    echo "✗ Cluster is not responding"
    exit 1
fi

CLUSTER_STATE=$(docker exec redis-node-1 redis-cli -p 9000 cluster info | grep cluster_state | cut -d: -f2 | tr -d '\r')
if [ "$CLUSTER_STATE" != "ok" ]; then
    echo "✗ Cluster state is '$CLUSTER_STATE', not 'ok'"
    echo "Please fix cluster issues before upgrading"
    exit 1
fi

echo "✓ Cluster is healthy and ready for upgrade"

# Get current cluster topology
echo ""
echo "Current cluster topology:"
docker exec redis-node-1 redis-cli -p 9000 cluster nodes

# Upgrade replicas first (safer)
echo ""
echo "Step 2: Upgrading replica nodes first..."

REPLICA_NODES=(redis-node-4 redis-node-5 redis-node-6)
REPLICA_PORTS=(9003 9004 9005)

for i in "${!REPLICA_NODES[@]}"; do
    NODE=${REPLICA_NODES[$i]}
    PORT=${REPLICA_PORTS[$i]}
    
    echo ""
    echo "Upgrading replica: $NODE (port $PORT)..."
    
    # Stop the replica
    echo "  Stopping $NODE..."
    docker stop $NODE
    
    # Remove old container
    echo "  Removing old container..."
    docker rm $NODE
    
    # Start new container with updated version
    echo "  Starting with $NEW_REDIS_VERSION..."
    docker run -d \
        --name $NODE \
        --network lab15-redis-cluster-ha_redis-cluster-net \
        -p $PORT:$PORT \
        -v "$(pwd)/config/redis-node-$((PORT - 8999)).conf:/usr/local/etc/redis/redis.conf" \
        -v "redis-node-$((PORT - 8999))-data:/data" \
        --memory=1g \
        $NEW_REDIS_VERSION redis-server /usr/local/etc/redis/redis.conf
    
    if [ $? -eq 0 ]; then
        echo "  ✓ $NODE upgraded successfully"
    else
        echo "  ✗ Failed to upgrade $NODE"
        exit 1
    fi
    
    # Wait for node to be ready
    echo "  Waiting for $NODE to be ready..."
    for attempt in {1..30}; do
        if docker exec $NODE redis-cli -p $PORT ping &> /dev/null; then
            echo "  ✓ $NODE is responding"
            break
        fi
        
        if [ $attempt -eq 30 ]; then
            echo "  ✗ $NODE failed to start properly"
            exit 1
        fi
        
        sleep 2
    done
    
    # Check if replica rejoined cluster
    echo "  Verifying cluster membership..."
    sleep 5
    
    NODE_IN_CLUSTER=$(docker exec redis-node-1 redis-cli -p 9000 cluster nodes | grep ":$PORT@" | wc -l)
    if [ "$NODE_IN_CLUSTER" -eq 1 ]; then
        echo "  ✓ $NODE rejoined cluster successfully"
    else
        echo "  ⚠ $NODE may need manual cluster rejoin"
    fi
    
    if [ $i -lt $((${#REPLICA_NODES[@]} - 1)) ]; then
        echo "  Waiting ${UPGRADE_DELAY}s before next replica..."
        sleep $UPGRADE_DELAY
    fi
done

echo ""
echo "Step 3: Upgrading master nodes..."

MASTER_NODES=(redis-node-1 redis-node-2 redis-node-3)
MASTER_PORTS=(9000 9001 9002)

for i in "${!MASTER_NODES[@]}"; do
    NODE=${MASTER_NODES[$i]}
    PORT=${MASTER_PORTS[$i]}
    
    echo ""
    echo "Upgrading master: $NODE (port $PORT)..."
    
    # Get replicas of this master
    echo "  Checking replicas for master $NODE..."
    REPLICA_COUNT=$(docker exec redis-node-1 redis-cli -p $PORT info replication | grep connected_slaves | cut -d: -f2 | tr -d '\r')
    echo "  Master has $REPLICA_COUNT connected replicas"
    
    if [ "$REPLICA_COUNT" -eq 0 ]; then
        echo "  ⚠ Warning: Master has no replicas. Upgrade will cause brief downtime."
        read -p "  Continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "  Upgrade cancelled for $NODE"
            continue
        fi
    fi
    
    # Stop the master
    echo "  Stopping master $NODE..."
    docker stop $NODE
    
    # Remove old container
    echo "  Removing old container..."
    docker rm $NODE
    
    # Start new container with updated version
    echo "  Starting with $NEW_REDIS_VERSION..."
    docker run -d \
        --name $NODE \
        --network lab15-redis-cluster-ha_redis-cluster-net \
        -p $PORT:$PORT \
        -v "$(pwd)/config/redis-node-$((PORT - 8999)).conf:/usr/local/etc/redis/redis.conf" \
        -v "redis-node-$((PORT - 8999))-data:/data" \
        --memory=1g \
        $NEW_REDIS_VERSION redis-server /usr/local/etc/redis/redis.conf
    
    if [ $? -eq 0 ]; then
        echo "  ✓ $NODE upgraded successfully"
    else
        echo "  ✗ Failed to upgrade $NODE"
        exit 1
    fi
    
    # Wait for node to be ready
    echo "  Waiting for $NODE to be ready..."
    for attempt in {1..30}; do
        if docker exec $NODE redis-cli -p $PORT ping &> /dev/null; then
            echo "  ✓ $NODE is responding"
            break
        fi
        
        if [ $attempt -eq 30 ]; then
            echo "  ✗ $NODE failed to start properly"
            exit 1
        fi
        
        sleep 2
    done
    
    # Check cluster health after master upgrade
    echo "  Checking cluster health..."
    sleep 10
    
    CLUSTER_STATE=$(docker exec $NODE redis-cli -p $PORT cluster info | grep cluster_state | cut -d: -f2 | tr -d '\r' 2>/dev/null)
    if [ "$CLUSTER_STATE" = "ok" ]; then
        echo "  ✓ Cluster state is healthy after master upgrade"
    else
        echo "  ⚠ Cluster state: $CLUSTER_STATE (may need time to stabilize)"
    fi
    
    if [ $i -lt $((${#MASTER_NODES[@]} - 1)) ]; then
        echo "  Waiting ${UPGRADE_DELAY}s before next master..."
        sleep $UPGRADE_DELAY
    fi
done

echo ""
echo "Step 4: Post-upgrade verification..."

# Wait for cluster to stabilize
echo "Waiting for cluster to stabilize..."
sleep 15

# Check overall cluster health
echo "Final cluster health check:"
CLUSTER_STATE=$(docker exec redis-node-1 redis-cli -p 9000 cluster info | grep cluster_state | cut -d: -f2 | tr -d '\r')
SLOTS_OK=$(docker exec redis-node-1 redis-cli -p 9000 cluster info | grep cluster_slots_ok | cut -d: -f2 | tr -d '\r')

echo "  Cluster state: $CLUSTER_STATE"
echo "  Slots OK: $SLOTS_OK"

if [ "$CLUSTER_STATE" = "ok" ] && [ "$SLOTS_OK" = "16384" ]; then
    echo "  ✓ Cluster is fully healthy after upgrade"
else
    echo "  ⚠ Cluster may need additional time to stabilize"
fi

# Show final topology
echo ""
echo "Final cluster topology:"
docker exec redis-node-1 redis-cli -p 9000 cluster nodes

# Test basic functionality
echo ""
echo "Testing basic functionality..."
if docker exec redis-node-1 redis-cli -p 9000 set "upgrade:test" "success" > /dev/null 2>&1; then
    VALUE=$(docker exec redis-node-1 redis-cli -p 9000 get "upgrade:test")
    if [ "$VALUE" = "success" ]; then
        echo "✓ Basic read/write operations working"
        docker exec redis-node-1 redis-cli -p 9000 del "upgrade:test" > /dev/null 2>&1
    else
        echo "⚠ Read operation returned unexpected value: $VALUE"
    fi
else
    echo "⚠ Write operation failed"
fi

echo ""
echo "========================================"
echo "Rolling Upgrade Complete"
echo "========================================"
echo ""
echo "Summary:"
echo "  Target version: $NEW_REDIS_VERSION"
echo "  Upgraded nodes: 6/6"
echo "  Final cluster state: $CLUSTER_STATE"
echo ""
echo "Verification commands:"
echo "  docker exec redis-node-1 redis-cli -p 9000 cluster info"
echo "  docker exec redis-node-1 redis-cli -p 9000 cluster nodes"
echo "  npm run test-sharding"
echo ""
echo "If cluster is not stable, try:"
echo "  ./scripts/setup-cluster.sh  # Re-initialize if needed"