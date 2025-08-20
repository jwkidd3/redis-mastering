// examples/basic-operations.js
const RedisClient = require('../src/clients/redisClient');

async function interactiveExamples() {
    console.log('🎮 Interactive Redis Operations');
    console.log('==============================');

    const redisClient = new RedisClient();
    
    try {
        await redisClient.connect();
        const client = redisClient.getClient();

        // String operations
        console.log('\n🔤 String Operations:');
        await client.set('example:greeting', 'Hello Redis from JavaScript!');
        const greeting = await client.get('example:greeting');
        console.log('Greeting:', greeting);

        // Numeric operations
        console.log('\n🔢 Numeric Operations:');
        await client.set('example:counter', 0);
        await client.incr('example:counter');
        await client.incrBy('example:counter', 5);
        const counter = await client.get('example:counter');
        console.log('Counter value:', counter);

        // JSON operations
        console.log('\n📋 JSON Data Operations:');
        const sampleData = {
            name: 'Alice Brown',
            age: 30,
            policies: ['AUTO001', 'HOME001']
        };
        await client.set('example:customer', JSON.stringify(sampleData));
        const customerData = JSON.parse(await client.get('example:customer'));
        console.log('Customer data:', customerData);

        // Multiple operations
        console.log('\n🔄 Multiple Operations:');
        await client.mSet({
            'example:key1': 'value1',
            'example:key2': 'value2',
            'example:key3': 'value3'
        });
        const values = await client.mGet(['example:key1', 'example:key2', 'example:key3']);
        console.log('Multiple values:', values);

        // Expiration
        console.log('\n⏰ Expiration Operations:');
        await client.setEx('example:temp', 60, 'This expires in 60 seconds');
        const ttl = await client.ttl('example:temp');
        console.log('TTL for temp key:', ttl, 'seconds');

        // Cleanup
        console.log('\n🧹 Cleanup:');
        const keys = await client.keys('example:*');
        if (keys.length > 0) {
            await client.del(keys);
            console.log('Deleted', keys.length, 'example keys');
        }

    } catch (error) {
        console.error('❌ Error in examples:', error.message);
    } finally {
        await redisClient.disconnect();
    }
}

// Run examples
interactiveExamples();