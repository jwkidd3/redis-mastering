# Lab 10: Advanced Caching Patterns

**Duration:** 45 minutes  
**Objective:** Master advanced caching patterns using JavaScript Redis client for high-performance business applications

## 🎯 Learning Objectives

By the end of this lab, you will be able to:
- Implement cache-aside pattern for policy data optimization
- Build write-through caching for customer profile updates
- Create intelligent cache invalidation strategies for business entities
- Implement cache warming and preloading for frequently accessed data
- Design multi-tier caching architectures for complex business systems
- Monitor and optimize cache hit ratios for production workloads

---

## Part 1: Cache-Aside Pattern Implementation (15 minutes)

### Step 1: Environment Setup with Caching Infrastructure

```bash
# Start Redis with optimized caching configuration
docker run -d --name redis-cache-lab10 \
  -p 6379:6379 \
  redis:7-alpine redis-server \
  --maxmemory 1gb \
  --maxmemory-policy allkeys-lru \
  --lfu-log-factor 10 \
  --lfu-decay-time 1

# Verify Redis is running
redis-cli ping

# Initialize Node.js project
npm init -y
npm install redis dotenv express

# Load sample business data
./scripts/load-cache-demo-data.sh
```

### Step 2: Cache-Aside Pattern for Policy Data

Create `src/cache-aside-pattern.js`:

```javascript
const redis = require('redis');
const client = redis.createClient({ url: 'redis://localhost:6379' });

// Simulated database layer
class PolicyDatabase {
    constructor() {
        this.policies = new Map();
        this.queryDelay = 100; // Simulate database latency
        this.initSampleData();
    }

    initSampleData() {
        for (let i = 1; i <= 1000; i++) {
            this.policies.set(`POL${i.toString().padStart(6, '0')}`, {
                policyId: `POL${i.toString().padStart(6, '0')}`,
                type: ['AUTO', 'HOME', 'LIFE'][i % 3],
                premium: Math.floor(Math.random() * 2000) + 500,
                customer: `CUST${(i % 100).toString().padStart(3, '0')}`,
                status: ['ACTIVE', 'PENDING', 'EXPIRED'][i % 3],
                createdAt: new Date(Date.now() - Math.random() * 365 * 24 * 60 * 60 * 1000)
            });
        }
    }

    async getPolicy(policyId) {
        // Simulate database query delay
        await new Promise(resolve => setTimeout(resolve, this.queryDelay));
        return this.policies.get(policyId);
    }

    async updatePolicy(policyId, updates) {
        await new Promise(resolve => setTimeout(resolve, this.queryDelay));
        const policy = this.policies.get(policyId);
        if (policy) {
            Object.assign(policy, updates);
            this.policies.set(policyId, policy);
        }
        return policy;
    }
}

// Cache-Aside Pattern Implementation
class PolicyCacheService {
    constructor(redisClient, database) {
        this.redis = redisClient;
        this.db = database;
        this.cacheTTL = 3600; // 1 hour default TTL
        this.stats = {
            hits: 0,
            misses: 0,
            updates: 0
        };
    }

    async getPolicy(policyId) {
        const startTime = Date.now();
        const cacheKey = `cache:policy:${policyId}`;
        
        try {
            // Step 1: Check cache
            const cached = await this.redis.get(cacheKey);
            
            if (cached) {
                this.stats.hits++;
                console.log(`✅ Cache HIT for ${policyId} (${Date.now() - startTime}ms)`);
                return JSON.parse(cached);
            }
            
            // Step 2: Cache miss - fetch from database
            this.stats.misses++;
            console.log(`❌ Cache MISS for ${policyId} - fetching from database`);
            
            const policy = await this.db.getPolicy(policyId);
            
            if (policy) {
                // Step 3: Store in cache
                await this.redis.setex(
                    cacheKey,
                    this.cacheTTL,
                    JSON.stringify(policy)
                );
                console.log(`📝 Cached ${policyId} (total: ${Date.now() - startTime}ms)`);
            }
            
            return policy;
            
        } catch (error) {
            console.error('Cache error, falling back to database:', error);
            return await this.db.getPolicy(policyId);
        }
    }

    async updatePolicy(policyId, updates) {
        const cacheKey = `cache:policy:${policyId}`;
        
        // Update database
        const updatedPolicy = await this.db.updatePolicy(policyId, updates);
        
        if (updatedPolicy) {
            // Invalidate cache
            await this.redis.del(cacheKey);
            this.stats.updates++;
            console.log(`🔄 Cache invalidated for ${policyId} after update`);
        }
        
        return updatedPolicy;
    }

    getStats() {
        const total = this.stats.hits + this.stats.misses;
        const hitRate = total > 0 ? (this.stats.hits / total * 100).toFixed(2) : 0;
        return {
            ...this.stats,
            total,
            hitRate: `${hitRate}%`
        };
    }
}

// Test the cache-aside pattern
async function demonstrateCacheAside() {
    await client.connect();
    
    const db = new PolicyDatabase();
    const cacheService = new PolicyCacheService(client, db);
    
    console.log('\n🎯 Cache-Aside Pattern Demonstration\n');
    console.log('=' . repeat(50));
    
    // First access - cache miss
    console.log('\n📊 First Access (Cold Cache):');
    await cacheService.getPolicy('POL000001');
    
    // Second access - cache hit
    console.log('\n📊 Second Access (Warm Cache):');
    await cacheService.getPolicy('POL000001');
    
    // Multiple policy accesses
    console.log('\n📊 Batch Access Test:');
    const policies = ['POL000002', 'POL000003', 'POL000001', 'POL000002'];
    for (const policyId of policies) {
        await cacheService.getPolicy(policyId);
    }
    
    // Update and invalidation
    console.log('\n📊 Update and Invalidation:');
    await cacheService.updatePolicy('POL000001', { premium: 1500 });
    await cacheService.getPolicy('POL000001'); // Will fetch from DB
    
    // Display statistics
    console.log('\n📈 Cache Statistics:');
    console.log(cacheService.getStats());
    
    await client.quit();
}

// Run demonstration if executed directly
if (require.main === module) {
    demonstrateCacheAside().catch(console.error);
}

module.exports = { PolicyCacheService, PolicyDatabase };
```

