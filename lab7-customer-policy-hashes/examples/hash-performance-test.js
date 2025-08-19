const RedisClient = require('../src/redis-client');

async function hashPerformanceTest() {
    const redisClient = new RedisClient();
    
    try {
        await redisClient.connect();
        const client = redisClient.getClient();
        
        console.log('🚀 Hash Performance Testing\n');

        // Test 1: Single field operations
        console.log('📊 Single field operations...');
        const start1 = Date.now();
        
        for (let i = 0; i < 1000; i++) {
            await client.hSet(`perf:single:${i}`, 'field1', `value${i}`);
        }
        
        const end1 = Date.now();
        console.log(`Created 1000 single-field hashes in ${end1 - start1}ms`);

        // Test 2: Multi-field operations
        console.log('\n📊 Multi-field operations...');
        const start2 = Date.now();
        
        for (let i = 0; i < 1000; i++) {
            await client.hSet(`perf:multi:${i}`, {
                'field1': `value1_${i}`,
                'field2': `value2_${i}`,
                'field3': `value3_${i}`,
                'field4': `value4_${i}`,
                'field5': `value5_${i}`
            });
        }
        
        const end2 = Date.now();
        console.log(`Created 1000 multi-field hashes in ${end2 - start2}ms`);

        // Test 3: Batch retrieval
        console.log('\n📊 Batch retrieval test...');
        const start3 = Date.now();
        
        for (let i = 0; i < 100; i++) {
            await client.hGetAll(`perf:multi:${i}`);
        }
        
        const end3 = Date.now();
        console.log(`Retrieved 100 complete hashes in ${end3 - start3}ms`);

        // Test 4: Partial field retrieval
        console.log('\n📊 Partial field retrieval...');
        const start4 = Date.now();
        
        for (let i = 0; i < 100; i++) {
            await client.hmGet(`perf:multi:${i}`, ['field1', 'field3']);
        }
        
        const end4 = Date.now();
        console.log(`Retrieved 2 fields from 100 hashes in ${end4 - start4}ms`);

        // Test 5: Memory usage analysis
        console.log('\n💾 Memory usage analysis...');
        try {
            const memory1 = await client.memory('usage', 'perf:single:0');
            const memory2 = await client.memory('usage', 'perf:multi:0');
            console.log(`Single field hash memory: ${memory1} bytes`);
            console.log(`Multi field hash memory: ${memory2} bytes`);
        } catch (error) {
            console.log('Memory usage command not available on this Redis version');
        }

        // Cleanup performance test data
        console.log('\n🧹 Cleaning up test data...');
        const keys = await client.keys('perf:*');
        if (keys.length > 0) {
            await client.del(keys);
            console.log(`Deleted ${keys.length} test keys`);
        }

        console.log('\n✅ Performance test completed!');

    } catch (error) {
        console.error('❌ Performance test failed:', error);
    } finally {
        await redisClient.disconnect();
    }
}

hashPerformanceTest();
