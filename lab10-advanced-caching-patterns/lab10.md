# Lab 10: Advanced Caching Patterns

**Duration:** 45 minutes  
**Objective:** Implement sophisticated multi-level caching strategies and performance optimization

## 🎯 Learning Objectives

By the end of this lab, you will be able to:
- Implement cache-aside and write-through patterns
- Build multi-level caching architectures
- Create intelligent cache invalidation strategies
- Optimize cache performance with TTL strategies
- Monitor and measure cache effectiveness
- Handle cache stampede and thundering herd problems

---

## Prerequisites

- Completed Labs 1-9
- Node.js and Redis CLI installed
- Redis server connection details from instructor
- Visual Studio Code ready
- Basic understanding of Redis data structures

---

## Part 1: Environment Setup (5 minutes)

### Step 1: Create Project Structure

```bash
# Create project directory
mkdir lab10-caching
cd lab10-caching

# Initialize Node.js project
npm init -y

# Install dependencies
npm install redis express dotenv helmet morgan
```

### Step 2: Environment Configuration

Create `.env` file:
```bash
# Redis Configuration (get from instructor)
REDIS_HOST=redis-server.training.com
REDIS_PORT=6379
REDIS_PASSWORD=

# Application Configuration
PORT=3000
NODE_ENV=development

# Cache Configuration
DEFAULT_TTL=300
QUOTE_CACHE_TTL=600
POLICY_CACHE_TTL=1800
```

### Step 3: Basic Connection Setup

Create `src/redis-client.js`:
```javascript
const redis = require('redis');
require('dotenv').config();

class RedisClient {
    constructor() {
        this.client = redis.createClient({
            socket: {
                host: process.env.REDIS_HOST,
                port: parseInt(process.env.REDIS_PORT)
            },
            password: process.env.REDIS_PASSWORD || undefined
        });

        this.client.on('error', (err) => {
            console.error('Redis Client Error:', err);
        });

        this.client.on('connect', () => {
            console.log('✅ Connected to Redis server');
        });
    }

    async connect() {
        if (!this.client.isOpen) {
            await this.client.connect();
        }
        return this.client;
    }

    async disconnect() {
        if (this.client.isOpen) {
            await this.client.disconnect();
        }
    }

    getClient() {
        return this.client;
    }
}

module.exports = new RedisClient();
```

### Step 4: Test Connection

Create `test-connection.js`:
```javascript
const redisClient = require('./src/redis-client');

async function testConnection() {
    try {
        await redisClient.connect();
        const client = redisClient.getClient();
        
        const result = await client.ping();
        console.log('🏓 PING result:', result);
        
        await client.set('lab10:test', 'Advanced Caching Lab');
        const value = await client.get('lab10:test');
        console.log('📝 Test value:', value);
        
        await redisClient.disconnect();
        console.log('✅ Connection test successful');
    } catch (error) {
        console.error('❌ Connection test failed:', error);
    }
}

testConnection();
```

Run test:
```bash
node test-connection.js
```

---

## Part 2: Cache-Aside Pattern Implementation (12 minutes)

### Step 1: Basic Cache-Aside Pattern

Create `src/cache-aside.js`:
```javascript
const redisClient = require('./redis-client');

class CacheAside {
    constructor() {
        this.client = null;
    }

    async init() {
        await redisClient.connect();
        this.client = redisClient.getClient();
    }

    // Cache-aside pattern: Read
    async get(key, dataSource, ttl = 300) {
        try {
            // Try cache first
            const cached = await this.client.get(key);
            if (cached) {
                console.log(`🎯 Cache HIT: ${key}`);
                return JSON.parse(cached);
            }

            // Cache miss - fetch from data source
            console.log(`❌ Cache MISS: ${key}`);
            const data = await dataSource();
            
            if (data) {
                // Store in cache for future requests
                await this.client.setEx(key, ttl, JSON.stringify(data));
                console.log(`💾 Cached: ${key} (TTL: ${ttl}s)`);
            }

            return data;
        } catch (error) {
            console.error('Cache-aside get error:', error);
            // Fallback to data source on cache error
            return await dataSource();
        }
    }

    // Cache-aside pattern: Write
    async set(key, data, ttl = 300) {
        try {
            await this.client.setEx(key, ttl, JSON.stringify(data));
            console.log(`💾 Cache SET: ${key}`);
        } catch (error) {
            console.error('Cache-aside set error:', error);
        }
    }

    // Invalidate cache entry
    async invalidate(key) {
        try {
            await this.client.del(key);
            console.log(`🗑️ Cache INVALIDATED: ${key}`);
        } catch (error) {
            console.error('Cache invalidation error:', error);
        }
    }

    // Invalidate multiple keys by pattern
    async invalidatePattern(pattern) {
        try {
            const keys = await this.client.keys(pattern);
            if (keys.length > 0) {
                await this.client.del(keys);
                console.log(`🗑️ Cache INVALIDATED ${keys.length} keys: ${pattern}`);
            }
        } catch (error) {
            console.error('Pattern invalidation error:', error);
        }
    }
}

module.exports = CacheAside;
```

