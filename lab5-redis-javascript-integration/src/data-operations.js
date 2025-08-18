import connectRedis from './connection.js';

class DataProcessor {
    constructor() {
        this.client = null;
    }
    
    async initialize() {
        this.client = await connectRedis();
        console.log('📊 Data processor initialized');
        
        // Clear any existing conflicting data to prevent WRONGTYPE errors
        await this.clearTestData();
    }
    
    async clearTestData() {
        console.log('🧹 Clearing any existing test data...');
        try {
            // Clear any keys that might conflict with our operations
            const keysToDelete = [
                'customers:all',
                'customers:scores'
            ];
            
            // Get all customer keys that might exist
            const customerKeys = await this.client.keys('customer:*');
            keysToDelete.push(...customerKeys);
            
            if (keysToDelete.length > 0) {
                await this.client.del(keysToDelete);
                console.log(`✅ Cleared ${keysToDelete.length} potential conflicting keys`);
            }
        } catch (error) {
            console.log('ℹ️ No conflicting data to clear:', error.message);
        }
    }
    
    async processCustomerData(customers) {
        console.log('Processing customer data...');
        
        try {
            // Use individual operations instead of pipeline for better error handling
            for (const customer of customers) {
                // Store customer hash - ensure key doesn't exist as wrong type
                const customerKey = `customer:${customer.id}`;
                await this.client.del(customerKey); // Clear any existing key
                
                await this.client.hSet(customerKey, {
                    name: customer.name,
                    email: customer.email,
                    created: new Date().toISOString()
                });
                
                // Add to customer set - ensure it's a set
                const customersSetKey = 'customers:all';
                const existingType = await this.client.type(customersSetKey);
                if (existingType !== 'set' && existingType !== 'none') {
                    await this.client.del(customersSetKey);
                }
                await this.client.sAdd(customersSetKey, customer.id);
                
                // Score for ranking - ensure it's a sorted set
                const scoresKey = 'customers:scores';
                const scoresType = await this.client.type(scoresKey);
                if (scoresType !== 'zset' && scoresType !== 'none') {
                    await this.client.del(scoresKey);
                }
                await this.client.zAdd(scoresKey, {
                    score: Math.floor(Math.random() * 1000),
                    value: customer.id
                });
            }
            
            console.log(`✅ Processed ${customers.length} customers successfully`);
            return { success: true, count: customers.length };
            
        } catch (error) {
            console.error('❌ Error processing customer data:', error);
            throw error;
        }
    }
    
    async getCustomerDetails(customerId) {
        try {
            const customerKey = `customer:${customerId}`;
            
            // Check if customer exists and is correct type
            const exists = await this.client.exists(customerKey);
            if (!exists) {
                throw new Error(`Customer ${customerId} not found`);
            }
            
            const type = await this.client.type(customerKey);
            if (type !== 'hash') {
                console.log(`⚠️ Customer key has wrong type: ${type}, recreating...`);
                await this.client.del(customerKey);
                throw new Error(`Customer ${customerId} has wrong data type, please recreate`);
            }
            
            const customer = await this.client.hGetAll(customerKey);
            
            // Get score safely
            let score = null;
            try {
                score = await this.client.zScore('customers:scores', customerId);
            } catch (error) {
                console.log(`ℹ️ No score found for customer ${customerId}`);
            }
            
            return {
                id: customerId,
                ...customer,
                score: score
            };
        } catch (error) {
            console.error(`❌ Error getting customer details for ${customerId}:`, error);
            throw error;
        }
    }
    
    async searchCustomers(pattern) {
        try {
            const keys = await this.client.keys(`customer:${pattern}`);
            const customers = [];
            
            for (const key of keys) {
                try {
                    const type = await this.client.type(key);
                    if (type === 'hash') {
                        const customer = await this.client.hGetAll(key);
                        customers.push({
                            id: key.split(':')[1],
                            ...customer
                        });
                    } else {
                        console.log(`⚠️ Skipping key ${key} with wrong type: ${type}`);
                    }
                } catch (error) {
                    console.log(`⚠️ Error processing key ${key}:`, error.message);
                }
            }
            
            return customers;
        } catch (error) {
            console.error('❌ Error searching customers:', error);
            throw error;
        }
    }
    
    async cleanup() {
        if (this.client) {
            await this.client.disconnect();
            console.log('🔌 Data processor disconnected');
        }
    }
}

export default DataProcessor;
