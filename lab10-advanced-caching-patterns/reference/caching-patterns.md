# Advanced Caching Patterns Reference

## 1. Cache-Aside Pattern

**Definition:** Application manages cache directly, falling back to data source on cache miss.

**Characteristics:**
- Manual cache management
- Cache miss triggers data source lookup
- Application controls cache lifecycle
- Suitable for read-heavy workloads

**Implementation:**
```javascript
async function cacheAside(key, dataSource, ttl = 300) {
    // Try cache first
    let data = await cache.get(key);
    if (data) return data;
    
    // Cache miss - fetch from source
    data = await dataSource();
    if (data) {
        await cache.set(key, data, ttl);
    }
    return data;
}
```

**Pros:**
- Simple to implement
- Application has full control
- Handles cache failures gracefully
- Works with any data source

**Cons:**
- Additional complexity in application code
- Potential for cache inconsistency
- Manual invalidation required

## 2. Write-Through Pattern

**Definition:** Data written to cache and data source simultaneously.

**Characteristics:**
- Synchronous writes to both cache and database
- Ensures cache-database consistency
- Higher write latency
- Suitable for write-heavy workloads requiring consistency

**Implementation:**
```javascript
async function writeThrough(key, data, ttl = 300) {
    // Write to database first
    await database.save(data);
    
    // Then write to cache
    await cache.set(key, data, ttl);
    
    return data;
}
```

**Pros:**
- Strong consistency
- No cache warm-up needed
- Simplified read operations

**Cons:**
- Higher write latency
- Cache writes may fail after DB writes
- Potential performance bottleneck

## 3. Write-Behind (Write-Back) Pattern

**Definition:** Data written to cache immediately, database updated asynchronously.

**Characteristics:**
- Fast write operations
- Eventual consistency
- Risk of data loss if cache fails
- Complex implementation

**Implementation:**
```javascript
async function writeBehind(key, data, ttl = 300) {
    // Write to cache immediately
    await cache.set(key, data, ttl);
    
    // Queue for async database write
    writeQueue.push({ key, data });
    
    return data;
}
```

**Pros:**
- Fast write performance
- Reduced database load
- Better user experience

**Cons:**
- Complex error handling
- Risk of data loss
- Eventual consistency only

## 4. Multi-Level Caching

**Definition:** Hierarchical caching with multiple cache layers.

**Architecture:**
```
Application → L1 (Memory) → L2 (Redis) → L3 (Database)
```

**Characteristics:**
- L1: Ultra-fast, small capacity (memory)
- L2: Fast, larger capacity (Redis)
- L3: Slow, unlimited capacity (database)

**Implementation Strategy:**
```javascript
class MultiLevelCache {
    async get(key) {
        // L1: Check memory cache
        if (memoryCache.has(key)) return memoryCache.get(key);
        
        // L2: Check Redis cache
        const redisData = await redis.get(key);
        if (redisData) {
            memoryCache.set(key, redisData);
            return redisData;
        }
        
        // L3: Fetch from database
        const dbData = await database.get(key);
        if (dbData) {
            await redis.set(key, dbData);
            memoryCache.set(key, dbData);
        }
        return dbData;
    }
}
```

## 5. Cache Invalidation Strategies

### Time-Based Invalidation (TTL)
```javascript
// Fixed TTL
await cache.setEx(key, 300, data); // 5 minutes

// Sliding TTL (refresh on access)
await cache.expire(key, 300);
```

### Event-Driven Invalidation
```javascript
// Invalidate on data changes
emitter.on('user:updated', async (userId) => {
    await cache.del(`user:${userId}`);
    await cache.del(`user:${userId}:profile`);
});
```

### Pattern-Based Invalidation
```javascript
// Invalidate multiple related keys
const keys = await cache.keys('user:*');
await cache.del(keys);
```

### Versioning Strategy
```javascript
// Version-based cache keys
const version = await cache.incr('user:version');
const key = `user:${userId}:v${version}`;
```

## 6. Cache Warming Strategies

### Eager Loading
```javascript
// Pre-populate cache with frequently accessed data
async function warmCache() {
    const popularItems = await database.getPopularItems();
    for (const item of popularItems) {
        await cache.set(`item:${item.id}`, item, 3600);
    }
}
```