### Step 2: Mock Data Sources

Create `src/data-sources.js`:
```javascript
// Simulate database/API calls with delays

class DataSources {
    // Simulate policy lookup (slow database query)
    static async getPolicyById(policyId) {
        console.log(`🔍 Fetching policy ${policyId} from database...`);
        
        // Simulate database delay
        await new Promise(resolve => setTimeout(resolve, 100));
        
        return {
            id: policyId,
            number: `POL-${policyId}`,
            holder: `Customer ${policyId}`,
            type: 'Auto',
            premium: 1200 + (policyId % 500),
            deductible: 500,
            coverage: {
                liability: 100000,
                collision: 50000,
                comprehensive: 25000
            },
            effectiveDate: '2024-01-01',
            expirationDate: '2025-01-01',
            lastUpdated: new Date().toISOString()
        };
    }

    // Simulate customer profile lookup
    static async getCustomerById(customerId) {
        console.log(`👤 Fetching customer ${customerId} from database...`);
        
        await new Promise(resolve => setTimeout(resolve, 80));
        
        return {
            id: customerId,
            name: `Customer ${customerId}`,
            email: `customer${customerId}@example.com`,
            phone: `555-${customerId.toString().padStart(4, '0')}`,
            address: {
                street: `${customerId} Main St`,
                city: 'Anytown',
                state: 'TX',
                zip: '12345'
            },
            riskScore: Math.floor(Math.random() * 100),
            policies: [`POL-${customerId}`, `POL-${customerId + 1000}`],
            lastLogin: new Date().toISOString()
        };
    }

    // Simulate quote calculation (expensive operation)
    static async calculateQuote(quoteRequest) {
        console.log(`💰 Calculating quote for ${quoteRequest.vehicleType}...`);
        
        await new Promise(resolve => setTimeout(resolve, 200));
        
        const baseRate = 800;
        const ageMultiplier = quoteRequest.driverAge < 25 ? 1.5 : 1.0;
        const vehicleMultiplier = quoteRequest.vehicleType === 'sports' ? 2.0 : 1.0;
        
        return {
            quoteId: `QUO-${Date.now()}`,
            premium: Math.round(baseRate * ageMultiplier * vehicleMultiplier),
            deductible: quoteRequest.deductible || 500,
            coverage: quoteRequest.coverage,
            validUntil: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
            calculatedAt: new Date().toISOString()
        };
    }

    // Simulate agent performance data
    static async getAgentStats(agentId) {
        console.log(`📊 Fetching agent ${agentId} statistics...`);
        
        await new Promise(resolve => setTimeout(resolve, 150));
        
        return {
            id: agentId,
            name: `Agent ${agentId}`,
            salesThisMonth: Math.floor(Math.random() * 50),
            revenue: Math.floor(Math.random() * 100000),
            customerSatisfaction: 3.5 + Math.random() * 1.5,
            policiesManaged: Math.floor(Math.random() * 500),
            lastUpdated: new Date().toISOString()
        };
    }
}

module.exports = DataSources;
```

### Step 3: Test Cache-Aside Pattern

Create `examples/test-cache-aside.js`:
```javascript
const CacheAside = require('../src/cache-aside');
const DataSources = require('../src/data-sources');

async function testCacheAside() {
    const cache = new CacheAside();
    await cache.init();

    console.log('🧪 Testing Cache-Aside Pattern\n');

    // Test 1: Policy caching
    console.log('=== Test 1: Policy Caching ===');
    
    const policyId = '12345';
    const policyKey = `policy:${policyId}`;
    
    // First call - cache miss
    console.log('First call (cache miss):');
    let start = Date.now();
    const policy1 = await cache.get(
        policyKey,
        () => DataSources.getPolicyById(policyId),
        600 // 10 minute TTL
    );
    let duration = Date.now() - start;
    console.log(`⏱️ Duration: ${duration}ms\n`);

    // Second call - cache hit
    console.log('Second call (cache hit):');
    start = Date.now();
    const policy2 = await cache.get(
        policyKey,
        () => DataSources.getPolicyById(policyId),
        600
    );
    duration = Date.now() - start;
    console.log(`⏱️ Duration: ${duration}ms\n`);

    // Test 2: Quote caching with different parameters
    console.log('=== Test 2: Quote Caching ===');
    
    const quoteRequest = {
        driverAge: 25,
        vehicleType: 'sedan',
        deductible: 500,
        coverage: 'full'
    };
    
    const quoteKey = `quote:${JSON.stringify(quoteRequest).replace(/\s/g, '')}`;
    
    console.log('Quote calculation (cache miss):');
    start = Date.now();
    const quote = await cache.get(
        quoteKey,
        () => DataSources.calculateQuote(quoteRequest),
        300 // 5 minute TTL for quotes
    );
    duration = Date.now() - start;
    console.log(`💰 Quote: $${quote.premium}`);
    console.log(`⏱️ Duration: ${duration}ms\n`);

    // Test cache invalidation
    console.log('=== Test 3: Cache Invalidation ===');
    await cache.invalidate(policyKey);
    await cache.invalidatePattern('quote:*');

    await cache.client.disconnect();
}

testCacheAside().catch(console.error);
```

