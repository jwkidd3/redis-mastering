#!/bin/bash

# Key TTL Monitoring Tool for Insurance Redis Deployments
# Monitors key patterns, TTL distribution, and expiration patterns

echo "🔍 Redis Key TTL Monitoring Tool"
echo "================================"

# Function to get TTL distribution
get_ttl_distribution() {
    echo "📊 TTL Distribution Analysis:"
    redis-cli EVAL "
    local ttl_ranges = {60, 300, 1800, 3600, 86400, 604800}
    local range_names = {'≤1min', '≤5min', '≤30min', '≤1hr', '≤1day', '≤1week'}
    local counts = {}
    local total_with_ttl = 0
    
    for i, range in ipairs(ttl_ranges) do
      local count = 0
      local keys = redis.call('KEYS', '*')
      for j, key in ipairs(keys) do
        local ttl = redis.call('TTL', key)
        if ttl > 0 and ttl <= range then
          count = count + 1
        end
      end
      table.insert(counts, range_names[i] .. ': ' .. count)
      if i == 1 then total_with_ttl = count end
    end
    
    -- Count total keys with TTL
    local all_keys = redis.call('KEYS', '*')
    local keys_with_ttl = 0
    for i, key in ipairs(all_keys) do
      local ttl = redis.call('TTL', key)
      if ttl > 0 then
        keys_with_ttl = keys_with_ttl + 1
      end
    end
    
    table.insert(counts, 'Total with TTL: ' .. keys_with_ttl)
    return counts
    " 0
}

# Function to analyze key patterns
analyze_key_patterns() {
    echo ""
    echo "🗝️ Key Pattern Analysis:"
    redis-cli EVAL "
    local patterns = {'policy:*', 'customer:*', 'claim:*', 'quote:*', 'session:*', 'metrics:*'}
    local stats = {}
    
    for i, pattern in ipairs(patterns) do
      local keys = redis.call('KEYS', pattern)
      local with_ttl = 0
      local without_ttl = 0
      local avg_ttl = 0
      local ttl_sum = 0
      
      for j, key in ipairs(keys) do
        local ttl = redis.call('TTL', key)
        if ttl > 0 then
          with_ttl = with_ttl + 1
          ttl_sum = ttl_sum + ttl
        elseif ttl == -1 then
          without_ttl = without_ttl + 1
        end
      end
      
      if with_ttl > 0 then
        avg_ttl = math.floor(ttl_sum / with_ttl)
      end
      
      table.insert(stats, pattern .. ' → Total:' .. #keys .. ' TTL:' .. with_ttl .. ' Persistent:' .. without_ttl .. ' AvgTTL:' .. avg_ttl .. 's')
    end
    return stats
    " 0
}

# Function to find expiring keys
find_expiring_keys() {
    echo ""
    echo "⏰ Keys Expiring Soon (< 60 seconds):"
    redis-cli EVAL "
    local expiring = {}
    local keys = redis.call('KEYS', '*')
    
    for i, key in ipairs(keys) do
      local ttl = redis.call('TTL', key)
      if ttl > 0 and ttl <= 60 then
        table.insert(expiring, key .. ' (TTL: ' .. ttl .. 's)')
      end
    end
    
    if #expiring == 0 then
      table.insert(expiring, 'No keys expiring in next 60 seconds')
    end
    
    return expiring
    " 0
}

# Function to check quote health
check_quote_health() {
    echo ""
    echo "💰 Quote System Health:"
    redis-cli EVAL "
    local quote_types = {'auto', 'home', 'life'}
    local stats = {}
    
    for i, qtype in ipairs(quote_types) do
      local pattern = 'quote:' .. qtype .. ':*'
      local keys = redis.call('KEYS', pattern)
      local active = 0
      local expiring_soon = 0
      
      for j, key in ipairs(keys) do
        local ttl = redis.call('TTL', key)
        if ttl > 0 then
          active = active + 1
          if ttl <= 120 then  -- expiring in 2 minutes
            expiring_soon = expiring_soon + 1
          end
        end
      end
      
      table.insert(stats, qtype .. ' quotes: ' .. active .. ' active, ' .. expiring_soon .. ' expiring soon')
    end
    return stats
    " 0
}

# Function to check session health
check_session_health() {
    echo ""
    echo "👤 Session System Health:"
    redis-cli EVAL "
    local session_types = {'customer', 'agent', 'mobile'}
    local stats = {}
    
    for i, stype in ipairs(session_types) do
      local pattern = 'session:' .. stype .. ':*'
      local keys = redis.call('KEYS', pattern)
      local active = 0
      local expiring_soon = 0
      
      for j, key in ipairs(keys) do
        local ttl = redis.call('TTL', key)
        if ttl > 0 then
          active = active + 1
          if ttl <= 300 then  -- expiring in 5 minutes
            expiring_soon = expiring_soon + 1
          end
        end
      end
      
      table.insert(stats, stype .. ' sessions: ' .. active .. ' active, ' .. expiring_soon .. ' expiring soon')
    end
    return stats
    " 0
}

# Function to show memory usage by key pattern
show_memory_usage() {
    echo ""
    echo "💾 Memory Usage by Key Pattern:"
    
    # Check if MEMORY USAGE command is available (Redis 4.0+)
    if redis-cli MEMORY USAGE nonexistent 2>/dev/null | grep -q "unknown command"; then
        echo "MEMORY USAGE command not available in this Redis version"
        return
    fi
    
    echo "Sample key memory usage:"
    
    # Check a few sample keys from each pattern
    for pattern in "policy:*" "customer:*" "quote:*" "session:*"; do
        key=$(redis-cli KEYS "$pattern" | head -1)
        if [ ! -z "$key" ]; then
            memory=$(redis-cli MEMORY USAGE "$key" 2>/dev/null || echo "N/A")
            echo "  $key: $memory bytes"
        fi
    done
}

# Main execution
main() {
    # Check if Redis is available
    if ! redis-cli ping >/dev/null 2>&1; then
        echo "❌ Redis server not available"
        exit 1
    fi
    
    echo "📡 Connected to Redis server"
    echo "🕐 $(date)"
    echo ""
    
    # Database info
    echo "📈 Database Statistics:"
    echo "  Total Keys: $(redis-cli DBSIZE)"
    echo "  Memory Used: $(redis-cli INFO memory | grep used_memory_human | cut -d: -f2 | tr -d '\r')"
    echo ""
    
    # Run monitoring functions
    get_ttl_distribution
    analyze_key_patterns
    find_expiring_keys
    check_quote_health
    check_session_health
    show_memory_usage
    
    echo ""
    echo "✅ Monitoring complete"
}

# Run with continuous monitoring if -w flag provided
if [ "$1" = "-w" ] || [ "$1" = "--watch" ]; then
    echo "👀 Starting continuous monitoring (Ctrl+C to stop)..."
    while true; do
        clear
        main
        echo ""
        echo "🔄 Refreshing in 30 seconds..."
        sleep 30
    done
else
    main
fi
