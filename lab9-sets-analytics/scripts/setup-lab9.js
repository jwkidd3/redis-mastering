const CustomerSegments = require('../src/customer-segments');
const AgentLeaderboard = require('../src/agent-leaderboard');
const RiskScoring = require('../src/risk-scoring');
const client = require('../src/connection');

async function setupLab9() {
    console.log('🚀 Setting up Lab 9: Analytics with Sets and Sorted Sets');
    console.log('='.repeat(60));

    try {
        const segments = new CustomerSegments();
        const leaderboard = new AgentLeaderboard();
        const riskScoring = new RiskScoring();

        // Create sample customer segments
        console.log('\n📊 Creating customer segments...');
        
        // Premium customers
        await segments.addToSegment('CUST001', 'premium');
        await segments.addToSegment('CUST002', 'premium');
        await segments.addToSegment('CUST003', 'premium');
        
        // Standard customers
        await segments.addToSegment('CUST004', 'standard');
        await segments.addToSegment('CUST005', 'standard');
        await segments.addToSegment('CUST006', 'standard');
        
        // New customers
        await segments.addToSegment('CUST007', 'new');
        await segments.addToSegment('CUST008', 'new');
        
        // Active/Inactive status
        const activeCustomers = ['CUST001', 'CUST002', 'CUST004', 'CUST005', 'CUST007'];
        const inactiveCustomers = ['CUST003', 'CUST006', 'CUST008'];
        
        for (const customerId of activeCustomers) {
            await segments.addToSegment(customerId, 'active');
        }
        
        for (const customerId of inactiveCustomers) {
            await segments.addToSegment(customerId, 'inactive');
        }

        // Setup agent leaderboards
        console.log('\n🏆 Setting up agent leaderboards...');
        
        // Sales leaderboard
        await leaderboard.updateAgentScore('sales', 'AGENT001', 15000);
        await leaderboard.updateAgentScore('sales', 'AGENT002', 12500);
        await leaderboard.updateAgentScore('sales', 'AGENT003', 18000);
        await leaderboard.updateAgentScore('sales', 'AGENT004', 9500);
        await leaderboard.updateAgentScore('sales', 'AGENT005', 11000);

        // Policies sold leaderboard
        await leaderboard.updateAgentScore('policies_sold', 'AGENT001', 25);
        await leaderboard.updateAgentScore('policies_sold', 'AGENT002', 30);
        await leaderboard.updateAgentScore('policies_sold', 'AGENT003', 28);
        await leaderboard.updateAgentScore('policies_sold', 'AGENT004', 22);
        await leaderboard.updateAgentScore('policies_sold', 'AGENT005', 24);

        // Customer satisfaction leaderboard
        await leaderboard.updateAgentScore('customer_satisfaction', 'AGENT001', 4.8);
        await leaderboard.updateAgentScore('customer_satisfaction', 'AGENT002', 4.5);
        await leaderboard.updateAgentScore('customer_satisfaction', 'AGENT003', 4.9);
        await leaderboard.updateAgentScore('customer_satisfaction', 'AGENT004', 4.2);
        await leaderboard.updateAgentScore('customer_satisfaction', 'AGENT005', 4.6);

        // Setup risk scoring
        console.log('\n⚠️ Setting up risk scoring...');
        
        // Sample risk factors and scores
        const riskData = [
            { customerId: 'CUST001', factors: { age: 45, claimCount: 0, creditScore: 780, violations: 0, policyType: 'premium' }},
            { customerId: 'CUST002', factors: { age: 35, claimCount: 1, creditScore: 720, violations: 1, policyType: 'standard' }},
            { customerId: 'CUST003', factors: { age: 25, claimCount: 2, creditScore: 650, violations: 2, policyType: 'standard' }},
            { customerId: 'CUST004', factors: { age: 50, claimCount: 0, creditScore: 800, violations: 0, policyType: 'premium' }},
            { customerId: 'CUST005', factors: { age: 30, claimCount: 3, creditScore: 600, violations: 3, policyType: 'high_risk' }},
            { customerId: 'CUST006', factors: { age: 40, claimCount: 1, creditScore: 700, violations: 1, policyType: 'standard' }},
            { customerId: 'CUST007', factors: { age: 28, claimCount: 0, creditScore: 750, violations: 0, policyType: 'standard' }},
            { customerId: 'CUST008', factors: { age: 22, claimCount: 4, creditScore: 550, violations: 4, policyType: 'high_risk' }}
        ];

        for (const data of riskData) {
            const riskResult = await riskScoring.calculateRiskScore(data.customerId, data.factors);
            
            // Add to risk-based segments
            if (riskResult.category === 'low') {
                await segments.addToSegment(data.customerId, 'lowrisk');
            } else if (riskResult.category === 'high') {
                await segments.addToSegment(data.customerId, 'highrisk');
            }
        }

        console.log('\n✅ Lab 9 setup completed successfully!');
        console.log('\n📋 Setup Summary:');
        console.log('   • 8 customers in various segments');
        console.log('   • 5 agents with performance scores');
        console.log('   • Risk scores calculated for all customers');
        console.log('   • Sample analytics data ready for exploration');
        console.log('\n🚀 Ready to start Lab 9 exercises!');

    } catch (error) {
        console.error('❌ Setup failed:', error);
    } finally {
        client.quit();
    }
}

setupLab9();
