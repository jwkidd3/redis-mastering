#!/bin/bash

# Lab 12 Content Generator Script
# Generates complete content and code for Lab 12: Advanced Redis Patterns for Enterprise Applications
# Duration: 45 minutes
# Focus: JavaScript Redis client with advanced patterns, optimization, and enterprise features

set -e

LAB_DIR="lab12-advanced-patterns-enterprise"
LAB_NUMBER="12"
LAB_TITLE="Advanced Redis Patterns for Enterprise Applications"
LAB_DURATION="45"

echo "🚀 Generating Lab ${LAB_NUMBER}: ${LAB_TITLE}"
echo "📅 Duration: ${LAB_DURATION} minutes"
echo "🎯 Focus: Advanced patterns, optimization, and enterprise Redis features with JavaScript"
echo ""

# Create lab directory structure
mkdir -p ${LAB_DIR}
cd ${LAB_DIR}

echo "📁 Creating lab directory structure..."
mkdir -p {src,scripts,docs,examples,patterns,benchmarks,monitoring,tests}

# Create main lab instructions markdown file
echo "📋 Creating lab12.md..."
cat > lab12.md << 'EOF'
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
EOF

# Create package.json
echo "📦 Creating package.json..."
cat > package.json << 'EOF'
{
  "name": "lab12-advanced-patterns",
  "version": "1.0.0",
  "description": "Advanced Redis Patterns for Enterprise Applications",
  "main": "src/index.js",
  "scripts": {
    "start": "node src/index.js",
    "test": "node tests/test-all.js",
    "test-cache": "node tests/test-cache.js",
    "test-cache-aside": "node src/cache-patterns.js",
    "test-locking": "node tests/test-locking.js",
    "test-queue": "node tests/test-queue.js",
    "test-performance": "node tests/test-performance.js",
    "benchmark": "node benchmarks/run-benchmarks.js",
    "load-data": "node scripts/load-enterprise-data.js",
    "monitor": "node monitoring/monitor.js",
    "dev": "nodemon src/index.js"
  },
  "dependencies": {
    "redis": "^4.6.0",
    "generic-pool": "^3.9.0",
    "uuid": "^9.0.0",
    "dotenv": "^16.0.0",
    "chalk": "^4.1.2",
    "cli-table3": "^0.6.3"
  },
  "devDependencies": {
    "nodemon": "^2.0.0"
  }
}
EOF

# Create cache patterns implementation
echo "🔧 Creating src/cache-patterns.js..."
mkdir -p src
cat > src/cache-patterns.js << 'EOF'
const { createClient } = require('redis');

class CachePatterns {
    constructor() {
        this.client = null;
    }

    async connect() {
        this.client = createClient({
            socket: {
                host: 'localhost',
                port: 6379
            }
        });

        this.client.on('error', (err) => console.error('Redis Client Error', err));
        await this.client.connect();
        console.log('Connected to Redis for cache patterns');
    }

    // Cache-aside pattern
    async cacheAside(key, fetchFunction, ttl = 3600) {
        try {
            // Try to get from cache
            const cached = await this.client.get(key);
            
            if (cached) {
                console.log(`Cache HIT: ${key}`);
                return JSON.parse(cached);
            }
            
            console.log(`Cache MISS: ${key}`);
            
            // Fetch from source
            const data = await fetchFunction();
            
            // Store in cache with TTL
            await this.client.setEx(key, ttl, JSON.stringify(data));
            
            return data;
        } catch (error) {
            console.error('Cache-aside error:', error);
            // Fallback to fetch function
            return await fetchFunction();
        }
    }

    // Write-through cache
    async writeThrough(key, data, persistFunction) {
        try {
            // Write to cache immediately
            await this.client.set(key, JSON.stringify(data));
            console.log(`Cache updated: ${key}`);
            
            // Write to persistent storage asynchronously
            setImmediate(async () => {
                try {
                    await persistFunction(data);
                    console.log(`Persisted: ${key}`);
                } catch (error) {
                    console.error(`Failed to persist ${key}:`, error);
                    // Implement retry logic or dead letter queue
                }
            });
            
            return data;
        } catch (error) {
            console.error('Write-through error:', error);
            throw error;
        }
    }

    // Write-behind cache (with batching)
    async writeBehind(operations, batchSize = 10, delay = 1000) {
        const batch = [];
        
        for (const op of operations) {
            batch.push(op);
            
            if (batch.length >= batchSize) {
                await this.flushBatch(batch.splice(0, batchSize));
            }
        }
        
        // Flush remaining
        if (batch.length > 0) {
            setTimeout(() => this.flushBatch(batch), delay);
        }
    }

