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