Test the cache-aside pattern:

```bash
node src/cache-aside-pattern.js
```

---

## Part 2: Write-Through Caching Pattern (15 minutes)

### Step 3: Write-Through Cache for Customer Profiles

Create `src/write-through-pattern.js`:

```javascript
const redis = require('redis');
const client = redis.createClient({ url: 'redis://localhost:6379' });

// Write-Through Cache Implementation
class CustomerWriteThroughCache {
    constructor(redisClient) {
        this.redis = redisClient;
        this.cacheTTL = 7200; // 2 hours
        this.stats = {
            writes: 0,
            reads: 0,
            deletes: 0
        };
    }

    async saveCustomer(customerId, customerData) {
        const startTime = Date.now();
        const cacheKey = `cache:customer:${customerId}`;
        const dbKey = `db:customer:${customerId}`;
        
        try {
            // Write-through: Write to both cache and "database" simultaneously
            const pipeline = this.redis.pipeline();
            
            // Write to cache with TTL
            pipeline.setex(cacheKey, this.cacheTTL, JSON.stringify(customerData));
            
            // Write to persistent storage (simulated database)
            pipeline.set(dbKey, JSON.stringify(customerData));
            
            // Update indices for efficient queries
            pipeline.sadd(`idx:customer:status:${customerData.status}`, customerId);
            pipeline.zadd('idx:customer:by_value', customerData.totalValue, customerId);
            
            // Update metadata
            pipeline.hset('meta:customers', customerId, new Date().toISOString());
            
            await pipeline.exec();
            
            this.stats.writes++;
            console.log(`✅ Write-through completed for ${customerId} (${Date.now() - startTime}ms)`);
            
            return customerData;
            
        } catch (error) {
            console.error('Write-through error:', error);
            throw error;
        }
    }

    async getCustomer(customerId) {
        const startTime = Date.now();
        const cacheKey = `cache:customer:${customerId}`;
        const dbKey = `db:customer:${customerId}`;
        
        try {
            // Try cache first
            let customer = await this.redis.get(cacheKey);
            
            if (customer) {
                this.stats.reads++;
                console.log(`✅ Cache HIT for ${customerId} (${Date.now() - startTime}ms)`);
                return JSON.parse(customer);
            }
            
            // Fallback to database
            customer = await this.redis.get(dbKey);
            
            if (customer) {
                // Refresh cache
                await this.redis.setex(cacheKey, this.cacheTTL, customer);
                console.log(`📝 Cache refreshed for ${customerId} (${Date.now() - startTime}ms)`);
                this.stats.reads++;
                return JSON.parse(customer);
            }
            
            return null;
            
        } catch (error) {
            console.error('Read error:', error);
            throw error;
        }
    }

    async bulkImport(customers) {
        console.log(`\n📦 Bulk importing ${customers.length} customers...`);
        const startTime = Date.now();
        
        for (const customer of customers) {
            await this.saveCustomer(customer.id, customer);
        }
        
        console.log(`✅ Bulk import completed in ${Date.now() - startTime}ms`);
    }

    getStats() {
        return {
            ...this.stats,
            total: this.stats.writes + this.stats.reads + this.stats.deletes
        };
    }
}

// Test the write-through pattern
async function demonstrateWriteThrough() {
    await client.connect();
    
    const cache = new CustomerWriteThroughCache(client);
    
    console.log('\n🎯 Write-Through Pattern Demonstration\n');
    console.log('=' . repeat(50));
    
    // Sample customer data
    const customers = [
        {
            id: 'CUST001',
            name: 'John Smith',
            email: 'john.smith@email.com',
            status: 'PREMIUM',
            totalValue: 25000,
            policies: ['POL000001', 'POL000045', 'POL000089']
        },
        {
            id: 'CUST002',
            name: 'Jane Doe',
            email: 'jane.doe@email.com',
            status: 'STANDARD',
            totalValue: 12000,
            policies: ['POL000002', 'POL000067']
        },
        {
            id: 'CUST003',
            name: 'Bob Johnson',
            email: 'bob.johnson@email.com',
            status: 'PREMIUM',
            totalValue: 45000,
            policies: ['POL000003', 'POL000034', 'POL000078', 'POL000092']
        }
    ];
    
    // Bulk import with write-through
    await cache.bulkImport(customers);
    
    // Read customers
    console.log('\n📊 Reading Customers:');
    for (const cust of customers) {
        await cache.getCustomer(cust.id);
    }
    
    // Update a customer
    console.log('\n📊 Updating Customer:');
    customers[0].totalValue = 30000;
    await cache.saveCustomer(customers[0].id, customers[0]);
    
    // Read again to verify
    console.log('\n📊 Verification Read:');
    const updated = await cache.getCustomer('CUST001');
    console.log(`Customer CUST001 value: $${updated.totalValue}`);
    
    // Display statistics
    console.log('\n📈 Cache Statistics:');
    console.log(cache.getStats());
    
    await client.quit();
}

// Run demonstration if executed directly
if (require.main === module) {
    demonstrateWriteThrough().catch(console.error);
}

module.exports = { CustomerWriteThroughCache };
```

