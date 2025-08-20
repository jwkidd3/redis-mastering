# Redis Performance Report - Insurance Production

**Date:** $(date)
**Redis Host:** $REDIS_HOST:$REDIS_PORT

## Key Metrics

### Memory Usage
- Used Memory: $(redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO memory | grep "used_memory_human")
- Max Memory: $(redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG GET maxmemory)
- Fragmentation: $(redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO memory | grep "mem_fragmentation_ratio")

### Performance
- Total Commands: $(redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO stats | grep "total_commands_processed")
- Keyspace Hits: $(redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO stats | grep "keyspace_hits")
- Keyspace Misses: $(redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO stats | grep "keyspace_misses")

### Insurance Data
- Policies: $(redis-cli -h $REDIS_HOST -p $REDIS_PORT KEYS "policy:*" | wc -l)
- Customers: $(redis-cli -h $REDIS_HOST -p $REDIS_PORT KEYS "customer:*" | wc -l)
- Claims: $(redis-cli -h $REDIS_HOST -p $REDIS_PORT KEYS "claim:*" | wc -l)
