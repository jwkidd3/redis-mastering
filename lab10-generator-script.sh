#!/bin/bash

# Lab 10 Content Generator Script
# Generates complete content and code for Lab 10: Advanced Caching Patterns
# Duration: 45 minutes
# Focus: JavaScript caching strategies, cache-aside, write-through, and cache invalidation

set -e

LAB_DIR="lab10-advanced-caching-patterns"
LAB_NUMBER="10"
LAB_TITLE="Advanced Caching Patterns"
LAB_DURATION="45"

echo "🚀 Generating Lab ${LAB_NUMBER}: ${LAB_TITLE}"
echo "📅 Duration: ${LAB_DURATION} minutes"
echo "🎯 Focus: JavaScript caching strategies, cache-aside, write-through, and cache invalidation"
echo ""

# Create lab directory structure
mkdir -p ${LAB_DIR}
cd ${LAB_DIR}

echo "📁 Creating lab directory structure..."
mkdir -p {src,scripts,docs,examples,cache-strategies,performance-tests,monitoring}

# Create main lab instructions markdown file
echo "📋 Creating lab10.md..."
cat > lab10.md << 'EOF'
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
EOF

# Create load-cache-demo-data.sh script
echo "📝 Creating scripts/load-cache-demo-data.sh..."
mkdir -p scripts
cat > scripts/load-cache-demo-data.sh << 'EOF'
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
EOF

chmod +x scripts/load-cache-demo-data.sh

# Create package.json
echo "📝 Creating package.json..."
cat > package.json << 'EOF'
{
  "name": "lab10-advanced-caching-patterns",
  "version": "1.0.0",
  "description": "Advanced caching patterns with Redis and JavaScript",
  "main": "src/cache-aside-pattern.js",
  "scripts": {
    "start": "node src/cache-aside-pattern.js",
    "cache-aside": "node src/cache-aside-pattern.js",
    "write-through": "node src/write-through-pattern.js",
    "invalidation": "node src/cache-invalidation.js",
    "benchmark": "node performance-tests/cache-benchmark.js",
    "test": "npm run cache-aside && npm run write-through && npm run invalidation && npm run benchmark"
  },
  "keywords": [
    "redis",
    "cache",
    "caching-patterns",
    "performance"
  ],
  "author": "",
  "license": "MIT",
  "dependencies": {
    "redis": "^4.6.5",
    "dotenv": "^16.0.3",
    "express": "^4.18.2"
  }
}
EOF

# Create comprehensive README
echo "📚 Creating README.md..."
cat > README.md << 'EOF'
# Lab 10: Advanced Caching Patterns

**Duration:** 45 minutes  
**Focus:** JavaScript caching strategies, cache-aside, write-through, and cache invalidation  
**Technology:** Redis, Node.js, JavaScript

## 📁 Project Structure

```
lab10-advanced-caching-patterns/
├── lab10.md                            # Complete lab instructions (START HERE)
├── src/
│   ├── cache-aside-pattern.js          # Cache-aside pattern implementation
│   ├── write-through-pattern.js        # Write-through caching strategy
│   └── cache-invalidation.js           # Advanced invalidation and monitoring
├── scripts/
│   └── load-cache-demo-data.sh         # Sample data loader
├── performance-tests/
│   └── cache-benchmark.js              # Performance benchmarking tool
├── package.json                        # Node.js project configuration
└── README.md                           # This file
```

## 🚀 Quick Start

1. **Start Redis:**
   ```bash
   docker run -d --name redis-cache-lab10 -p 6379:6379 redis:7-alpine
   ```

2. **Install Dependencies:**
   ```bash
   npm install
   ```

3. **Load Sample Data:**
   ```bash
   ./scripts/load-cache-demo-data.sh
   ```

4. **Run Lab Exercises:**
   ```bash
   npm run cache-aside      # Part 1: Cache-Aside Pattern
   npm run write-through    # Part 2: Write-Through Pattern
   npm run invalidation     # Part 3: Invalidation & Monitoring
   npm run benchmark        # Performance Testing
   ```

## 🎯 Learning Objectives

By completing this lab, you will:

1. **Master Cache-Aside Pattern** - Implement lazy loading with fallback strategies
2. **Implement Write-Through Caching** - Ensure data consistency across cache and database
3. **Design Invalidation Strategies** - Build cascade, pattern, and time-based invalidation
4. **Monitor Cache Performance** - Track hit rates, memory usage, and optimize configuration
5. **Benchmark Cache Operations** - Measure and improve cache throughput

## 📊 Key Concepts

### Cache-Aside Pattern
- Application manages cache population
- Load data on cache miss
- Ideal for read-heavy workloads
- Manual invalidation required

### Write-Through Pattern
- Synchronous writes to cache and database
- Ensures data consistency
- Higher write latency
- Automatic cache population

### Cache Invalidation
- **Cascade**: Dependencies trigger related invalidations
- **Pattern**: Wildcard-based key removal
- **Time-based**: Age-based expiration
- **Event-driven**: Application-triggered updates

## 🔧 Available Scripts