Test the write-through pattern:

```bash
node src/write-through-pattern.js
```

---

## Part 3: Advanced Cache Invalidation & Monitoring (15 minutes)

### Step 4: Intelligent Cache Invalidation Strategy

Create `src/cache-invalidation.js`:

```javascript
const redis = require('redis');
const client = redis.createClient({ url: 'redis://localhost:6379' });

// Advanced Cache Invalidation System
class CacheInvalidationManager {
    constructor(redisClient) {
        this.redis = redisClient;
        this.dependencies = new Map();
        this.stats = {
            invalidations: 0,
            cascades: 0,
            patterns: 0
        };
    }

    // Register cache dependencies
    async registerDependency(parentKey, dependentKeys) {
        const depKey = `dep:${parentKey}`;
        
        if (Array.isArray(dependentKeys)) {
            await this.redis.sadd(depKey, ...dependentKeys);
        } else {
            await this.redis.sadd(depKey, dependentKeys);
        }
        
        console.log(`📌 Registered dependencies for ${parentKey}`);
    }

    // Invalidate with cascade
    async invalidate(key, cascade = true) {
        const startTime = Date.now();
        const invalidated = new Set();
        
        // Queue for breadth-first traversal
        const queue = [key];
        
        while (queue.length > 0) {
            const currentKey = queue.shift();
            
            if (invalidated.has(currentKey)) continue;
            
            // Delete the key
            await this.redis.del(currentKey);
            invalidated.add(currentKey);
            this.stats.invalidations++;
            
            if (cascade) {
                // Find dependent keys
                const depKey = `dep:${currentKey}`;
                const dependents = await this.redis.smembers(depKey);
                
                if (dependents.length > 0) {
                    queue.push(...dependents);
                    this.stats.cascades++;
                    console.log(`🔄 Cascading invalidation from ${currentKey} to ${dependents.length} keys`);
                }
            }
        }
        
        console.log(`✅ Invalidated ${invalidated.size} keys in ${Date.now() - startTime}ms`);
        return Array.from(invalidated);
    }

    // Pattern-based invalidation
    async invalidatePattern(pattern) {
        const startTime = Date.now();
        let cursor = '0';
        let totalDeleted = 0;
        
        do {
            const result = await this.redis.scan(cursor, 'MATCH', pattern, 'COUNT', 100);
            cursor = result.cursor;
            const keys = result.keys;
            
            if (keys.length > 0) {
                await this.redis.del(...keys);
                totalDeleted += keys.length;
            }
        } while (cursor !== '0');
        
        this.stats.patterns++;
        console.log(`✅ Pattern invalidation deleted ${totalDeleted} keys matching "${pattern}" (${Date.now() - startTime}ms)`);
        
        return totalDeleted;
    }

    // Time-based invalidation
    async invalidateOlderThan(prefix, ageInSeconds) {
        const cutoffTime = Date.now() - (ageInSeconds * 1000);
        let cursor = '0';
        let totalDeleted = 0;
        
        do {
            const result = await this.redis.scan(cursor, 'MATCH', `${prefix}*`, 'COUNT', 100);
            cursor = result.cursor;
            
            for (const key of result.keys) {
                const ttl = await this.redis.ttl(key);
                const metadata = await this.redis.get(`meta:${key}`);
                
                if (metadata) {
                    const created = JSON.parse(metadata).created;
                    if (new Date(created).getTime() < cutoffTime) {
                        await this.redis.del(key);
                        totalDeleted++;
                    }
                }
            }
        } while (cursor !== '0');
        
        console.log(`✅ Time-based invalidation removed ${totalDeleted} keys older than ${ageInSeconds}s`);
        return totalDeleted;
    }

    getStats() {
        return this.stats;
    }
}

// Cache Monitoring System
class CacheMonitor {
    constructor(redisClient) {
        this.redis = redisClient;
        this.metrics = {
            hits: 0,
            misses: 0,
            evictions: 0,
            memoryUsage: 0
        };
    }

    async collectMetrics() {
        const info = await this.redis.info('stats');
        const memory = await this.redis.info('memory');
        
        // Parse Redis INFO output
        const stats = this.parseInfo(info);
        const memStats = this.parseInfo(memory);
        
        this.metrics = {
            hits: parseInt(stats.keyspace_hits || 0),
            misses: parseInt(stats.keyspace_misses || 0),
            evictions: parseInt(stats.evicted_keys || 0),
            memoryUsage: memStats.used_memory_human || '0B'
        };
        
        return this.metrics;
    }

    parseInfo(infoString) {
        const result = {};
        infoString.split('\\r\\n').forEach(line => {
            if (line && line.includes(':')) {
                const [key, value] = line.split(':');
                result[key] = value;
            }
        });
        return result;
    }

    async analyzeKeyDistribution() {
        const distribution = {
            cache: 0,
            db: 0,
            index: 0,
            meta: 0,
            other: 0
        };
        
        let cursor = '0';
        do {
            const result = await this.redis.scan(cursor, 'COUNT', 1000);
            cursor = result.cursor;
            
            for (const key of result.keys) {
                if (key.startsWith('cache:')) distribution.cache++;
                else if (key.startsWith('db:')) distribution.db++;
                else if (key.startsWith('idx:')) distribution.index++;
                else if (key.startsWith('meta:')) distribution.meta++;
                else distribution.other++;
            }
        } while (cursor !== '0');
        
        return distribution;
    }

    calculateHitRate() {
        const total = this.metrics.hits + this.metrics.misses;
        if (total === 0) return 0;
        return ((this.metrics.hits / total) * 100).toFixed(2);
    }

    async generateReport() {
        await this.collectMetrics();
        const distribution = await this.analyzeKeyDistribution();
        const hitRate = this.calculateHitRate();
        
        console.log('\n📊 Cache Performance Report');
        console.log('=' . repeat(50));
        console.log(`Hit Rate: ${hitRate}%`);
        console.log(`Total Hits: ${this.metrics.hits}`);
        console.log(`Total Misses: ${this.metrics.misses}`);
        console.log(`Evictions: ${this.metrics.evictions}`);
        console.log(`Memory Usage: ${this.metrics.memoryUsage}`);
        console.log('\n📈 Key Distribution:');
        console.log(`  Cache Keys: ${distribution.cache}`);
        console.log(`  Database Keys: ${distribution.db}`);
        console.log(`  Index Keys: ${distribution.index}`);
        console.log(`  Metadata Keys: ${distribution.meta}`);
        console.log(`  Other Keys: ${distribution.other}`);
        console.log('=' . repeat(50));
        
        return {
            hitRate,
            metrics: this.metrics,
            distribution
        };
    }
}

// Test invalidation and monitoring
async function demonstrateInvalidationAndMonitoring() {
    await client.connect();
    
    const invalidator = new CacheInvalidationManager(client);
    const monitor = new CacheMonitor(client);
    
    console.log('\n🎯 Cache Invalidation & Monitoring Demonstration\n');
    console.log('=' . repeat(50));
    
    // Setup test data
    console.log('\n📦 Setting up test data...');
    await client.set('cache:policy:POL001', JSON.stringify({ id: 'POL001', type: 'AUTO' }));
    await client.set('cache:policy:POL002', JSON.stringify({ id: 'POL002', type: 'HOME' }));
    await client.set('cache:customer:CUST001', JSON.stringify({ id: 'CUST001', name: 'John' }));
    await client.set('cache:quote:Q001', JSON.stringify({ id: 'Q001', amount: 1000 }));
    
    // Register dependencies
    console.log('\n📌 Registering dependencies...');
    await invalidator.registerDependency('cache:customer:CUST001', [
        'cache:policy:POL001',
        'cache:policy:POL002',
        'cache:quote:Q001'
    ]);
    
    // Test cascade invalidation
    console.log('\n🔄 Testing cascade invalidation...');
    await invalidator.invalidate('cache:customer:CUST001', true);
    
    // Test pattern invalidation
    console.log('\n🎯 Testing pattern invalidation...');
    await client.set('cache:temp:001', 'temp1');
    await client.set('cache:temp:002', 'temp2');
    await client.set('cache:temp:003', 'temp3');
    await invalidator.invalidatePattern('cache:temp:*');
    
    // Generate monitoring report
    console.log('\n📊 Generating monitoring report...');
    await monitor.generateReport();
    
    // Display invalidation statistics
    console.log('\n📈 Invalidation Statistics:');
    console.log(invalidator.getStats());
    
    await client.quit();
}

// Run demonstration if executed directly
if (require.main === module) {
    demonstrateInvalidationAndMonitoring().catch(console.error);
}

module.exports = { CacheInvalidationManager, CacheMonitor };
```

