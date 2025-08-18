// src/data-operations.js
import connectRedis from './connection.js';

class DataProcessor {
    constructor() {
        this.client = null;
    }

    async initialize() {
        this.client = await connectRedis();
    }

    async processCustomerData(customers) {
        const pipeline = this.client.multi();
        
        for (const customer of customers) {
            pipeline.hSet(`customer:${customer.id}`, {
                name: customer.name,
                email: customer.email,
                registeredAt: new Date().toISOString()
            });
            
            pipeline.sAdd('customers:active', customer.id);
            pipeline.zAdd('customers:by-registration', {
                score: Date.now(),
                value: customer.id
            });
        }
        
        const results = await pipeline.exec();
        console.log(`Processed ${customers.length} customers`);
        return results;
    }

    async getCustomerDetails(customerId) {
        const details = await this.client.hGetAll(`customer:${customerId}`);
        return details;
    }

    async getRecentCustomers(limit = 10) {
        const customerIds = await this.client.zRange(
            'customers:by-registration',
            -limit,
            -1,
            { REV: true }
        );
        
        const customers = [];
        for (const id of customerIds) {
            const details = await this.getCustomerDetails(id);
            customers.push({ id, ...details });
        }
        
        return customers;
    }

    async cleanup() {
        await this.client.disconnect();
    }
}

export default DataProcessor;
