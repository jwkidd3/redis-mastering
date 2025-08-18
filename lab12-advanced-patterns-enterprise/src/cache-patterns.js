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
