# Lab 7: Customer Profiles & Policy Management with Hashes

**Duration:** 45 minutes  
**Objective:** Build customer and policy management system using Redis hashes with JavaScript

## 🎯 Learning Objectives

By the end of this lab, you will be able to:
- Use Redis hashes to store structured customer and policy data
- Implement CRUD operations for customer profiles with JavaScript
- Manage complex policy information using hash field operations
- Handle nested data structures efficiently with Redis hashes
- Build a foundation for customer relationship management systems

---

## Part 1: Environment Setup (8 minutes)

### Step 1: Initialize Project Structure

```bash
# Create project directory
mkdir customer-policy-system
cd customer-policy-system

# Initialize Node.js project
npm init -y

# Install Redis client
npm install redis
```

### Step 2: Create Base Connection Module

Create `src/redis-client.js`:

```javascript
const redis = require('redis');

class RedisClient {
    constructor() {
        this.client = null;
        this.isConnected = false;
    }

    async connect(options = {}) {
        try {
            // Replace with your actual Redis server details
            const config = {
                host: process.env.REDIS_HOST || 'redis-server.training.com',
                port: process.env.REDIS_PORT || 6379,
                password: process.env.REDIS_PASSWORD || undefined,
                ...options
            };

            this.client = redis.createClient(config);
            
            this.client.on('error', (err) => {
                console.error('Redis Client Error:', err);
                this.isConnected = false;
            });

            this.client.on('connect', () => {
                console.log('✅ Connected to Redis server');
                this.isConnected = true;
            });

            await this.client.connect();
            return this.client;
        } catch (error) {
            console.error('Failed to connect to Redis:', error);
            throw error;
        }
    }

    async disconnect() {
        if (this.client) {
            await this.client.disconnect();
            this.isConnected = false;
            console.log('📤 Disconnected from Redis');
        }
    }

    getClient() {
        if (!this.isConnected) {
            throw new Error('Redis client not connected');
        }
        return this.client;
    }
}

module.exports = RedisClient;
```

### Step 3: Test Connection

Create `test-connection.js`:

```javascript
const RedisClient = require('./src/redis-client');

async function testConnection() {
    const redisClient = new RedisClient();
    
    try {
        await redisClient.connect();
        const client = redisClient.getClient();
        
        // Test basic operation
        await client.ping();
        console.log('🏓 PING successful');
        
        await redisClient.disconnect();
    } catch (error) {
        console.error('Connection test failed:', error);
    }
}

testConnection();
```

Run the test:
```bash
node test-connection.js
```

---

## Part 2: Customer Profile Management (15 minutes)

### Step 1: Create Customer Profile Module

Create `src/customer-manager.js`:

```javascript
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
```

### Step 2: Test Customer Operations

Create `examples/test-customers.js`:

```javascript
const CustomerManager = require('../src/customer-manager');

async function testCustomerOperations() {
    const customerManager = new CustomerManager();
    
    try {
        await customerManager.initialize();
        console.log('🚀 Testing Customer Profile Operations\n');

        // Test 1: Create customers
        console.log('📝 Creating test customers...');
        
        await customerManager.createCustomer('C001', {
            firstName: 'John',
            lastName: 'Smith',
            email: 'john.smith@email.com',
            phone: '555-0101',
            dateOfBirth: '1985-03-15',
            address: '123 Main St',
            city: 'Anytown',
            state: 'CA',
            zipCode: '12345'
        });

        await customerManager.createCustomer('C002', {
            firstName: 'Sarah',
            lastName: 'Johnson',
            email: 'sarah.johnson@email.com',
            phone: '555-0102',
            dateOfBirth: '1990-07-22',
            address: '456 Oak Ave',
            city: 'Springfield',
            state: 'IL',
            zipCode: '62701'
        });

        // Test 2: Retrieve customer
        console.log('\n📖 Retrieving customer data...');
        const customer1 = await customerManager.getCustomer('C001');
        console.log('Customer C001:', JSON.stringify(customer1, null, 2));

        // Test 3: Update specific field
        console.log('\n✏️ Updating customer phone...');
        await customerManager.updateCustomerField('C001', 'phone', '555-9999');

        // Test 4: Update multiple fields
        console.log('\n📝 Updating customer address...');
        await customerManager.updateCustomer('C002', {
            address: '789 Pine St',
            city: 'Chicago',
            zipCode: '60601'
        });

        // Test 5: Get specific field
        console.log('\n🔍 Getting customer email...');
        const email = await customerManager.getCustomerField('C001', 'email');
        console.log('Customer C001 email:', email);

        // Test 6: List all customers
        console.log('\n📋 Listing all customers...');
        const allCustomers = await customerManager.getAllCustomers();
        console.log(`Found ${allCustomers.length} customers`);
        allCustomers.forEach(customer => {
            console.log(`- ${customer.id}: ${customer.firstName} ${customer.lastName}`);
        });

        console.log('\n✅ Customer operations test completed successfully!');

    } catch (error) {
        console.error('❌ Test failed:', error);
    } finally {
        await customerManager.cleanup();
    }
}

testCustomerOperations();
```

