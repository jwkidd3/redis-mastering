const RedisClient = require('./src/redis-client');

async function testConnection() {
    const redisClient = new RedisClient();
    
    try {
        await redisClient.connect();
        const client = redisClient.getClient();
        
        // Test basic operation
        await client.ping();
        console.log('🏓 PING successful');
        
        await redisClient.disconnect();
    } catch (error) {
        console.error('Connection test failed:', error);
    }
}

testConnection();