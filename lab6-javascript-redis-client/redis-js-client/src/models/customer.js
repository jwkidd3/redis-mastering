// src/models/customer.js
class Customer {
    constructor(redisClient) {
        this.redis = redisClient.getClient();
        this.keyPrefix = 'customer';
    }

    // Generate customer key
    _getKey(customerId) {
        return `${this.keyPrefix}:${customerId}`;
    }

    // Create customer record
    async create(customerId, customerData) {
        try {
            const key = this._getKey(customerId);
            
            // Store customer as JSON string
            const customerJson = JSON.stringify({
                id: customerId,
                name: customerData.name,
                email: customerData.email,
                phone: customerData.phone,
                address: customerData.address,
                dateOfBirth: customerData.dateOfBirth,
                customerSince: customerData.customerSince || new Date().toISOString(),
                riskScore: customerData.riskScore || 'low',
                createdAt: new Date().toISOString(),
                updatedAt: new Date().toISOString()
            });

            await this.redis.set(key, customerJson);
            
            // Add to customer index
            await this.redis.sAdd('customers:index', customerId);
            
            console.log(`✅ Customer ${customerId} created`);
            return { success: true, customerId };
            
        } catch (error) {
            console.error('❌ Error creating customer:', error.message);
            throw error;
        }
    }

    // Retrieve customer record
    async get(customerId) {
        try {
            const key = this._getKey(customerId);
            const customerJson = await this.redis.get(key);
            
            if (!customerJson) {
                return null;
            }
            
            return JSON.parse(customerJson);
            
        } catch (error) {
            console.error('❌ Error retrieving customer:', error.message);
            throw error;
        }
    }

    // Update customer record
    async update(customerId, updateData) {
        try {
            const existing = await this.get(customerId);
            if (!existing) {
                throw new Error(`Customer ${customerId} not found`);
            }

            // Merge update data
            const updated = {
                ...existing,
                ...updateData,
                updatedAt: new Date().toISOString()
            };

            const key = this._getKey(customerId);
            await this.redis.set(key, JSON.stringify(updated));
            
            console.log(`✅ Customer ${customerId} updated`);
            return { success: true, customer: updated };
            
        } catch (error) {
            console.error('❌ Error updating customer:', error.message);
            throw error;
        }
    }

    // Delete customer record
    async delete(customerId) {
        try {
            const key = this._getKey(customerId);
            const deleted = await this.redis.del(key);
            
            if (deleted) {
                // Remove from index
                await this.redis.sRem('customers:index', customerId);
                console.log(`✅ Customer ${customerId} deleted`);
                return { success: true };
            } else {
                return { success: false, message: 'Customer not found' };
            }
            
        } catch (error) {
            console.error('❌ Error deleting customer:', error.message);
            throw error;
        }
    }

    // List all customer IDs
    async listIds() {
        try {
            return await this.redis.sMembers('customers:index');
        } catch (error) {
            console.error('❌ Error listing customers:', error.message);
            throw error;
        }
    }

    // Get customer count
    async count() {
        try {
            return await this.redis.sCard('customers:index');
        } catch (error) {
            console.error('❌ Error counting customers:', error.message);
            throw error;
        }
    }
}

module.exports = Customer;