Test the invalidation and monitoring:

```bash
node src/cache-invalidation.js
```

### Step 5: Performance Testing and Optimization

Create `performance-tests/cache-benchmark.js`:

```javascript
const redis = require('redis');
const client = redis.createClient({ url: 'redis://localhost:6379' });

async function benchmarkCachePerformance() {
    await client.connect();
    
    console.log('\n⚡ Cache Performance Benchmark\n');
    console.log('=' . repeat(50));
    
    const iterations = 10000;
    const testData = JSON.stringify({
        id: 'TEST001',
        data: 'x'.repeat(1000) // 1KB payload
    });
    
    // Benchmark SET operations
    console.log(`\n🔧 Testing ${iterations} SET operations...`);
    const setStart = Date.now();
    
    for (let i = 0; i < iterations; i++) {
        await client.set(`bench:${i}`, testData, { EX: 60 });
    }
    
    const setTime = Date.now() - setStart;
    const setOpsPerSec = Math.floor(iterations / (setTime / 1000));
    console.log(`✅ SET: ${setTime}ms (${setOpsPerSec} ops/sec)`);
    
    // Benchmark GET operations
    console.log(`\n🔧 Testing ${iterations} GET operations...`);
    const getStart = Date.now();
    
    for (let i = 0; i < iterations; i++) {
        await client.get(`bench:${i}`);
    }
    
    const getTime = Date.now() - getStart;
    const getOpsPerSec = Math.floor(iterations / (getTime / 1000));
    console.log(`✅ GET: ${getTime}ms (${getOpsPerSec} ops/sec)`);
    
    // Benchmark Pipeline operations
    console.log(`\n🔧 Testing ${iterations} PIPELINE operations...`);
    const pipeStart = Date.now();
    
    const pipeline = client.pipeline();
    for (let i = 0; i < iterations; i++) {
        pipeline.get(`bench:${i}`);
    }
    await pipeline.exec();
    
    const pipeTime = Date.now() - pipeStart;
    const pipeOpsPerSec = Math.floor(iterations / (pipeTime / 1000));
    console.log(`✅ PIPELINE: ${pipeTime}ms (${pipeOpsPerSec} ops/sec)`);
    
    // Cleanup
    console.log('\n🧹 Cleaning up benchmark data...');
    const keys = [];
    for (let i = 0; i < iterations; i++) {
        keys.push(`bench:${i}`);
    }
    await client.del(...keys);
    
    // Summary
    console.log('\n📊 Performance Summary:');
    console.log('=' . repeat(50));
    console.log(`SET Operations: ${setOpsPerSec} ops/sec`);
    console.log(`GET Operations: ${getOpsPerSec} ops/sec`);
    console.log(`Pipeline Operations: ${pipeOpsPerSec} ops/sec`);
    console.log(`Pipeline Speedup: ${(pipeOpsPerSec / getOpsPerSec).toFixed(2)}x`);
    
    await client.quit();
}

// Run benchmark if executed directly
if (require.main === module) {
    benchmarkCachePerformance().catch(console.error);
}
```

