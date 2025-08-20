const CustomerManager = require('../src/customer-manager');

async function testCustomerOperations() {
    const customerManager = new CustomerManager();
    
    try {
        await customerManager.initialize();
        console.log('🚀 Testing Customer Profile Operations\n');

        // Test 1: Create customers
        console.log('📝 Creating test customers...');
        
        await customerManager.createCustomer('C001', {
            firstName: 'John',
            lastName: 'Smith',
            email: 'john.smith@email.com',
            phone: '555-0101',
            dateOfBirth: '1985-03-15',
            address: '123 Main St',
            city: 'Anytown',
            state: 'CA',
            zipCode: '12345'
        });

        await customerManager.createCustomer('C002', {
            firstName: 'Sarah',
            lastName: 'Johnson',
            email: 'sarah.johnson@email.com',
            phone: '555-0102',
            dateOfBirth: '1990-07-22',
            address: '456 Oak Ave',
            city: 'Springfield',
            state: 'IL',
            zipCode: '62701'
        });

        // Test 2: Retrieve customer
        console.log('\n📖 Retrieving customer data...');
        const customer1 = await customerManager.getCustomer('C001');
        console.log('Customer C001:', JSON.stringify(customer1, null, 2));

        // Test 3: Update specific field
        console.log('\n✏️ Updating customer phone...');
        await customerManager.updateCustomerField('C001', 'phone', '555-9999');

        // Test 4: Update multiple fields
        console.log('\n📝 Updating customer address...');
        await customerManager.updateCustomer('C002', {
            address: '789 Pine St',
            city: 'Chicago',
            zipCode: '60601'
        });

        // Test 5: Get specific field
        console.log('\n🔍 Getting customer email...');
        const email = await customerManager.getCustomerField('C001', 'email');
        console.log('Customer C001 email:', email);

        // Test 6: List all customers
        console.log('\n📋 Listing all customers...');
        const allCustomers = await customerManager.getAllCustomers();
        console.log(`Found ${allCustomers.length} customers`);
        allCustomers.forEach(customer => {
            console.log(`- ${customer.id}: ${customer.firstName} ${customer.lastName}`);
        });

        console.log('\n✅ Customer operations test completed successfully!');

    } catch (error) {
        console.error('❌ Test failed:', error);
    } finally {
        await customerManager.cleanup();
    }
}

testCustomerOperations();