# Lab 12: Advanced Redis Patterns for Enterprise Applications

**Duration:** 45 minutes  
**Objective:** Master advanced Redis patterns, optimization techniques, and enterprise features using JavaScript

## 🎯 Learning Objectives

By the end of this lab, you will be able to:
- Implement advanced caching strategies with cache-aside and write-through patterns
- Build distributed locking mechanisms for concurrent operations
- Create message queue patterns with reliable delivery guarantees
- Implement data sharding and partitioning strategies
- Apply Redis Cluster concepts for high availability
- Optimize performance with pipelining and connection pooling

---

## Part 1: Advanced Caching Patterns (15 minutes)

### Step 1: Environment Setup with Advanced Configuration

```bash
# Start Redis with advanced configuration
docker run -d --name redis-enterprise-lab12 \
  -p 6379:6379 \
  redis:7-alpine redis-server \
  --maxmemory 1gb \
  --maxmemory-policy allkeys-lru \
  --save 60 1000 \
  --rdbcompression yes \
  --activerehashing yes \
  --lazyfree-lazy-eviction yes \
  --lazyfree-lazy-expire yes
```

### Step 2: Install Dependencies and Initialize Project

```bash
# Install project dependencies
npm install

# Verify Redis connection
npm test

# Load sample enterprise data
npm run load-data
```

### Step 3: Implement Cache-Aside Pattern

Open `src/cache-patterns.js` in VS Code and examine the implementation:

```javascript
// Cache-aside pattern with automatic refresh
async function cacheAside(key, fetchFunction, ttl = 3600) {
    // Try to get from cache
    let data = await redis.get(key);
    
    if (data) {
        console.log(`Cache HIT: ${key}`);
        return JSON.parse(data);
    }
    
    console.log(`Cache MISS: ${key}`);
    // Fetch from source
    data = await fetchFunction();
    
    // Store in cache with TTL
    await redis.setex(key, ttl, JSON.stringify(data));
    
    return data;
}
```

**Test the cache-aside pattern:**
```bash
npm run test-cache-aside
```

### Step 4: Implement Write-Through Cache

```javascript
// Write-through cache pattern
async function writeThrough(key, data, persistFunction) {
    // Write to cache immediately
    await redis.set(key, JSON.stringify(data));
    
    // Write to persistent storage asynchronously
    setImmediate(async () => {
        try {
            await persistFunction(data);
            console.log(`Persisted: ${key}`);
        } catch (error) {
            console.error(`Failed to persist ${key}:`, error);
            // Implement retry logic here
        }
    });
    
    return data;
}
```

---

## Part 2: Distributed Locking & Concurrency (15 minutes)

### Step 5: Implement Redlock Algorithm

Open `src/distributed-lock.js`:

```javascript
const { createClient } = require('redis');
const crypto = require('crypto');

class RedisLock {
    constructor(client) {
        this.client = client;
        this.locks = new Map();
    }

    async acquireLock(resource, ttl = 5000) {
        const token = crypto.randomBytes(16).toString('hex');
        const lockKey = `lock:${resource}`;
        
        // Try to acquire lock with NX (only if not exists)
        const acquired = await this.client.set(
            lockKey,
            token,
            {
                NX: true,
                PX: ttl
            }
        );
        
        if (acquired) {
            this.locks.set(resource, { token, timer: null });
            console.log(`Lock acquired: ${resource}`);
            return token;
        }
        
        return null;
    }

    async releaseLock(resource, token) {
        const lockKey = `lock:${resource}`;
        
        // Lua script for atomic check and delete
        const script = `
            if redis.call("get", KEYS[1]) == ARGV[1] then
                return redis.call("del", KEYS[1])
            else
                return 0
            end
        `;
        
        const released = await this.client.eval(
            script,
            {
                keys: [lockKey],
                arguments: [token]
            }
        );
        
        if (released) {
            this.locks.delete(resource);
            console.log(`Lock released: ${resource}`);
        }
        
        return released === 1;
    }
}
```

