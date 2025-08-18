import DataProcessor from './data-operations.js';

(async () => {
    console.log('🧪 Starting Async Operations Test...\n');
    
    const processor = new DataProcessor();
    
    try {
        await processor.initialize();
        
        // Sample customer data
        const customers = [
            { id: 'CUST001', name: 'Alice Johnson', email: 'alice@example.com' },
            { id: 'CUST002', name: 'Bob Smith', email: 'bob@example.com' },
            { id: 'CUST003', name: 'Carol White', email: 'carol@example.com' }
        ];
        
        console.log('📊 Processing customer data...');
        const result = await processor.processCustomerData(customers);
        console.log('✅ Processing result:', result);
        
        console.log('\n🔍 Retrieving customer details...');
        for (const customer of customers) {
            try {
                const details = await processor.getCustomerDetails(customer.id);
                console.log(`Customer ${customer.id}:`, details);
            } catch (error) {
                console.log(`⚠️ Could not retrieve ${customer.id}:`, error.message);
            }
        }
        
        console.log('\n🔎 Searching all customers...');
        const allCustomers = await processor.searchCustomers('*');
        console.log(`Found ${allCustomers.length} customers:`, allCustomers);
        
        console.log('\n✅ Async operations test completed successfully!');
        
    } catch (error) {
        console.error('❌ Test failed:', error.message);
        console.error('Stack trace:', error.stack);
        
        // Provide helpful debugging info
        console.log('\n🔧 Debugging Information:');
        console.log('- Make sure Redis is running: docker ps | grep redis');
        console.log('- Test Redis connection: redis-cli ping');
        console.log('- Clear Redis data: redis-cli FLUSHDB');
        console.log('- Check for conflicting keys: redis-cli KEYS "*"');
        
        process.exit(1);
    } finally {
        await processor.cleanup();
    }
})();