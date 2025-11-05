#!/bin/bash

echo "========================================"
echo "Testing Redis Cluster Replication"
echo "========================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to find replica for a master
find_replica() {
    local master_port=$1
    local master_id=$(docker exec redis-node-$((master_port-8999)) redis-cli -p $master_port cluster myid | tr -d '\r')
    
    for port in 9000 9001 9002 9003 9004 9005; do
        local node_info=$(docker exec redis-node-$((port-8999)) redis-cli -p $port cluster nodes 2>/dev/null | grep myself)
        if echo "$node_info" | grep -q "slave $master_id"; then
            echo $port
            return
        fi
    done
    echo ""
}

# Test replication for each master
for master_port in 9000 9002 9004; do
    echo "Testing Master on port $master_port"
    echo "-------------------------------------"
    
    # Find replica for this master
    replica_port=$(find_replica $master_port)
    
    if [ -z "$replica_port" ]; then
        echo -e "${RED}✗ No replica found for master on port $master_port${NC}"
        continue
    fi
    
    echo "Master port: $master_port"
    echo "Replica port: $replica_port"
    echo ""
    
    # Generate unique test key
    test_key="replication:test:$(date +%s):$RANDOM"
    test_value="test-value-$RANDOM"
    
    # Write to master
    echo "1. Writing to master..."
    docker exec redis-node-$((master_port-8999)) redis-cli -p $master_port SET "$test_key" "$test_value" > /dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Successfully wrote to master${NC}"
    else
        echo -e "${RED}✗ Failed to write to master${NC}"
        continue
    fi
    
    # Wait for replication
    echo "2. Waiting for replication..."
    sleep 1
    
    # Read from replica
    echo "3. Reading from replica..."
    replica_value=$(docker exec redis-node-$((replica_port-8999)) redis-cli -p $replica_port --readonly GET "$test_key" 2>/dev/null | tr -d '\r')
    
    if [ "$replica_value" = "$test_value" ]; then
        echo -e "${GREEN}✓ Replication successful! Value matches: $replica_value${NC}"
    else
        echo -e "${RED}✗ Replication failed! Expected: $test_value, Got: $replica_value${NC}"
    fi
    
    # Check replication lag
    echo "4. Checking replication lag..."
    lag_info=$(docker exec redis-node-$((replica_port-8999)) redis-cli -p $replica_port info replication 2>/dev/null | grep master_last_io_seconds_ago | cut -d: -f2 | tr -d '\r')
    
    if [ ! -z "$lag_info" ]; then
        echo "   Replication lag: ${lag_info} seconds"
        if [ "$lag_info" -le 1 ]; then
            echo -e "${GREEN}   ✓ Replication lag is acceptable${NC}"
        else
            echo -e "${YELLOW}   ⚠ Replication lag is high${NC}"
        fi
    fi
    
    # Cleanup
    docker exec redis-node-$((master_port-8999)) redis-cli -p $master_port DEL "$test_key" > /dev/null
    
    echo ""
done

echo "========================================"
echo "Testing Replication Under Load"
echo "========================================"
echo ""

# Pick a master for load testing
master_port=9000
replica_port=$(find_replica $master_port)

echo "Generating load on master (port $master_port)..."
echo "Writing 1000 keys..."

# Write many keys quickly
for i in {1..1000}; do
    docker exec redis-node-$((master_port-8999)) redis-cli -p $master_port SET "load:test:$i" "value-$i" > /dev/null 2>&1 &
    if [ $((i % 100)) -eq 0 ]; then
        echo "  Written $i keys..."
    fi
done

wait # Wait for all background jobs to complete

echo -e "${GREEN}✓ Completed writing 1000 keys${NC}"
echo ""

# Check replication status
echo "Checking replication status..."
master_info=$(docker exec redis-node-$((master_port-8999)) redis-cli -p $master_port info replication 2>/dev/null)
connected_slaves=$(echo "$master_info" | grep connected_slaves | cut -d: -f2 | tr -d '\r')
echo "Connected slaves: $connected_slaves"

if [ "$connected_slaves" -gt 0 ]; then
    echo -e "${GREEN}✓ Replica is connected${NC}"
    
    # Verify some keys on replica
    echo ""
    echo "Verifying keys on replica..."
    missing_keys=0
    for i in 1 50 100 500 1000; do
        value=$(docker exec redis-node-$((replica_port-8999)) redis-cli -p $replica_port --readonly GET "load:test:$i" 2>/dev/null | tr -d '\r')
        if [ "$value" = "value-$i" ]; then
            echo -e "  Key $i: ${GREEN}✓${NC}"
        else
            echo -e "  Key $i: ${RED}✗${NC}"
            ((missing_keys++))
        fi
    done
    
    if [ $missing_keys -eq 0 ]; then
        echo -e "${GREEN}✓ All sampled keys successfully replicated${NC}"
    else
        echo -e "${YELLOW}⚠ Some keys missing on replica${NC}"
    fi
else
    echo -e "${RED}✗ No replicas connected${NC}"
fi

# Cleanup
echo ""
echo "Cleaning up test keys..."
for i in {1..1000}; do
    docker exec redis-node-$((master_port-8999)) redis-cli -p $master_port DEL "load:test:$i" > /dev/null 2>&1 &
done
wait

echo ""
echo "========================================"
echo "Replication Test Complete"
echo "========================================"