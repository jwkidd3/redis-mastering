# Lab 10: Advanced Caching Patterns

> **📌 Optional / Take-Home Lab**
>
> This lab is not part of the core 3-day in-class schedule. The caching-patterns theory is covered in **Presentation 6: Streams, Event Sourcing & Caching Patterns**. Complete this lab as homework to practice cache-aside, write-through, and event-driven invalidation.

**Duration:** 45 minutes  
**Focus:** Multi-level caching, intelligent invalidation, and performance optimization  

## 🎯 Learning Objectives

Master sophisticated caching strategies including:
- Cache-aside and write-through patterns
- Multi-level caching architectures  
- Smart cache invalidation strategies
- Performance monitoring and optimization
- Cache warming

## 🚀 Quick Start

1. **Setup Environment:**
   ```bash
   chmod +x build-lab10.sh
   ./build-lab10.sh
   cd lab10-advanced-caching-patterns
   ```

2. **Install Dependencies:**
   ```bash
   npm install
   ```

3. **Configure Connection:**
   - Update `.env` with Redis connection details from instructor
   - Test connection: `node test-connection.js`

4. **Run Lab:**
   - Test examples in `examples/` directory
   - Run completion test: `node test-completion.js`

## 📁 Project Structure

```
lab10-advanced-caching-patterns/
├── src/
│   ├── redis-client.js         # Redis connection management
│   ├── cache-aside.js          # Cache-aside pattern implementation
│   ├── multi-level-cache.js    # Multi-level caching system
│   ├── cache-invalidator.js    # Smart invalidation strategies
│   ├── cache-warmer.js         # Cache warming utilities
│   ├── cache-monitor.js        # Performance monitoring
│   └── data-sources.js         # Mock data sources
├── examples/
│   ├── test-cache-aside.js     # Cache-aside pattern demo
│   ├── test-multi-level.js     # Multi-level cache demo
│   ├── test-invalidation.js    # Invalidation strategies demo
│   └── performance-test.js     # Performance testing
├── reference/
│   └── caching-patterns.md     # Comprehensive reference guide
├── test-connection.js          # Connection verification
├── test-completion.js          # Lab completion validation
└── README.md                   # This file
```

## 🔧 Features Implemented

### Core Caching Patterns
- **Cache-Aside Pattern**: Manual cache management with fallback
- **Multi-Level Architecture**: Memory + Redis for optimal performance
- **Smart Invalidation**: Event-driven cache invalidation
- **Cache Warming**: Proactive cache population strategies

### Performance Features
- **Connection Pooling**: Optimized Redis connections
- **Pipeline Operations**: Batch Redis commands
- **TTL Strategies**: Intelligent expiration policies
- **Memory Management**: Automatic cleanup and eviction

### Monitoring & Analytics
- **Real-time Metrics**: Hit rates, latency, throughput
- **Performance Reports**: Automated monitoring intervals
- **Optimization Recommendations**: AI-driven suggestions
- **Multi-level Statistics**: L1/L2/L3 cache analytics

## 🧪 Testing & Validation

Run individual tests:
```bash
# Test cache-aside pattern
node examples/test-cache-aside.js

# Test multi-level caching
node examples/test-multi-level.js

# Test invalidation strategies
node examples/test-invalidation.js

# Run performance benchmarks
node examples/performance-test.js
```

Complete validation:
```bash
node test-completion.js
```

## 📊 Performance Benchmarks

Expected performance improvements with multi-level caching:
- **L1 Cache (Memory)**: ~1-5ms response time
- **L2 Cache (Redis)**: ~10-50ms response time  
- **L3 Source (Database)**: ~100-500ms response time
- **Overall Hit Rate**: 85%+ in production workloads
- **Performance Improvement**: 10-50x faster than database-only access

## 🎯 Key Concepts Demonstrated

### 1. Cache-Aside Pattern
```javascript
// Check cache first, fallback to data source
const data = await cache.get(key, () => dataSource.fetch(id), ttl);
```

### 2. Multi-Level Architecture
```javascript
// L1 (Memory) → L2 (Redis) → L3 (Database)
const result = await multiCache.get(key, dataSource, {
    memoryTtl: 60,    // 1 minute in memory
    redisTtl: 300     // 5 minutes in Redis
});
```

### 3. Smart Invalidation
```javascript
// Event-driven invalidation
invalidator.emit('policy:updated', { policyId: '12345' });
// Automatically invalidates related cache entries
```

### 4. Performance Monitoring
```javascript
// Real-time metrics collection
monitor.recordOperation('hit', latency);
console.log(monitor.getStats()); // Hit rate, latency, etc.
```

## 🔍 Advanced Features

### Cache Stampede Prevention
Prevents multiple requests from hitting the database simultaneously:
```javascript
const lockKey = `lock:${key}`;
const acquired = await redis.set(lockKey, '1', 'EX', 10, 'NX');
```

### Probabilistic Early Expiration
Reduces thundering herd problems:
```javascript
const jitter = Math.random() * 0.1; // 10% jitter
const earlyExpiry = ttl * (1 - jitter);
```

### Memory Usage Optimization
Automatic cleanup and size management:
```javascript
// Automatic memory cache cleanup
setInterval(() => this.cleanMemoryCache(), 60000);
```

## 🚨 Common Issues & Solutions

### Connection Issues
**Using Redis Insight Workbench:**
1. Open Redis Insight and connect to your Redis instance
2. Navigate to **Workbench**
3. Test connectivity by running: `PING`
4. Expected response: `PONG`

**Or use Node.js test script:**
```bash
# Check Redis connectivity programmatically
node test-connection.js
```

### Memory Leaks
```javascript
// Ensure proper cleanup
process.on('SIGINT', async () => {
    await cache.client.disconnect();
    process.exit(0);
});
```

### Performance Problems
```javascript
// Monitor key metrics
const stats = monitor.getStats();
const recommendations = monitor.getRecommendations();
```

## 📚 Additional Resources

- **Redis Documentation**: https://redis.io/documentation
- **Caching Strategies**: See `reference/caching-patterns.md`
- **Node.js Redis Client**: https://github.com/redis/node-redis
- **Performance Best Practices**: Built into monitor recommendations

## 🎉 Success Criteria

To complete this lab successfully, you should achieve:
- [ ] 5/5 tests passing in completion validation
- [ ] Cache hit rate > 80% in performance tests
- [ ] Understanding of multi-level caching benefits
- [ ] Ability to implement smart invalidation strategies
- [ ] Knowledge of performance monitoring and optimization

## 🔗 Integration Points

This lab integrates with:
- **Lab 9**: Builds on advanced Redis operations
- **Lab 11**: Foundation for production deployment patterns
- **Real Applications**: Direct application to production systems

---

