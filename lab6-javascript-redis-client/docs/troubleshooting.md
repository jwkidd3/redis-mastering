# Lab 6 Troubleshooting Guide

## Common Issues and Solutions

### 1. Redis Connection Failed

**Problem:** `Error: connect ECONNREFUSED 127.0.0.1:6379`

**Solutions:**
```bash
# Check if Redis is running
docker ps | grep redis

# Start Redis container if not running
docker run -d --name redis-lab -p 6379:6379 redis:7-alpine

# Check Redis logs
docker logs redis-lab
```

### 2. Module Not Found Error

**Problem:** `Cannot find module 'redis'`

**Solutions:**
```bash
# Install dependencies
npm install

# If issues persist, clear cache
npm cache clean --force
rm -rf node_modules package-lock.json
npm install
```

### 3. Async/Await Not Working

**Problem:** `SyntaxError: await is only valid in async functions`

**Solution:**
```javascript
// Ensure function is marked as async
async function myFunction() {
  const result = await redisOperation();
  return result;
}

// Or use .then() for promises
redisOperation().then(result => {
  console.log(result);
});
```

### 4. Connection Pool Issues

**Problem:** Too many connections or connection timeout

**Solutions:**
```javascript
// Configure connection pool
const client = redis.createClient({
  socket: {
    host: 'localhost',
    port: 6379,
    connectTimeout: 10000
  },
  commandsQueueMaxLength: 100
});

// Always close connections when done
await client.quit();
```

### 5. Memory Issues with Large Datasets

**Problem:** JavaScript heap out of memory

**Solutions:**
```bash
# Increase Node.js memory limit
node --max-old-space-size=4096 src/app.js

# Use streaming for large operations
const stream = client.scanStream({
  match: 'pattern:*',
  count: 100
});
```

### 6. Test Failures

**Problem:** Integration tests failing

**Solutions:**
```bash
# Ensure Redis is clean
redis-cli FLUSHALL

# Run tests with verbose output
npm test -- --verbose

# Run specific test file
npm test -- redis.test.js
```

## Performance Debugging

### Check Redis Performance
```bash
# Monitor commands in real-time
redis-cli monitor

# Check slow queries
redis-cli SLOWLOG GET 10

# View memory usage
redis-cli INFO memory
```

### JavaScript Profiling
```javascript
// Add timing to operations
console.time('redis-operation');
await client.set('key', 'value');
console.timeEnd('redis-operation');

// Use performance hooks
const { performance } = require('perf_hooks');
const start = performance.now();
// ... operation ...
const duration = performance.now() - start;
```

### Connection Monitoring
```javascript
// Log connection events
client.on('connect', () => console.log('Connected'));
client.on('ready', () => console.log('Ready'));
client.on('error', (err) => console.error('Error:', err));
client.on('reconnecting', () => console.log('Reconnecting'));
```

## Getting Help

If issues persist:

1. **Check Redis logs:** `docker logs redis-lab`
2. **Verify Node version:** `node --version` (should be 14+)
3. **Review error stack trace** for specific line numbers
4. **Test with redis-cli** to isolate JavaScript issues
5. **Ask instructor** for assistance

## Useful Commands

```bash
# Complete environment check
node --version
npm --version
redis-cli ping
docker ps

# Clean environment
docker stop redis-lab
docker rm redis-lab
rm -rf node_modules
npm cache clean --force

# Fresh start
docker run -d --name redis-lab -p 6379:6379 redis:7-alpine
npm install
npm start
```
