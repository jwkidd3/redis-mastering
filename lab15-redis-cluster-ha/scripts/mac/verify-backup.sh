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
echo "Redis Cluster Backup Verification"
echo "========================================"
echo ""

if [ ! -d "$BACKUP_PATH" ]; then
    echo "✗ Error: Backup path '$BACKUP_PATH' does not exist"
    exit 1
fi

echo "Verifying backup: $BACKUP_PATH"
echo ""

VERIFICATION_PASSED=true

echo "Step 1: Checking backup structure..."

# Required files check
REQUIRED_FILES=(
    "cluster-nodes.txt"
    "cluster-info.txt"
)

echo "Required files:"
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$BACKUP_PATH/$file" ]; then
        echo "  ✓ $file"
    else
        echo "  ✗ $file (missing)"
        VERIFICATION_PASSED=false
    fi
done

# Optional files check
OPTIONAL_FILES=(
    "backup-metadata.json"
    "docker-compose.yml"
    "config/"
)

echo ""
echo "Optional files:"
for file in "${OPTIONAL_FILES[@]}"; do
    if [ -e "$BACKUP_PATH/$file" ]; then
        echo "  ✓ $file"
    else
        echo "  - $file (not present)"
    fi
done

echo ""
echo "Step 2: Analyzing backup content..."

# Check backup size
BACKUP_SIZE=$(du -sh "$BACKUP_PATH" | cut -f1)
FILE_COUNT=$(find "$BACKUP_PATH" -type f | wc -l | tr -d ' ')

echo "Backup statistics:"
echo "  Size: $BACKUP_SIZE"
echo "  Files: $FILE_COUNT"

# Check metadata if available
if [ -f "$BACKUP_PATH/backup-metadata.json" ]; then
    echo ""
    echo "Step 3: Validating metadata..."
    
    # Try to parse JSON (basic validation)
    if command -v python3 &> /dev/null; then
        if python3 -m json.tool "$BACKUP_PATH/backup-metadata.json" > /dev/null 2>&1; then
            echo "  ✓ Metadata is valid JSON"
            
            # Extract backup timestamp
            BACKUP_TIMESTAMP=$(python3 -c "import json; data=json.load(open('$BACKUP_PATH/backup-metadata.json')); print(data.get('backup_timestamp', 'Unknown'))" 2>/dev/null)
            echo "  ✓ Backup timestamp: $BACKUP_TIMESTAMP"
        else
            echo "  ✗ Metadata JSON is invalid"
            VERIFICATION_PASSED=false
        fi
    else
        echo "  - Cannot validate JSON (python3 not available)"
    fi
else
    echo ""
    echo "Step 3: No metadata file to validate"
fi

echo ""
echo "Step 4: Analyzing cluster information..."

if [ -f "$BACKUP_PATH/cluster-info.txt" ]; then
    echo "Cluster state information:"
    
    CLUSTER_STATE=$(grep cluster_state "$BACKUP_PATH/cluster-info.txt" | cut -d: -f2 | tr -d '\r' || echo "unknown")
    KNOWN_NODES=$(grep cluster_known_nodes "$BACKUP_PATH/cluster-info.txt" | cut -d: -f2 | tr -d '\r' || echo "0")
    SLOTS_ASSIGNED=$(grep cluster_slots_assigned "$BACKUP_PATH/cluster-info.txt" | cut -d: -f2 | tr -d '\r' || echo "0")
    
    echo "  State: $CLUSTER_STATE"
    echo "  Known nodes: $KNOWN_NODES"
    echo "  Slots assigned: $SLOTS_ASSIGNED"
    
    if [ "$CLUSTER_STATE" = "ok" ]; then
        echo "  ✓ Cluster was in healthy state"
    else
        echo "  ⚠ Cluster was in '$CLUSTER_STATE' state"
    fi
    
    if [ "$SLOTS_ASSIGNED" = "16384" ]; then
        echo "  ✓ All slots were assigned"
    else
        echo "  ⚠ Only $SLOTS_ASSIGNED/16384 slots were assigned"
    fi
else
    echo "  ✗ No cluster info file found"
    VERIFICATION_PASSED=false
fi

echo ""
echo "Step 5: Analyzing node configuration..."

