const RedisClient = require('./redis-client');

class PolicyManager {
    constructor() {
        this.redisClient = new RedisClient();
        this.client = null;
    }

    async initialize() {
        await this.redisClient.connect();
        this.client = this.redisClient.getClient();
    }

    async createPolicy(policyData) {
        try {
            const policyId = policyData.policyNumber || `POL${Date.now()}`;
            const key = `policy:${policyId}`;
            
            // Prepare policy data
            const policyInfo = {
                policyNumber: policyId,
                customerId: policyData.customerId,
                type: policyData.type, // auto, home, life, health
                status: 'active',
                effectiveDate: policyData.effectiveDate,
                expirationDate: policyData.expirationDate,
                premium: policyData.premium.toString(),
                deductible: policyData.deductible.toString(),
                coverageAmount: policyData.coverageAmount.toString(),
                coverageDetails: JSON.stringify(policyData.coverageDetails || {}),
                agent: policyData.agent || 'unassigned',
                paymentFrequency: policyData.paymentFrequency || 'monthly',
                createdDate: new Date().toISOString(),
                lastUpdated: new Date().toISOString()
            };

            // Store policy as hash
            await this.client.hSet(key, policyInfo);
            
            // Add to policy index
            await this.client.sAdd('policies:index', policyId);
            
            // Add to customer's policies set
            await this.client.sAdd(`customer:${policyData.customerId}:policies`, policyId);
            
            // Add to policy type index
            await this.client.sAdd(`policies:type:${policyData.type}`, policyId);
            
            console.log(`✅ Policy ${policyId} created successfully`);
            return policyId;
        } catch (error) {
            console.error('Error creating policy:', error);
            throw error;
        }
    }

    async getPolicy(policyId) {
        try {
            const key = `policy:${policyId}`;
            
            const exists = await this.client.exists(key);
            if (!exists) {
                throw new Error(`Policy ${policyId} not found`);
            }

            const policyData = await this.client.hGetAll(key);
            
            // Parse JSON fields
            if (policyData.coverageDetails) {
                try {
                    policyData.coverageDetails = JSON.parse(policyData.coverageDetails);
                } catch (e) {
                    policyData.coverageDetails = {};
                }
            }
            
            return policyData;
        } catch (error) {
            console.error('Error retrieving policy:', error);
            throw error;
        }
    }

    async updatePolicy(policyId, updates) {
        try {
            const key = `policy:${policyId}`;
            
            const exists = await this.client.exists(key);
            if (!exists) {
                throw new Error(`Policy ${policyId} not found`);
            }

            // Handle special fields
            if (updates.coverageDetails && typeof updates.coverageDetails === 'object') {
                updates.coverageDetails = JSON.stringify(updates.coverageDetails);
            }

            // Convert numbers to strings for Redis
            ['premium', 'deductible', 'coverageAmount'].forEach(field => {
                if (updates[field] !== undefined) {
                    updates[field] = updates[field].toString();
                }
            });

            // Add lastUpdated timestamp
            updates.lastUpdated = new Date().toISOString();

            await this.client.hSet(key, updates);
            
            console.log(`✅ Policy ${policyId} updated successfully`);
        } catch (error) {
            console.error('Error updating policy:', error);
            throw error;
        }
    }

    async getPolicyField(policyId, field) {
        try {
            const key = `policy:${policyId}`;
            
            const value = await this.client.hGet(key, field);
            
            if (value === null) {
                throw new Error(`Field '${field}' not found for policy ${policyId}`);
            }
            
            return value;
        } catch (error) {
            console.error('Error getting policy field:', error);
            throw error;
        }
    }

    async getCustomerPolicies(customerId) {
        try {
            const policyIds = await this.client.sMembers(`customer:${customerId}:policies`);
            const policies = [];

            for (const policyId of policyIds) {
                try {
                    const policyData = await this.getPolicy(policyId);
                    policies.push(policyData);
                } catch (error) {
                    console.warn(`Could not retrieve policy ${policyId}:`, error.message);
                }
            }

            return policies;
        } catch (error) {
            console.error('Error getting customer policies:', error);
            throw error;
        }
    }

    async getPoliciesByType(type) {
        try {
            const policyIds = await this.client.sMembers(`policies:type:${type}`);
            const policies = [];

            for (const policyId of policyIds) {
                try {
                    const policyData = await this.getPolicy(policyId);
                    policies.push(policyData);
                } catch (error) {
                    console.warn(`Could not retrieve policy ${policyId}:`, error.message);
                }
            }

            return policies;
        } catch (error) {
            console.error('Error getting policies by type:', error);
            throw error;
        }
    }

    async calculatePolicyMetrics(policyId) {
        try {
            const policy = await this.getPolicy(policyId);
            
            const premium = parseFloat(policy.premium) || 0;
            const deductible = parseFloat(policy.deductible) || 0;
            const coverageAmount = parseFloat(policy.coverageAmount) || 0;
            
            const metrics = {
                policyId: policyId,
                annualPremium: premium * 12, // assuming monthly premium
                coverageRatio: coverageAmount / premium,
                deductiblePercentage: (deductible / coverageAmount) * 100,
                effectiveDate: policy.effectiveDate,
                daysUntilRenewal: this.calculateDaysUntilRenewal(policy.expirationDate)
            };

            return metrics;
        } catch (error) {
            console.error('Error calculating policy metrics:', error);
            throw error;
        }
    }

    calculateDaysUntilRenewal(expirationDate) {
        try {
            const expiry = new Date(expirationDate);
            const today = new Date();
            const diffTime = expiry - today;
            const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
            return diffDays;
        } catch (error) {
            return null;
        }
    }

    async cleanup() {
        await this.redisClient.disconnect();
    }
}

module.exports = PolicyManager;