**Test distributed locking:**
```bash
npm run test-locking
```

### Step 6: Implement Optimistic Locking with WATCH

```javascript
// Optimistic locking for inventory management
async function updateInventory(productId, quantity) {
    const key = `inventory:${productId}`;
    const maxRetries = 3;
    
    for (let i = 0; i < maxRetries; i++) {
        try {
            // Watch the key for changes
            await redis.watch(key);
            
            // Get current inventory
            const current = parseInt(await redis.get(key) || '0');
            
            if (current < quantity) {
                await redis.unwatch();
                throw new Error('Insufficient inventory');
            }
            
            // Start transaction
            const multi = redis.multi();
            multi.decrby(key, quantity);
            multi.lpush(`inventory:log:${productId}`, 
                JSON.stringify({
                    action: 'decrement',
                    quantity,
                    timestamp: Date.now()
                })
            );
            
            // Execute transaction
            const result = await multi.exec();
            
            if (result) {
                console.log(`Inventory updated: ${productId} -= ${quantity}`);
                return true;
            }
            
            // Transaction failed due to watched key change
            console.log(`Retry ${i + 1}: Inventory changed during transaction`);
        } catch (error) {
            console.error('Inventory update error:', error);
            throw error;
        }
    }
    
    throw new Error('Failed to update inventory after retries');
}
```

---

## Part 3: Message Queue Patterns (15 minutes)

### Step 7: Implement Reliable Queue with Streams

Open `src/message-queue.js`:

```javascript
class ReliableQueue {
    constructor(client, queueName) {
        this.client = client;
        this.streamKey = `queue:${queueName}`;
        this.consumerGroup = `${queueName}-group`;
        this.consumerId = `consumer-${process.pid}`;
    }

    async initialize() {
        try {
            await this.client.xGroupCreate(
                this.streamKey,
                this.consumerGroup,
                '$',
                { MKSTREAM: true }
            );
        } catch (error) {
            // Group already exists
            if (!error.message.includes('BUSYGROUP')) {
                throw error;
            }
        }
    }

    async publish(message) {
        const messageId = await this.client.xAdd(
            this.streamKey,
            '*',
            {
                data: JSON.stringify(message),
                timestamp: Date.now().toString()
            }
        );
        
        console.log(`Published message: ${messageId}`);
        return messageId;
    }

    async consume(handler, options = {}) {
        const { count = 10, block = 1000 } = options;
        
        while (true) {
            try {
                // Read pending messages first
                const pending = await this.client.xReadGroup(
                    this.consumerGroup,
                    this.consumerId,
                    [{ key: this.streamKey, id: '0' }],
                    { COUNT: count }
                );
                
                if (pending && pending.length > 0) {
                    await this.processMessages(pending[0].messages, handler);
                }
                
                // Read new messages
                const messages = await this.client.xReadGroup(
                    this.consumerGroup,
                    this.consumerId,
                    [{ key: this.streamKey, id: '>' }],
                    { COUNT: count, BLOCK: block }
                );
                
                if (messages && messages.length > 0) {
                    await this.processMessages(messages[0].messages, handler);
                }
            } catch (error) {
                console.error('Consumer error:', error);
                await new Promise(r => setTimeout(r, 1000));
            }
        }
    }

    async processMessages(messages, handler) {
        for (const message of messages) {
            try {
                const data = JSON.parse(message.message.data);
                await handler(data, message.id);
                
                // Acknowledge message
                await this.client.xAck(
                    this.streamKey,
                    this.consumerGroup,
                    message.id
                );
                
                console.log(`Processed: ${message.id}`);
            } catch (error) {
                console.error(`Failed to process ${message.id}:`, error);
                // Message will be redelivered
            }
        }
    }
}
```

**Test message queue:**
```bash
npm run test-queue
```

### Step 8: Implement Priority Queue with Sorted Sets

