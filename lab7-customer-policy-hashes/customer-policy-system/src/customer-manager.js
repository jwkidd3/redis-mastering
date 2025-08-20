const RedisClient = require('./redis-client');

class CustomerManager {
    constructor() {
        this.redisClient = new RedisClient();
        this.client = null;
    }

    async initialize() {
        await this.redisClient.connect();
        this.client = this.redisClient.getClient();
    }

    async createCustomer(customerId, customerData) {
        try {
            const key = `customer:${customerId}`;
            
            // Prepare customer data with metadata
            const profileData = {
                id: customerId,
                firstName: customerData.firstName,
                lastName: customerData.lastName,
                email: customerData.email,
                phone: customerData.phone,
                dateOfBirth: customerData.dateOfBirth,
                address: customerData.address,
                city: customerData.city,
                state: customerData.state,
                zipCode: customerData.zipCode,
                customerSince: new Date().toISOString(),
                lastUpdated: new Date().toISOString(),
                status: 'active'
            };

            // Store customer profile as hash
            await this.client.hSet(key, profileData);
            
            // Add to customer index
            await this.client.sAdd('customers:index', customerId);
            
            console.log(`✅ Customer ${customerId} created successfully`);
            return customerId;
        } catch (error) {
            console.error('Error creating customer:', error);
            throw error;
        }
    }

    async getCustomer(customerId) {
        try {
            const key = `customer:${customerId}`;
            
            // Check if customer exists
            const exists = await this.client.exists(key);
            if (!exists) {
                throw new Error(`Customer ${customerId} not found`);
            }

            // Get all customer data
            const customerData = await this.client.hGetAll(key);
            
            return customerData;
        } catch (error) {
            console.error('Error retrieving customer:', error);
            throw error;
        }
    }

    async updateCustomerField(customerId, field, value) {
        try {
            const key = `customer:${customerId}`;
            
            // Check if customer exists
            const exists = await this.client.exists(key);
            if (!exists) {
                throw new Error(`Customer ${customerId} not found`);
            }

            // Update specific field
            await this.client.hSet(key, field, value);
            
            // Update lastUpdated timestamp
            await this.client.hSet(key, 'lastUpdated', new Date().toISOString());
            
            console.log(`✅ Customer ${customerId} field '${field}' updated`);
        } catch (error) {
            console.error('Error updating customer field:', error);
            throw error;
        }
    }

    async updateCustomer(customerId, updates) {
        try {
            const key = `customer:${customerId}`;
            
            // Check if customer exists
            const exists = await this.client.exists(key);
            if (!exists) {
                throw new Error(`Customer ${customerId} not found`);
            }

            // Add lastUpdated timestamp
            updates.lastUpdated = new Date().toISOString();

            // Update multiple fields
            await this.client.hSet(key, updates);
            
            console.log(`✅ Customer ${customerId} updated successfully`);
        } catch (error) {
            console.error('Error updating customer:', error);
            throw error;
        }
    }

    async getCustomerField(customerId, field) {
        try {
            const key = `customer:${customerId}`;
            
            const value = await this.client.hGet(key, field);
            
            if (value === null) {
                throw new Error(`Field '${field}' not found for customer ${customerId}`);
            }
            
            return value;
        } catch (error) {
            console.error('Error getting customer field:', error);
            throw error;
        }
    }

    async getAllCustomers() {
        try {
            const customerIds = await this.client.sMembers('customers:index');
            const customers = [];

            for (const id of customerIds) {
                try {
                    const customerData = await this.getCustomer(id);
                    customers.push(customerData);
                } catch (error) {
                    console.warn(`Could not retrieve customer ${id}:`, error.message);
                }
            }

            return customers;
        } catch (error) {
            console.error('Error getting all customers:', error);
            throw error;
        }
    }

    async deleteCustomer(customerId) {
        try {
            const key = `customer:${customerId}`;
            
            // Check if customer exists
            const exists = await this.client.exists(key);
            if (!exists) {
                throw new Error(`Customer ${customerId} not found`);
            }

            // Delete customer profile
            await this.client.del(key);
            
            // Remove from index
            await this.client.sRem('customers:index', customerId);
            
            console.log(`✅ Customer ${customerId} deleted successfully`);
        } catch (error) {
            console.error('Error deleting customer:', error);
            throw error;
        }
    }

    async cleanup() {
        await this.redisClient.disconnect();
    }
}

module.exports = CustomerManager;