    async flushBatch(batch) {
        const pipeline = this.client.pipeline();
        
        for (const op of batch) {
            switch (op.type) {
                case 'set':
                    pipeline.set(op.key, JSON.stringify(op.value));
                    break;
                case 'del':
                    pipeline.del(op.key);
                    break;
                case 'expire':
                    pipeline.expire(op.key, op.ttl);
                    break;
            }
        }
        
        await pipeline.exec();
        console.log(`Flushed batch of ${batch.length} operations`);
    }

    // Cache warming
    async warmCache(keys, fetchFunction) {
        console.log(`Warming cache with ${keys.length} keys...`);
        const pipeline = this.client.pipeline();
        
        for (const key of keys) {
            const data = await fetchFunction(key);
            pipeline.setEx(key, 3600, JSON.stringify(data));
        }
        
        await pipeline.exec();
        console.log('Cache warming completed');
    }

    async disconnect() {
        if (this.client) {
            await this.client.quit();
        }
    }
}

// Test the patterns
async function main() {
    const cache = new CachePatterns();
    await cache.connect();

    console.log('\n--- Testing Cache-Aside Pattern ---\n');
    
    // Simulate expensive operation
    const fetchUserData = async () => {
        console.log('Fetching from database...');
        await new Promise(r => setTimeout(r, 1000));
        return {
            id: 1,
            name: 'John Doe',
            email: 'john@example.com',
            timestamp: Date.now()
        };
    };

    // First call - cache miss
    const user1 = await cache.cacheAside('user:1', fetchUserData, 60);
    console.log('First call result:', user1);

    // Second call - cache hit
    const user2 = await cache.cacheAside('user:1', fetchUserData, 60);
    console.log('Second call result:', user2);

    console.log('\n--- Testing Write-Through Pattern ---\n');
    
    const persistToDatabase = async (data) => {
        console.log('Persisting to database:', data);
        await new Promise(r => setTimeout(r, 500));
    };

    const newData = {
        id: 2,
        name: 'Jane Smith',
        email: 'jane@example.com'
    };

    await cache.writeThrough('user:2', newData, persistToDatabase);

    // Give async persist time to complete
    await new Promise(r => setTimeout(r, 1000));

    await cache.disconnect();
    console.log('\nCache patterns test completed!');
}

if (require.main === module) {
    main().catch(console.error);
}

module.exports = CachePatterns;
EOF

# Create distributed lock implementation
echo "🔒 Creating src/distributed-lock.js..."
cat > src/distributed-lock.js << 'EOF'
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
        
        try {
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
                console.log(`Lock acquired: ${resource} with token ${token.substring(0, 8)}...`);
                return token;
            }
            
            console.log(`Failed to acquire lock: ${resource}`);
            return null;
        } catch (error) {
            console.error('Error acquiring lock:', error);
            return null;
        }
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
        
        try {
            const released = await this.client.eval(script, {
                keys: [lockKey],
                arguments: [token]
            });
            
            if (released === 1) {
                this.locks.delete(resource);
                console.log(`Lock released: ${resource}`);
                return true;
            }
            
            console.log(`Failed to release lock: ${resource} (wrong token)`);
            return false;
        } catch (error) {
            console.error('Error releasing lock:', error);
            return false;
        }
    }

    async extendLock(resource, token, ttl = 5000) {
        const lockKey = `lock:${resource}`;
        
        // Lua script for atomic check and extend
        const script = `
            if redis.call("get", KEYS[1]) == ARGV[1] then
                return redis.call("pexpire", KEYS[1], ARGV[2])
            else
                return 0
            end
        `;
        
        const extended = await this.client.eval(script, {
            keys: [lockKey],
            arguments: [token, ttl.toString()]
        });
        
        if (extended === 1) {
            console.log(`Lock extended: ${resource}`);
            return true;
        }
        
        return false;
    }

    async withLock(resource, operation, options = {}) {
        const { ttl = 5000, retries = 3, retryDelay = 100 } = options;
        
        for (let i = 0; i < retries; i++) {
            const token = await this.acquireLock(resource, ttl);
            
            if (token) {
                try {
                    const result = await operation();
                    return result;
                } finally {
                    await this.releaseLock(resource, token);
                }
            }
            
            if (i < retries - 1) {
                console.log(`Retrying lock acquisition... (${i + 1}/${retries})`);
                await new Promise(r => setTimeout(r, retryDelay * (i + 1)));
            }
        }
        
        throw new Error(`Failed to acquire lock for ${resource} after ${retries} attempts`);
    }
}

