#!/bin/bash

echo "========================================"
echo "Redis Cluster Slot Distribution"
echo "========================================"
echo ""

# Get cluster slots information
docker exec redis-node-1 redis-cli -p 9000 cluster slots | while IFS= read -r line; do
    echo "$line"
done

echo ""
echo "Detailed Node Information:"
echo "=========================="

# Parse and display node information with slot counts
docker exec redis-node-1 redis-cli -p 9000 cluster nodes | while IFS= read -r line; do
    node_id=$(echo "$line" | awk '{print $1}')
    ip_port=$(echo "$line" | awk '{print $2}')
    flags=$(echo "$line" | awk '{print $3}')
    master_id=$(echo "$line" | awk '{print $4}')
    
    if [[ "$flags" == *"master"* ]]; then
        # Count slots for master nodes
        slots=$(echo "$line" | cut -d' ' -f9-)
        if [ ! -z "$slots" ] && [ "$slots" != "-" ]; then
            # Count the number of slots
            slot_count=0
            for range in $slots; do
                if [[ "$range" == *"-"* ]]; then
                    start=$(echo "$range" | cut -d'-' -f1)
                    end=$(echo "$range" | cut -d'-' -f2)
                    count=$((end - start + 1))
                    slot_count=$((slot_count + count))
                else
                    slot_count=$((slot_count + 1))
                fi
            done
            echo "Master Node: $ip_port"
            echo "  Node ID: ${node_id:0:8}..."
            echo "  Slots: $slot_count"
            echo "  Ranges: $slots"
        fi
    else
        echo "Replica Node: $ip_port"
        echo "  Node ID: ${node_id:0:8}..."
        echo "  Master: ${master_id:0:8}..."
    fi
    echo ""
done

echo "========================================"
echo "Total Slots: 16384"
echo "========================================"