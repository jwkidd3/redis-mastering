#!/usr/bin/env node

/**
 * Consumer Service Tests
 */

const redisClient = require('../src/utils/redisClient');

async function testConsumerSetup() {
    console.log('🧪 Testing Consumer Setup');
    console.log('='.repeat(40));
    
    try {
        await redisClient.connect();
        const client = redisClient.getClient();
        
        console.log('\n📊 Test 1: Stream Exists');
        try {
            const streamInfo = await client.xInfoStream('claims:events');
            console.log('✅ PASS', `Stream exists with ${streamInfo.length} events`);
        } catch (error) {
            if (error.message.includes('no such key')) {
                console.log('⚠️ INFO', 'Stream not yet created (normal for new setup)');
            } else {
                console.log('❌ FAIL', `Stream check failed: ${error.message}`);
            }
        }
        
        console.log('\n👥 Test 2: Consumer Group');
        try {
            await redisClient.createConsumerGroup('claims:events', 'test-consumer-group', ');
            const groups = await client.xInfoGroups('claims:events');
            const testGroup = groups.find(g => g.name === 'test-consumer-group');
            
            if (testGroup) {
                console.log('✅ PASS', 'Consumer group created and verified');
                // Clean up
                await client.xGroupDestroy('claims:events', 'test-consumer-group');
            } else {
                console.log('❌ FAIL', 'Consumer group not found');
            }
        } catch (error) {
            console.log('❌ FAIL', `Consumer group test failed: ${error.message}`);
        }
        
        console.log('\n📈 Test 3: Stream Writing');
        try {
            const streamId = await client.xAdd('claims:events', '*', {
                type: 'test_event',
                message: 'Consumer test event',
                timestamp: Date.now()
            });
            console.log('✅ PASS', `Test event added: ${streamId}`);
        } catch (error) {
            console.log('❌ FAIL', `Stream writing failed: ${error.message}`);
        }
        
        console.log('\n🎉 Consumer tests completed!');
        
    } catch (error) {
        console.error('Consumer test failed:', error);
    } finally {
        await redisClient.disconnect();
    }
}

if (require.main === module) {
    testConsumerSetup();
}

module.exports = { testConsumerSetup };