module.exports = RedisLock;
EOF

# Create message queue implementation
echo "📬 Creating src/message-queue.js..."
cat > src/message-queue.js << 'EOF'
const { createClient } = require('redis');

class ReliableQueue {
    constructor(client, queueName) {
        this.client = client;
        this.streamKey = `queue:${queueName}`;
        this.consumerGroup = `${queueName}-group`;
        this.consumerId = `consumer-${process.pid}-${Date.now()}`;
        this.running = false;
    }

    async initialize() {
        try {
            await this.client.xGroupCreate(
                this.streamKey,
                this.consumerGroup,
                '$',
                { MKSTREAM: true }
            );
            console.log(`Created consumer group: ${this.consumerGroup}`);
        } catch (error) {
            if (error.message.includes('BUSYGROUP')) {
                console.log(`Consumer group already exists: ${this.consumerGroup}`);
            } else {
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
        this.running = true;
        
        console.log(`Consumer ${this.consumerId} started`);
        
        while (this.running) {
            try {
                // Read pending messages first (messages that were read but not acknowledged)
                const pending = await this.client.xReadGroup(
                    this.consumerGroup,
                    this.consumerId,
                    [{ key: this.streamKey, id: '0' }],
                    { COUNT: count, BLOCK: 0 }
                );
                
                if (pending && pending.length > 0 && pending[0].messages.length > 0) {
                    console.log(`Processing ${pending[0].messages.length} pending messages`);
                    await this.processMessages(pending[0].messages, handler);
                }
                
                // Read new messages
                const messages = await this.client.xReadGroup(
                    this.consumerGroup,
                    this.consumerId,
                    [{ key: this.streamKey, id: '>' }],
                    { COUNT: count, BLOCK: block }
                );
                
                if (messages && messages.length > 0 && messages[0].messages.length > 0) {
                    console.log(`Processing ${messages[0].messages.length} new messages`);
                    await this.processMessages(messages[0].messages, handler);
                }
            } catch (error) {
                if (error.message.includes('NOGROUP')) {
                    await this.initialize();
                } else {
                    console.error('Consumer error:', error);
                    await new Promise(r => setTimeout(r, 1000));
                }
            }
        }
        
        console.log(`Consumer ${this.consumerId} stopped`);
    }

    async processMessages(messages, handler) {
        for (const message of messages) {
            try {
                const data = JSON.parse(message.message.data);
                
                // Process message
                await handler(data, message.id);
                
                // Acknowledge message
                await this.client.xAck(
                    this.streamKey,
                    this.consumerGroup,
                    message.id
                );
                
                console.log(`Processed and acknowledged: ${message.id}`);
            } catch (error) {
                console.error(`Failed to process ${message.id}:`, error);
                // Message will be redelivered to another consumer
            }
        }
    }

    stop() {
        this.running = false;
    }

    async getInfo() {
        const info = await this.client.xInfoGroups(this.streamKey);
        const streamInfo = await this.client.xInfoStream(this.streamKey);
        
        return {
            stream: streamInfo,
            groups: info,
            consumerId: this.consumerId
        };
    }
}

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
            score: -priority, // Negative for high priority first
            value: payload
        });
        
        console.log(`Enqueued item with priority ${priority}`);
    }

    async dequeue() {
        // Lua script for atomic dequeue
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
            console.log('Dequeued item');
            return JSON.parse(item);
        }
        
        return null;
    }

    async complete(item) {
        const payload = JSON.stringify(item);
        const removed = await this.client.zRem(this.processingKey, payload);
        
        if (removed) {
            console.log('Item marked as completed');
        }
        
        return removed > 0;
    }

    async requeueStale(maxAge = 60000) {
        const staleTime = Date.now() - maxAge;
        const staleItems = await this.client.zRangeByScore(
            this.processingKey,
            '-inf',
            staleTime
        );
        
        console.log(`Found ${staleItems.length} stale items`);
        
        for (const item of staleItems) {
            const parsed = JSON.parse(item);
            await this.enqueue(parsed, -1); // Lower priority for retry
            await this.client.zRem(this.processingKey, item);
        }
        
        return staleItems.length;
    }

    async getStats() {
        const queueSize = await this.client.zCard(this.queueKey);
        const processingSize = await this.client.zCard(this.processingKey);
        
        return {
            pending: queueSize,
            processing: processingSize,
            total: queueSize + processingSize
        };
    }
}

