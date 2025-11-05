// test-connection.js - Test Redis connection
const RedisClient = require('./redis-client');

async function testConnection() {
    const redisClient = new RedisClient();

    try {
        // Connect to Redis
        await redisClient.connect();

        // Test basic operations
        const client = redisClient.getClient();

        // SET operation
        await client.set('test:connection', 'success');

        // GET operation
        const value = await client.get('test:connection');
        console.log('✓ Test value:', value);

        // Clean up
        await client.del('test:connection');

        console.log('✓ Connection test passed!');

    } catch (error) {
        console.error('✗ Connection test failed:', error.message);
        process.exit(1);
    } finally {
        await redisClient.disconnect();
    }
}

testConnection();