Run the performance benchmark:

```bash
node performance-tests/cache-benchmark.js
```

---

## 🎉 Lab Summary

Congratulations! You've mastered advanced caching patterns including:

✅ **Cache-Aside Pattern**: Lazy loading with database fallback  
✅ **Write-Through Pattern**: Synchronous cache and database updates  
✅ **Cache Invalidation**: Cascade, pattern, and time-based strategies  
✅ **Cache Monitoring**: Hit rates, memory usage, and key distribution  
✅ **Performance Optimization**: Pipeline operations and benchmarking  

### Key Takeaways

1. **Cache-Aside** is ideal for read-heavy workloads with occasional updates
2. **Write-Through** ensures consistency but may impact write performance  
3. **Intelligent invalidation** prevents stale data while minimizing cache misses
4. **Monitoring** is essential for maintaining optimal cache performance
5. **Pipeline operations** can significantly improve throughput for batch operations

### Production Best Practices

- Always implement fallback mechanisms for cache failures
- Monitor cache hit rates and adjust TTL values accordingly
- Use appropriate eviction policies based on access patterns
- Implement cache warming for critical data
- Regular performance benchmarking ensures optimal configuration

### Next Steps

- Implement cache clustering for high availability
- Explore Redis Cluster for horizontal scaling
- Add cache encryption for sensitive data
- Integrate with APM tools for production monitoring