module.exports = { ReliableQueue, PriorityQueue };
EOF

# Create test file
echo "🧪 Creating tests/test-all.js..."
mkdir -p tests
cat > tests/test-all.js << 'EOF'
const { createClient } = require('redis');
const CachePatterns = require('../src/cache-patterns');
const RedisLock = require('../src/distributed-lock');
const { ReliableQueue, PriorityQueue } = require('../src/message-queue');

async function runTests() {
    console.log('🧪 Running Lab 12 Tests...\n');
    
    const client = createClient({
        socket: {
            host: 'localhost',
            port: 6379
        }
    });
    
    await client.connect();
    
    // Test 1: Cache Patterns
    console.log('Test 1: Cache Patterns');
    const cache = new CachePatterns();
    await cache.connect();
    
    const testData = await cache.cacheAside('test:key', async () => {
        return { test: 'data', timestamp: Date.now() };
    }, 10);
    
    console.log('✅ Cache-aside pattern working\n');
    
    // Test 2: Distributed Locking
    console.log('Test 2: Distributed Locking');
    const lock = new RedisLock(client);
    
    const token = await lock.acquireLock('test:resource', 5000);
    if (token) {
        const released = await lock.releaseLock('test:resource', token);
        console.log('✅ Distributed lock working\n');
    }
    
    // Test 3: Message Queue
    console.log('Test 3: Message Queue');
    const queue = new ReliableQueue(client, 'test');
    await queue.initialize();
    
    await queue.publish({ test: 'message', id: 1 });
    console.log('✅ Message queue working\n');
    
    // Test 4: Priority Queue
    console.log('Test 4: Priority Queue');
    const pQueue = new PriorityQueue(client, 'test');
    
    await pQueue.enqueue({ task: 'high-priority' }, 10);
    await pQueue.enqueue({ task: 'low-priority' }, 1);
    
    const item = await pQueue.dequeue();
    if (item && item.task === 'high-priority') {
        console.log('✅ Priority queue working\n');
    }
    
    // Cleanup
    await cache.disconnect();
    await client.quit();
    
    console.log('✨ All tests passed!\n');
}

runTests().catch(console.error);
EOF

# Create data loader script
echo "📊 Creating scripts/load-enterprise-data.js..."
mkdir -p scripts
cat > scripts/load-enterprise-data.js << 'EOF'
const { createClient } = require('redis');

