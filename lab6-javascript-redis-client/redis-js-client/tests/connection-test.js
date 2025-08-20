// tests/connection-test.js
const RedisClient = require('../src/clients/redisClient');

async function testConnection() {
    console.log('🧪 Testing Redis Connection...');
    console.log('================================');

    const redisClient = new RedisClient();

    try {
        // Test connection
        await redisClient.connect();
        
        // Test basic operations
        const client = redisClient.getClient();
        
        // Set and get test data
        await client.set('test:connection', 'success');
        const result = await client.get('test:connection');
        console.log('✅ Test data:', result);
        
        // Clean up test data
        await client.del('test:connection');
        
        // Health check
        const health = await redisClient.healthCheck();
        console.log('🏥 Health check:', health);
        
    } catch (error) {
        console.error('❌ Connection test failed:', error.message);
    } finally {
        await redisClient.disconnect();
    }
}

// Run test if this file is executed directly
if (require.main === module) {
    testConnection();
}

module.exports = testConnection;