const RedisClient = require('./src/redis-client');

async function testConnection() {
    const redisClient = new RedisClient();
    
    try {
        console.log('🔌 Testing Redis connection...');
        await redisClient.connect();
        
        const client = redisClient.getClient();
        
        // Test basic operation
        const result = await client.ping();
        console.log('🏓 PING result:', result);
        
        // Test hash operations
        await client.hSet('test:connection', 'timestamp', new Date().toISOString());
        const timestamp = await client.hGet('test:connection', 'timestamp');
        console.log('✅ Hash operation successful:', timestamp);
        
        // Cleanup
        await client.del('test:connection');
        
        console.log('✅ Redis connection test passed!');
        
    } catch (error) {
        console.error('❌ Redis connection test failed:', error.message);
        console.log('\n🔧 Troubleshooting:');
        console.log('1. Verify Redis server details in src/redis-client.js');
        console.log('2. Check network connectivity to Redis server');
        console.log('3. Ensure Redis server is running and accessible');
    } finally {
        await redisClient.disconnect();
    }
}

testConnection();