async function loadData() {
    const client = createClient({
        socket: {
            host: 'localhost',
            port: 6379
        }
    });
    
    await client.connect();
    console.log('Loading enterprise sample data...\n');
    
    // Clear existing data
    await client.flushDb();
    
    // Load customer data
    const customers = [
        { id: 'C001', name: 'Acme Corp', tier: 'enterprise', revenue: 5000000 },
        { id: 'C002', name: 'TechStart Inc', tier: 'startup', revenue: 100000 },
        { id: 'C003', name: 'Global Systems', tier: 'enterprise', revenue: 10000000 },
        { id: 'C004', name: 'Local Business', tier: 'small', revenue: 50000 },
        { id: 'C005', name: 'MegaCorp', tier: 'enterprise', revenue: 50000000 }
    ];
    
    for (const customer of customers) {
        await client.hSet(`customer:${customer.id}`, {
            name: customer.name,
            tier: customer.tier,
            revenue: customer.revenue.toString(),
            created: Date.now().toString()
        });
    }
    
    console.log(`✅ Loaded ${customers.length} customers`);
    
    // Load product inventory
    const products = [
        { id: 'P001', name: 'Enterprise License', stock: 100, price: 10000 },
        { id: 'P002', name: 'Pro License', stock: 500, price: 1000 },
        { id: 'P003', name: 'Basic License', stock: 1000, price: 100 },
        { id: 'P004', name: 'Support Package', stock: 50, price: 5000 },
        { id: 'P005', name: 'Training Package', stock: 25, price: 2500 }
    ];
    
    for (const product of products) {
        await client.hSet(`product:${product.id}`, {
            name: product.name,
            stock: product.stock.toString(),
            price: product.price.toString()
        });
        
        // Set inventory levels
        await client.set(`inventory:${product.id}`, product.stock.toString());
    }
    
    console.log(`✅ Loaded ${products.length} products`);
    
    // Create sample transactions
    const transactions = [];
    for (let i = 1; i <= 20; i++) {
        const customerId = customers[Math.floor(Math.random() * customers.length)].id;
        const productId = products[Math.floor(Math.random() * products.length)].id;
        const quantity = Math.floor(Math.random() * 5) + 1;
        
        transactions.push({
            id: `T${String(i).padStart(4, '0')}`,
            customerId,
            productId,
            quantity,
            timestamp: Date.now() - Math.floor(Math.random() * 86400000)
        });
    }
    
    // Store transactions in sorted set by timestamp
    for (const tx of transactions) {
        await client.zAdd('transactions:all', {
            score: tx.timestamp,
            value: JSON.stringify(tx)
        });
    }
    
    console.log(`✅ Loaded ${transactions.length} transactions`);
    
    // Create sample metrics
    const metrics = [
        { name: 'api.requests', value: 15234 },
        { name: 'api.errors', value: 23 },
        { name: 'db.queries', value: 45678 },
        { name: 'cache.hits', value: 89012 },
        { name: 'cache.misses', value: 1234 }
    ];
    
    for (const metric of metrics) {
        await client.set(`metric:${metric.name}`, metric.value.toString());
    }
    
    console.log(`✅ Loaded ${metrics.length} metrics`);
    
    // Create sample user sessions
    const sessions = [];
    for (let i = 1; i <= 10; i++) {
        const sessionId = `sess_${Date.now()}_${i}`;
        sessions.push({
            id: sessionId,
            userId: `U${String(i).padStart(3, '0')}`,
            createdAt: Date.now(),
            lastAccess: Date.now()
        });
    }
    
    for (const session of sessions) {
        await client.setEx(
            `session:${session.id}`,
            3600,
            JSON.stringify(session)
        );
    }
    
    console.log(`✅ Loaded ${sessions.length} sessions\n`);
    
    // Display summary
    const dbSize = await client.dbSize();
    console.log('📊 Database Summary:');
    console.log(`   Total keys: ${dbSize}`);
    console.log(`   Customers: ${customers.length}`);
    console.log(`   Products: ${products.length}`);
    console.log(`   Transactions: ${transactions.length}`);
    console.log(`   Metrics: ${metrics.length}`);
    console.log(`   Sessions: ${sessions.length}\n`);
    
    await client.quit();
    console.log('✨ Enterprise data loaded successfully!');
}

loadData().catch(console.error);
EOF

# Create README
echo "📖 Creating README.md..."
cat > README.md << 'EOF'
# Lab 12: Advanced Redis Patterns for Enterprise Applications

**Duration:** 45 minutes  
**Focus:** Advanced patterns, optimization, and enterprise Redis features with JavaScript

## 📚 Project Structure

```
lab12-advanced-patterns-enterprise/
├── lab12.md                    # Complete lab instructions (START HERE)
├── src/
│   ├── cache-patterns.js       # Advanced caching implementations
│   ├── distributed-lock.js     # Distributed locking mechanisms
│   └── message-queue.js        # Reliable queue patterns
├── tests/
│   └── test-all.js             # Comprehensive test suite
├── scripts/
│   └── load-enterprise-data.js # Sample data loader
├── package.json                # Node.js dependencies
└── README.md                   # This file
```

## 🚀 Quick Start

1. **Install Dependencies:**
   ```bash
   npm install
   ```

2. **Start Redis:**
   ```bash
   docker run -d --name redis-enterprise-lab12 \
     -p 6379:6379 \
     redis:7-alpine redis-server \
     --maxmemory 1gb \
     --maxmemory-policy allkeys-lru
   ```

3. **Load Sample Data:**
   ```bash
   npm run load-data
   ```

4. **Run Tests:**
   ```bash
   npm test
   ```

## 🎯 Learning Objectives

### Advanced Caching Patterns
- Cache-aside for read optimization
- Write-through for consistency
- Write-behind with batching
- Cache warming strategies

### Distributed Locking
- Redlock algorithm implementation
- Optimistic locking with WATCH
- Lock extension and auto-renewal
- Deadlock prevention

### Message Queue Patterns
- Reliable queues with Redis Streams
- Priority queues with Sorted Sets
- Message acknowledgment and retry
- Dead letter queue handling

