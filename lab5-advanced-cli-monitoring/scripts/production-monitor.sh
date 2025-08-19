#!/bin/bash

# Production Monitoring Dashboard for Redis
# Real-time monitoring of Redis health, performance, and operations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Configuration
UPDATE_INTERVAL=5
LOG_FILE="monitoring/production-monitor.log"
STATUS_FILE="monitoring/status.json"

# Create monitoring directory
mkdir -p monitoring

echo -e "${CYAN}================================================${NC}"
echo -e "${CYAN}   🔍 Redis Production Monitoring Dashboard${NC}"
echo -e "${CYAN}   📊 Real-time Health & Performance Tracking${NC}"
echo -e "${CYAN}================================================${NC}"
echo ""

# Function to get Redis info
get_redis_info() {
    redis-cli INFO 2>/dev/null || echo "ERROR: Cannot connect to Redis"
}

# Function to extract value from Redis INFO
extract_info() {
    echo "$1" | grep "^$2:" | cut -d: -f2 | tr -d '\r'
}

# Function to format bytes
format_bytes() {
    local bytes=$1
    if [ "$bytes" -ge 1073741824 ]; then
        echo "$(($bytes / 1073741824))GB"
    elif [ "$bytes" -ge 1048576 ]; then
        echo "$(($bytes / 1048576))MB"
    elif [ "$bytes" -ge 1024 ]; then
        echo "$(($bytes / 1024))KB"
    else
        echo "${bytes}B"
    fi
}

