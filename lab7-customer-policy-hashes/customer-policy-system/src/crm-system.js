const CustomerManager = require('./customer-manager');
const PolicyManager = require('./policy-manager');

class CRMSystem {
    constructor() {
        this.customerManager = new CustomerManager();
        this.policyManager = new PolicyManager();
    }

    async initialize() {
        await this.customerManager.initialize();
        // Reuse the same Redis connection
        this.policyManager.client = this.customerManager.client;
        this.policyManager.redisClient = this.customerManager.redisClient;
    }

    async createCustomerWithPolicy(customerData, policyData) {
        try {
            // Create customer first
            const customerId = await this.customerManager.createCustomer(
                customerData.id, 
                customerData
            );

            // Create policy for the customer
            policyData.customerId = customerId;
            const policyId = await this.policyManager.createPolicy(policyData);

            console.log(`✅ Created customer ${customerId} with policy ${policyId}`);
            
            return { customerId, policyId };
        } catch (error) {
            console.error('Error creating customer with policy:', error);
            throw error;
        }
    }

    async getCustomerProfile(customerId) {
        try {
            const customer = await this.customerManager.getCustomer(customerId);
            const policies = await this.policyManager.getCustomerPolicies(customerId);
            
            return {
                customer,
                policies,
                summary: {
                    totalPolicies: policies.length,
                    totalMonthlyPremium: policies.reduce((sum, pol) => 
                        sum + parseFloat(pol.premium || 0), 0
                    ),
                    policyTypes: [...new Set(policies.map(pol => pol.type))]
                }
            };
        } catch (error) {
            console.error('Error getting customer profile:', error);
            throw error;
        }
    }

    async updateCustomerContact(customerId, contactInfo) {
        try {
            await this.customerManager.updateCustomer(customerId, contactInfo);
            
            // Update customer info in policies if needed
            const policies = await this.policyManager.getCustomerPolicies(customerId);
            console.log(`📞 Updated contact info for customer with ${policies.length} policies`);
            
        } catch (error) {
            console.error('Error updating customer contact:', error);
            throw error;
        }
    }

    async generateCustomerReport(customerId) {
        try {
            const profile = await this.getCustomerProfile(customerId);
            
            const report = {
                customerId: customerId,
                customerName: `${profile.customer.firstName} ${profile.customer.lastName}`,
                email: profile.customer.email,
                customerSince: profile.customer.customerSince,
                totalPolicies: profile.summary.totalPolicies,
                monthlyPremium: profile.summary.totalMonthlyPremium,
                annualPremium: profile.summary.totalMonthlyPremium * 12,
                policyBreakdown: profile.policies.map(pol => ({
                    policyNumber: pol.policyNumber,
                    type: pol.type,
                    premium: parseFloat(pol.premium),
                    status: pol.status,
                    expirationDate: pol.expirationDate
                })),
                generatedAt: new Date().toISOString()
            };

            return report;
        } catch (error) {
            console.error('Error generating customer report:', error);
            throw error;
        }
    }

    async cleanup() {
        await this.customerManager.cleanup();
    }
}

module.exports = CRMSystem;