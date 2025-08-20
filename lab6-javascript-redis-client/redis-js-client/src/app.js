// src/app.js
const RedisClient = require('./clients/redisClient');
const Customer = require('./models/customer');
const Policy = require('./models/policy');

class App {
    constructor() {
        this.redisClient = new RedisClient();
        this.customer = null;
        this.policy = null;
    }

    async initialize() {
        try {
            console.log('🚀 Initializing application...');
            
            // Connect to Redis
            await this.redisClient.connect();
            
            // Initialize models
            this.customer = new Customer(this.redisClient);
            this.policy = new Policy(this.redisClient);
            
            console.log('✅ Application initialized successfully');
            
        } catch (error) {
            console.error('💥 Failed to initialize application:', error.message);
            throw error;
        }
    }

    async createSampleData() {
        console.log('📝 Creating sample data...');
        
        try {
            // Create sample customers
            await this.customer.create('CUST001', {
                name: 'John Smith',
                email: 'john.smith@email.com',
                phone: '555-0101',
                address: '123 Main St, Anytown, USA',
                dateOfBirth: '1980-05-15',
                riskScore: 'low'
            });

            await this.customer.create('CUST002', {
                name: 'Sarah Johnson',
                email: 'sarah.johnson@email.com',
                phone: '555-0102',
                address: '456 Oak Ave, Somewhere, USA',
                dateOfBirth: '1975-08-22',
                riskScore: 'medium'
            });

            // Create sample policies
            await this.policy.create('POL001', {
                customerId: 'CUST001',
                type: 'auto',
                coverage: 'Full Coverage',
                premium: 1200.00,
                deductible: 500.00,
                startDate: '2024-01-01',
                endDate: '2024-12-31',
                agent: 'Agent Smith'
            });

            await this.policy.create('POL002', {
                customerId: 'CUST001',
                type: 'home',
                coverage: 'Comprehensive',
                premium: 800.00,
                deductible: 1000.00,
                startDate: '2024-01-01',
                endDate: '2024-12-31',
                agent: 'Agent Smith'
            });

            await this.policy.create('POL003', {
                customerId: 'CUST002',
                type: 'auto',
                coverage: 'Basic Coverage',
                premium: 900.00,
                deductible: 750.00,
                startDate: '2024-02-01',
                endDate: '2025-01-31',
                agent: 'Agent Jones'
            });

            console.log('✅ Sample data created successfully');

        } catch (error) {
            console.error('❌ Error creating sample data:', error.message);
            throw error;
        }
    }

    async runExamples() {
        console.log('🎯 Running example operations...');
        console.log('================================');

        try {
            // Customer operations
            console.log('\n📋 Customer Operations:');
            const customer1 = await this.customer.get('CUST001');
            console.log('Customer CUST001:', customer1?.name);

            const customerCount = await this.customer.count();
            console.log('Total customers:', customerCount);

            // Policy operations
            console.log('\n📋 Policy Operations:');
            const policy1 = await this.policy.get('POL001');
            console.log('Policy POL001:', policy1?.type, '$' + policy1?.premium);

            const customerPolicies = await this.policy.getByCustomer('CUST001');
            console.log('CUST001 policies:', customerPolicies.length);

            const totalPremium = await this.policy.getTotalPremium('CUST001');
            console.log('CUST001 total premium: $' + totalPremium);

            // Update operations
            console.log('\n📋 Update Operations:');
            await this.customer.update('CUST001', { 
                phone: '555-9999',
                riskScore: 'medium'
            });

            await this.policy.updateStatus('POL003', 'pending');

            console.log('✅ All example operations completed');

        } catch (error) {
            console.error('❌ Error running examples:', error.message);
            throw error;
        }
    }

    async cleanup() {
        try {
            if (this.redisClient) {
                await this.redisClient.disconnect();
            }
        } catch (error) {
            console.error('Error during cleanup:', error.message);
        }
    }
}

// Main execution function
async function main() {
    const app = new App();
    
    try {
        await app.initialize();
        await app.createSampleData();
        await app.runExamples();
        
    } catch (error) {
        console.error('💥 Application error:', error.message);
    } finally {
        await app.cleanup();
    }
}

// Run if this file is executed directly
if (require.main === module) {
    main();
}

module.exports = App;