# Redis Lists Reference for Queue Processing

## List Commands Used in Lab 8

### Basic List Operations

```javascript
// Push operations (add elements)
await client.lPush(key, value)      // Push to left (head)
await client.rPush(key, value)      // Push to right (tail)
await client.lPushX(key, value)     // Push only if list exists

// Pop operations (remove and return elements)
await client.lPop(key)              // Pop from left (head)
await client.rPop(key)              // Pop from right (tail)

// Blocking pop operations (wait for elements)
await client.blPop(keys, timeout)   // Blocking left pop
await client.brPop(keys, timeout)   // Blocking right pop

// List information
await client.lLen(key)              // Get list length
await client.lRange(key, start, end) // Get range of elements
```

### Advanced List Operations

```javascript
// List manipulation
await client.lRem(key, count, value) // Remove elements
await client.lSet(key, index, value) // Set element at index
await client.lIndex(key, index)      // Get element at index

// List trimming
await client.lTrim(key, start, end)  // Keep only specified range

// Moving elements between lists
await client.rPopLPush(source, dest) // Pop from source, push to dest
await client.brPopLPush(source, dest, timeout) // Blocking version
```

## Queue Patterns

### 1. Simple FIFO Queue
```javascript
// Producer
await client.lPush('queue', item)

// Consumer
const item = await client.rPop('queue')
```

### 2. Priority Queue System
```javascript
// High priority queue
await client.lPush('urgent_queue', item)

// Standard priority queue  
await client.lPush('standard_queue', item)

// Consumer (check urgent first)
let item = await client.rPop('urgent_queue')
if (!item) {
    item = await client.rPop('standard_queue')
}
```

### 3. Blocking Queue Consumer
```javascript
// Wait for items from multiple queues
const result = await client.brPop(['urgent_queue', 'standard_queue'], 30)
if (result) {
    const { key, element } = result
    console.log(`Got ${element} from ${key}`)
}
```

### 4. Work Queue with Processing Status
```javascript
// Move from pending to processing
const item = await client.rPopLPush('pending_queue', 'processing_queue')

// After processing, remove from processing
await client.lRem('processing_queue', 1, item)
await client.lPush('completed_queue', item)
```

## Queue Management Patterns

### Dead Letter Queue
```javascript
async function processWithRetry(item, maxRetries = 3) {
    for (let attempt = 1; attempt <= maxRetries; attempt++) {
        try {
            await processItem(item)
            return true
        } catch (error) {
            if (attempt === maxRetries) {
                // Move to dead letter queue
                await client.lPush('dead_letter_queue', item)
                return false
            }
            // Retry after delay
            await new Promise(resolve => setTimeout(resolve, 1000 * attempt))
        }
    }
}
```

### Queue Monitoring
```javascript
async function getQueueStats() {
    return {
        pending: await client.lLen('pending_queue'),
        processing: await client.lLen('processing_queue'),
        completed: await client.lLen('completed_queue'),
        failed: await client.lLen('failed_queue')
    }
}
```

## Performance Considerations

### 1. Blocking vs Polling
```javascript
// ❌ Inefficient polling
while (true) {
    const item = await client.rPop('queue')
    if (item) {
        await processItem(item)
    } else {
        await new Promise(resolve => setTimeout(resolve, 1000)) // Wait
    }
}

// ✅ Efficient blocking
while (true) {
    const result = await client.brPop(['queue'], 10) // 10 second timeout
    if (result) {
        await processItem(result.element)
    }
}
```

### 2. Batch Processing
```javascript
// Process multiple items at once
const items = []
for (let i = 0; i < batchSize; i++) {
    const item = await client.rPop('queue')
    if (item) items.push(item)
    else break
}

if (items.length > 0) {
    await processBatch(items)
}
```

### 3. Memory Management
```javascript
// Limit queue size
async function addToLimitedQueue(key, item, maxSize = 1000) {
    await client.lPush(key, item)
    await client.lTrim(key, 0, maxSize - 1) // Keep only latest items
}
```

## Error Handling

### Connection Recovery
```javascript
const client = redis.createClient({
    host: 'redis-server.training.com',
    port: 6379,
    retry_strategy: (options) => {
        if (options.error && options.error.code === 'ECONNREFUSED') {
            return new Error('Redis server refused connection')
        }
        if (options.total_retry_time > 1000 * 60 * 60) {
            return new Error('Retry time exhausted')
        }
        return Math.min(options.attempt * 100, 3000)
    }
})
```

### Graceful Shutdown
```javascript
let isShuttingDown = false

process.on('SIGINT', () => {
    isShuttingDown = true
    console.log('Graceful shutdown initiated...')
})

while (!isShuttingDown) {
    const result = await client.brPop(['queue'], 5)
    if (result) {
        await processItem(result.element)
    }
}

await client.quit()
```

## Common Use Cases

### 1. Task Queue
```javascript
// Job queue for background processing
await client.lPush('jobs', JSON.stringify({
    type: 'email',
    data: { to: 'user@example.com', subject: 'Welcome' }
}))
```

### 2. Event Sourcing
```javascript
// Event log using lists
await client.lPush('events', JSON.stringify({
    timestamp: Date.now(),
    type: 'user_registered',
    data: { userId: 123, email: 'user@example.com' }
}))
```

### 3. Real-time Notifications
```javascript
// Notification queue per user
await client.lPush(`notifications:${userId}`, JSON.stringify(notification))

// Consumer gets notifications
const notification = await client.brPop([`notifications:${userId}`], 0)
```

## Best Practices

1. **Use appropriate data structures**: Lists for queues, Sets for uniqueness, Sorted Sets for priority
2. **Implement proper error handling**: Retry logic, dead letter queues, connection recovery
3. **Monitor queue lengths**: Prevent unbounded growth
4. **Use blocking operations**: More efficient than polling
5. **Batch operations when possible**: Reduce network round trips
6. **Plan for scale**: Consider sharding strategies for high-volume scenarios

## Debugging Commands

```bash
# Check queue lengths
redis-cli -h hostname -p port LLEN queue_name

# View queue contents
redis-cli -h hostname -p port LRANGE queue_name 0 -1

# Monitor queue activity
redis-cli -h hostname -p port MONITOR

# Get server info
redis-cli -h hostname -p port INFO memory
```