Run test:
```bash
node examples/test-cache-aside.js
```

---

## Part 3: Multi-Level Caching Architecture (15 minutes)

### Step 1: Multi-Level Cache Implementation

Create `src/multi-level-cache.js`:
```javascript
const redisClient = require('./redis-client');

class MultiLevelCache {
    constructor() {
        this.client = null;
        this.memoryCache = new Map();
        this.memoryCacheSize = 1000; // Max items in memory
        this.stats = {
            l1Hits: 0,
            l2Hits: 0,
            misses: 0,
            total: 0
        };
    }

    async init() {
        await redisClient.connect();
        this.client = redisClient.getClient();
        
        // Memory cache cleanup interval
        setInterval(() => this.cleanMemoryCache(), 60000);
    }

    // L1: Memory cache, L2: Redis cache, L3: Data source
    async get(key, dataSource, options = {}) {
        const {
            memoryTtl = 60,     // Memory cache TTL (seconds)
            redisTtl = 300,     // Redis cache TTL (seconds)
            skipMemory = false   // Force skip memory cache
        } = options;

        this.stats.total++;

        try {
            // Level 1: Memory cache
            if (!skipMemory && this.memoryCache.has(key)) {
                const item = this.memoryCache.get(key);
                if (item.expires > Date.now()) {
                    this.stats.l1Hits++;
                    console.log(`🟢 L1 HIT (Memory): ${key}`);
                    return item.data;
                }
                this.memoryCache.delete(key);
            }

            // Level 2: Redis cache
            const cached = await this.client.get(key);
            if (cached) {
                this.stats.l2Hits++;
                console.log(`🔵 L2 HIT (Redis): ${key}`);
                
                const data = JSON.parse(cached);
                
                // Store in memory cache for next time
                if (!skipMemory) {
                    this.setMemoryCache(key, data, memoryTtl);
                }
                
                return data;
            }

            // Level 3: Data source (cache miss)
            this.stats.misses++;
            console.log(`🔴 L3 MISS (DataSource): ${key}`);
            
            const data = await dataSource();
            
            if (data) {
                // Store in both cache levels
                await this.client.setEx(key, redisTtl, JSON.stringify(data));
                if (!skipMemory) {
                    this.setMemoryCache(key, data, memoryTtl);
                }
                console.log(`💾 Cached in L1+L2: ${key}`);
            }

            return data;
        } catch (error) {
            console.error('Multi-level cache error:', error);
            return await dataSource();
        }
    }

    // Set data in memory cache
    setMemoryCache(key, data, ttlSeconds) {
        // Evict oldest items if cache is full
        if (this.memoryCache.size >= this.memoryCacheSize) {
            const firstKey = this.memoryCache.keys().next().value;
            this.memoryCache.delete(firstKey);
        }

        this.memoryCache.set(key, {
            data,
            expires: Date.now() + (ttlSeconds * 1000),
            created: Date.now()
        });
    }

    // Clean expired items from memory cache
    cleanMemoryCache() {
        const now = Date.now();
        let cleaned = 0;
        
        for (const [key, item] of this.memoryCache.entries()) {
            if (item.expires <= now) {
                this.memoryCache.delete(key);
                cleaned++;
            }
        }
        
        if (cleaned > 0) {
            console.log(`🧹 Cleaned ${cleaned} expired items from memory cache`);
        }
    }

    // Invalidate from all cache levels
    async invalidate(key) {
        try {
            // Remove from memory
            this.memoryCache.delete(key);
            
            // Remove from Redis
            await this.client.del(key);
            
            console.log(`🗑️ Invalidated from all levels: ${key}`);
        } catch (error) {
            console.error('Invalidation error:', error);
        }
    }

    // Invalidate pattern from Redis (memory cache patterns not supported)
    async invalidatePattern(pattern) {
        try {
            // Clear matching items from memory
            for (const key of this.memoryCache.keys()) {
                if (this.matchesPattern(key, pattern)) {
                    this.memoryCache.delete(key);
                }
            }

            // Clear from Redis
            const keys = await this.client.keys(pattern);
            if (keys.length > 0) {
                await this.client.del(keys);
                console.log(`🗑️ Pattern invalidated: ${pattern} (${keys.length} keys)`);
            }
        } catch (error) {
            console.error('Pattern invalidation error:', error);
        }
    }

    // Simple pattern matching for memory cache
    matchesPattern(key, pattern) {
        const regex = new RegExp(pattern.replace(/\*/g, '.*'));
        return regex.test(key);
    }

    // Get cache statistics
    getStats() {
        const hitRate = this.stats.total > 0 ? 
            ((this.stats.l1Hits + this.stats.l2Hits) / this.stats.total * 100).toFixed(1) : 0;
        
        return {
            ...this.stats,
            hitRate: `${hitRate}%`,
            memoryItems: this.memoryCache.size,
            distribution: {
                l1Rate: this.stats.total > 0 ? (this.stats.l1Hits / this.stats.total * 100).toFixed(1) + '%' : '0%',
                l2Rate: this.stats.total > 0 ? (this.stats.l2Hits / this.stats.total * 100).toFixed(1) + '%' : '0%',
                missRate: this.stats.total > 0 ? (this.stats.misses / this.stats.total * 100).toFixed(1) + '%' : '0%'
            }
        };
    }

    // Reset statistics
    resetStats() {
        this.stats = {
            l1Hits: 0,
            l2Hits: 0,
            misses: 0,
            total: 0
        };
    }
}

module.exports = MultiLevelCache;
```

