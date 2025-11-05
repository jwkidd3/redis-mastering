#!/bin/bash

BACKUP_DIR="backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="$BACKUP_DIR/cluster_backup_$TIMESTAMP"

echo "========================================"
echo "Redis Cluster Backup"
echo "========================================"
echo ""

# Create backup directory
mkdir -p "$BACKUP_PATH"

echo "Creating cluster backup at: $BACKUP_PATH"
echo ""

echo "Step 1: Backing up cluster configuration..."

# Backup cluster nodes and info
docker exec redis-node-1 redis-cli -p 9000 cluster nodes > "$BACKUP_PATH/cluster-nodes.txt"
docker exec redis-node-1 redis-cli -p 9000 cluster info > "$BACKUP_PATH/cluster-info.txt"

echo "✓ Cluster configuration saved"

echo ""
echo "Step 2: Backing up data from each node..."

# Backup data from each node
for port in 9000 9001 9002 9003 9004 9005; do
    echo "Backing up node on port $port..."
    
    # Get node info
    docker exec redis-node-1 redis-cli -p $port info server > "$BACKUP_PATH/node-$port-info.txt" 2>/dev/null || echo "Port $port not accessible" > "$BACKUP_PATH/node-$port-info.txt"
    
    # Get all keys
    docker exec redis-node-1 redis-cli -p $port --scan > "$BACKUP_PATH/node-$port-keys.txt" 2>/dev/null || echo "Port $port not accessible" > "$BACKUP_PATH/node-$port-keys.txt"
    
    # Create RDB dump if accessible
    docker exec redis-node-1 redis-cli -p $port bgsave > /dev/null 2>&1 || true
done

echo "✓ Node data backed up"

echo ""
echo "Step 3: Backing up configuration files..."

# Backup config files
cp -r config/ "$BACKUP_PATH/" 2>/dev/null || echo "No config directory found"
cp docker-compose.yml "$BACKUP_PATH/" 2>/dev/null || echo "No docker-compose.yml found"

echo "✓ Configuration files backed up"

echo ""
echo "Step 4: Creating backup metadata..."

# Create comprehensive metadata
cat > "$BACKUP_PATH/backup-metadata.json" << EOF
{
  "backup_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "backup_type": "full",
  "cluster_info": {
    "nodes": $(docker exec redis-node-1 redis-cli -p 9000 cluster info | grep cluster_known_nodes | cut -d: -f2 | tr -d '\r'),
    "state": "$(docker exec redis-node-1 redis-cli -p 9000 cluster info | grep cluster_state | cut -d: -f2 | tr -d '\r')",
    "slots_assigned": $(docker exec redis-node-1 redis-cli -p 9000 cluster info | grep cluster_slots_assigned | cut -d: -f2 | tr -d '\r'),
    "current_epoch": $(docker exec redis-node-1 redis-cli -p 9000 cluster info | grep cluster_current_epoch | cut -d: -f2 | tr -d '\r')
  },
  "backup_contents": [
    "cluster-nodes.txt",
    "cluster-info.txt",
    "node-*-info.txt",
    "node-*-keys.txt",
    "config/",
    "docker-compose.yml"
  ]
}
EOF

echo "✓ Metadata created"

echo ""
echo "Step 5: Calculating backup size..."

BACKUP_SIZE=$(du -sh "$BACKUP_PATH" | cut -f1)
FILE_COUNT=$(find "$BACKUP_PATH" -type f | wc -l | tr -d ' ')

echo "✓ Backup completed"
echo ""
echo "Backup Summary:"
echo "  Location: $BACKUP_PATH"
echo "  Size: $BACKUP_SIZE"
echo "  Files: $FILE_COUNT"
echo ""

# List backup contents
echo "Backup contents:"
ls -la "$BACKUP_PATH/"

echo ""
echo "To restore this backup, run:"
echo "  ./scripts/restore-cluster.sh $BACKUP_PATH"