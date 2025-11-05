#!/bin/bash

echo "========================================"
echo "Simulating Redis Node Failures"
echo "========================================"
echo ""
echo "This script simulates node failures for testing cluster resilience"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to show usage
show_usage() {
    echo "Usage: $0 [scenario]"
    echo ""
    echo "Available scenarios:"
    echo "  1 | single-master     - Stop one master node"
    echo "  2 | single-replica    - Stop one replica node"
    echo "  3 | master-replica    - Stop a master and its replica"
    echo "  4 | split-brain       - Stop nodes to create split-brain scenario"
    echo "  5 | cascade-failure   - Simulate cascade failure"
    echo "  restore               - Restore all stopped nodes"
    echo "  status                - Show current cluster status"
    echo ""
    echo "Example: $0 single-master"
    echo "         $0 restore"
}

# Function to check cluster status
check_cluster_status() {
    echo -e "${YELLOW}Cluster Status:${NC}"
    echo "=============="
    
    for i in {1..6}; do
        container="redis-node-$i"
        port=$((8999 + i))
        
        if docker ps --format "table {{.Names}}" | grep -q "^$container$"; then
            # Container is running, check Redis status
            if docker exec $container redis-cli -p $port ping > /dev/null 2>&1; then
                role=$(docker exec $container redis-cli -p $port info replication 2>/dev/null | grep "role:" | cut -d: -f2 | tr -d '\r')
                echo -e "  ${GREEN}✓${NC} $container (port $port): Running - $role"
            else
                echo -e "  ${YELLOW}⚠${NC} $container (port $port): Container up but Redis not responding"
            fi
        else
            echo -e "  ${RED}✗${NC} $container (port $port): Stopped"
        fi
    done
    
    # Try to get cluster info from any running node
    echo ""
    for i in {1..6}; do
        container="redis-node-$i"
        port=$((8999 + i))
        
        if docker ps --format "table {{.Names}}" | grep -q "^$container$"; then
            cluster_state=$(docker exec $container redis-cli -p $port cluster info 2>/dev/null | grep cluster_state | cut -d: -f2 | tr -d '\r' 2>/dev/null || echo "unknown")
            if [ "$cluster_state" != "unknown" ]; then
                echo "Cluster state (from $container): $cluster_state"
                
                # Show node count
                known_nodes=$(docker exec $container redis-cli -p $port cluster info 2>/dev/null | grep cluster_known_nodes | cut -d: -f2 | tr -d '\r' || echo "?")
                echo "Known nodes: $known_nodes"
                break
            fi
        fi
    done
    echo ""
}

# Scenario 1: Stop single master
scenario_single_master() {
    echo -e "${YELLOW}Scenario 1: Stopping single master node${NC}"
    echo "This will stop redis-node-1 (master) and test automatic failover"
    echo ""
    
    docker stop redis-node-1
    echo -e "${RED}✗ Stopped redis-node-1 (master)${NC}"
    echo ""
    echo "Waiting 10 seconds for failover to complete..."
    sleep 10
    
    check_cluster_status
    echo ""
    echo -e "${YELLOW}Expected result:${NC}"
    echo "- redis-node-5 (replica) should promote to master"
    echo "- Cluster should remain operational"
    echo "- Some keys may be temporarily unavailable during failover"
}

# Scenario 2: Stop single replica
scenario_single_replica() {
    echo -e "${YELLOW}Scenario 2: Stopping single replica node${NC}"
    echo "This will stop redis-node-4 (replica) and test replica recovery"
    echo ""
    
    docker stop redis-node-4
    echo -e "${RED}✗ Stopped redis-node-4 (replica)${NC}"
    echo ""
    echo "Waiting 5 seconds..."
    sleep 5
    
    check_cluster_status
    echo ""
    echo -e "${YELLOW}Expected result:${NC}"
    echo "- Cluster should remain fully operational"
    echo "- Master nodes continue serving requests"
    echo "- No data loss or service interruption"
}

