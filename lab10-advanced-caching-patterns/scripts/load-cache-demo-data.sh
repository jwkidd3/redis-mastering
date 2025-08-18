#!/bin/bash

echo "📊 Loading cache demonstration data..."

redis-cli FLUSHALL > /dev/null

# Load sample policies
for i in {1..100}; do
    policy_id="POL$(printf "%06d" $i)"
    policy_type=$((i % 3))
    case $policy_type in
        0) type="AUTO" ;;
        1) type="HOME" ;;
        2) type="LIFE" ;;
    esac
    
    premium=$((500 + RANDOM % 2000))
    customer_id="CUST$(printf "%03d" $((i % 20)))"
    
    redis-cli HSET "db:policy:$policy_id" \
        id "$policy_id" \
        type "$type" \
        premium "$premium" \
        customer "$customer_id" \
        status "ACTIVE" > /dev/null
done

# Load sample customers
for i in {1..20}; do
    customer_id="CUST$(printf "%03d" $i)"
    redis-cli HSET "db:customer:$customer_id" \
        id "$customer_id" \
        name "Customer $i" \
        email "customer$i@example.com" \
        tier "$([ $((i % 3)) -eq 0 ] && echo "PREMIUM" || echo "STANDARD")" \
        total_value "$((10000 + RANDOM % 50000))" > /dev/null
done

# Create indices
echo "Creating indices..."
redis-cli EVAL "
    local customers = redis.call('KEYS', 'db:customer:*')
    for i, key in ipairs(customers) do
        local customer = redis.call('HGETALL', key)
        local data = {}
        for j = 1, #customer, 2 do
            data[customer[j]] = customer[j + 1]
        end
        redis.call('ZADD', 'idx:customers:by_value', data['total_value'], data['id'])
        redis.call('SADD', 'idx:customers:tier:' .. data['tier'], data['id'])
    end
    return #customers .. ' customers indexed'
" 0

echo "✅ Sample data loaded successfully!"
echo "   - 100 policies"
echo "   - 20 customers"
echo "   - Value and tier indices created"