### Lazy Loading with Prefetch
```javascript
// Load requested item + related items
async function getWithPrefetch(id) {
    const item = await cache.get(`item:${id}`);
    if (item) return item;
    
    // Cache miss - load and prefetch related
    const [mainItem, relatedItems] = await Promise.all([
        database.getItem(id),
        database.getRelatedItems(id)
    ]);
    
    // Cache main item
    await cache.set(`item:${id}`, mainItem, 1800);
    
    // Cache related items
    for (const related of relatedItems) {
        await cache.set(`item:${related.id}`, related, 1800);
    }
    
    return mainItem;
}
```

## 7. Cache Sizing and Memory Management

### Memory Usage Patterns
```javascript
// Monitor memory usage
const info = await redis.info('memory');
const memoryUsage = info.used_memory_human;
const maxMemory = info.maxmemory_human;
```

### Eviction Policies
- **LRU (Least Recently Used)**: Good for general purpose
- **LFU (Least Frequently Used)**: Good for workloads with distinct hot/cold data
- **TTL**: Remove expired keys first
- **Random**: Random eviction (fastest)

### Size Estimation
```javascript
// Estimate key size
const keySize = Buffer.byteLength(key, 'utf8');
const valueSize = Buffer.byteLength(JSON.stringify(value), 'utf8');
const totalSize = keySize + valueSize + 100; // 100 bytes overhead
```

## 8. Performance Optimization Techniques

### Connection Pooling
```javascript
const redis = require('redis');
const client = redis.createClient({
    socket: {
        reconnectStrategy: (retries) => Math.min(retries * 50, 500)
    },
    // Connection pooling handled automatically by node_redis v4+
});
```

### Pipelining
```javascript
// Batch multiple commands
const pipeline = redis.multi();
pipeline.set('key1', 'value1');
pipeline.set('key2', 'value2');
pipeline.get('key3');
const results = await pipeline.exec();
```

### Lua Scripts for Atomic Operations
```javascript
const luaScript = `
    local current = redis.call('GET', KEYS[1])
    if current == false then
        current = 0
    end
    local new_value = current + ARGV[1]
    redis.call('SET', KEYS[1], new_value)
    return new_value
`;

const result = await redis.eval(luaScript, {
    keys: ['counter'],
    arguments: ['1']
});
```

## 9. Monitoring and Metrics

### Key Metrics to Track
- **Hit Rate**: (hits / total_requests) × 100
- **Miss Rate**: (misses / total_requests) × 100
- **Latency**: Average response time
- **Throughput**: Requests per second
- **Memory Usage**: Cache memory consumption
- **Eviction Rate**: Keys evicted per time period

### Alerting Thresholds
- Hit rate < 80%
- Average latency > 50ms
- Memory usage > 90%
- Error rate > 1%

## 10. Common Anti-Patterns

### Cache Stampede
**Problem:** Multiple requests for same expired key hit database simultaneously.

**Solution:**
```javascript
const lockKey = `lock:${key}`;
const acquired = await redis.set(lockKey, '1', 'EX', 10, 'NX');

if (acquired) {
    // Only one thread loads data
    const data = await database.get(key);
    await cache.set(key, data, ttl);
    await redis.del(lockKey);
    return data;
} else {
    // Wait and retry
    await new Promise(resolve => setTimeout(resolve, 100));
    return await cache.get(key) || await database.get(key);
}
```

### Thundering Herd
**Problem:** Many requests wait for same slow operation.

**Solution:** Use probabilistic early expiration
```javascript
const jitter = Math.random() * 0.1; // 10% jitter
const earlyExpiry = ttl * (1 - jitter);
await cache.setEx(key, earlyExpiry, data);
```

### Hot Key Problem
**Problem:** Single key receives too much traffic.

**Solution:** Use multiple keys with hash distribution
```javascript
const hashSuffix = hash(requestId) % 10;
const distributedKey = `${key}:${hashSuffix}`;
```

## Best Practices Summary

1. **Choose the right pattern** for your use case
2. **Monitor cache performance** continuously
3. **Use appropriate TTL values** for different data types
4. **Implement proper error handling** for cache failures
5. **Consider data consistency** requirements
6. **Plan for cache warm-up** strategies
7. **Use compression** for large values
8. **Implement circuit breakers** for cache dependencies
9. **Test cache invalidation** scenarios thoroughly
10. **Document caching strategies** for your team
