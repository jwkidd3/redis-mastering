#!/bin/bash

# TTL Monitoring Tool for Lab 4 - Remote Host Support
# Monitors key expiration patterns and provides TTL analysis

# Parse command line arguments
REDIS_HOST=${1:-"localhost"}
REDIS_PORT=${2:-"6379"}
REDIS_PASSWORD=${3:-""}

WATCH_MODE=false
if [[ "$1" == "--watch" ]] || [[ "$4" == "--watch" ]]; then
    WATCH_MODE=true
fi

# Build Redis CLI command
REDIS_CMD="redis-cli -h $REDIS_HOST -p $REDIS_PORT"
if [ ! -z "$REDIS_PASSWORD" ]; then
    REDIS_CMD="$REDIS_CMD -a $REDIS_PASSWORD"
fi

# Test connection
if ! $REDIS_CMD ping > /dev/null 2>&1; then
    echo "❌ Cannot connect to Redis at $REDIS_HOST:$REDIS_PORT"
    echo "Usage: $0 [REDIS_HOST] [REDIS_PORT] [REDIS_PASSWORD] [--watch]"
    echo "Example: $0 redis.example.com 6379 mypassword"
    exit 1
fi

monitor_ttl() {
    clear
    echo "🔍 Redis Key TTL Monitoring Dashboard"
    echo "📍 Host: $REDIS_HOST:$REDIS_PORT"
    echo "$(date)"
    echo "=" $(printf '=%.0s' {1..60})

    # TTL Distribution Analysis
    echo ""
    echo "📊 TTL Distribution by Key Pattern:"
    echo "-----------------------------------"

    # Quote TTL Analysis
    echo "🏷️  QUOTE KEYS:"
    for key in $($REDIS_CMD KEYS "quote:*" 2>/dev/null); do
        ttl=$($REDIS_CMD TTL "$key" 2>/dev/null)
        if [[ $ttl -gt 0 ]]; then
            printf "   %-25s TTL: %3d seconds (%s)\n" "$key" "$ttl" "$(date -d "+${ttl} seconds" '+%H:%M:%S' 2>/dev/null || echo 'expires soon')"
        elif [[ $ttl -eq -1 ]]; then
            printf "   %-25s TTL: persistent\n" "$key"
        else
            printf "   %-25s TTL: expired/missing\n" "$key"
        fi
    done

    # Session TTL Analysis  
    echo ""
    echo "👤 SESSION KEYS:"
    for key in $($REDIS_CMD KEYS "session:*" 2>/dev/null); do
        ttl=$($REDIS_CMD TTL "$key" 2>/dev/null)
        if [[ $ttl -gt 0 ]]; then
            hours=$((ttl / 3600))
            minutes=$(((ttl % 3600) / 60))
            seconds=$((ttl % 60))
            printf "   %-35s TTL: %3d seconds (%02d:%02d:%02d)\n" "$key" "$ttl" "$hours" "$minutes" "$seconds"
        elif [[ $ttl -eq -1 ]]; then
            printf "   %-35s TTL: persistent\n" "$key"
        else
            printf "   %-35s TTL: expired/missing\n" "$key"
        fi
    done

    # Temporal Data TTL Analysis
    echo ""
    echo "📅 TEMPORAL DATA KEYS:"
    for pattern in "metrics:*" "report:*" "analytics:*"; do
        for key in $($REDIS_CMD KEYS "$pattern" 2>/dev/null); do
            ttl=$($REDIS_CMD TTL "$key" 2>/dev/null)
            if [[ $ttl -gt 0 ]]; then
                days=$((ttl / 86400))
                hours=$(((ttl % 86400) / 3600))
                printf "   %-40s TTL: %6d seconds (%dd %02dh)\n" "$key" "$ttl" "$days" "$hours"
            elif [[ $ttl -eq -1 ]]; then
                printf "   %-40s TTL: persistent\n" "$key"
            else
                printf "   %-40s TTL: expired/missing\n" "$key"
            fi
        done
    done

    # Security Keys TTL Analysis
    echo ""
    echo "🔒 SECURITY KEYS:"
    for key in $($REDIS_CMD KEYS "security:*" 2>/dev/null); do
        ttl=$($REDIS_CMD TTL "$key" 2>/dev/null)
        if [[ $ttl -gt 0 ]]; then
            minutes=$((ttl / 60))
            seconds=$((ttl % 60))
            printf "   %-40s TTL: %3d seconds (%02d:%02d)\n" "$key" "$ttl" "$minutes" "$seconds"
        elif [[ $ttl -eq -1 ]]; then
            printf "   %-40s TTL: persistent\n" "$key"
        else
            printf "   %-40s TTL: expired/missing\n" "$key"
        fi
    done

    # Cache Keys TTL Analysis
    echo ""
    echo "💾 CACHE KEYS:"
    for key in $($REDIS_CMD KEYS "cache:*" 2>/dev/null); do
        ttl=$($REDIS_CMD TTL "$key" 2>/dev/null)
        if [[ $ttl -gt 0 ]]; then
            minutes=$((ttl / 60))
            seconds=$((ttl % 60))
            printf "   %-40s TTL: %4d seconds (%02d:%02d)\n" "$key" "$ttl" "$minutes" "$seconds"
        elif [[ $ttl -eq -1 ]]; then
            printf "   %-40s TTL: persistent\n" "$key"
        else
            printf "   %-40s TTL: expired/missing\n" "$key"
        fi
    done

    # Key Pattern Health Summary
    echo ""
    echo "📈 Key Pattern Health Summary:"
    echo "------------------------------"
    
    total_keys=$($REDIS_CMD DBSIZE 2>/dev/null)
    quote_keys=$($REDIS_CMD KEYS "quote:*" 2>/dev/null | wc -l)
    session_keys=$($REDIS_CMD KEYS "session:*" 2>/dev/null | wc -l)
    policy_keys=$($REDIS_CMD KEYS "policy:*" 2>/dev/null | wc -l)
    customer_keys=$($REDIS_CMD KEYS "customer:*" 2>/dev/null | wc -l)
    temporal_keys=$($REDIS_CMD EVAL "return #redis.call('KEYS', 'metrics:*') + #redis.call('KEYS', 'report:*') + #redis.call('KEYS', 'analytics:*')" 0 2>/dev/null)
    security_keys=$($REDIS_CMD KEYS "security:*" 2>/dev/null | wc -l)
    cache_keys=$($REDIS_CMD KEYS "cache:*" 2>/dev/null | wc -l)

    printf "   Total Keys:     %3d\n" "$total_keys"
    printf "   Policy Keys:    %3d (persistent)\n" "$policy_keys"
    printf "   Customer Keys:  %3d (persistent)\n" "$customer_keys"
    printf "   Quote Keys:     %3d (with TTL)\n" "$quote_keys"
    printf "   Session Keys:   %3d (with TTL)\n" "$session_keys"
    printf "   Temporal Keys:  %3d (with TTL)\n" "$temporal_keys"
    printf "   Security Keys:  %3d (with TTL)\n" "$security_keys"
    printf "   Cache Keys:     %3d (with TTL)\n" "$cache_keys"

    # Expiration Alerts
    echo ""
    echo "⚠️  EXPIRATION ALERTS (Next 60 seconds):"
    echo "----------------------------------------"
    
    alerts_found=false
    for key in $($REDIS_CMD KEYS "*" 2>/dev/null); do
        ttl=$($REDIS_CMD TTL "$key" 2>/dev/null)
        if [[ $ttl -gt 0 ]] && [[ $ttl -lt 60 ]]; then
            printf "   🚨 %-30s expires in %2d seconds\n" "$key" "$ttl"
            alerts_found=true
        fi
    done
    
    if [[ $alerts_found == false ]]; then
        echo "   ✅ No keys expiring in the next 60 seconds"
    fi

    # Memory Usage by Pattern
    echo ""
    echo "💾 Memory Usage Analysis:"
    echo "-------------------------"
    
    memory_used=$($REDIS_CMD INFO memory 2>/dev/null | grep "used_memory_human:" | cut -d: -f2 | tr -d '\r')
    memory_peak=$($REDIS_CMD INFO memory 2>/dev/null | grep "used_memory_peak_human:" | cut -d: -f2 | tr -d '\r')
    
    echo "   Memory Used:    $memory_used"
    echo "   Memory Peak:    $memory_peak"
    
    # Big keys analysis
    echo ""
    echo "🔍 Largest Keys by Memory Usage:"
    $REDIS_CMD --bigkeys 2>/dev/null | grep -E "(string|hash|list|set|zset)" | head -5 | while read line; do
        echo "   $line"
    done

    # Database info
    echo ""
    echo "📊 Database Statistics:"
    echo "-----------------------"
    $REDIS_CMD INFO keyspace 2>/dev/null | grep "db0:" | sed 's/db0:/   Database 0: /'
}

if [[ $WATCH_MODE == true ]]; then
    echo "Starting continuous TTL monitoring for $REDIS_HOST:$REDIS_PORT (Press Ctrl+C to stop)..."
    while true; do
        monitor_ttl
        echo ""
        echo "🔄 Updating in 5 seconds... (Press Ctrl+C to stop)"
        sleep 5
    done
else
    monitor_ttl
    echo ""
    echo "💡 Use --watch flag for continuous monitoring: $0 $REDIS_HOST $REDIS_PORT $REDIS_PASSWORD --watch"
fi