```javascript
class PriorityQueue {
    constructor(client, queueName) {
        this.client = client;
        this.queueKey = `priority:${queueName}`;
        this.processingKey = `${this.queueKey}:processing`;
    }

    async enqueue(item, priority = 0) {
        const payload = JSON.stringify({
            ...item,
            enqueuedAt: Date.now()
        });
        
        await this.client.zAdd(this.queueKey, {
            score: priority,
            value: payload
        });
        
        console.log(`Enqueued with priority ${priority}`);
    }

    async dequeue() {
        // Move item to processing set atomically
        const script = `
            local item = redis.call('zrange', KEYS[1], 0, 0)[1]
            if item then
                redis.call('zrem', KEYS[1], item)
                redis.call('zadd', KEYS[2], ARGV[1], item)
                return item
            end
            return nil
        `;
        
        const item = await this.client.eval(script, {
            keys: [this.queueKey, this.processingKey],
            arguments: [Date.now().toString()]
        });
        
        if (item) {
            return JSON.parse(item);
        }
        
        return null;
    }

    async complete(item) {
        const payload = JSON.stringify(item);
        await this.client.zRem(this.processingKey, payload);
        console.log('Item completed and removed from processing');
    }

    async requeueStale(maxAge = 60000) {
        const staleTime = Date.now() - maxAge;
        const staleItems = await this.client.zRangeByScore(
            this.processingKey,
            '-inf',
            staleTime
        );
        
        for (const item of staleItems) {
            const parsed = JSON.parse(item);
            await this.enqueue(parsed, -1); // Lower priority for retry
            await this.client.zRem(this.processingKey, item);
            console.log('Requeued stale item');
        }
        
        return staleItems.length;
    }
}
```

---

## Part 4: Performance Optimization & Monitoring (15 minutes)

### Step 9: Implement Pipeline Optimization

```javascript
// Batch operations with pipelining
async function batchUpdateMetrics(metrics) {
    const pipeline = redis.pipeline();
    const timestamp = Date.now();
    
    for (const [key, value] of Object.entries(metrics)) {
        // Update counter
        pipeline.incrBy(`metric:${key}:count`, value.count || 1);
        
        // Update sum
        pipeline.incrByFloat(`metric:${key}:sum`, value.value || 0);
        
        // Add to time series
        pipeline.zAdd(`metric:${key}:series`, {
            score: timestamp,
            value: JSON.stringify(value)
        });
        
        // Trim old data (keep last 1000 points)
        pipeline.zRemRangeByRank(`metric:${key}:series`, 0, -1001);
        
        // Update last seen
        pipeline.set(`metric:${key}:last`, timestamp);
    }
    
    // Execute all commands in one round trip
    const results = await pipeline.exec();
    console.log(`Batch updated ${results.length} operations`);
    
    return results;
}
```

### Step 10: Connection Pool Management

```javascript
const { createPool } = require('generic-pool');

// Create connection pool
const redisPool = createPool({
    create: async () => {
        const client = createClient({
            socket: {
                host: 'localhost',
                port: 6379,
                reconnectStrategy: (retries) => Math.min(retries * 100, 3000)
            }
        });
        
        await client.connect();
        console.log('Pool connection created');
        return client;
    },
    destroy: async (client) => {
        await client.quit();
        console.log('Pool connection destroyed');
    },
    validate: async (client) => {
        try {
            await client.ping();
            return true;
        } catch {
            return false;
        }
    }
}, {
    min: 2,
    max: 10,
    acquireTimeoutMillis: 3000,
    idleTimeoutMillis: 30000,
    evictionRunIntervalMillis: 1000
});

// Use pool for operations
async function executeWithPool(operation) {
    const client = await redisPool.acquire();
    try {
        return await operation(client);
    } finally {
        await redisPool.release(client);
    }
}
```

### Step 11: Performance Monitoring

