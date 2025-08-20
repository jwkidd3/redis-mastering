const CRMSystem = require('../src/crm-system');

async function testIntegratedSystem() {
    const crm = new CRMSystem();
    
    try {
        await crm.initialize();
        console.log('🚀 Testing Integrated CRM System\n');

        // Test 1: Create customer with policy
        console.log('📝 Creating customer with policy...');
        const result = await crm.createCustomerWithPolicy(
            {
                id: 'C003',
                firstName: 'Mike',
                lastName: 'Wilson',
                email: 'mike.wilson@email.com',
                phone: '555-0103',
                dateOfBirth: '1982-12-10',
                address: '789 Cedar St',
                city: 'Portland',
                state: 'OR',
                zipCode: '97201'
            },
            {
                policyNumber: 'AUTO002',
                type: 'auto',
                effectiveDate: '2024-02-01',
                expirationDate: '2025-01-31',
                premium: 140.00,
                deductible: 500.00,
                coverageAmount: 75000.00,
                coverageDetails: {
                    liability: 'Full',
                    collision: 'Full'
                },
                agent: 'AGT003'
            }
        );

        // Test 2: Get complete customer profile
        console.log('\n📊 Getting complete customer profile...');
        const profile = await crm.getCustomerProfile('C003');
        console.log('Customer Profile:');
        console.log(`Name: ${profile.customer.firstName} ${profile.customer.lastName}`);
        console.log(`Email: ${profile.customer.email}`);
        console.log(`Total Policies: ${profile.summary.totalPolicies}`);
        console.log(`Monthly Premium: $${profile.summary.totalMonthlyPremium.toFixed(2)}`);

        // Test 3: Update customer contact
        console.log('\n📞 Updating customer contact info...');
        await crm.updateCustomerContact('C003', {
            phone: '555-7777',
            email: 'mike.wilson.new@email.com'
        });

        // Test 4: Generate customer report
        console.log('\n📋 Generating customer report...');
        const report = await crm.generateCustomerReport('C003');
        console.log('Customer Report:', JSON.stringify(report, null, 2));

        console.log('\n✅ Integrated system test completed successfully!');

    } catch (error) {
        console.error('❌ Test failed:', error);
    } finally {
        await crm.cleanup();
    }
}

testIntegratedSystem();