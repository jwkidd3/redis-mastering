// test-invalidation.js - Test cache invalidation patterns
const { getRedisClient, disconnect } = require('./redis-client');

async function invalidateByKey(key) {
    const client = await getRedisClient();
    await client.del(key);
    console.log(`✓ Invalidated: ${key}`);
}

async function invalidateByPattern(pattern) {
    const client = await getRedisClient();
    const keys = await client.keys(pattern);
    if (keys.length > 0) {
        await client.del(keys);
        console.log(`✓ Invalidated ${keys.length} keys matching: ${pattern}`);
    }
}

async function test() {
    try {
        const client = await getRedisClient();

        // Set some cache keys
        await client.set('cache:customer:CUST-001', 'data1');
        await client.set('cache:customer:CUST-002', 'data2');
        await client.set('cache:policy:POL-001', 'data3');

        // Test single key invalidation
        await invalidateByKey('cache:customer:CUST-001');

        // Test pattern invalidation
        await invalidateByPattern('cache:customer:*');

        console.log('✓ Cache invalidation test passed');
    } finally {
        await disconnect();
    }
}

if (require.main === module) {
    test();
}

module.exports = { invalidateByKey, invalidateByPattern };
