// src/models/policy.js
class Policy {
    constructor(redisClient) {
        this.redis = redisClient.getClient();
        this.keyPrefix = 'policy';
    }

    // Generate policy key
    _getKey(policyNumber) {
        return `${this.keyPrefix}:${policyNumber}`;
    }

    // Create policy record
    async create(policyNumber, policyData) {
        try {
            const key = this._getKey(policyNumber);
            
            const policyJson = JSON.stringify({
                policyNumber: policyNumber,
                customerId: policyData.customerId,
                type: policyData.type, // auto, home, life, etc.
                coverage: policyData.coverage,
                premium: parseFloat(policyData.premium),
                deductible: parseFloat(policyData.deductible || 0),
                startDate: policyData.startDate,
                endDate: policyData.endDate,
                status: policyData.status || 'active',
                agent: policyData.agent,
                createdAt: new Date().toISOString(),
                updatedAt: new Date().toISOString()
            });

            await this.redis.set(key, policyJson);
            
            // Add to policy index
            await this.redis.sAdd('policies:index', policyNumber);
            
            // Add to customer's policies
            await this.redis.sAdd(`customer:${policyData.customerId}:policies`, policyNumber);
            
            console.log(`✅ Policy ${policyNumber} created`);
            return { success: true, policyNumber };
            
        } catch (error) {
            console.error('❌ Error creating policy:', error.message);
            throw error;
        }
    }

    // Retrieve policy record
    async get(policyNumber) {
        try {
            const key = this._getKey(policyNumber);
            const policyJson = await this.redis.get(key);
            
            if (!policyJson) {
                return null;
            }
            
            return JSON.parse(policyJson);
            
        } catch (error) {
            console.error('❌ Error retrieving policy:', error.message);
            throw error;
        }
    }

    // Get policies for a customer
    async getByCustomer(customerId) {
        try {
            const policyNumbers = await this.redis.sMembers(`customer:${customerId}:policies`);
            const policies = [];
            
            for (const policyNumber of policyNumbers) {
                const policy = await this.get(policyNumber);
                if (policy) {
                    policies.push(policy);
                }
            }
            
            return policies;
            
        } catch (error) {
            console.error('❌ Error retrieving customer policies:', error.message);
            throw error;
        }
    }

    // Calculate total premium for customer
    async getTotalPremium(customerId) {
        try {
            const policies = await this.getByCustomer(customerId);
            return policies.reduce((total, policy) => {
                return total + (policy.premium || 0);
            }, 0);
        } catch (error) {
            console.error('❌ Error calculating total premium:', error.message);
            throw error;
        }
    }

    // Update policy status
    async updateStatus(policyNumber, newStatus) {
        try {
            const policy = await this.get(policyNumber);
            if (!policy) {
                throw new Error(`Policy ${policyNumber} not found`);
            }

            policy.status = newStatus;
            policy.updatedAt = new Date().toISOString();

            const key = this._getKey(policyNumber);
            await this.redis.set(key, JSON.stringify(policy));
            
            console.log(`✅ Policy ${policyNumber} status updated to ${newStatus}`);
            return { success: true, policy };
            
        } catch (error) {
            console.error('❌ Error updating policy status:', error.message);
            throw error;
        }
    }

    // List all policy numbers
    async listNumbers() {
        try {
            return await this.redis.sMembers('policies:index');
        } catch (error) {
            console.error('❌ Error listing policies:', error.message);
            throw error;
        }
    }
}

module.exports = Policy;