- `npm start` - Run cache-aside demonstration
- `npm test` - Run all demonstrations in sequence
- `npm run benchmark` - Execute performance tests

## 📈 Performance Metrics

The lab includes comprehensive performance monitoring:
- Cache hit/miss rates
- Operation throughput (ops/sec)
- Memory usage tracking
- Key distribution analysis
- Pipeline optimization metrics

## 🚨 Troubleshooting

If you encounter issues:

1. **Redis Connection Error:**
   ```bash
   docker ps  # Verify container is running
   redis-cli ping  # Test connectivity
   ```

2. **Module Not Found:**
   ```bash
   npm install  # Reinstall dependencies
   ```

3. **Permission Denied:**
   ```bash
   chmod +x scripts/*.sh  # Make scripts executable
   ```

## 💡 Best Practices

1. **Choose the Right Pattern**: Consider read/write ratio and consistency requirements
2. **Set Appropriate TTLs**: Balance freshness with cache efficiency
3. **Monitor Continuously**: Track metrics to identify optimization opportunities
4. **Handle Failures Gracefully**: Always implement fallback mechanisms
5. **Optimize for Your Workload**: Adjust configuration based on access patterns

## 🎉 Completion

After completing this lab, you will have:
- Implemented three major caching patterns
- Built a cache monitoring system
- Created performance benchmarking tools
- Learned production-ready caching strategies

Continue to Lab 11 for session management and security patterns!
EOF

# Create examples directory with additional examples
echo "📝 Creating examples/advanced-patterns.md..."
mkdir -p examples
cat > examples/advanced-patterns.md << 'EOF'
# Advanced Caching Pattern Examples

## 1. Cache Warming Strategy

```javascript
async function warmCache(keys) {
    console.log(`🔥 Warming cache with ${keys.length} keys...`);
    const pipeline = redis.pipeline();
    
    for (const key of keys) {
        pipeline.get(`db:${key}`);
    }
    
    const results = await pipeline.exec();
    
    for (let i = 0; i < keys.length; i++) {
        if (results[i][1]) {
            await redis.setex(`cache:${keys[i]}`, 3600, results[i][1]);
        }
    }
}
```

## 2. Multi-Tier Caching

```javascript
class MultiTierCache {
    constructor() {
        this.l1 = new Map(); // In-memory
        this.l2 = redis; // Redis
        this.l3 = database; // Database
    }
    
    async get(key) {
        // Check L1
        if (this.l1.has(key)) {
            return this.l1.get(key);
        }
        
        // Check L2
        const l2Value = await this.l2.get(key);
        if (l2Value) {
            this.l1.set(key, l2Value);
            return l2Value;
        }
        
        // Check L3
        const l3Value = await this.l3.get(key);
        if (l3Value) {
            await this.l2.setex(key, 3600, l3Value);
            this.l1.set(key, l3Value);
            return l3Value;
        }
        
        return null;
    }
}
```

## 3. Probabilistic Cache Refresh

```javascript
async function getWithProbabilisticRefresh(key, ttl) {
    const value = await redis.get(key);
    const remaining = await redis.ttl(key);
    
    // Probabilistic early expiration
    const beta = 1.0;
    const now = Date.now() / 1000;
    const expiry = now + remaining;
    const random = Math.random();
    
    const xfetch = beta * Math.log(random) * -1;
    
    if (now - xfetch >= expiry) {
        // Refresh cache before actual expiration
        const fresh = await fetchFromDatabase(key);
        await redis.setex(key, ttl, fresh);
        return fresh;
    }
    
    return value;
}
```

## 4. Lazy Deletion Pattern

```javascript
async function lazyDelete(pattern) {
    const stream = redis.scanStream({
        match: pattern,
        count: 100
    });
    
    stream.on('data', async (keys) => {
        if (keys.length) {
            const pipeline = redis.pipeline();
            keys.forEach(key => {
                pipeline.expire(key, 1); // Mark for deletion
            });
            await pipeline.exec();
        }
    });
}
```

## 5. Cache Stampede Prevention

```javascript
async function getWithStampedeProtection(key, fetchFn) {
    const lockKey = `lock:${key}`;
    const value = await redis.get(key);
    
    if (value) return JSON.parse(value);
    
    // Try to acquire lock
    const lockAcquired = await redis.set(lockKey, '1', 'NX', 'EX', 10);
    
    if (lockAcquired) {
        try {
            const fresh = await fetchFn();
            await redis.setex(key, 3600, JSON.stringify(fresh));
            return fresh;
        } finally {
            await redis.del(lockKey);
        }
    } else {
        // Wait for other process to populate cache
        await new Promise(r => setTimeout(r, 100));
        return getWithStampedeProtection(key, fetchFn);
    }
}
```
EOF

# Create monitoring dashboard
echo "📝 Creating monitoring/cache-dashboard.js..."
mkdir -p monitoring
cat > monitoring/cache-dashboard.js << 'EOF'
const redis = require('redis');
const client = redis.createClient({ url: 'redis://localhost:6379' });