Run the test:
```bash
node examples/test-customers.js
```

---

## Part 3: Policy Management System (15 minutes)

### Step 1: Create Policy Manager Module

Create `src/policy-manager.js`:

```javascript
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
```

### Step 2: Test Policy Operations

Create `examples/test-policies.js`:

```javascript
const PolicyManager = require('../src/policy-manager');

async function testPolicyOperations() {
    const policyManager = new PolicyManager();
    
    try {
        await policyManager.initialize();
        console.log('🚀 Testing Policy Management Operations\n');

        // Test 1: Create policies
        console.log('📝 Creating test policies...');
        
        const autoPolicy = await policyManager.createPolicy({
            policyNumber: 'AUTO001',
            customerId: 'C001',
            type: 'auto',
            effectiveDate: '2024-01-01',
            expirationDate: '2024-12-31',
            premium: 150.00,
            deductible: 500.00,
            coverageAmount: 50000.00,
            coverageDetails: {
                liability: 'Full',
                collision: 'Full',
                comprehensive: 'Full'
            },
            agent: 'AGT001',
            paymentFrequency: 'monthly'
        });

        const homePolicy = await policyManager.createPolicy({
            policyNumber: 'HOME001',
            customerId: 'C001',
            type: 'home',
            effectiveDate: '2024-01-01',
            expirationDate: '2024-12-31',
            premium: 120.00,
            deductible: 1000.00,
            coverageAmount: 250000.00,
            coverageDetails: {
                dwelling: 250000,
                personalProperty: 100000,
                liability: 300000
            },
            agent: 'AGT002'
        });

        // Test 2: Retrieve policy
        console.log('\n📖 Retrieving policy data...');
        const policy = await policyManager.getPolicy('AUTO001');
        console.log('Auto Policy:', JSON.stringify(policy, null, 2));

        // Test 3: Update policy
        console.log('\n✏️ Updating policy premium...');
        await policyManager.updatePolicy('AUTO001', {
            premium: 165.00,
            status: 'active',
            coverageDetails: {
                liability: 'Full',
                collision: 'Full',
                comprehensive: 'Full',
                rentalCar: 'Added'
            }
        });

        // Test 4: Get specific field
        console.log('\n🔍 Getting policy premium...');
        const premium = await policyManager.getPolicyField('AUTO001', 'premium');
        console.log('Updated premium:', premium);

        // Test 5: Get customer policies
        console.log('\n📋 Getting all policies for customer C001...');
        const customerPolicies = await policyManager.getCustomerPolicies('C001');
        console.log(`Customer has ${customerPolicies.length} policies:`);
        customerPolicies.forEach(pol => {
            console.log(`- ${pol.policyNumber} (${pol.type}): $${pol.premium}/month`);
        });

        // Test 6: Get policies by type
        console.log('\n🏠 Getting all home policies...');
        const homePolicies = await policyManager.getPoliciesByType('home');
        console.log(`Found ${homePolicies.length} home policies`);

        // Test 7: Calculate policy metrics
        console.log('\n📊 Calculating policy metrics...');
        const metrics = await policyManager.calculatePolicyMetrics('AUTO001');
        console.log('Policy Metrics:', JSON.stringify(metrics, null, 2));

        console.log('\n✅ Policy operations test completed successfully!');

    } catch (error) {
        console.error('❌ Test failed:', error);
    } finally {
        await policyManager.cleanup();
    }
}

testPolicyOperations();
```

