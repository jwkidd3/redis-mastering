#!/usr/bin/env node

/**
 * Lab 8 Completion Verification
 */

const redisClient = require('../src/utils/redisClient');
const Claim = require('../src/models/claim');

class LabVerifier {
    constructor() {
        this.tests = [];
        this.score = 0;
        this.maxScore = 10;
    }

    async runAllTests() {
        console.log('🎯 Lab 8 Completion Verification');
        console.log('='.repeat(50));
        
        await redisClient.connect();
        
        await this.testEnvironmentSetup();
        await this.testStreamOperations();
        await this.testClaimLifecycle();
        await this.testConsumerGroups();
        await this.testErrorHandling();
        
        await redisClient.disconnect();
        
        this.displayResults();
        return this.score === this.maxScore;
    }

    async testEnvironmentSetup() {
        console.log('\n🔧 Test: Environment Setup');
        console.log('-'.repeat(30));
        
        try {
            // Test Redis connection
            const client = redisClient.getClient();
            const pong = await client.ping();
            
            if (pong === 'PONG') {
                this.addTest('Redis Connection', 'PASS', 'Successfully connected to Redis');
                this.score += 2;
            } else {
                this.addTest('Redis Connection', 'FAIL', 'Redis ping failed');
            }
        } catch ();
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
