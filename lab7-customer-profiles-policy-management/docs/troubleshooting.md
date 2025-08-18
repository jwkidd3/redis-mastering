# Troubleshooting Guide - Lab 7

## Common Issues and Solutions

### 1. Connection Issues

**Problem:** Cannot connect to Redis
```
Error: Redis connection to localhost:6379 failed
```

**Solution:**
```bash
# Check if Redis is running
docker ps | grep redis

# Start Redis if not running
docker run -d --name redis-lab7 -p 6379:6379 redis:7-alpine

# Test connection
redis-cli ping
```

### 2. Module Import Errors

**Problem:** Cannot find module 'redis'
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

### 3. Hash Operation Errors

**Problem:** Hash fields not updating
```javascript
// Wrong way
await client.hSet('key', 'field', {object}); // Objects not allowed

// Correct way
await client.hSet('key', {
    field1: 'value1',
    field2: 'value2'
});
```

### 4. Memory Issues

**Problem:** Redis running out of memory

**Solution:**
```bash
# Check memory usage
redis-cli INFO memory | grep used_memory_human

# Set memory limit
redis-cli CONFIG SET maxmemory 512mb
redis-cli CONFIG SET maxmemory-policy allkeys-lru

# Clear test data
redis-cli FLUSHDB
```

### 5. Async/Await Issues

**Problem:** Operations not completing

**Solution:**
```javascript
// Always use async/await
async function operation() {
    try {
        await client.connect();
        const result = await client.hGetAll('key');
        console.log(result);
    } catch (error) {
        console.error('Error:', error);
    } finally {
        await client.quit();
    }
}
```

## Debugging Commands

```bash
# Monitor Redis commands in real-time
redis-cli MONITOR

# Check Redis logs
docker logs redis-lab7

# View all keys
redis-cli KEYS "*"

# Check specific hash
redis-cli HGETALL customer:CUST001:profile

# Database statistics
redis-cli INFO stats
```

## Performance Optimization

```javascript
// Use pipelines for bulk operations
const pipeline = client.multi();
for (let i = 0; i < 1000; i++) {
    pipeline.hSet(`key:${i}`, data);
}
await pipeline.exec();

// Use HMGET for multiple fields
const fields = await client.hmGet('hash', ['field1', 'field2', 'field3']);
```
