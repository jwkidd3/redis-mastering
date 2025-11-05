// performance-test.js - Test caching performance
const { getRedisClient, disconnect } = require('./redis-client');

async function benchmarkCacheOperations() {
    const client = await getRedisClient();
    const iterations = 1000;

    // Benchmark SET operations
    console.log(`Running ${iterations} SET operations...`);
    const setStart = Date.now();
    for (let i = 0; i < iterations; i++) {
        await client.set(`bench:key:${i}`, `value:${i}`);
    }
    const setTime = Date.now() - setStart;
    console.log(`✓ SET: ${setTime}ms (${(iterations / (setTime / 1000)).toFixed(2)} ops/sec)`);

    // Benchmark GET operations
    console.log(`Running ${iterations} GET operations...`);
    const getStart = Date.now();
    for (let i = 0; i < iterations; i++) {
        await client.get(`bench:key:${i}`);
    }
    const getTime = Date.now() - getStart;
    console.log(`✓ GET: ${getTime}ms (${(iterations / (getTime / 1000)).toFixed(2)} ops/sec)`);

    // Cleanup
    const keys = await client.keys('bench:key:*');
    if (keys.length > 0) {
        await client.del(keys);
    }

    return { setTime, getTime };
}

async function test() {
    try {
        await benchmarkCacheOperations();
        console.log('✓ Performance test completed');
    } finally {
        await disconnect();
    }
}

if (require.main === module) {
    test();
}

module.exports = { benchmarkCacheOperations };
