# Troubleshooting Guide - Lab 9

## Common Issues and Solutions

### 1. Connection Refused Error

**Error:**
```
Error: connect ECONNREFUSED 127.0.0.1:6379
```

**Solution:**
```bash
# Start Redis container
docker run -d --name redis-analytics-lab9 -p 6379:6379 redis:7-alpine

# Verify Redis is running
docker ps | grep redis
redis-cli ping
```

### 2. Module Not Found

**Error:**
```
Error: Cannot find module 'redis'
```

**Solution:**
```bash
# Install dependencies
npm install

# Verify installation
npm list redis
```

### 3. Empty Analytics Results

**Problem:** Analytics show no data or empty results

**Solution:**
```bash
# Load sample data first
npm run load-data

# Verify data exists
redis-cli DBSIZE
redis-cli KEYS "*"
```

### 4. Async/Await Errors

**Error:**
```
SyntaxError: await is only valid in async function
```

**Solution:**
Ensure all functions using `await` are declared as `async`:
```javascript
async function myFunction() {
    const result = await client.get('key');
    return result;
}
```

### 5. Redis Memory Issues

**Error:**
```
OOM command not allowed when used memory > 'maxmemory'
```

**Solution:**
```bash
# Increase Redis memory limit
redis-cli CONFIG SET maxmemory 2gb

# Or restart with higher limit
docker run -d --name redis-analytics-lab9 \
  -p 6379:6379 \
  redis:7-alpine redis-server --maxmemory 2gb
```

## Performance Optimization

### Batch Operations
Use pipelines for multiple operations:
```javascript
const pipeline = client.pipeline();
for (const item of items) {
    pipeline.sAdd('set:key', item);
}
await pipeline.exec();
```

### Connection Pooling
Reuse connections instead of creating new ones:
```javascript
// Good - single connection
const client = redis.createClient();
await client.connect();
// Use client for all operations

// Bad - multiple connections
async function operation1() {
    const client = redis.createClient();
    await client.connect();
    // ...
}
```

## Debugging Tips

### Enable Debug Logging
```javascript
const client = redis.createClient({
    socket: {
        host: 'localhost',
        port: 6379
    },
    legacyMode: false,
    socket: {
        reconnectStrategy: (retries) => {
            console.log(`Reconnection attempt ${retries}`);
            return Math.min(retries * 50, 1000);
        }
    }
});

client.on('error', (err) => console.error('Redis Error:', err));
client.on('connect', () => console.log('Redis Connected'));
client.on('ready', () => console.log('Redis Ready'));
client.on('reconnecting', () => console.log('Redis Reconnecting'));
```

### Monitor Redis Commands
```bash
# In terminal
redis-cli MONITOR

# See slow queries
redis-cli SLOWLOG GET 10
```

### Check Data Types
```bash
# Verify data type before operations
redis-cli TYPE key:name
```

## Best Practices

1. **Always handle errors:**
   ```javascript
   try {
       const result = await client.get('key');
   } catch (error) {
       console.error('Operation failed:', error);
   }
   ```

2. **Close connections properly:**
   ```javascript
   try {
       // operations
   } finally {
       await client.quit();
   }
   ```

3. **Use appropriate data structures:**
   - Sets for unique values
   - Sorted Sets for rankings
   - Choose based on access patterns

4. **Implement retry logic:**
   ```javascript
   async function withRetry(operation, maxRetries = 3) {
       for (let i = 0; i < maxRetries; i++) {
           try {
               return await operation();
           } catch (error) {
               if (i === maxRetries - 1) throw error;
               await new Promise(r => setTimeout(r, 1000 * Math.pow(2, i)));
           }
       }
   }
   ```