if [ -f "$BACKUP_PATH/cluster-nodes.txt" ]; then
    TOTAL_NODES=$(cat "$BACKUP_PATH/cluster-nodes.txt" | wc -l | tr -d ' ')
    MASTER_NODES=$(grep master "$BACKUP_PATH/cluster-nodes.txt" | wc -l | tr -d ' ')
    SLAVE_NODES=$(grep slave "$BACKUP_PATH/cluster-nodes.txt" | wc -l | tr -d ' ')
    FAILED_NODES=$(grep fail "$BACKUP_PATH/cluster-nodes.txt" | wc -l | tr -d ' ')
    
    echo "Node distribution:"
    echo "  Total nodes: $TOTAL_NODES"
    echo "  Master nodes: $MASTER_NODES"
    echo "  Slave nodes: $SLAVE_NODES"
    echo "  Failed nodes: $FAILED_NODES"
    
    if [ "$MASTER_NODES" -ge 3 ]; then
        echo "  ✓ Sufficient master nodes for HA"
    else
        echo "  ⚠ Only $MASTER_NODES master nodes (recommended: 3+)"
    fi
    
    if [ "$FAILED_NODES" -eq 0 ]; then
        echo "  ✓ No failed nodes"
    else
        echo "  ⚠ $FAILED_NODES failed nodes detected"
    fi
    
    echo ""
    echo "Node details:"
    cat "$BACKUP_PATH/cluster-nodes.txt" | while read line; do
        if [ -n "$line" ]; then
            NODE_ID=$(echo "$line" | awk '{print $1}' | cut -c1-8)
            ADDRESS=$(echo "$line" | awk '{print $2}')
            FLAGS=$(echo "$line" | awk '{print $3}')
            echo "  $NODE_ID... $ADDRESS $FLAGS"
        fi
    done
else
    echo "  ✗ No cluster nodes file found"
    VERIFICATION_PASSED=false
fi

echo ""
echo "Step 6: Checking individual node backups..."

NODE_BACKUP_COUNT=0
for port in 9000 9001 9002 9003 9004 9005; do
    if [ -f "$BACKUP_PATH/node-$port-info.txt" ]; then
        NODE_BACKUP_COUNT=$((NODE_BACKUP_COUNT + 1))
    fi
done

echo "Node-specific backups: $NODE_BACKUP_COUNT/6 nodes"

if [ $NODE_BACKUP_COUNT -ge 3 ]; then
    echo "  ✓ Sufficient node backups"
else
    echo "  ⚠ Limited node backup coverage"
fi

echo ""
echo "Step 7: Configuration file verification..."

if [ -d "$BACKUP_PATH/config" ]; then
    CONFIG_FILES=$(find "$BACKUP_PATH/config" -name "*.conf" | wc -l | tr -d ' ')
    echo "Configuration files: $CONFIG_FILES"
    
    if [ $CONFIG_FILES -ge 6 ]; then
        echo "  ✓ Complete configuration backup"
    else
        echo "  ⚠ Incomplete configuration backup"
    fi
    
    echo "  Configuration files:"
    find "$BACKUP_PATH/config" -name "*.conf" | while read file; do
        echo "    $(basename "$file")"
    done
else
    echo "  - No configuration directory in backup"
fi

if [ -f "$BACKUP_PATH/docker-compose.yml" ]; then
    echo "  ✓ Docker Compose configuration included"
else
    echo "  - No Docker Compose configuration"
fi

echo ""
echo "Step 8: Backup integrity summary..."

if [ "$VERIFICATION_PASSED" = true ]; then
    echo "✅ Backup verification PASSED"
    echo ""
    echo "This backup appears to be complete and valid for restoration."
    echo ""
    echo "Backup contains:"
    echo "  - Cluster topology and configuration"
    echo "  - Node information and status"
    echo "  - Configuration files (if applicable)"
    echo "  - Metadata for verification"
else
    echo "❌ Backup verification FAILED"
    echo ""
    echo "This backup has issues and may not restore properly."
    echo "Please check the missing files and consider creating a new backup."
fi

echo ""
echo "========================================"
echo "Verification Complete"
echo "========================================"
echo ""

if [ "$VERIFICATION_PASSED" = true ]; then
    echo "To restore this backup:"
    echo "  ./scripts/restore-cluster.sh $BACKUP_PATH"
    echo ""
    echo "To create a new backup:"
    echo "  ./scripts/backup-cluster.sh"
else
    echo "Recommendation: Create a new backup when cluster is healthy"
    echo "  ./scripts/backup-cluster.sh"
fi