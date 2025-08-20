#!/usr/bin/env node

/**
 * Load Sample Claims Data for Testing
 */

const redisClient = require('../src/utils/redisClient');
const Claim = require('../src/models/claim');

const sampleClaims = [
    {
        customer_id: 'CUST-001',
        policy_number: 'POL-AUTO-001',
        amount: 750,
        description: 'Minor fender bender - rear bumper repair',
        incident_date: '2024-08-15T10:30:00Z'
    },
    {
        customer_id: 'CUST-002', 
        policy_number: 'POL-HOME-002',
        amount: 2500,
        description: 'Water damage from pipe burst in basement',
        incident_date: '2024-08-14T14:22:00Z'
    },
    {
        customer_id: 'CUST-003',
        policy_number: 'POL-AUTO-003', 
        amount: 15000,
        description: 'Total vehicle loss from accident',
        incident_date: '2024-08-13T08:45:00Z'
    },
    {
        customer_id: 'CUST-004',
        policy_number: 'POL-HOME-004',
        amount: 450,
        description: 'Window replacement after storm',
        incident_date: '2024-08-16T16:00:00Z'
    },
    {
        customer_id: 'CUST-005',
        policy_number: 'POL-AUTO-005',
        amount: 3200,
        description: 'Engine repair after collision',
        incident_date: '2024-08-12T12:15:00Z'
    }
];

async function loadSampleData() {
    console.log('📋 Loading sample claims data...');
    
    try {
        await redisClient.connect();
        const claim = new Claim(redisClient);
        
        const results = [];
        
        for (const claimData of sampleClaims) {
            console.log(`📝 Submitting claim for ${claimData.customer_id}...`);
            const result = await claim.submitClaim(claimData);
            
            if (result.success) {
                console.log(`✅ Claim created: ${result.claim_id}`);
                results.push(result.claim_id);
                
                // Add some random status updates
                if (Math.random() > 0.5) {
                    await new Promise(resolve => setTimeout(resolve, 100));
                    await claim.updateClaimStatus(result.claim_id, 'under_review', {
                        reviewer: 'agent_001',
                        notes: 'Initial review in progress'
                    });
                    console.log(`📋 Status updated for ${result.claim_id}: under_review`);
                }
                
                // Auto-approve small claims
                if (claimData.amount < 1000) {
                    await new Promise(resolve => setTimeout(resolve, 100));
                    await claim.approveClaim(result.claim_id, claimData.amount, 'auto_system');
                    console.log(`🚀 Auto-approved ${result.claim_id}`);
                    
                    await new Promise(resolve => setTimeout(resolve, 100));
                    await claim.processPayment(result.claim_id, claimData.amount);
                    console.log(`💰 Payment processed for ${result.claim_id}`);
                }
            } else {
                console.error(`❌ Failed to create claim: ${result.error}`);
            }
        }
        
        console.log('\n🎉 Sample data loading complete!');
        console.log(`📊 Created ${results.length} claims:`);
        results.forEach(claimId => console.log(`   - ${claimId}`));
        
        // Display stream info
        const client = redisClient.getClient();
        const streamInfo = await client.xInfoStream('claims:events');
        console.log(`\n📈 Stream statistics:`);
        console.log(`   Total events: ${streamInfo.length}`);
        console.log(`   First event: ${streamInfo.firstEntry ? streamInfo.firstEntry.id : 'None'}`);
        console.log(`   Last event: ${streamInfo.lastEntry ? streamInfo.lastEntry.id : 'None'}`);
        
    } catch (error) {
        console.error('Failed to load sample data:', error);
        process.exit(1);
    } finally {
        await redisClient.disconnect();
    }
}

// Run if called directly
if (require.main === module) {
    loadSampleData();
}

module.exports = { loadSampleData, sampleClaims };