### Step 2: Cache Warming and Preloading

Create `src/cache-warmer.js`:
```javascript
const MultiLevelCache = require('./multi-level-cache');
const DataSources = require('./data-sources');

class CacheWarmer {
    constructor(cache) {
        this.cache = cache;
    }

    // Warm cache with popular policies
    async warmPolicies(policyIds) {
        console.log('🔥 Warming policy cache...');
        
        const promises = policyIds.map(async (id) => {
            const key = `policy:${id}`;
            try {
                await this.cache.get(
                    key,
                    () => DataSources.getPolicyById(id),
                    { redisTtl: 1800, memoryTtl: 300 } // 30min Redis, 5min memory
                );
            } catch (error) {
                console.error(`Failed to warm policy ${id}:`, error);
            }
        });

        await Promise.all(promises);
        console.log(`✅ Warmed ${policyIds.length} policies`);
    }

    // Warm cache with customer data
    async warmCustomers(customerIds) {
        console.log('🔥 Warming customer cache...');
        
        const promises = customerIds.map(async (id) => {
            const key = `customer:${id}`;
            try {
                await this.cache.get(
                    key,
                    () => DataSources.getCustomerById(id),
                    { redisTtl: 900, memoryTtl: 180 } // 15min Redis, 3min memory
                );
            } catch (error) {
                console.error(`Failed to warm customer ${id}:`, error);
            }
        });

        await Promise.all(promises);
        console.log(`✅ Warmed ${customerIds.length} customers`);
    }

    // Warm cache with agent statistics
    async warmAgentStats(agentIds) {
        console.log('🔥 Warming agent stats cache...');
        
        const promises = agentIds.map(async (id) => {
            const key = `agent:stats:${id}`;
            try {
                await this.cache.get(
                    key,
                    () => DataSources.getAgentStats(id),
                    { redisTtl: 3600, memoryTtl: 600 } // 1hr Redis, 10min memory
                );
            } catch (error) {
                console.error(`Failed to warm agent ${id}:`, error);
            }
        });

        await Promise.all(promises);
        console.log(`✅ Warmed ${agentIds.length} agent stats`);
    }

    // Comprehensive cache warming
    async warmAll() {
        console.log('🔥 Starting comprehensive cache warming...');
        
        const popularPolicies = ['12345', '12346', '12347', '12348', '12349'];
        const activeCustomers = ['1001', '1002', '1003', '1004', '1005'];
        const topAgents = ['101', '102', '103', '104', '105'];

        await Promise.all([
            this.warmPolicies(popularPolicies),
            this.warmCustomers(activeCustomers),
            this.warmAgentStats(topAgents)
        ]);

        console.log('✅ Cache warming completed');
        console.log('📊 Cache stats:', this.cache.getStats());
    }
}

module.exports = CacheWarmer;
```

### Step 3: Test Multi-Level Cache

