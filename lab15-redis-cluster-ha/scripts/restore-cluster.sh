#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <backup_path>"
    echo "Example: $0 backups/cluster_backup_20231201_143022"
    echo ""
    echo "Available backups:"
    ls -la backups/ 2>/dev/null | grep cluster_backup || echo "No backups found"
    exit 1
fi

BACKUP_PATH="$1"

echo "========================================"
echo "Redis Cluster Restore"
echo "========================================"
echo ""

if [ ! -d "$BACKUP_PATH" ]; then
    echo "Error: Backup path '$BACKUP_PATH' does not exist"
    exit 1
fi

echo "Restoring from backup: $BACKUP_PATH"
echo ""

# Check backup contents
if [ ! -f "$BACKUP_PATH/backup-metadata.json" ]; then
    echo "Warning: No metadata file found. This may be an incomplete backup."
fi

if [ ! -f "$BACKUP_PATH/cluster-nodes.txt" ]; then
    echo "Error: cluster-nodes.txt not found in backup"
    exit 1
fi

echo "Step 1: Stopping current cluster..."

# Stop current cluster
docker-compose down 2>/dev/null || echo "No running cluster found"

echo "✓ Current cluster stopped"

echo ""
echo "Step 2: Restoring configuration files..."

# Restore config files if they exist in backup
if [ -d "$BACKUP_PATH/config" ]; then
    echo "Restoring config directory..."
    cp -r "$BACKUP_PATH/config" . 2>/dev/null || true
    echo "✓ Config directory restored"
else
    echo "No config directory in backup"
fi

# Restore docker-compose.yml if it exists
if [ -f "$BACKUP_PATH/docker-compose.yml" ]; then
    echo "Restoring docker-compose.yml..."
    cp "$BACKUP_PATH/docker-compose.yml" . 2>/dev/null || true
    echo "✓ docker-compose.yml restored"
else
    echo "No docker-compose.yml in backup"
fi

echo ""
echo "Step 3: Starting cluster with restored configuration..."

# Start the cluster
docker-compose up -d

if [ $? -ne 0 ]; then
    echo "✗ Failed to start cluster with restored configuration"
    exit 1
fi

echo "✓ Cluster containers started"

echo ""
echo "Step 4: Waiting for nodes to be ready..."

# Wait for nodes to be ready
sleep 10

# Check if nodes are responding
NODES_READY=0
for port in 9000 9001 9002 9003 9004 9005; do
    if docker exec redis-node-1 redis-cli -p $port ping &> /dev/null; then
        NODES_READY=$((NODES_READY + 1))
    fi
done

echo "✓ $NODES_READY/6 nodes are responding"

if [ $NODES_READY -lt 3 ]; then
    echo "✗ Not enough nodes are ready. Manual intervention required."
    exit 1
fi

echo ""
echo "Step 5: Analyzing backup cluster topology..."

# Display backed up cluster information
echo "Backed up cluster information:"
if [ -f "$BACKUP_PATH/cluster-info.txt" ]; then
    cat "$BACKUP_PATH/cluster-info.txt" | grep -E "(cluster_state|cluster_known_nodes|cluster_slots_assigned)"
else
    echo "No cluster info available in backup"
fi

echo ""
echo "Backed up node topology:"
if [ -f "$BACKUP_PATH/cluster-nodes.txt" ]; then
    cat "$BACKUP_PATH/cluster-nodes.txt" | head -10
else
    echo "No cluster nodes info available in backup"
fi

echo ""
echo "Step 6: Current cluster status..."

# Check current cluster status
echo "Current cluster status:"
docker exec redis-node-1 redis-cli -p 9000 cluster info | grep -E "(cluster_state|cluster_known_nodes|cluster_slots_assigned)" 2>/dev/null || echo "Cluster not yet initialized"

echo ""
echo "Current nodes:"
docker exec redis-node-1 redis-cli -p 9000 cluster nodes 2>/dev/null || echo "Cluster nodes not available"

echo ""
echo "Step 7: Restore options..."

echo "⚠ Important: This script has restored configuration files only."
echo ""
echo "To complete the restoration, you have several options:"
echo ""
echo "1. Re-initialize cluster (will lose existing data):"
echo "   ./scripts/setup-cluster.sh"
echo ""
echo "2. Manually recreate cluster topology based on backup:"
echo "   # Review backup files and manually configure cluster"
echo ""
echo "3. If this was a configuration restore only:"
echo "   # Your cluster should now be running with restored config"
echo ""

if [ -f "$BACKUP_PATH/backup-metadata.json" ]; then
    echo "Backup metadata:"
    cat "$BACKUP_PATH/backup-metadata.json" 2>/dev/null || echo "Could not read metadata"
fi

echo ""
echo "========================================"
echo "Restore Process Complete"
echo "========================================"
echo ""
echo "Next steps:"
echo "1. Verify cluster status: docker exec redis-node-1 redis-cli -p 9000 cluster nodes"
echo "2. Check cluster health: docker exec redis-node-1 redis-cli -p 9000 cluster info"
echo "3. Test connectivity: npm run test-sharding"
echo ""
echo "Note: Data restoration from RDB files requires manual intervention"
echo "      and depends on your specific backup strategy."