#!/usr/bin/env node

const ClaimsQueue = require('../src/claims-queue');
const ClaimsProcessor = require('../src/claims-processor');

async function runSystemTest() {
    console.log('🧪 Testing Claims Processing System');
    console.log('===================================\n');

    const queue = new ClaimsQueue();
    const processor = new ClaimsProcessor('TEST-PROCESSOR');

    try {
        // Connect to Redis
        console.log('1. Testing Redis connection...');
        await queue.connect();
        await processor.connect();
        console.log('   ✅ Connected successfully\n');

        // Test claim submission
        console.log('2. Testing claim submission...');
        const testClaim = {
            policyNumber: 'TEST-001',
            customerName: 'Test Customer',
            claimType: 'auto',
            priority: 'urgent',
            amount: 1000,
            description: 'Test claim for system validation'
        };

        const claimId = await queue.submitClaim(testClaim);
        console.log(`   ✅ Claim submitted: ${claimId}\n`);

        // Test queue statistics
        console.log('3. Testing queue statistics...');
        const stats = await queue.getQueueStats();
        console.log('   ✅ Queue stats retrieved:', stats);
        console.log('');

        // Test claim processing
        console.log('4. Testing claim processing...');
        const processedClaimId = await processor.processNextClaim();
        console.log(`   ✅ Processed claim: ${processedClaimId}\n`);

        // Test claim data retrieval
        console.log('5. Testing claim data retrieval...');
        const claimData = await queue.getClaimData(claimId);
        console.log('   ✅ Claim data retrieved:', claimData ? 'Success' : 'Failed');
        console.log('');

        // Test blocking operations
        console.log('6. Testing blocking operations...');
        setTimeout(async () => {
            await queue.submitClaim({
                ...testClaim,
                policyNumber: 'TEST-002',
                customerName: 'Second Test Customer'
            });
        }, 2000);

        const blockResult = await processor.waitForClaim(5);
        console.log('   ✅ Blocking operation:', blockResult ? 'Success' : 'Timeout');
        console.log('');

        // Final statistics
        console.log('7. Final system state...');
        const finalStats = await queue.getQueueStats();
        console.log('   ✅ Final stats:', finalStats);

        console.log('\n🎉 All tests completed successfully!');

    } catch (error) {
        console.error('❌ Test failed:', error);
        process.exit(1);
    } finally {
        await queue.disconnect();
        await processor.disconnect();
    }
}

runSystemTest().catch(console.error);