# Function to display monitoring data
display_monitoring() {
    clear
    
    echo -e "${CYAN}🔍 Redis Production Monitor - $(date)${NC}"
    echo -e "${CYAN}================================================${NC}"
    
    local info=$(get_redis_info)
    
    if [[ "$info" == *"ERROR"* ]]; then
        echo -e "${RED}❌ Redis Connection Failed${NC}"
        echo -e "${RED}   Check if Redis server is running${NC}"
        return 1
    fi
    
    # Extract key metrics
    local memory_used=$(extract_info "$info" "used_memory")
    local memory_peak=$(extract_info "$info" "used_memory_peak")
    local memory_rss=$(extract_info "$info" "used_memory_rss")
    local fragmentation=$(extract_info "$info" "mem_fragmentation_ratio")
    local connected_clients=$(extract_info "$info" "connected_clients")
    local total_commands=$(extract_info "$info" "total_commands_processed")
    local keyspace_hits=$(extract_info "$info" "keyspace_hits")
    local keyspace_misses=$(extract_info "$info" "keyspace_misses")
    local evicted_keys=$(extract_info "$info" "evicted_keys")
    local expired_keys=$(extract_info "$info" "expired_keys")
    local uptime_seconds=$(extract_info "$info" "uptime_in_seconds")
    local redis_version=$(extract_info "$info" "redis_version")
    
    # Calculate hit ratio
    local total_requests=$((keyspace_hits + keyspace_misses))
    local hit_ratio=0
    if [ "$total_requests" -gt 0 ]; then
        hit_ratio=$((keyspace_hits * 100 / total_requests))
    fi
    
    # Format uptime
    local uptime_days=$((uptime_seconds / 86400))
    local uptime_hours=$(((uptime_seconds % 86400) / 3600))
    local uptime_mins=$(((uptime_seconds % 3600) / 60))
    
    # Server Status
    echo -e "${GREEN}🚀 Server Status${NC}"
    echo -e "   Version: ${YELLOW}$redis_version${NC}"
    echo -e "   Uptime: ${YELLOW}${uptime_days}d ${uptime_hours}h ${uptime_mins}m${NC}"
    echo -e "   Clients: ${YELLOW}$connected_clients${NC}"
    echo ""
    
    # Memory Status
    echo -e "${BLUE}💾 Memory Usage${NC}"
    echo -e "   Used: ${YELLOW}$(format_bytes $memory_used)${NC}"
    echo -e "   Peak: ${YELLOW}$(format_bytes $memory_peak)${NC}"
    echo -e "   RSS: ${YELLOW}$(format_bytes $memory_rss)${NC}"
    echo -e "   Fragmentation: ${YELLOW}$fragmentation${NC}"
    
    # Memory warning
    if command -v bc > /dev/null && (( $(echo "$fragmentation > 1.5" | bc -l) )); then
        echo -e "   ${RED}⚠️  High fragmentation detected${NC}"
    fi
    echo ""
    
    # Performance Metrics
    echo -e "${MAGENTA}⚡ Performance${NC}"
    echo -e "   Total Commands: ${YELLOW}$total_commands${NC}"
    echo -e "   Cache Hits: ${YELLOW}$keyspace_hits${NC}"
    echo -e "   Cache Misses: ${YELLOW}$keyspace_misses${NC}"
    echo -e "   Hit Ratio: ${YELLOW}${hit_ratio}%${NC}"
    
    # Hit ratio warning
    if [ "$hit_ratio" -lt 80 ]; then
        echo -e "   ${RED}⚠️  Low hit ratio detected${NC}"
    fi
    echo ""
    
    # Key Statistics
    echo -e "${CYAN}🔑 Key Statistics${NC}"
    echo -e "   Evicted: ${YELLOW}$evicted_keys${NC}"
    echo -e "   Expired: ${YELLOW}$expired_keys${NC}"
    
    # Get database info
    local db_info=$(redis-cli INFO keyspace | grep "^db0:" | cut -d: -f2)
    if [ -n "$db_info" ]; then
        local keys=$(echo "$db_info" | sed 's/keys=\([0-9]*\).*/\1/')
        local expires=$(echo "$db_info" | sed 's/.*expires=\([0-9]*\).*/\1/')
        echo -e "   Total Keys: ${YELLOW}$keys${NC}"
        echo -e "   With TTL: ${YELLOW}$expires${NC}"
    fi
    echo ""
    
    # Sample Pattern Analysis
    echo -e "${GREEN}🔍 Key Pattern Analysis${NC}"
    local customer_keys=$(redis-cli EVAL "return #redis.call('keys', 'customer:*')" 0)
    local policy_keys=$(redis-cli EVAL "return #redis.call('keys', 'policy:*')" 0)
    local claim_keys=$(redis-cli EVAL "return #redis.call('keys', 'claim:*')" 0)
    local session_keys=$(redis-cli EVAL "return #redis.call('keys', 'session:*')" 0)
    
    echo -e "   Customers: ${YELLOW}$customer_keys${NC}"
    echo -e "   Policies: ${YELLOW}$policy_keys${NC}"
    echo -e "   Claims: ${YELLOW}$claim_keys${NC}"
    echo -e "   Sessions: ${YELLOW}$session_keys${NC}"
    echo ""
    
    # Alerts
    echo -e "${RED}🚨 Alert Status${NC}"
    local alerts=0
    
    if [ "$connected_clients" -gt 100 ]; then
        echo -e "   ${RED}⚠️  High client connections: $connected_clients${NC}"
        ((alerts++))
    fi
    
    if [ "$hit_ratio" -lt 80 ]; then
        echo -e "   ${RED}⚠️  Low cache hit ratio: ${hit_ratio}%${NC}"
        ((alerts++))
    fi
    
    if command -v bc > /dev/null && (( $(echo "$fragmentation > 1.5" | bc -l) )); then
        echo -e "   ${RED}⚠️  High memory fragmentation: $fragmentation${NC}"
        ((alerts++))
    fi
    
    if [ "$alerts" -eq 0 ]; then
        echo -e "   ${GREEN}✅ All systems normal${NC}"
    fi
    
    # Log to file
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] Memory: $(format_bytes $memory_used), Clients: $connected_clients, Hit Ratio: ${hit_ratio}%, Fragmentation: $fragmentation" >> "$LOG_FILE"
    
    echo ""
    echo -e "${CYAN}📊 Auto-refresh in ${UPDATE_INTERVAL}s | Press Ctrl+C to exit${NC}"
    echo -e "${CYAN}📁 Logs: $LOG_FILE${NC}"
}

# Main monitoring loop
while true; do
    display_monitoring
    sleep $UPDATE_INTERVAL
done