Create `examples/test-multi-level.js`:
```javascript
const MultiLevelCache = require('../src/multi-level-cache');
const CacheWarmer = require('../src/cache-warmer');
const DataSources = require('../src/data-sources');

async function testMultiLevelCache() {
    const cache = new MultiLevelCache();
    await cache.init();

    console.log('🧪 Testing Multi-Level Cache\n');

    // Test 1: Cache level progression
    console.log('=== Test 1: Cache Level Progression ===');
    
    const policyId = '12345';
    const policyKey = `policy:${policyId}`;
    
    // First call - L3 miss, populates L2 and L1
    console.log('Call 1 - Cold cache:');
    let start = Date.now();
    await cache.get(
        policyKey,
        () => DataSources.getPolicyById(policyId),
        { memoryTtl: 60, redisTtl: 300 }
    );
    console.log(`⏱️ Duration: ${Date.now() - start}ms\n`);

    // Second call - L1 hit (memory)
    console.log('Call 2 - Memory hit:');
    start = Date.now();
    await cache.get(
        policyKey,
        () => DataSources.getPolicyById(policyId),
        { memoryTtl: 60, redisTtl: 300 }
    );
    console.log(`⏱️ Duration: ${Date.now() - start}ms\n`);

    // Third call - Skip memory, L2 hit (Redis)
    console.log('Call 3 - Skip memory, Redis hit:');
    start = Date.now();
    await cache.get(
        policyKey,
        () => DataSources.getPolicyById(policyId),
        { memoryTtl: 60, redisTtl: 300, skipMemory: true }
    );
    console.log(`⏱️ Duration: ${Date.now() - start}ms\n`);

    // Test 2: Performance comparison
    console.log('=== Test 2: Performance Comparison ===');
    
    const customerIds = ['1001', '1002', '1003', '1004', '1005'];
    
    // Cold cache performance
    console.log('Cold cache performance (5 customers):');
    start = Date.now();
    for (const id of customerIds) {
        await cache.get(
            `customer:${id}`,
            () => DataSources.getCustomerById(id),
            { memoryTtl: 60, redisTtl: 300 }
        );
    }
    const coldDuration = Date.now() - start;
    console.log(`⏱️ Cold cache total: ${coldDuration}ms\n`);

    // Warm cache performance (memory hits)
    console.log('Warm cache performance (same 5 customers):');
    start = Date.now();
    for (const id of customerIds) {
        await cache.get(
            `customer:${id}`,
            () => DataSources.getCustomerById(id),
            { memoryTtl: 60, redisTtl: 300 }
        );
    }
    const warmDuration = Date.now() - start;
    console.log(`⏱️ Warm cache total: ${warmDuration}ms`);
    console.log(`🚀 Speedup: ${(coldDuration / warmDuration).toFixed(1)}x\n`);

    // Test 3: Cache warming
    console.log('=== Test 3: Cache Warming ===');
    cache.resetStats();
    
    const warmer = new CacheWarmer(cache);
    await warmer.warmAll();
    
    console.log('\n📊 Final cache statistics:');
    console.log(cache.getStats());

    await cache.client.disconnect();
}

testMultiLevelCache().catch(console.error);
```

Run test:
```bash
node examples/test-multi-level.js
```

---

## Part 4: Cache Invalidation Strategies (8 minutes)

### Step 1: Smart Cache Invalidation

