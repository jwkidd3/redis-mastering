# JavaScript Redis Patterns

## Connection Management

### Basic Connection
```javascript
const redis = require('redis');

const client = redis.createClient({
    socket: {
        host: 'redis-server.training.com',
        port: 6379
    },
    password: 'your_password'
});

await client.connect();
```

### Connection with Error Handling
```javascript
class RedisClient {
    constructor() {
        this.client = null;
        this.isConnected = false;
    }

    async connect() {
        this.client = redis.createClient(config);
        
        this.client.on('error', (err) => {
            console.error('Redis error:', err);
            this.isConnected = false;
        });

        this.client.on('ready', () => {
            this.isConnected = true;
        });

        await this.client.connect();
    }
}
```

## Data Operations

### String Operations
```javascript
// Basic string operations
await client.set('key', 'value');
const value = await client.get('key');

// String with expiration
await client.setEx('session:123', 3600, 'user_data');

// Multiple operations
await client.mSet({
    'key1': 'value1',
    'key2': 'value2'
});

const values = await client.mGet(['key1', 'key2']);
```

### JSON Data Storage
```javascript
// Store object as JSON
const userData = { name: 'John', age: 30 };
await client.set('user:123', JSON.stringify(userData));

// Retrieve and parse JSON
const userJson = await client.get('user:123');
const user = JSON.parse(userJson);
```

### Numeric Operations
```javascript
// Counter operations
await client.set('counter', 0);
await client.incr('counter');           // Increment by 1
await client.incrBy('counter', 5);      // Increment by 5
await client.decr('counter');           // Decrement by 1

const count = await client.get('counter');
```

## Error Handling Patterns

### Try-Catch Pattern
```javascript
async function safeRedisOperation() {
    try {
        const result = await client.get('key');
        return result;
    } catch (error) {
        console.error('Redis operation failed:', error.message);
        return null;
    }
}
```

### Promise Pattern
```javascript
function getValueWithFallback(key, fallback) {
    return client.get(key)
        .then(value => value || fallback)
        .catch(error => {
            console.error('Redis error:', error);
            return fallback;
        });
}
```

## Advanced Patterns

### Batch Operations
```javascript
async function batchOperations() {
    const multi = client.multi();
    
    multi.set('key1', 'value1');
    multi.set('key2', 'value2');
    multi.incr('counter');
    
    const results = await multi.exec();
    return results;
}
```

### Pipeline Pattern
```javascript
async function pipelineExample() {
    const pipeline = client.multi();
    
    for (let i = 0; i < 100; i++) {
        pipeline.set(`key:${i}`, `value:${i}`);
    }
    
    await pipeline.exec();
}
```

### Retry Logic
```javascript
async function retryOperation(operation, maxRetries = 3) {
    for (let attempt = 1; attempt <= maxRetries; attempt++) {
        try {
            return await operation();
        } catch (error) {
            if (attempt === maxRetries) {
                throw error;
            }
            
            console.warn(`Attempt ${attempt} failed, retrying...`);
            await sleep(1000 * attempt); // Exponential backoff
        }
    }
}

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}
```

## Data Modeling Patterns

### Customer Model
```javascript
class Customer {
    constructor(redisClient) {
        this.redis = redisClient;
        this.keyPrefix = 'customer';
    }

    async save(id, data) {
        const key = `${this.keyPrefix}:${id}`;
        await this.redis.set(key, JSON.stringify(data));
        
        // Add to index
        await this.redis.sAdd('customers:index', id);
    }

    async find(id) {
        const key = `${this.keyPrefix}:${id}`;
        const data = await this.redis.get(key);
        return data ? JSON.parse(data) : null;
    }

    async findAll() {
        const ids = await this.redis.sMembers('customers:index');
        const customers = [];
        
        for (const id of ids) {
            const customer = await this.find(id);
            if (customer) customers.push(customer);
        }
        
        return customers;
    }
}
```

### Session Management
```javascript
class SessionManager {
    constructor(redisClient) {
        this.redis = redisClient;
        this.defaultTTL = 3600; // 1 hour
    }

    async createSession(userId, sessionData) {
        const sessionId = generateSessionId();
        const key = `session:${sessionId}`;
        
        const data = {
            userId,
            ...sessionData,
            createdAt: new Date().toISOString()
        };
        
        await this.redis.setEx(key, this.defaultTTL, JSON.stringify(data));
        return sessionId;
    }

    async getSession(sessionId) {
        const key = `session:${sessionId}`;
        const data = await this.redis.get(key);
        return data ? JSON.parse(data) : null;
    }

    async refreshSession(sessionId) {
        const key = `session:${sessionId}`;
        await this.redis.expire(key, this.defaultTTL);
    }

    async destroySession(sessionId) {
        const key = `session:${sessionId}`;
        await this.redis.del(key);
    }
}
```

## Performance Optimization

### Connection Pooling
```javascript
class RedisPool {
    constructor(config, poolSize = 10) {
        this.config = config;
        this.pool = [];
        this.poolSize = poolSize;
        this.currentIndex = 0;
    }

    async initialize() {
        for (let i = 0; i < this.poolSize; i++) {
            const client = redis.createClient(this.config);
            await client.connect();
            this.pool.push(client);
        }
    }

    getClient() {
        const client = this.pool[this.currentIndex];
        this.currentIndex = (this.currentIndex + 1) % this.poolSize;
        return client;
    }
}
```

### Caching Pattern
```javascript
class CacheManager {
    constructor(redisClient) {
        this.redis = redisClient;
        this.defaultTTL = 300; // 5 minutes
    }

    async get(key, fetchFunction, ttl = this.defaultTTL) {
        // Try cache first
        const cached = await this.redis.get(key);
        if (cached) {
            return JSON.parse(cached);
        }

        // Fetch data and cache
        const data = await fetchFunction();
        await this.redis.setEx(key, ttl, JSON.stringify(data));
        
        return data;
    }

    async invalidate(pattern) {
        const keys = await this.redis.keys(pattern);
        if (keys.length > 0) {
            await this.redis.del(keys);
        }
    }
}
```

## Testing Patterns

### Unit Test Example
```javascript
const RedisClient = require('../src/clients/redisClient');

describe('Redis Client', () => {
    let redisClient;

    beforeEach(async () => {
        redisClient = new RedisClient();
        await redisClient.connect();
    });

    afterEach(async () => {
        await redisClient.disconnect();
    });

    test('should store and retrieve data', async () => {
        const client = redisClient.getClient();
        
        await client.set('test:key', 'test:value');
        const result = await client.get('test:key');
        
        expect(result).toBe('test:value');
        
        await client.del('test:key');
    });
});
```

These patterns provide a solid foundation for building production-ready Redis applications in JavaScript.
