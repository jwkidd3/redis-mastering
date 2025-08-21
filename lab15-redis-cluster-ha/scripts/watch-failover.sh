#!/bin/bash

echo "========================================"
echo "Monitoring Redis Cluster Failover"
echo "========================================"
echo ""
echo "Press Ctrl+C to stop monitoring"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Initial state
echo "Capturing initial cluster state..."
initial_masters=""
for port in 9000 9002 9004; do
    node_info=$(docker exec redis-node-$((port-8999)) redis-cli -p $port info replication 2>/dev/null | grep role | cut -d: -f2 | tr -d '\r')
    if [ "$node_info" = "master" ]; then
        initial_masters="$initial_masters $port"
    fi
done
echo "Initial masters:$initial_masters"
echo ""

# Monitor loop
while true; do
    clear
    echo "========================================"
    echo "Redis Cluster Status - $(date '+%Y-%m-%d %H:%M:%S')"
    echo "========================================"
    echo ""
    
    # Check each node
    for i in {1..6}; do
        port=$((8999 + i))
        container="redis-node-$i"
        
        # Check if container is running
        if docker ps | grep -q $container; then
            # Try to get node info
            node_info=$(docker exec $container redis-cli -p $port info replication 2>/dev/null)
            
            if [ $? -eq 0 ]; then
                role=$(echo "$node_info" | grep "role:" | cut -d: -f2 | tr -d '\r')
                
                if [ "$role" = "master" ]; then
                    connected_slaves=$(echo "$node_info" | grep "connected_slaves:" | cut -d: -f2 | tr -d '\r')
                    echo -e "${GREEN}✓${NC} Node $i (port $port): ${GREEN}MASTER${NC} - Slaves: $connected_slaves"
                    
                    # Show slot info for masters
                    slots=$(docker exec $container redis-cli -p $port cluster nodes 2>/dev/null | grep myself | grep master | cut -d' ' -f9-)
                    if [ ! -z "$slots" ] && [ "$slots" != "-" ]; then
                        echo "    Slots: $slots"
                    fi
                elif [ "$role" = "slave" ]; then
                    master_host=$(echo "$node_info" | grep "master_host:" | cut -d: -f2 | tr -d '\r')
                    master_port=$(echo "$node_info" | grep "master_port:" | cut -d: -f2 | tr -d '\r')
                    link_status=$(echo "$node_info" | grep "master_link_status:" | cut -d: -f2 | tr -d '\r')
                    
                    if [ "$link_status" = "up" ]; then
                        echo -e "${GREEN}✓${NC} Node $i (port $port): REPLICA of $master_host:$master_port - Link: ${GREEN}UP${NC}"
                    else
                        echo -e "${YELLOW}⚠${NC} Node $i (port $port): REPLICA of $master_host:$master_port - Link: ${RED}DOWN${NC}"
                    fi
                else
                    echo -e "${YELLOW}⚠${NC} Node $i (port $port): Unknown role"
                fi
            else
                echo -e "${RED}✗${NC} Node $i (port $port): ${RED}NOT RESPONDING${NC}"
            fi
        else
            echo -e "${RED}✗${NC} Node $i (port $port): ${RED}CONTAINER DOWN${NC}"
        fi
    done
    
    echo ""
    echo "Cluster State:"
    echo "=============="
    
    # Try to get cluster state from any running node
    for i in {1..6}; do
        port=$((8999 + i))
        container="redis-node-$i"
        
        if docker ps | grep -q $container; then
            cluster_state=$(docker exec $container redis-cli -p $port cluster info 2>/dev/null | grep cluster_state | cut -d: -f2 | tr -d '\r')
            if [ ! -z "$cluster_state" ]; then
                if [ "$cluster_state" = "ok" ]; then
                    echo -e "State: ${GREEN}$cluster_state${NC}"
                else
                    echo -e "State: ${RED}$cluster_state${NC}"
                fi
                
                # Get additional cluster metrics
                cluster_info=$(docker exec $container redis-cli -p $port cluster info 2>/dev/null)
                known_nodes=$(echo "$cluster_info" | grep cluster_known_nodes | cut -d: -f2 | tr -d '\r')
                current_epoch=$(echo "$cluster_info" | grep cluster_current_epoch | cut -d: -f2 | tr -d '\r')
                
                echo "Known nodes: $known_nodes"
                echo "Current epoch: $current_epoch"
                break
            fi
        fi
    done
    
    sleep 2
done