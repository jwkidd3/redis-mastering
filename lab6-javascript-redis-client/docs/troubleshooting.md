# JavaScript Redis Client Troubleshooting

## Connection Issues

### Problem: "ECONNREFUSED" Error

**Symptoms:**
```
Error: connect ECONNREFUSED [IP]:6379
```

**Solutions:**
1. **Verify server details in .env file**
   ```bash
   # Check your .env file
   cat .env
   
   # Ensure values match instructor's details
   REDIS_HOST=redis-server.training.com
   REDIS_PORT=6379
   ```

2. **Test with Redis CLI first**
   ```bash
   redis-cli -h redis-server.training.com -p 6379 ping
   ```

3. **Check network connectivity**
   ```bash
   ping redis-server.training.com
   telnet redis-server.training.com 6379
   ```

### Problem: "NOAUTH Authentication required"

**Solution:**
```javascript
// Add password to .env file
REDIS_PASSWORD=your_actual_password

// Verify in Redis client config
const client = redis.createClient({
    socket: { host: process.env.REDIS_HOST, port: process.env.REDIS_PORT },
    password: process.env.REDIS_PASSWORD
});
```

### Problem: Connection Timeout

**Solutions:**
```javascript
// Increase timeout in client config
const client = redis.createClient({
    socket: {
        host: process.env.REDIS_HOST,
        port: process.env.REDIS_PORT,
        connectTimeout: 20000,  // 20 seconds
        commandTimeout: 10000   // 10 seconds
    }
});
```

## Node.js Issues

### Problem: "Cannot find module 'redis'"

**Solutions:**
```bash
# Reinstall dependencies
rm -rf node_modules package-lock.json
npm install

# Check if redis is in dependencies
npm list redis

# Install specifically
npm install redis@^4.6.0
```

### Problem: "SyntaxError: Unexpected token"

**Causes & Solutions:**
1. **Using old Node.js version**
   ```bash
   node --version  # Should be 16+
   ```

2. **Missing async/await**
   ```javascript
   // Wrong
   const value = client.get('key');
   
   // Correct
   const value = await client.get('key');
   ```

3. **Missing await in function**
   ```javascript
   // Wrong
   function getData() {
       return client.get('key');
   }
   
   // Correct
   async function getData() {
       return await client.get('key');
   }
   ```

### Problem: "UnhandledPromiseRejectionWarning"

**Solution:**
```javascript
// Always use try-catch with async operations
async function safeOperation() {
    try {
        const result = await client.get('key');
        return result;
    } catch (error) {
        console.error('Redis operation failed:', error.message);
        throw error; // or handle gracefully
    }
}
```

## Redis Operation Issues

### Problem: Data Not Found

**Debugging Steps:**
```javascript
// Check if key exists
const exists = await client.exists('customer:123');
console.log('Key exists:', exists);

// Check key type
const type = await client.type('customer:123');
console.log('Key type:', type);

// List keys matching pattern
const keys = await client.keys('customer:*');
console.log('Customer keys:', keys);

// Check TTL
const ttl = await client.ttl('customer:123');
console.log('TTL:', ttl); // -1 = no expiry, -2 = expired
```

### Problem: JSON Parse Errors

**Solutions:**
```javascript
// Safe JSON parsing
async function safeGetJSON(key) {
    try {
        const data = await client.get(key);
        if (!data) return null;
        
        return JSON.parse(data);
    } catch (error) {
        console.error('JSON parse error for key', key, ':', error.message);
        return null;
    }
}

// Validate before parsing
async function getValidJSON(key) {
    const data = await client.get(key);
    if (!data || typeof data !== 'string') {
        return null;
    }
    
    try {
        return JSON.parse(data);
    } catch (error) {
        console.error('Invalid JSON in key', key, ':', data);
        return null;
    }
}
```

### Problem: Type Errors

**Understanding Redis Data Types:**
```javascript
// Check what type a key contains
const type = await client.type('mykey');

switch (type) {
    case 'string':
        const value = await client.get('mykey');
        break;
    case 'hash':
        const hash = await client.hGetAll('mykey');
        break;
    case 'list':
        const list = await client.lRange('mykey', 0, -1);
        break;
    case 'set':
        const set = await client.sMembers('mykey');
        break;
    case 'none':
        console.log('Key does not exist');
        break;
}
```

## Environment Issues

### Problem: .env Variables Not Loading

**Solutions:**
```javascript
// Ensure dotenv is loaded at the top
require('dotenv').config();

// Check if variables are loaded
console.log('Redis Host:', process.env.REDIS_HOST);
console.log('Redis Port:', process.env.REDIS_PORT);

// Use defaults if not set
const redisConfig = {
    host: process.env.REDIS_HOST || 'localhost',
    port: parseInt(process.env.REDIS_PORT) || 6379
};
```

