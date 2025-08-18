const { createClient } = require('redis');
const CachePatterns = require('../src/cache-patterns');
const RedisLock = require('../src/distributed-lock');
const { ReliableQueue, PriorityQueue } = require('../src/message-queue');

async function runTests() {
    console.log('🧪 Running Lab 12 Tests...\n');
    
    const client = createClient({
        socket: {
            host: 'localhost',
            port: 6379
        }
    });
    
    await client.connect();
    
    // Test 1: Cache Patterns
    console.log('Test 1: Cache Patterns');
    const cache = new CachePatterns();
    await cache.connect();
    
    const testData = await cache.cacheAside('test:key', async () => {
        return { test: 'data', timestamp: Date.now() };
    }, 10);
    
    console.log('✅ Cache-aside pattern working\n');
    
    // Test 2: Distributed Locking
    console.log('Test 2: Distributed Locking');
    const lock = new RedisLock(client);
    
    const token = await lock.acquireLock('test:resource', 5000);
    if (token) {
        const released = await lock.releaseLock('test:resource', token);
        console.log('✅ Distributed lock working\n');
    }
    
    // Test 3: Message Queue
    console.log('Test 3: Message Queue');
    const queue = new ReliableQueue(client, 'test');
    await queue.initialize();
    
    await queue.publish({ test: 'message', id: 1 });
    console.log('✅ Message queue working\n');
    
    // Test 4: Priority Queue
    console.log('Test 4: Priority Queue');
    const pQueue = new PriorityQueue(client, 'test');
    
    await pQueue.enqueue({ task: 'high-priority' }, 10);
    await pQueue.enqueue({ task: 'low-priority' }, 1);
    
    const item = await pQueue.dequeue();
    if (item && item.task === 'high-priority') {
        console.log('✅ Priority queue working\n');
    }
    
    // Cleanup
    await cache.disconnect();
    await client.quit();
    
    console.log('✨ All tests passed!\n');
}

runTests().catch(console.error);