Run the test:
```bash
node examples/test-policies.js
```

---

## Part 4: Integrated Customer-Policy Operations (7 minutes)

### Step 1: Create Integrated Management System

Create `src/crm-system.js`:

```javascript
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
```

### Step 2: Test Integrated System

Create `examples/test-integrated-system.js`:

```javascript
const CRMSystem = require('../src/crm-system');

async function testIntegratedSystem() {
    const crm = new CRMSystem();
    
    try {
        await crm.initialize();
        console.log('🚀 Testing Integrated CRM System\n');

        // Test 1: Create customer with policy
        console.log('📝 Creating customer with policy...');
        const result = await crm.createCustomerWithPolicy(
            {
                id: 'C003',
                firstName: 'Mike',
                lastName: 'Wilson',
                email: 'mike.wilson@email.com',
                phone: '555-0103',
                dateOfBirth: '1982-12-10',
                address: '789 Cedar St',
                city: 'Portland',
                state: 'OR',
                zipCode: '97201'
            },
            {
                policyNumber: 'AUTO002',
                type: 'auto',
                effectiveDate: '2024-02-01',
                expirationDate: '2025-01-31',
                premium: 140.00,
                deductible: 500.00,
                coverageAmount: 75000.00,
                coverageDetails: {
                    liability: 'Full',
                    collision: 'Full'
                },
                agent: 'AGT003'
            }
        );

        // Test 2: Get complete customer profile
        console.log('\n📊 Getting complete customer profile...');
        const profile = await crm.getCustomerProfile('C003');
        console.log('Customer Profile:');
        console.log(`Name: ${profile.customer.firstName} ${profile.customer.lastName}`);
        console.log(`Email: ${profile.customer.email}`);
        console.log(`Total Policies: ${profile.summary.totalPolicies}`);
        console.log(`Monthly Premium: $${profile.summary.totalMonthlyPremium.toFixed(2)}`);

        // Test 3: Update customer contact
        console.log('\n📞 Updating customer contact info...');
        await crm.updateCustomerContact('C003', {
            phone: '555-7777',
            email: 'mike.wilson.new@email.com'
        });

        // Test 4: Generate customer report
        console.log('\n📋 Generating customer report...');
        const report = await crm.generateCustomerReport('C003');
        console.log('Customer Report:', JSON.stringify(report, null, 2));

        console.log('\n✅ Integrated system test completed successfully!');

    } catch (error) {
        console.error('❌ Test failed:', error);
    } finally {
        await crm.cleanup();
    }
}

testIntegratedSystem();
```

Run the test:
```bash
node examples/test-integrated-system.js
```

---

## Part 5: Redis Insight Exploration & Advanced Operations

### Step 1: Explore Data in Redis Insight

1. **Open Redis Insight** and connect to your Redis server
2. **Navigate to Browser tab**
3. **Look for hash keys** you created:
   - `customer:*` - Customer profile hashes
   - `policy:*` - Policy data hashes
   - `customers:index` - Set of customer IDs
   - `policies:index` - Set of policy IDs

4. **Examine hash structure:**
   - Click on a customer key (e.g., `customer:C001`)
   - View all hash fields and values
   - Edit a field value through the GUI

5. **Use the CLI tab in Redis Insight:**
   ```bash
   # List all customer keys
   KEYS customer:*
   
   # Get all fields for a customer
   HGETALL customer:C001
   
   # Get specific field
   HGET customer:C001 email
   
   # Check hash field count
   HLEN customer:C001
   
   # Get all field names
   HKEYS customer:C001
   ```

### Step 2: Advanced Hash Operations

Create `examples/advanced-hash-operations.js`:

