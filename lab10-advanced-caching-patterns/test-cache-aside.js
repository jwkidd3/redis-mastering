// test-cache-aside.js - Test cache-aside pattern
const { getRedisClient, disconnect } = require('./redis-client');

// Simulated database
const database = {
    'CUST-001': { name: 'John Doe', email: 'john@example.com' },
    'CUST-002': { name: 'Jane Smith', email: 'jane@example.com' }
};

async function getCacheCustomer(customerId) {
    const client = await getRedisClient();
    const cacheKey = `cache:customer:${customerId}`;

    // Try cache first
    const cached = await client.get(cacheKey);
    if (cached) {
        console.log('✓ Cache hit');
        return JSON.parse(cached);
    }

    console.log('✗ Cache miss - fetching from database');

    // Fetch from database
    const data = database[customerId];
    if (data) {
        // Store in cache with TTL
        await client.setEx(cacheKey, 300, JSON.stringify(data));
    }

    return data;
}

async function test() {
    try {
        // First call - cache miss
        await getCustomer('CUST-001');

        // Second call - cache hit
        await getCustomer('CUST-001');

        console.log('✓ Cache-aside pattern test passed');
    } finally {
        await disconnect();
    }
}

if (require.main === module) {
    test();
}

module.exports = { getCustomer };