async function displayDashboard() {
    await client.connect();
    
    console.clear();
    console.log('📊 Redis Cache Dashboard');
    console.log('=' . repeat(60));
    
    setInterval(async () => {
        const info = await client.info('all');
        const stats = parseRedisInfo(info);
        
        console.clear();
        console.log('📊 Redis Cache Dashboard - ' + new Date().toISOString());
        console.log('=' . repeat(60));
        
        // Performance Metrics
        console.log('\n⚡ Performance Metrics:');
        console.log(`  Hit Rate: ${calculateHitRate(stats)}%`);
        console.log(`  Commands/sec: ${stats.instantaneous_ops_per_sec || 0}`);
        console.log(`  Network In: ${stats.instantaneous_input_kbps || 0} KB/s`);
        console.log(`  Network Out: ${stats.instantaneous_output_kbps || 0} KB/s`);
        
        // Memory Metrics
        console.log('\n💾 Memory Metrics:');
        console.log(`  Used Memory: ${stats.used_memory_human || '0B'}`);
        console.log(`  Peak Memory: ${stats.used_memory_peak_human || '0B'}`);
        console.log(`  Evicted Keys: ${stats.evicted_keys || 0}`);
        console.log(`  Memory Fragmentation: ${stats.mem_fragmentation_ratio || 0}`);
        
        // Key Statistics
        const dbSize = await client.dbSize();
        console.log('\n🔑 Key Statistics:');
        console.log(`  Total Keys: ${dbSize}`);
        console.log(`  Expired Keys: ${stats.expired_keys || 0}`);
        
        console.log('\n[Press Ctrl+C to exit]');
        
    }, 2000);
}

function parseRedisInfo(info) {
    const stats = {};
    info.split('\r\n').forEach(line => {
        if (line && line.includes(':')) {
            const [key, value] = line.split(':');
            stats[key] = value;
        }
    });
    return stats;
}

function calculateHitRate(stats) {
    const hits = parseInt(stats.keyspace_hits || 0);
    const misses = parseInt(stats.keyspace_misses || 0);
    const total = hits + misses;
    if (total === 0) return 0;
    return ((hits / total) * 100).toFixed(2);
}

if (require.main === module) {
    displayDashboard().catch(console.error);
}
EOF

# Create .gitignore
cat > .gitignore << 'EOF'
# Dependencies
node_modules/
package-lock.json

# Logs
*.log
npm-debug.log*

# Runtime data
pids
*.pid
*.seed
*.pid.lock

# Environment variables
.env
.env.local

# OS files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# IDE files
.vscode/
.idea/
*.swp
*.swo

# Test output
coverage/
.nyc_output/
test-results/
performance-results/

# Temporary files
*.tmp
*.temp
tmp/
temp/
EOF

echo ""
echo "📂 Project structure created:"
echo "   ${LAB_DIR}/"
echo "   ├── lab10.md                            📋 START HERE - Complete lab guide"
echo "   ├── src/"
echo "   │   ├── cache-aside-pattern.js          💾 Cache-aside implementation"
echo "   │   ├── write-through-pattern.js        ✍️ Write-through caching"
echo "   │   └── cache-invalidation.js           🔄 Invalidation strategies"
echo "   ├── scripts/"
echo "   │   └── load-cache-demo-data.sh         📊 Sample data loader"
echo "   ├── performance-tests/"
echo "   │   └── cache-benchmark.js              ⚡ Performance benchmarking"
echo "   ├── monitoring/"
echo "   │   └── cache-dashboard.js              📊 Real-time dashboard"
echo "   ├── examples/"
echo "   │   └── advanced-patterns.md            📚 Additional pattern examples"
echo "   ├── package.json                        📦 Node.js configuration"
echo "   ├── README.md                           📖 Project documentation"
echo "   └── .gitignore                          🚫 Git ignore rules"
echo ""
echo "🎯 NEXT STEPS:"
echo "   1. cd ${LAB_DIR}"
echo "   2. code .                               # Open in VS Code"
echo "   3. docker run -d --name redis-cache-lab10 -p 6379:6379 redis:7-alpine"
echo "   4. npm install                          # Install dependencies"
echo "   5. ./scripts/load-cache-demo-data.sh   # Load sample data"
echo "   6. npm run cache-aside                  # Start first exercise"
echo ""
echo "🔧 JAVASCRIPT CACHING FOCUS:"
echo "   💾 Cache-Aside Pattern: Lazy loading with database fallback"
echo "   ✍️ Write-Through Pattern: Synchronous cache and database updates"
echo "   🔄 Cache Invalidation: Cascade, pattern, and time-based strategies"
echo "   📊 Cache Monitoring: Hit rates, memory usage, and optimization"
echo "   ⚡ Performance Testing: Benchmarking and pipeline optimization"
echo ""
echo "💡 KEY CONCEPTS:"
echo "   • Choose patterns based on read/write ratios"
echo "   • Monitor cache performance continuously"
echo "   • Implement proper invalidation strategies"
echo "   • Handle failures with graceful fallbacks"
echo "   • Optimize for your specific workload"
echo ""
echo "🎉 READY TO START LAB 10!"
echo "   Master advanced caching patterns with JavaScript and Redis!"