```javascript
const RedisClient = require('../src/redis-client');

async function advancedHashOperations() {
    const redisClient = new RedisClient();
    
    try {
        await redisClient.connect();
        const client = redisClient.getClient();
        
        console.log('🚀 Advanced Hash Operations\n');

        // Bulk hash operations
        console.log('📦 Bulk hash operations...');
        
        // HMSET equivalent with multiple fields
        await client.hSet('customer:bulk', {
            'name': 'Jane Doe',
            'age': '28',
            'city': 'Seattle',
            'premium': '200'
        });

        // Get multiple fields at once
        const fields = await client.hmGet('customer:bulk', ['name', 'age', 'city']);
        console.log('Multiple fields:', fields);

        // Increment numeric field
        console.log('\n🔢 Numeric operations...');
        await client.hIncrBy('customer:bulk', 'age', 1);
        await client.hIncrByFloat('customer:bulk', 'premium', 15.50);
        
        const newAge = await client.hGet('customer:bulk', 'age');
        const newPremium = await client.hGet('customer:bulk', 'premium');
        console.log(`Updated age: ${newAge}, Updated premium: ${newPremium}`);

        // Check field existence
        console.log('\n❓ Field existence checks...');
        const emailExists = await client.hExists('customer:bulk', 'email');
        const nameExists = await client.hExists('customer:bulk', 'name');
        console.log(`Email exists: ${emailExists}, Name exists: ${nameExists}`);

        // Get all field names
        console.log('\n🔑 Getting field names...');
        const fieldNames = await client.hKeys('customer:bulk');
        console.log('Field names:', fieldNames);

        // Get all values
        console.log('\n📝 Getting all values...');
        const values = await client.hVals('customer:bulk');
        console.log('Values:', values);

        // Hash length
        const hashLength = await client.hLen('customer:bulk');
        console.log(`\n📏 Hash has ${hashLength} fields`);

        // Delete specific field
        console.log('\n🗑️ Deleting field...');
        await client.hDel('customer:bulk', 'age');
        const remainingFields = await client.hKeys('customer:bulk');
        console.log('Remaining fields:', remainingFields);

        console.log('\n✅ Advanced hash operations completed!');

    } catch (error) {
        console.error('❌ Advanced operations failed:', error);
    } finally {
        await redisClient.disconnect();
    }
}

advancedHashOperations();
```

---

## Lab Completion Checklist

- [ ] Set up JavaScript project with Redis client connection
- [ ] Created CustomerManager class with CRUD operations
- [ ] Implemented PolicyManager for policy data management
- [ ] Built integrated CRM system combining both managers
- [ ] Tested all hash operations with sample data
- [ ] Explored data structures in Redis Insight
- [ ] Performed advanced hash operations (HMGET, HINCRBY, etc.)
- [ ] Generated customer reports with policy summaries
- [ ] Successfully managed nested data with hash fields

---

## Key Takeaways

🎉 **Congratulations!** You've mastered Redis hash operations with JavaScript:

1. **Hash Structure Benefits**: Perfect for storing structured data like customer profiles and policies
2. **Field-Level Operations**: Update individual fields without affecting others
3. **Memory Efficiency**: Hashes are memory-optimized for storing related data
4. **JavaScript Integration**: Seamless integration with Node.js applications
5. **Real-World Applications**: Built a foundation for customer relationship management

**Next Lab Preview:** Lab 8 will explore Redis Lists for implementing task queues and workflow systems.

---

## Troubleshooting

### Common Issues

**Hash field not found:**
```javascript
// Always check if field exists before accessing
const exists = await client.hExists(key, field);
if (!exists) {
    console.log('Field does not exist');
}
```

**JSON data handling:**
```javascript
// Store complex objects as JSON strings in hash fields
const complexData = { nested: { data: 'value' } };
await client.hSet(key, 'complexField', JSON.stringify(complexData));

// Retrieve and parse
const stored = await client.hGet(key, 'complexField');
const parsed = JSON.parse(stored);
```

**Connection management:**
```javascript
// Always handle connection errors
client.on('error', (err) => {
    console.error('Redis Client Error:', err);
});
```

## Quick Reference

**Essential Hash Commands:**
- `HSET key field value` - Set hash field
- `HGET key field` - Get hash field
- `HGETALL key` - Get all fields and values
- `HMGET key field1 field2` - Get multiple fields
- `HEXISTS key field` - Check field existence
- `HDEL key field` - Delete field
- `HKEYS key` - Get all field names
- `HVALS key` - Get all values
- `HLEN key` - Get field count
- `HINCRBY key field increment` - Increment numeric field
