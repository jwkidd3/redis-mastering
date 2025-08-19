#!/bin/bash

# Production Monitoring Dashboard
set -e

# Colors
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
NC="\033[0m"

echo -e "${CYAN}🔍 Redis Production Monitor${NC}"
echo -e "${CYAN}============================${NC}"

# Create monitoring directory
mkdir -p monitoring

# Function to display monitoring data
display_monitoring() {
    clear
    echo -e "${CYAN}🔍 Redis Monitor - $(date)${NC}"
    echo -e "${CYAN}==============================${NC}"
    echo ""
    
    # Test Redis connection
    if ! redis-cli ping > /dev/null 2>&1; then
        echo -e "${RED}❌ Redis Connection Failed${NC}"
        return 1
    fi
    
    # Get Redis info
    INFO=$(redis-cli INFO)
    
    # Extract metrics
    MEMORY_USED=$(echo "$INFO" | grep "used_memory:" | cut -d: -f2 | tr -d "\r")
    CLIENTS=$(echo "$INFO" | grep "connected_clients:" | cut -d: -f2 | tr -d "\r")
    HITS=$(echo "$INFO" | grep "keyspace_hits:" | cut -d: -f2 | tr -d "\r")
    MISSES=$(echo "$INFO" | grep "keyspace_misses:" | cut -d: -f2 | tr -d "\r")
    VERSION=$(echo "$INFO" | grep "redis_version:" | cut -d: -f2 | tr -d "\r")
    
    # Calculate hit ratio
    TOTAL_REQUESTS=$((HITS + MISSES))
    HIT_RATIO=0
    if [ "$TOTAL_REQUESTS" -gt 0 ]; then
        HIT_RATIO=$((HITS * 100 / TOTAL_REQUESTS))
    fi
    
    # Display metrics
    echo -e "${GREEN}🚀 Server Status${NC}"
    echo -e "   Version: ${YELLOW}$VERSION${NC}"
    echo -e "   Clients: ${YELLOW}$CLIENTS${NC}"
    echo ""
    
    echo -e "${BLUE}💾 Memory Usage${NC}"
    MEMORY_MB=$((MEMORY_USED / 1048576))
    echo -e "   Used: ${YELLOW}${MEMORY_MB}MB${NC}"
    echo ""
    
    echo -e "${CYAN}⚡ Performance${NC}"
    echo -e "   Cache Hits: ${YELLOW}$HITS${NC}"
    echo -e "   Cache Misses: ${YELLOW}$MISSES${NC}"
    echo -e "   Hit Ratio: ${YELLOW}${HIT_RATIO}%${NC}"
    echo ""
    
    # Key analysis
    echo -e "${GREEN}🔍 Key Analysis${NC}"
    TOTAL_KEYS=$(redis-cli DBSIZE)
    CUSTOMER_KEYS=$(redis-cli EVAL "return #redis.call(\"keys\", \"customer:*\")" 0)
    POLICY_KEYS=$(redis-cli EVAL "return #redis.call(\"keys\", \"policy:*\")" 0)
    CLAIM_KEYS=$(redis-cli EVAL "return #redis.call(\"keys\", \"claim:*\")" 0)
    
    echo -e "   Total Keys: ${YELLOW}$TOTAL_KEYS${NC}"
    echo -e "   Customers: ${YELLOW}$CUSTOMER_KEYS${NC}"
    echo -e "   Policies: ${YELLOW}$POLICY_KEYS${NC}"
    echo -e "   Claims: ${YELLOW}$CLAIM_KEYS${NC}"
    echo ""
    
    # Alerts
    echo -e "${RED}🚨 Alert Status${NC}"
    ALERTS=0
    
    if [ "$CLIENTS" -gt 50 ]; then
        echo -e "   ${RED}⚠️  High client connections: $CLIENTS${NC}"
        ALERTS=$((ALERTS + 1))
    fi
    
    if [ "$HIT_RATIO" -lt 80 ] && [ "$TOTAL_REQUESTS" -gt 0 ]; then
        echo -e "   ${RED}⚠️  Low cache hit ratio: ${HIT_RATIO}%${NC}"
        ALERTS=$((ALERTS + 1))
    fi
    
    if [ "$ALERTS" -eq 0 ]; then
        echo -e "   ${GREEN}✅ All systems normal${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}📊 Auto-refresh in 5s | Press Ctrl+C to exit${NC}"
}

# Main monitoring loop
while true; do
    display_monitoring
    sleep 5
done