Create `src/cache-invalidator.js`:
```javascript
const EventEmitter = require('events');

class SmartCacheInvalidator extends EventEmitter {
    constructor(cache) {
        super();
        this.cache = cache;
        this.invalidationRules = new Map();
        this.setupEventListeners();
    }

    // Setup event listeners for automatic invalidation
    setupEventListeners() {
        this.on('policy:updated', this.handlePolicyUpdate.bind(this));
        this.on('customer:updated', this.handleCustomerUpdate.bind(this));
        this.on('quote:expired', this.handleQuoteExpiration.bind(this));
        this.on('agent:stats:changed', this.handleAgentStatsChange.bind(this));
    }

    // Register invalidation rules
    addRule(event, pattern) {
        if (!this.invalidationRules.has(event)) {
            this.invalidationRules.set(event, []);
        }
        this.invalidationRules.get(event).push(pattern);
    }

    // Handle policy updates
    async handlePolicyUpdate(data) {
        const { policyId, customerId } = data;
        
        console.log(`🔄 Policy updated: ${policyId}`);
        
        // Invalidate policy cache
        await this.cache.invalidate(`policy:${policyId}`);
        
        // Invalidate related customer cache
        if (customerId) {
            await this.cache.invalidate(`customer:${customerId}`);
        }
        
        // Invalidate policy summaries
        await this.cache.invalidatePattern('policies:summary:*');
        
        console.log('✅ Policy update invalidation complete');
    }

    // Handle customer updates
    async handleCustomerUpdate(data) {
        const { customerId } = data;
        
        console.log(`🔄 Customer updated: ${customerId}`);
        
        // Invalidate customer cache
        await this.cache.invalidate(`customer:${customerId}`);
        
        // Invalidate customer's policies
        await this.cache.invalidatePattern(`policy:customer:${customerId}:*`);
        
        // Invalidate quotes for this customer
        await this.cache.invalidatePattern(`quote:customer:${customerId}:*`);
        
        console.log('✅ Customer update invalidation complete');
    }

    // Handle quote expiration
    async handleQuoteExpiration(data) {
        const { quoteId, customerId } = data;
        
        console.log(`⏰ Quote expired: ${quoteId}`);
        
        // Remove expired quote
        await this.cache.invalidate(`quote:${quoteId}`);
        
        // Clean up related temporary data
        await this.cache.invalidatePattern(`quote:temp:${customerId}:*`);
        
        console.log('✅ Quote expiration cleanup complete');
    }

    // Handle agent statistics changes
    async handleAgentStatsChange(data) {
        const { agentId } = data;
        
        console.log(`📊 Agent stats changed: ${agentId}`);
        
        // Invalidate agent stats
        await this.cache.invalidate(`agent:stats:${agentId}`);
        
        // Invalidate leaderboards that might include this agent
        await this.cache.invalidatePattern('leaderboard:*');
        
        console.log('✅ Agent stats invalidation complete');
    }

    // Time-based invalidation for expired quotes
    startQuoteCleanup() {
        setInterval(async () => {
            console.log('🧹 Running quote cleanup...');
            
            try {
                // Get all quote keys
                const quoteKeys = await this.cache.client.keys('quote:*');
                let cleanedCount = 0;
                
                for (const key of quoteKeys) {
                    const ttl = await this.cache.client.ttl(key);
                    if (ttl <= 60) { // Expiring within 1 minute
                        await this.cache.invalidate(key);
                        cleanedCount++;
                    }
                }
                
                if (cleanedCount > 0) {
                    console.log(`🗑️ Cleaned ${cleanedCount} expiring quotes`);
                }
            } catch (error) {
                console.error('Quote cleanup error:', error);
            }
        }, 60000); // Run every minute
    }

    // Cascade invalidation for related data
    async cascadeInvalidate(primaryKey, relatedPatterns) {
        console.log(`🌊 Cascade invalidating: ${primaryKey}`);
        
        // Invalidate primary key
        await this.cache.invalidate(primaryKey);
        
        // Invalidate related patterns
        for (const pattern of relatedPatterns) {
            await this.cache.invalidatePattern(pattern);
        }
        
        console.log('✅ Cascade invalidation complete');
    }

    // Bulk invalidation with confirmation
    async bulkInvalidate(patterns, confirm = false) {
        if (!confirm) {
            console.log('⚠️ Bulk invalidation requires confirmation');
            return false;
        }
        
        console.log('💥 Starting bulk invalidation...');
        let totalInvalidated = 0;
        
        for (const pattern of patterns) {
            const keys = await this.cache.client.keys(pattern);
            if (keys.length > 0) {
                await this.cache.client.del(keys);
                totalInvalidated += keys.length;
                console.log(`🗑️ Invalidated ${keys.length} keys: ${pattern}`);
            }
        }
        
        console.log(`✅ Bulk invalidation complete: ${totalInvalidated} total keys`);
        return totalInvalidated;
    }
}

module.exports = SmartCacheInvalidator;
```

### Step 2: Test Cache Invalidation

Create `examples/test-invalidation.js`:
```javascript
const MultiLevelCache = require('../src/multi-level-cache');
const SmartCacheInvalidator = require('../src/cache-invalidator');
const DataSources = require('../src/data-sources');

async function testCacheInvalidation() {
    const cache = new MultiLevelCache();
    await cache.init();

    const invalidator = new SmartCacheInvalidator(cache);

    console.log('🧪 Testing Cache Invalidation Strategies\n');

    // Setup some test data
    console.log('Setting up test data...');
    await cache.get('policy:12345', () => DataSources.getPolicyById('12345'));
    await cache.get('customer:1001', () => DataSources.getCustomerById('1001'));
    await cache.get('agent:stats:101', () => DataSources.getAgentStats('101'));

    console.log('📊 Initial cache stats:', cache.getStats());
    console.log();

    // Test 1: Single key invalidation
    console.log('=== Test 1: Single Key Invalidation ===');
    
    invalidator.emit('policy:updated', {
        policyId: '12345',
        customerId: '1001'
    });
    
    // Wait for invalidation to complete
    await new Promise(resolve => setTimeout(resolve, 100));
    
    console.log('After policy update invalidation:');
    console.log('📊 Cache stats:', cache.getStats());
    console.log();

    // Test 2: Pattern invalidation
    console.log('=== Test 2: Pattern Invalidation ===');
    
    // Create some quote data
    await cache.get('quote:customer:1001:auto', () => ({
        quoteId: 'QUO-1001-AUTO',
        premium: 1200,
        expires: Date.now() + 300000
    }));
    await cache.get('quote:customer:1001:home', () => ({
        quoteId: 'QUO-1001-HOME',
        premium: 800,
        expires: Date.now() + 300000
    }));

    invalidator.emit('customer:updated', {
        customerId: '1001'
    });
    
    await new Promise(resolve => setTimeout(resolve, 100));
    
    console.log('After customer update invalidation:');
    console.log('📊 Cache stats:', cache.getStats());
    console.log();

    // Test 3: Cascade invalidation
    console.log('=== Test 3: Cascade Invalidation ===');
    
    // Setup data for cascade test
    await cache.get('policy:12346', () => DataSources.getPolicyById('12346'));
    await cache.get('policies:summary:active', () => ({ count: 150, total: 200 }));
    await cache.get('policies:summary:expired', () => ({ count: 50, total: 200 }));

    await invalidator.cascadeInvalidate('policy:12346', [
        'policies:summary:*',
        'customer:*'
    ]);
    
    console.log('After cascade invalidation:');
    console.log('📊 Cache stats:', cache.getStats());

    await cache.client.disconnect();
}

testCacheInvalidation().catch(console.error);
```