### Problem: Cross-Platform Path Issues

**Solutions:**
```javascript
// Use path.join for file paths
const path = require('path');

// Wrong
require('../config/redis.js');

// Better
require(path.join(__dirname, '..', 'config', 'redis.js'));
```

## Performance Issues

### Problem: Slow Operations

**Debugging:**
```javascript
// Measure operation time
async function timedOperation(operation) {
    const start = Date.now();
    const result = await operation();
    const duration = Date.now() - start;
    
    console.log(`Operation took ${duration}ms`);
    return result;
}

// Example usage
const customer = await timedOperation(() => 
    client.get('customer:123')
);
```

**Optimization:**
```javascript
// Use batch operations for multiple keys
// Slow - multiple round trips
const customer1 = await client.get('customer:1');
const customer2 = await client.get('customer:2');
const customer3 = await client.get('customer:3');

// Fast - single round trip
const customers = await client.mGet([
    'customer:1',
    'customer:2', 
    'customer:3'
]);
```

### Problem: Memory Leaks

**Solutions:**
```javascript
// Always disconnect when done
process.on('SIGINT', async () => {
    console.log('Shutting down...');
    await redisClient.disconnect();
    process.exit(0);
});

// Use connection pooling for high-volume apps
class ConnectionPool {
    constructor(size = 10) {
        this.connections = [];
        this.size = size;
    }
    
    async initialize() {
        for (let i = 0; i < this.size; i++) {
            const client = redis.createClient(config);
            await client.connect();
            this.connections.push(client);
        }
    }
    
    getConnection() {
        return this.connections[Math.floor(Math.random() * this.size)];
    }
}
```

## Development Tips

### Debugging Commands

```javascript
// Enable Redis command monitoring
client.on('command', (command) => {
    console.log('Redis command:', command);
});

// Log all Redis events
client.on('connect', () => console.log('Redis connecting...'));
client.on('ready', () => console.log('Redis ready'));
client.on('error', (err) => console.error('Redis error:', err));
client.on('end', () => console.log('Redis connection ended'));
```

### Testing Connection

```javascript
// Comprehensive connection test
async function testRedisConnection() {
    try {
        // Test basic connection
        await client.ping();
        console.log('✅ Connection: OK');
        
        // Test write operation
        await client.set('test:write', 'success');
        console.log('✅ Write: OK');
        
        // Test read operation
        const value = await client.get('test:write');
        console.log('✅ Read: OK', value);
        
        // Test delete operation
        await client.del('test:write');
        console.log('✅ Delete: OK');
        
        // Get server info
        const info = await client.info('server');
        console.log('✅ Server info retrieved');
        
        return true;
    } catch (error) {
        console.error('❌ Connection test failed:', error.message);
        return false;
    }
}
```

### Common Patterns to Avoid

```javascript
// Don't mix callbacks and promises
// Wrong
client.get('key', (err, result) => {
    if (err) throw err;
    console.log(result);
});

// Correct
try {
    const result = await client.get('key');
    console.log(result);
} catch (error) {
    console.error(error);
}

// Don't forget to handle connection errors
// Wrong
const client = redis.createClient();
await client.connect();

// Correct
const client = redis.createClient();
client.on('error', (err) => console.error('Redis error:', err));
await client.connect();

// Don't create multiple clients unnecessarily
// Wrong - creates new client each time
function getClient() {
    return redis.createClient(config);
}

// Correct - reuse single client
const client = redis.createClient(config);
function getClient() {
    return client;
}
```

## Getting Help

### Diagnostic Information to Collect

```javascript
// System information
console.log('Node.js version:', process.version);
console.log('Platform:', process.platform);
console.log('Architecture:', process.arch);

// Redis client information
console.log('Redis client version:', require('redis/package.json').version);

// Environment information
console.log('Environment variables:');
console.log('REDIS_HOST:', process.env.REDIS_HOST);
console.log('REDIS_PORT:', process.env.REDIS_PORT);
console.log('NODE_ENV:', process.env.NODE_ENV);

// Connection test results
const connectionOK = await testRedisConnection();
console.log('Connection test passed:', connectionOK);
```

### When to Ask for Help

Contact instructor if:
- Connection consistently fails after checking all settings
- Getting unusual error messages not covered here
- Performance is significantly slower than expected
- Data operations behave unexpectedly
- Environment setup issues persist

Provide the diagnostic information above when asking for help.
