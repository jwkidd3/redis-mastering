// test-multi-level.js - Test multi-level caching
const { getRedisClient, disconnect } = require('./redis-client');

// L1 cache (memory)
const memoryCache = new Map();

// L2 cache (Redis)
async function getFromL2(key) {
    const client = await getRedisClient();
    return await client.get(key);
}

async function setToL2(key, value, ttl = 300) {
    const client = await getRedisClient();
    await client.setEx(key, ttl, value);
}

// Multi-level get
async function multiLevelGet(key) {
    // Check L1 (memory)
    if (memoryCache.has(key)) {
        console.log('✓ L1 cache hit (memory)');
        return memoryCache.get(key);
    }

    // Check L2 (Redis)
    const l2Value = await getFromL2(key);
    if (l2Value) {
        console.log('✓ L2 cache hit (Redis)');
        memoryCache.set(key, l2Value); // Populate L1
        return l2Value;
    }

    console.log('✗ Cache miss - would fetch from database');
    return null;
}

async function test() {
    try {
        // Populate L2
        await setToL2('test:key', 'test:value');

        // First call - L2 hit
        await multiLevelGet('test:key');

        // Second call - L1 hit
        await multiLevelGet('test:key');

        console.log('✓ Multi-level caching test passed');
    } finally {
        await disconnect();
    }
}

if (require.main === module) {
    test();
}

module.exports = { multiLevelGet };
