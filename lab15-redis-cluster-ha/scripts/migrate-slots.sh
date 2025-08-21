#!/bin/bash

# Check if parameters are provided
if [ $# -ne 3 ]; then
    echo "Usage: $0 <source_port> <target_port> <slots>"
    echo "Example: $0 9000 9001 100"
    echo ""
    echo "This will migrate <slots> number of slots from source node to target node"
    exit 1
fi

SOURCE_PORT=$1
TARGET_PORT=$2
SLOTS_TO_MIGRATE=$3
EXISTING_NODE_PORT=9000

echo "========================================"
echo "Redis Cluster Slot Migration"
echo "========================================"
echo ""
echo "Migrating $SLOTS_TO_MIGRATE slots from port $SOURCE_PORT to port $TARGET_PORT..."

# Validate ports
if [ "$SOURCE_PORT" = "$TARGET_PORT" ]; then
    echo "Error: Source and target ports cannot be the same"
    exit 1
fi

# Check if nodes exist in cluster
echo "Step 1: Verifying nodes exist in cluster..."

SOURCE_NODE_INFO=$(docker exec redis-node-1 redis-cli -p $EXISTING_NODE_PORT cluster nodes 2>/dev/null | grep ":$SOURCE_PORT@")
if [ -z "$SOURCE_NODE_INFO" ]; then
    echo "Error: Source node on port $SOURCE_PORT not found in cluster"
    exit 1
fi

TARGET_NODE_INFO=$(docker exec redis-node-1 redis-cli -p $EXISTING_NODE_PORT cluster nodes 2>/dev/null | grep ":$TARGET_PORT@")
if [ -z "$TARGET_NODE_INFO" ]; then
    echo "Error: Target node on port $TARGET_PORT not found in cluster"
    exit 1
fi

SOURCE_NODE_ID=$(echo "$SOURCE_NODE_INFO" | awk '{print $1}')
TARGET_NODE_ID=$(echo "$TARGET_NODE_INFO" | awk '{print $1}')

echo "✓ Source node: $SOURCE_NODE_ID on port $SOURCE_PORT"
echo "✓ Target node: $TARGET_NODE_ID on port $TARGET_PORT"

# Verify both are masters
SOURCE_ROLE=$(echo "$SOURCE_NODE_INFO" | awk '{print $3}')
TARGET_ROLE=$(echo "$TARGET_NODE_INFO" | awk '{print $3}')

if ! echo "$SOURCE_ROLE" | grep -q "master"; then
    echo "Error: Source node is not a master"
    exit 1
fi

if ! echo "$TARGET_ROLE" | grep -q "master"; then
    echo "Error: Target node is not a master"
    exit 1
fi

echo ""
echo "Step 2: Checking source node slots..."

# Get source node slots
SOURCE_SLOTS=$(echo "$SOURCE_NODE_INFO" | cut -d' ' -f9-)
if [ "$SOURCE_SLOTS" = "-" ] || [ -z "$SOURCE_SLOTS" ]; then
    echo "Error: Source node has no slots to migrate"
    exit 1
fi

# Count available slots
AVAILABLE_SLOTS=$(echo "$SOURCE_SLOTS" | tr ',' '\n' | wc -l | tr -d ' ')
echo "Source node has slots available for migration"

if [ "$SLOTS_TO_MIGRATE" -gt "$AVAILABLE_SLOTS" ]; then
    echo "Warning: Requested $SLOTS_TO_MIGRATE slots, but only $AVAILABLE_SLOTS available"
    echo "Will migrate all available slots"
    SLOTS_TO_MIGRATE=$AVAILABLE_SLOTS
fi

echo ""
echo "Step 3: Performing slot migration..."

# Use redis-cli reshard to migrate slots
docker exec redis-node-1 redis-cli --cluster reshard 127.0.0.1:$EXISTING_NODE_PORT \
    --cluster-from $SOURCE_NODE_ID \
    --cluster-to $TARGET_NODE_ID \
    --cluster-slots $SLOTS_TO_MIGRATE \
    --cluster-yes

if [ $? -eq 0 ]; then
    echo "✓ Slot migration completed successfully"
else
    echo "✗ Slot migration failed"
    echo ""
    echo "Manual migration steps:"
    echo "1. Run: docker exec -it redis-node-1 redis-cli --cluster reshard 127.0.0.1:$EXISTING_NODE_PORT"
    echo "2. Choose source node: $SOURCE_NODE_ID"
    echo "3. Choose target node: $TARGET_NODE_ID"
    echo "4. Specify slots to migrate: $SLOTS_TO_MIGRATE"
    exit 1
fi

echo ""
echo "Step 4: Verifying migration..."
sleep 5

# Check new slot distribution
echo ""
echo "Updated slot distribution:"
docker exec redis-node-1 redis-cli -p $EXISTING_NODE_PORT cluster nodes | grep master | awk '{print $2 " " $9}'

echo ""
echo "Cluster health:"
docker exec redis-node-1 redis-cli -p $EXISTING_NODE_PORT cluster info | grep -E "(cluster_state|cluster_slots_assigned|cluster_slots_ok)"

echo ""
echo "========================================"
echo "Slot Migration Complete"
echo "========================================"
echo ""
echo "✓ Migrated $SLOTS_TO_MIGRATE slots successfully"
echo "✓ From node: $SOURCE_NODE_ID (port $SOURCE_PORT)"
echo "✓ To node: $TARGET_NODE_ID (port $TARGET_PORT)"
echo ""
echo "Verification commands:"
echo "1. Check slot distribution:"
echo "   ./scripts/show-slot-distribution.sh"
echo ""
echo "2. Test cluster functionality:"
echo "   npm run test-sharding"