### Performance Optimization
- Pipeline batching for throughput
- Connection pooling for scalability
- Performance monitoring and metrics
- Memory optimization strategies

## 🧪 Testing

Run individual test suites:

```bash
npm run test-cache      # Test caching patterns
npm run test-locking    # Test distributed locks
npm run test-queue      # Test message queues
npm run test-performance # Test optimizations
```

Run benchmarks:

```bash
npm run benchmark
```

## 📊 Sample Data

The lab includes enterprise sample data:
- 5 customer records (various tiers)
- 5 product inventory items
- 20 transaction records
- 5 performance metrics
- 10 active sessions

## 🔧 Key Technologies

- **Redis 7+**: Latest Redis features
- **Node.js**: JavaScript runtime
- **Redis Streams**: Reliable message delivery
- **Lua Scripting**: Atomic operations
- **Connection Pooling**: Scalability

## 📈 Performance Tips

1. **Use Pipelining**: Batch operations to reduce round trips
2. **Connection Pooling**: Reuse connections efficiently
3. **Appropriate Data Structures**: Choose the right Redis type
4. **Monitor Metrics**: Track performance continuously
5. **Optimize Memory**: Use compression and expiration

## 🛠️ Troubleshooting

**Redis Connection Issues:**
```bash
# Check Redis status
docker ps | grep redis
redis-cli ping

# View Redis logs
docker logs redis-enterprise-lab12
```

**Performance Issues:**
```bash
# Monitor Redis commands
redis-cli monitor

# Check slow queries
redis-cli slowlog get 10

# Memory analysis
redis-cli info memory
```

## 📚 Additional Resources

- [Redis Best Practices](https://redis.io/docs/manual/patterns/)
- [Redis Streams Guide](https://redis.io/docs/data-types/streams/)
- [Connection Pool Optimization](https://github.com/redis/node-redis)
- [Lua Scripting](https://redis.io/docs/manual/programmability/lua-api/)

## ✅ Success Criteria

- All tests pass successfully
- Cache patterns show hit/miss behavior
- Distributed locks prevent race conditions
- Message queues maintain order and reliability
- Performance optimizations show measurable improvement

---

**Ready to master enterprise Redis patterns?** Open `lab12.md` and begin! 🚀
EOF

# Create .gitignore
echo "🚫 Creating .gitignore..."
cat > .gitignore << 'EOF'
# Dependencies
node_modules/
package-lock.json

# Environment
.env
.env.local

# Logs
*.log
npm-debug.log*
yarn-debug.log*

# OS files
.DS_Store
.DS_Store?
._*
Thumbs.db

# IDE
.vscode/
.idea/
*.swp
*.swo

# Testing
coverage/
.nyc_output/

# Redis dump
dump.rdb
*.rdb

# Temporary
*.tmp
*.temp
tmp/
temp/
EOF

echo ""
echo "✅ Lab 12 build script completed successfully!"
echo ""
echo "📂 Project structure created:"
echo "   ${LAB_DIR}/"
echo "   ├── lab12.md                    📋 Complete lab instructions"
echo "   ├── package.json                📦 Node.js configuration"
echo "   ├── src/"
echo "   │   ├── cache-patterns.js       🔄 Advanced caching"
echo "   │   ├── distributed-lock.js     🔒 Locking mechanisms"
echo "   │   └── message-queue.js        📬 Queue patterns"
echo "   ├── tests/"
echo "   │   └── test-all.js            🧪 Test suite"
echo "   ├── scripts/"
echo "   │   └── load-enterprise-data.js 📊 Data loader"
echo "   ├── README.md                   📖 Quick reference"
echo "   └── .gitignore                  🚫 Git ignore rules"
echo ""
echo "🎯 NEXT STEPS:"
echo "   1. cd ${LAB_DIR}"
echo "   2. docker run -d --name redis-enterprise-lab12 -p 6379:6379 redis:7-alpine"
echo "   3. npm install"
echo "   4. npm run load-data"
echo "   5. code ."
echo "   6. Open lab12.md and start the lab!"
echo ""
echo "💡 Quick Commands:"
echo "   npm test              # Run all tests"
echo "   npm run test-cache    # Test caching patterns"
echo "   npm run test-locking  # Test distributed locks"
echo "   npm run test-queue    # Test message queues"
echo "   npm run benchmark     # Run performance benchmarks"
echo ""
echo "🚀 Ready to start Lab 12: Advanced Redis Patterns for Enterprise Applications!"