```javascript
class PerformanceMonitor {
    constructor(client) {
        this.client = client;
        this.metrics = new Map();
    }

    async monitorOperation(name, operation) {
        const start = process.hrtime.bigint();
        
        try {
            const result = await operation();
            const duration = Number(process.hrtime.bigint() - start) / 1e6; // ms
            
            await this.recordMetric(name, {
                success: true,
                duration,
                timestamp: Date.now()
            });
            
            return result;
        } catch (error) {
            const duration = Number(process.hrtime.bigint() - start) / 1e6;
            
            await this.recordMetric(name, {
                success: false,
                duration,
                error: error.message,
                timestamp: Date.now()
            });
            
            throw error;
        }
    }

    async recordMetric(name, metric) {
        // Store in sorted set for time series
        await this.client.zAdd(`perf:${name}`, {
            score: metric.timestamp,
            value: JSON.stringify(metric)
        });
        
        // Update aggregates
        const pipeline = this.client.pipeline();
        
        if (metric.success) {
            pipeline.incr(`perf:${name}:success`);
            pipeline.incrByFloat(`perf:${name}:duration:sum`, metric.duration);
            pipeline.incr(`perf:${name}:duration:count`);
            
            // Update percentiles (simplified)
            pipeline.zAdd(`perf:${name}:durations`, {
                score: metric.duration,
                value: metric.timestamp.toString()
            });
        } else {
            pipeline.incr(`perf:${name}:failure`);
        }
        
        await pipeline.exec();
    }

    async getStats(name, window = 3600000) {
        const now = Date.now();
        const start = now - window;
        
        // Get time series data
        const data = await this.client.zRangeByScore(
            `perf:${name}`,
            start,
            now,
            { WITHSCORES: true }
        );
        
        // Calculate statistics
        const metrics = data.map(d => JSON.parse(d.value));
        const durations = metrics
            .filter(m => m.success)
            .map(m => m.duration);
        
        if (durations.length === 0) {
            return { error: 'No data available' };
        }
        
        durations.sort((a, b) => a - b);
        
        return {
            count: durations.length,
            min: durations[0],
            max: durations[durations.length - 1],
            avg: durations.reduce((a, b) => a + b, 0) / durations.length,
            p50: durations[Math.floor(durations.length * 0.5)],
            p95: durations[Math.floor(durations.length * 0.95)],
            p99: durations[Math.floor(durations.length * 0.99)],
            errors: metrics.filter(m => !m.success).length
        };
    }
}
```

---

## Lab Verification

Run the complete test suite to verify all implementations:

```bash
# Run all tests
npm test

# Run specific pattern tests
npm run test-cache
npm run test-locking
npm run test-queue
npm run test-performance

# Run benchmark
npm run benchmark
```

Expected output:
```
✓ Cache-aside pattern working correctly
✓ Write-through cache operational
✓ Distributed lock acquired and released
✓ Optimistic locking successful
✓ Message queue publishing and consuming
✓ Priority queue ordering maintained
✓ Pipeline optimization showing improvement
✓ Connection pool managing resources
✓ Performance monitoring collecting metrics

All tests passed! Lab completed successfully.
```

---

## Summary

In this lab, you've mastered:

1. **Advanced Caching Patterns**
   - Cache-aside for read optimization
   - Write-through for consistency
   - Cache invalidation strategies

2. **Distributed Locking**
   - Redlock algorithm implementation
   - Optimistic locking with WATCH
   - Deadlock prevention

3. **Message Queue Patterns**
   - Reliable queues with Streams
   - Priority queues with Sorted Sets
   - Message acknowledgment and retry

4. **Performance Optimization**
   - Pipeline batching
   - Connection pooling
   - Performance monitoring

## Next Steps

1. **Implement Redis Cluster**: Set up multi-node configuration
2. **Add Geo-spatial Features**: Location-based queries
3. **Build Real-time Analytics**: Stream processing pipelines
4. **Create Backup Strategy**: RDB/AOF persistence patterns
5. **Implement Circuit Breaker**: Fault tolerance patterns

## Additional Resources

- Redis Best Practices Guide
- Redis Cluster Tutorial
- Redis Streams Documentation
- Connection Pool Optimization
- Performance Tuning Guide

---

**Congratulations!** You've completed the advanced Redis patterns lab and are ready to build enterprise-scale applications! 🎉