---

## Part 5: Performance Monitoring & Optimization (5 minutes)

### Step 1: Cache Performance Monitor

Create `src/cache-monitor.js`:
```javascript
class CacheMonitor {
    constructor(cache) {
        this.cache = cache;
        this.metrics = {
            requests: 0,
            hits: 0,
            misses: 0,
            errors: 0,
            totalLatency: 0,
            avgLatency: 0
        };
        
        this.startTime = Date.now();
        this.intervalId = null;
    }

    // Start monitoring
    startMonitoring(intervalSeconds = 30) {
        console.log(`📊 Starting cache monitoring (${intervalSeconds}s intervals)`);
        
        this.intervalId = setInterval(() => {
            this.reportMetrics();
        }, intervalSeconds * 1000);
    }

    // Stop monitoring
    stopMonitoring() {
        if (this.intervalId) {
            clearInterval(this.intervalId);
            this.intervalId = null;
            console.log('⏹️ Cache monitoring stopped');
        }
    }

    // Record cache operation
    recordOperation(type, latency) {
        this.metrics.requests++;
        this.metrics.totalLatency += latency;
        this.metrics.avgLatency = this.metrics.totalLatency / this.metrics.requests;

        if (type === 'hit') {
            this.metrics.hits++;
        } else if (type === 'miss') {
            this.metrics.misses++;
        } else if (type === 'error') {
            this.metrics.errors++;
        }
    }

    // Get current metrics
    getMetrics() {
        const hitRate = this.metrics.requests > 0 ? 
            (this.metrics.hits / this.metrics.requests * 100).toFixed(1) : 0;
        
        const runtime = Math.floor((Date.now() - this.startTime) / 1000);
        const rps = this.metrics.requests / runtime;

        return {
            ...this.metrics,
            hitRate: `${hitRate}%`,
            runtime: `${runtime}s`,
            requestsPerSecond: rps.toFixed(2),
            cacheStats: this.cache.getStats()
        };
    }

    // Report metrics to console
    reportMetrics() {
        console.log('\n📊 === Cache Performance Report ===');
        const metrics = this.getMetrics();
        
        console.log(`🎯 Hit Rate: ${metrics.hitRate}`);
        console.log(`📈 Requests: ${metrics.requests} (${metrics.requestsPerSecond}/sec)`);
        console.log(`✅ Hits: ${metrics.hits}`);
        console.log(`❌ Misses: ${metrics.misses}`);
        console.log(`🚨 Errors: ${metrics.errors}`);
        console.log(`⏱️ Avg Latency: ${metrics.avgLatency.toFixed(2)}ms`);
        console.log(`🏃 Runtime: ${metrics.runtime}`);
        
        console.log('\n🏗️ Cache Architecture Stats:');
        console.log(`L1 Hit Rate: ${metrics.cacheStats.distribution.l1Rate}`);
        console.log(`L2 Hit Rate: ${metrics.cacheStats.distribution.l2Rate}`);
        console.log(`Miss Rate: ${metrics.cacheStats.distribution.missRate}`);
        console.log(`Memory Items: ${metrics.cacheStats.memoryItems}`);
        
        console.log('================================\n');
    }

    // Reset metrics
    resetMetrics() {
        this.metrics = {
            requests: 0,
            hits: 0,
            misses: 0,
            errors: 0,
            totalLatency: 0,
            avgLatency: 0
        };
        this.startTime = Date.now();
        this.cache.resetStats();
        console.log('📊 Metrics reset');
    }

    // Generate performance recommendations
    getRecommendations() {
        const metrics = this.getMetrics();
        const recommendations = [];

        const hitRate = parseFloat(metrics.hitRate);
        if (hitRate < 80) {
            recommendations.push(`🔧 Low hit rate (${metrics.hitRate}). Consider: longer TTL, cache warming, or better key patterns`);
        }

        if (metrics.avgLatency > 50) {
            recommendations.push(`⚡ High average latency (${metrics.avgLatency.toFixed(2)}ms). Consider: connection pooling or network optimization`);
        }

        if (metrics.errors > 0) {
            recommendations.push(`🚨 Cache errors detected (${metrics.errors}). Check Redis connectivity and error handling`);
        }

        const memoryUtilization = metrics.cacheStats.memoryItems / 1000 * 100;
        if (memoryUtilization > 90) {
            recommendations.push(`💾 High memory cache utilization (${memoryUtilization.toFixed(1)}%). Consider increasing cache size`);
        }

        return recommendations;
    }
}

module.exports = CacheMonitor;
```

