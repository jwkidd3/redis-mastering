const CustomerManager = require('../src/customer-manager');

async function customerSearchExample() {
    const customerManager = new CustomerManager();
    
    try {
        await customerManager.initialize();
        console.log('🔍 Customer Search Examples\n');

        // Create sample customers for searching
        const customers = [
            { id: 'C100', firstName: 'Alice', lastName: 'Johnson', email: 'alice@example.com', city: 'Seattle', state: 'WA' },
            { id: 'C101', firstName: 'Bob', lastName: 'Smith', email: 'bob@example.com', city: 'Portland', state: 'OR' },
            { id: 'C102', firstName: 'Carol', lastName: 'Johnson', email: 'carol@example.com', city: 'Seattle', state: 'WA' },
            { id: 'C103', firstName: 'David', lastName: 'Brown', email: 'david@example.com', city: 'San Francisco', state: 'CA' }
        ];

        console.log('📝 Creating sample customers...');
        for (const customer of customers) {
            await customerManager.createCustomer(customer.id, customer);
        }

        // Search by city using Redis operations
        console.log('\n🏙️ Searching customers by city...');
        const client = customerManager.client;
        
        // Get all customers and filter by city
        const allCustomers = await customerManager.getAllCustomers();
        const seattleCustomers = allCustomers.filter(c => c.city === 'Seattle');
        
        console.log('Customers in Seattle:');
        seattleCustomers.forEach(customer => {
            console.log(`- ${customer.firstName} ${customer.lastName} (${customer.email})`);
        });

        // Search by last name
        console.log('\n👥 Searching customers by last name...');
        const johnsonCustomers = allCustomers.filter(c => c.lastName === 'Johnson');
        
        console.log('Customers with last name Johnson:');
        johnsonCustomers.forEach(customer => {
            console.log(`- ${customer.firstName} ${customer.lastName} in ${customer.city}`);
        });

        // Advanced: Create index for faster searching
        console.log('\n📇 Creating city index...');
        for (const customer of allCustomers) {
            await client.sAdd(`customers:city:${customer.city}`, customer.id);
        }

        // Search using index
        console.log('\n🚀 Fast city search using index...');
        const seattleIds = await client.sMembers('customers:city:Seattle');
        console.log(`Found ${seattleIds.length} customers in Seattle using index`);

        // Cleanup
        console.log('\n🧹 Cleaning up...');
        for (const customer of customers) {
            await customerManager.deleteCustomer(customer.id);
        }
        
        // Clean up indexes
        const cityKeys = await client.keys('customers:city:*');
        if (cityKeys.length > 0) {
            await client.del(cityKeys);
        }

        console.log('\n✅ Customer search examples completed!');

    } catch (error) {
        console.error('❌ Search example failed:', error);
    } finally {
        await customerManager.cleanup();
    }
}

customerSearchExample();