# Scenario 3: Stop master and replica pair
scenario_master_replica() {
    echo -e "${YELLOW}Scenario 3: Stopping master-replica pair${NC}"
    echo "This will stop redis-node-2 (master) and redis-node-6 (replica)"
    echo ""
    
    docker stop redis-node-2 redis-node-6
    echo -e "${RED}✗ Stopped redis-node-2 (master) and redis-node-6 (replica)${NC}"
    echo ""
    echo "Waiting 10 seconds for cluster to adapt..."
    sleep 10
    
    check_cluster_status
    echo ""
    echo -e "${YELLOW}Expected result:${NC}"
    echo "- Cluster loses one shard completely"
    echo "- Remaining nodes handle requests for their shards"
    echo "- Some hash slots may become unavailable"
}

# Scenario 4: Split brain simulation
scenario_split_brain() {
    echo -e "${YELLOW}Scenario 4: Split brain simulation${NC}"
    echo "This will stop nodes 1, 2, 3 leaving only nodes 4, 5, 6"
    echo ""
    
    docker stop redis-node-1 redis-node-2 redis-node-3
    echo -e "${RED}✗ Stopped redis-node-1, redis-node-2, redis-node-3${NC}"
    echo ""
    echo "Waiting 10 seconds..."
    sleep 10
    
    check_cluster_status
    echo ""
    echo -e "${YELLOW}Expected result:${NC}"
    echo "- Minority partition (nodes 4,5,6) should stop accepting writes"
    echo "- Cluster state should become 'fail'"
    echo "- Data consistency is preserved"
}

# Scenario 5: Cascade failure
scenario_cascade_failure() {
    echo -e "${YELLOW}Scenario 5: Cascade failure simulation${NC}"
    echo "This will progressively stop nodes to simulate cascade failure"
    echo ""
    
    echo "Step 1: Stop replica node-4..."
    docker stop redis-node-4
    sleep 3
    
    echo "Step 2: Stop master node-1..."
    docker stop redis-node-1
    sleep 5
    
    echo "Step 3: Stop replica node-6..."
    docker stop redis-node-6
    sleep 3
    
    echo "Step 4: Stop master node-2..."
    docker stop redis-node-2
    sleep 5
    
    echo -e "${RED}✗ Progressive failure complete${NC}"
    
    check_cluster_status
    echo ""
    echo -e "${YELLOW}Expected result:${NC}"
    echo "- Only nodes 3 and 5 remain"
    echo "- Cluster may be in degraded state"
    echo "- Limited functionality available"
}

# Restore all nodes
restore_all() {
    echo -e "${YELLOW}Restoring all stopped nodes...${NC}"
    echo ""
    
    # Start all nodes
    for i in {1..6}; do
        container="redis-node-$i"
        if ! docker ps --format "table {{.Names}}" | grep -q "^$container$"; then
            echo "Starting $container..."
            docker start $container
        else
            echo "$container already running"
        fi
    done
    
    echo ""
    echo "Waiting 15 seconds for cluster to stabilize..."
    sleep 15
    
    check_cluster_status
    echo ""
    echo -e "${GREEN}✓ All nodes restored${NC}"
    echo -e "${YELLOW}Note:${NC} Failed nodes should rejoin as replicas"
}

# Main script logic
case "${1:-}" in
    "1"|"single-master")
        scenario_single_master
        ;;
    "2"|"single-replica")
        scenario_single_replica
        ;;
    "3"|"master-replica")
        scenario_master_replica
        ;;
    "4"|"split-brain")
        scenario_split_brain
        ;;
    "5"|"cascade-failure")
        scenario_cascade_failure
        ;;
    "restore")
        restore_all
        ;;
    "status")
        check_cluster_status
        ;;
    *)
        show_usage
        exit 1
        ;;
esac

echo ""
echo -e "${YELLOW}To restore failed nodes, run: $0 restore${NC}"
echo -e "${YELLOW}To check status, run: $0 status${NC}"