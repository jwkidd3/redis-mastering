#!/usr/bin/env node

/**
 * Claim Model Tests
 */

const redisClient = require('../src/utils/redisClient');
const Claim = require('../src/models/claim');

async function runClaimTests() {
    console.log('🧪 Running Claim Model Tests');
    console.log('='.repeat(40));
    
    try {
        await redisClient.connect();
        const claim = new Claim(redisClient);
        
        console.log('\n📝 Test 1: Submit Valid Claim');
        const validClaim = {
            customer_id: 'CUST-TEST-001',
            policy_number: 'POL-TEST-001',
            amount: 1500,
            description: 'Test claim submission'
        };
        
        const submitResult = await claim.submitClaim(validClaim);
        console.log(submitResult.success ? '✅ PASS' : '❌ FAIL', 
                   `Claim submission: ${submitResult.claim_id || submitResult.error}`);
        
        if (submitResult.success) {
            const claimId = submitResult.claim_id;
            
            console.log('\n📋 Test 2: Update Claim Status');
            const updateResult = await claim.updateClaimStatus(claimId, 'under_review');
            console.log(updateResult.success ? '✅ PASS' : '❌ FAIL', 
                       `Status update: ${updateResult.success ? 'Updated' : updateResult.error}`);
            
            console.log('\n📚 Test 3: Get Claim History');
            const historyResult = await claim.getClaimHistory(claimId);
            console.log(historyResult.success ? '✅ PASS' : '❌ FAIL',
                       `History retrieval: ${historyResult.success ? historyResult.events.length + ' events' : historyResult.error}`);
        }
        
        console.log('\n❌ Test 4: Submit Invalid Claim');
        const invalidClaim = { description: 'Missing required fields' };
        const invalidResult = await claim.submitClaim(invalidClaim);
        console.log(!invalidResult.success ? '✅ PASS' : '❌ FAIL',
                   `Invalid claim rejection: ${invalidResult.error || 'Should have failed'}`);
        
        console.log('\n🎉 Claim tests completed!');
        
    } catch (error) {
        console.error('Test failed:', error);
    } finally {
        await redisClient.disconnect();
    }
}

if (require.main === module) {
    runClaimTests();
}

module.exports = { runClaimTests };