### Step 2: Complete Performance Test

Create `examples/performance-test.js`:
```javascript
const MultiLevelCache = require('../src/multi-level-cache');
const CacheMonitor = require('../src/cache-monitor');
const DataSources = require('../src/data-sources');

async function performanceTest() {
    const cache = new MultiLevelCache();
    await cache.init();

    const monitor = new CacheMonitor(cache);
    monitor.startMonitoring(10); // Report every 10 seconds

    console.log('🚀 Starting Performance Test\n');

    // Simulate realistic workload
    const testDuration = 30000; // 30 seconds
    const requestInterval = 50;  // Request every 50ms
    
    let requestCount = 0;
    const policyIds = ['12345', '12346', '12347', '12348', '12349'];
    const customerIds = ['1001', '1002', '1003', '1004', '1005'];

    const testInterval = setInterval(async () => {
        requestCount++;
        
        // Simulate mixed workload
        const operations = [
            // Policy lookups (60%)
            () => {
                const id = policyIds[Math.floor(Math.random() * policyIds.length)];
                const start = Date.now();
                return cache.get(`policy:${id}`, () => DataSources.getPolicyById(id))
                    .then(() => monitor.recordOperation('hit', Date.now() - start))
                    .catch(() => monitor.recordOperation('error', Date.now() - start));
            },
            
            // Customer lookups (30%)
            () => {
                const id = customerIds[Math.floor(Math.random() * customerIds.length)];
                const start = Date.now();
                return cache.get(`customer:${id}`, () => DataSources.getCustomerById(id))
                    .then(() => monitor.recordOperation('hit', Date.now() - start))
                    .catch(() => monitor.recordOperation('error', Date.now() - start));
            },
            
            // Quote calculations (10%)
            () => {
                const request = {
                    driverAge: 20 + Math.floor(Math.random() * 40),
                    vehicleType: Math.random() > 0.5 ? 'sedan' : 'suv',
                    deductible: 500
                };
                const key = `quote:${JSON.stringify(request)}`;
                const start = Date.now();
                return cache.get(key, () => DataSources.calculateQuote(request), { redisTtl: 300 })
                    .then(() => monitor.recordOperation('hit', Date.now() - start))
                    .catch(() => monitor.recordOperation('error', Date.now() - start));
            }
        ];

        // Weight the operations
        let operation;
        const rand = Math.random();
        if (rand < 0.6) {
            operation = operations[0]; // Policy
        } else if (rand < 0.9) {
            operation = operations[1]; // Customer
        } else {
            operation = operations[2]; // Quote
        }

        operation().catch(console.error);
        
    }, requestInterval);

    // Stop test after duration
    setTimeout(() => {
        clearInterval(testInterval);
        monitor.stopMonitoring();
        
        console.log('🏁 Performance Test Complete\n');
        console.log('📊 Final Results:');
        console.log(monitor.getMetrics());
        
        console.log('\n💡 Recommendations:');
        const recommendations = monitor.getRecommendations();
        if (recommendations.length > 0) {
            recommendations.forEach(rec => console.log(rec));
        } else {
            console.log('✅ Cache performance is optimal!');
        }
        
        cache.client.disconnect();
    }, testDuration);

    console.log(`⏱️ Running performance test for ${testDuration/1000} seconds...`);
    console.log(`📊 Monitoring reports every 10 seconds`);
}

performanceTest().catch(console.error);
```

Run performance test:
```bash
node examples/performance-test.js
```

---

## Lab Completion Checklist

- [ ] Implemented cache-aside pattern with Redis
- [ ] Built multi-level caching architecture (Memory + Redis)
- [ ] Created intelligent cache invalidation strategies
- [ ] Implemented cache warming and preloading
- [ ] Built performance monitoring and metrics
- [ ] Tested cache stampede prevention
- [ ] Optimized TTL strategies for different data types
- [ ] Measured and analyzed cache performance

---

## Key Takeaways

🎉 **Congratulations!** You've mastered advanced Redis caching patterns:

1. **Cache-Aside Pattern** - Manual cache management with fallback to data source
2. **Multi-Level Architecture** - Memory + Redis for optimal performance
3. **Smart Invalidation** - Event-driven cache invalidation strategies
4. **Performance Monitoring** - Metrics and optimization recommendations
5. **Cache Warming** - Proactive cache population for better performance

**Next Steps:** Apply these patterns to your real-world applications for dramatic performance improvements!

---

## Performance Optimization Tips

- **Use appropriate TTL values** for different data types
- **Implement cache warming** for frequently accessed data
- **Monitor hit rates** and adjust strategies accordingly
- **Use memory cache** for ultra-fast access to hot data
- **Implement smart invalidation** to maintain data consistency
- **Consider cache stampede** protection for high-traffic scenarios

Remember: Good caching is about finding the right balance between performance, consistency, and complexity!
