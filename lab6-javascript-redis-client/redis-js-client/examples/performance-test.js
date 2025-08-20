// examples/performance-test.js
const RedisClient = require('../src/clients/redisClient');

async function performanceTest() {
    console.log('⚡ Performance Testing');
    console.log('====================');

    const redisClient = new RedisClient();
    
    try {
        await redisClient.connect();
        const client = redisClient.getClient();

        // Test SET operations
        console.log('\n📊 SET Operations Test:');
        const setStart = Date.now();
        const setPromises = [];
        
        for (let i = 0; i < 100; i++) {
            setPromises.push(client.set(`perf:test:${i}`, `value${i}`));
        }
        
        await Promise.all(setPromises);
        const setDuration = Date.now() - setStart;
        console.log(`✅ 100 SET operations completed in ${setDuration}ms`);
        console.log(`📈 Average: ${(setDuration / 100).toFixed(2)}ms per operation`);

        // Test GET operations
        console.log('\n📊 GET Operations Test:');
        const getStart = Date.now();
        const getPromises = [];
        
        for (let i = 0; i < 100; i++) {
            getPromises.push(client.get(`perf:test:${i}`));
        }
        
        const results = await Promise.all(getPromises);
        const getDuration = Date.now() - getStart;
        console.log(`✅ 100 GET operations completed in ${getDuration}ms`);
        console.log(`📈 Average: ${(getDuration / 100).toFixed(2)}ms per operation`);
        console.log(`📋 Retrieved ${results.length} values`);

        // Cleanup
        const keys = await client.keys('perf:test:*');
        if (keys.length > 0) {
            await client.del(keys);
            console.log(`🧹 Cleaned up ${keys.length} test keys`);
        }

    } catch (error) {
        console.error('❌ Performance test error:', error.message);
    } finally {
        await redisClient.disconnect();
    }
}

performanceTest();