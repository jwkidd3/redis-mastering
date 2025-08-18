#!/bin/bash

echo "⚡ Simulating business transaction load..."
echo "Press Ctrl+C to stop"
echo ""

COUNTER=0

while true; do
    COUNTER=$((COUNTER + 1))
    
    # Customer login simulation
    CUSTOMER_ID=$((RANDOM % 100 + 1))
    redis-cli SETEX session:customer:${CUSTOMER_ID} 1800 "active" > /dev/null
    
    # Policy lookup
    POLICY_ID=$((RANDOM % 10 + 1000))
    redis-cli GET policy:AUTO:${POLICY_ID} > /dev/null
    
    # Claim processing
    if [ $((COUNTER % 5)) -eq 0 ]; then
        CLAIM_ID="CLM:AUTO:2024:${COUNTER}"
        redis-cli LPUSH claims:pending "${CLAIM_ID}" > /dev/null
        redis-cli INCR metrics:daily:claims_filed > /dev/null
    fi
    
    # Risk score check
    if [ $((COUNTER % 3)) -eq 0 ]; then
        redis-cli ZRANGE risk:scores 0 2 WITHSCORES > /dev/null
    fi
    
    # Metrics update
    redis-cli INCR metrics:daily:customers_active > /dev/null
    
    # Random delay between 10-100ms
    sleep 0.0$((RANDOM % 10 + 1))
    
    if [ $((COUNTER % 10)) -eq 0 ]; then
        echo "Processed ${COUNTER} transactions..."
    fi
done
