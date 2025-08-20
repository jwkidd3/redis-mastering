#!/usr/bin/env node

/**
 * Run All Lab 8 Tests
 */

const { runClaimTests } = require('./claim.test');
const { testProducerAPI } = require('./producer.test');
const { testConsumerSetup } = require('./consumer.test');

async function runAllTests() {
    console.log('🚀 Running All Lab 8 Tests');
    console.log('='.repeat(50));
    
    try {
        await runClaimTests();
        console.log('\n' + '='.repeat(50));
        
        await testConsumerSetup();
        console.log('\n' + '='.repeat(50));
        
        await testProducerAPI();
        console.log('\n' + '='.repeat(50));
        
        console.log('\n🎉 All tests completed!');
        console.log('📝 Check individual test results above');
        
    } catch (error) {
        console.error('Test suite failed:', error);
        process.exit(1);
    }
}

if (require.main === module) {
    runAllTests();
}

module.exports = { runAllTests };
