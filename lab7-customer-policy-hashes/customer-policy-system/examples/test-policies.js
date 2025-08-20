const PolicyManager = require('../src/policy-manager');

async function testPolicyOperations() {
    const policyManager = new PolicyManager();
    
    try {
        await policyManager.initialize();
        console.log('🚀 Testing Policy Management Operations\n');

        // Test 1: Create policies
        console.log('📝 Creating test policies...');
        
        const autoPolicy = await policyManager.createPolicy({
            policyNumber: 'AUTO001',
            customerId: 'C001',
            type: 'auto',
            effectiveDate: '2024-01-01',
            expirationDate: '2024-12-31',
            premium: 150.00,
            deductible: 500.00,
            coverageAmount: 50000.00,
            coverageDetails: {
                liability: 'Full',
                collision: 'Full',
                comprehensive: 'Full'
            },
            agent: 'AGT001',
            paymentFrequency: 'monthly'
        });

        const homePolicy = await policyManager.createPolicy({
            policyNumber: 'HOME001',
            customerId: 'C001',
            type: 'home',
            effectiveDate: '2024-01-01',
            expirationDate: '2024-12-31',
            premium: 120.00,
            deductible: 1000.00,
            coverageAmount: 250000.00,
            coverageDetails: {
                dwelling: 250000,
                personalProperty: 100000,
                liability: 300000
            },
            agent: 'AGT002'
        });

        // Test 2: Retrieve policy
        console.log('\n📖 Retrieving policy data...');
        const policy = await policyManager.getPolicy('AUTO001');
        console.log('Auto Policy:', JSON.stringify(policy, null, 2));

        // Test 3: Update policy
        console.log('\n✏️ Updating policy premium...');
        await policyManager.updatePolicy('AUTO001', {
            premium: 165.00,
            status: 'active',
            coverageDetails: {
                liability: 'Full',
                collision: 'Full',
                comprehensive: 'Full',
                rentalCar: 'Added'
            }
        });

        // Test 4: Get specific field
        console.log('\n🔍 Getting policy premium...');
        const premium = await policyManager.getPolicyField('AUTO001', 'premium');
        console.log('Updated premium:', premium);

        // Test 5: Get customer policies
        console.log('\n📋 Getting all policies for customer C001...');
        const customerPolicies = await policyManager.getCustomerPolicies('C001');
        console.log(`Customer has ${customerPolicies.length} policies:`);
        customerPolicies.forEach(pol => {
            console.log(`- ${pol.policyNumber} (${pol.type}): $${pol.premium}/month`);
        });

        // Test 6: Get policies by type
        console.log('\n🏠 Getting all home policies...');
        const homePolicies = await policyManager.getPoliciesByType('home');
        console.log(`Found ${homePolicies.length} home policies`);

        // Test 7: Calculate policy metrics
        console.log('\n📊 Calculating policy metrics...');
        const metrics = await policyManager.calculatePolicyMetrics('AUTO001');
        console.log('Policy Metrics:', JSON.stringify(metrics, null, 2));

        console.log('\n✅ Policy operations test completed successfully!');

    } catch (error) {
        console.error('❌ Test failed:', error);
    } finally {
        await policyManager.cleanup();
    }
}

testPolicyOperations();