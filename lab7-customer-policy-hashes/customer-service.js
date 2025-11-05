// customer-service.js - Customer service using Redis hashes
const redis = require('redis');

class CustomerService {
    constructor() {
        this.client = null;
    }

    async connect() {
        this.client = redis.createClient();
        await this.client.connect();
    }

    async disconnect() {
        if (this.client) {
            await this.client.quit();
        }
    }

    // Create or update customer profile
    async createCustomer(customerId, customerData) {
        const key = `customer:${customerId}`;
        await this.client.hSet(key, customerData);
        return customerId;
    }

    // Get customer profile
    async getCustomer(customerId) {
        const key = `customer:${customerId}`;
        return await this.client.hGetAll(key);
    }

    // Update specific customer fields
    async updateCustomer(customerId, updates) {
        const key = `customer:${customerId}`;
        await this.client.hSet(key, updates);
    }

    // Get specific customer field
    async getCustomerField(customerId, field) {
        const key = `customer:${customerId}`;
        return await this.client.hGet(key, field);
    }

    // Delete customer
    async deleteCustomer(customerId) {
        const key = `customer:${customerId}`;
        await this.client.del(key);
    }

    // Increment policy count
    async incrementPolicyCount(customerId) {
        const key = `customer:${customerId}`;
        return await this.client.hIncrBy(key, 'policy_count', 1);
    }
}

module.exports = CustomerService;
