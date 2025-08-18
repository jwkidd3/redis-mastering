#!/bin/bash

# Lab 7 Content Generator Script
# Generates complete content and code for Lab 7: Customer Profiles & Policy Management
# Duration: 45 minutes
# Focus: JavaScript + Redis Hashes for customer and policy management

set -e

LAB_DIR="lab7-customer-profiles-policy-management"
LAB_NUMBER="7"
LAB_TITLE="Customer Profiles & Policy Management"
LAB_DURATION="45"

echo "🚀 Generating Lab ${LAB_NUMBER}: ${LAB_TITLE}"
echo "📅 Duration: ${LAB_DURATION} minutes"
echo "🎯 Focus: JavaScript Redis client with hashes for customer and policy data"
echo ""

# Create lab directory structure
mkdir -p ${LAB_DIR}
cd ${LAB_DIR}

echo "📁 Creating lab directory structure..."
mkdir -p {src,scripts,docs,examples,test-data,config}

# Create main lab instructions markdown file
echo "📋 Creating lab7.md..."
cat > lab7.md << 'EOF'
# Lab 7: Customer Profiles & Policy Management

**Duration:** 45 minutes  
**Objective:** Build a comprehensive customer and policy management system using JavaScript and Redis hashes

## 🎯 Learning Objectives

By the end of this lab, you will be able to:
- Implement customer profile management with Redis hashes in JavaScript
- Build policy CRUD operations using hash data structures
- Model complex nested data for customer preferences and history
- Implement efficient bulk operations for policy renewals
- Apply atomic field updates for risk assessments and premiums
- Create relationship mappings between customers, policies, and claims

---

## Part 1: JavaScript Redis Client Setup for Hash Operations (10 minutes)

### Step 1: Environment Setup and Dependencies

```bash
# Initialize Node.js project
npm init -y

# Install Redis client
npm install redis

# Install development dependencies
npm install --save-dev nodemon

# Start Redis with optimized configuration
docker run -d --name redis-lab7 \
  -p 6379:6379 \
  redis:7-alpine redis-server \
  --maxmemory 512mb \
  --maxmemory-policy allkeys-lru

# Verify Redis connection
redis-cli ping
```

### Step 2: Create Redis Client Configuration

Create `config/redis-config.js`:
```javascript
const redis = require('redis');

// Create Redis client with retry strategy
const client = redis.createClient({
    url: 'redis://localhost:6379',
    retry_strategy: (options) => {
        if (options.error && options.error.code === 'ECONNREFUSED') {
            return new Error('Redis server refused connection');
        }
        if (options.total_retry_time > 1000 * 60 * 60) {
            return new Error('Retry time exhausted');
        }
        if (options.attempt > 10) {
            return undefined;
        }
        return Math.min(options.attempt * 100, 3000);
    }
});

// Error handling
client.on('error', (err) => {
    console.error('Redis Client Error:', err);
});

client.on('connect', () => {
    console.log('✅ Connected to Redis');
});

client.on('ready', () => {
    console.log('✅ Redis client ready');
});

// Connect to Redis
async function connect() {
    await client.connect();
}

module.exports = { client, connect };
```

### Step 3: Test Connection and Basic Hash Operations

Create `test-connection.js`:
```javascript
const { client, connect } = require('./config/redis-config');

async function testConnection() {
    try {
        await connect();
        
        // Test basic hash operations
        await client.hSet('test:customer', {
            'name': 'John Doe',
            'email': 'john@example.com'
        });
        
        const customer = await client.hGetAll('test:customer');
        console.log('Test customer:', customer);
        
        // Cleanup
        await client.del('test:customer');
        
        console.log('✅ Connection test successful');
        await client.quit();
    } catch (error) {
        console.error('❌ Connection test failed:', error);
        process.exit(1);
    }
}

testConnection();
```

Run the test:
```bash
node test-connection.js
```

---

## Part 2: Customer Profile Management System (15 minutes)

### Step 1: Customer Model Implementation

Create `src/customer-manager.js`:
```javascript
const { client } = require('../config/redis-config');

class CustomerManager {
    constructor() {
        this.keyPrefix = 'customer:';
    }
    
    // Generate customer key
    getKey(customerId) {
        return `${this.keyPrefix}${customerId}`;
    }
    
    // Create new customer profile
    async createCustomer(customerId, customerData) {
        const key = this.getKey(customerId);
        
        // Prepare customer data with timestamps
        const data = {
            ...customerData,
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString(),
            status: customerData.status || 'ACTIVE'
        };
        
        // Store customer profile
        await client.hSet(key + ':profile', data);
        
        // Initialize related data structures
        await client.hSet(key + ':preferences', {
            'communication': 'email',
            'paperless': 'true',
            'auto_renewal': 'false'
        });
        
        // Add to customer index
        await client.sAdd('customers:active', customerId);
        
        // Store in sorted set by creation date
        await client.zAdd('customers:by_date', {
            score: Date.now(),
            value: customerId
        });
        
        return { customerId, ...data };
    }
    
    // Get customer profile
    async getCustomer(customerId) {
        const key = this.getKey(customerId);
        const profile = await client.hGetAll(key + ':profile');
        
        if (Object.keys(profile).length === 0) {
            return null;
        }
        
        const preferences = await client.hGetAll(key + ':preferences');
        const policies = await client.sMembers(key + ':policies');
        
        return {
            customerId,
            profile,
            preferences,
            policies
        };
    }
    
    // Update customer fields
    async updateCustomer(customerId, updates) {
        const key = this.getKey(customerId);
        
        // Check if customer exists
        const exists = await client.exists(key + ':profile');
        if (!exists) {
            throw new Error(`Customer ${customerId} not found`);
        }
        
        // Update fields
        updates.updated_at = new Date().toISOString();
        await client.hSet(key + ':profile', updates);
        
        // Log update in audit trail
        await this.logCustomerActivity(customerId, 'UPDATE', updates);
        
        return await this.getCustomer(customerId);
    }
    
    // Update customer preferences
    async updatePreferences(customerId, preferences) {
        const key = this.getKey(customerId);
        await client.hSet(key + ':preferences', preferences);
        return preferences;
    }
    
    // Add customer activity to audit log
    async logCustomerActivity(customerId, action, details) {
        const key = `audit:customer:${customerId}`;
        const entry = {
            action,
            timestamp: new Date().toISOString(),
            details: JSON.stringify(details)
        };
        
        await client.zAdd(key, {
            score: Date.now(),
            value: JSON.stringify(entry)
        });
        
        // Keep only last 100 entries
        await client.zRemRangeByRank(key, 0, -101);
    }
    
    // Calculate customer risk score
    async calculateRiskScore(customerId) {
        const key = this.getKey(customerId);
        const profile = await client.hGetAll(key + ':profile');
        
        let riskScore = 700; // Base score
        
        // Age factor
        const age = parseInt(profile.age) || 30;
        if (age < 25) riskScore -= 50;
        if (age > 50) riskScore += 30;
        
        // Claims history factor
        const claimsCount = await client.sCard(key + ':claims');
        riskScore -= (claimsCount * 25);
        
        // Payment history factor
        const latePayments = parseInt(profile.late_payments) || 0;
        riskScore -= (latePayments * 15);
        
        // Loyalty factor
        const customerSince = new Date(profile.created_at);
        const yearsAsCustomer = (Date.now() - customerSince) / (365 * 24 * 60 * 60 * 1000);
        riskScore += Math.min(yearsAsCustomer * 10, 50);
        
        // Store risk score
        await client.hSet(key + ':profile', 'risk_score', Math.max(300, Math.min(850, riskScore)));
        
        return riskScore;
    }
}

module.exports = CustomerManager;
```

### Step 2: Test Customer Operations

Create `test-customer.js`:
```javascript
const { client, connect } = require('./config/redis-config');
const CustomerManager = require('./src/customer-manager');

async function testCustomerOperations() {
    await connect();
    const customerManager = new CustomerManager();
    
    try {
        // Create customer
        console.log('📝 Creating customer...');
        const customer = await customerManager.createCustomer('CUST001', {
            name: 'John Smith',
            email: 'john.smith@email.com',
            phone: '555-0123',
            age: '35',
            address: '123 Main St, Dallas, TX',
            occupation: 'Software Engineer'
        });
        console.log('Customer created:', customer);
        
        // Update preferences
        console.log('\\n🔧 Updating preferences...');
        await customerManager.updatePreferences('CUST001', {
            communication: 'sms',
            paperless: 'true',
            auto_renewal: 'true'
        });
        
        // Calculate risk score
        console.log('\\n📊 Calculating risk score...');
        const riskScore = await customerManager.calculateRiskScore('CUST001');
        console.log('Risk score:', riskScore);
        
        // Get complete customer profile
        console.log('\\n👤 Fetching complete profile...');
        const profile = await customerManager.getCustomer('CUST001');
        console.log('Complete profile:', JSON.stringify(profile, null, 2));
        
    } catch (error) {
        console.error('❌ Test failed:', error);
    } finally {
        await client.quit();
    }
}

testCustomerOperations();
```

---

## Part 3: Policy Management System (15 minutes)

### Step 1: Policy Manager Implementation

Create `src/policy-manager.js`:
```javascript
const { client } = require('../config/redis-config');

class PolicyManager {
    constructor() {
        this.keyPrefix = 'policy:';
        this.policyTypes = ['auto', 'home', 'life', 'health'];
    }
    
    // Generate policy number
    async generatePolicyNumber(type) {
        const counter = await client.incr(`policy:${type}:counter`);
        return `${type.toUpperCase()}-${String(counter).padStart(6, '0')}`;
    }
    
    // Create new policy
    async createPolicy(customerId, policyData) {
        const policyNumber = await this.generatePolicyNumber(policyData.type);
        const key = `${this.keyPrefix}${policyData.type}:${policyNumber}`;
        
        // Prepare policy data
        const policy = {
            policy_number: policyNumber,
            customer_id: customerId,
            type: policyData.type,
            status: 'ACTIVE',
            premium: policyData.premium,
            coverage_amount: policyData.coverage_amount,
            deductible: policyData.deductible,
            start_date: policyData.start_date || new Date().toISOString(),
            end_date: policyData.end_date,
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
        };
        
        // Store policy details
        await client.hSet(key + ':details', policy);
        
        // Store type-specific attributes
        if (policyData.attributes) {
            await client.hSet(key + ':attributes', policyData.attributes);
        }
        
        // Link policy to customer
        await client.sAdd(`customer:${customerId}:policies`, policyNumber);
        
        // Add to policy indices
        await client.sAdd(`policies:${policyData.type}:active`, policyNumber);
        await client.zAdd('policies:by_premium', {
            score: parseFloat(policyData.premium),
            value: policyNumber
        });
        
        // Set renewal reminder (30 days before expiry)
        if (policyData.end_date) {
            const expiryDate = new Date(policyData.end_date);
            const reminderDate = new Date(expiryDate.getTime() - (30 * 24 * 60 * 60 * 1000));
            const ttl = Math.floor((reminderDate - Date.now()) / 1000);
            
            if (ttl > 0) {
                await client.setEx(`reminder:policy:${policyNumber}`, ttl, customerId);
            }
        }
        
        return policy;
    }
    
    // Get policy details
    async getPolicy(policyType, policyNumber) {
        const key = `${this.keyPrefix}${policyType}:${policyNumber}`;
        
        const details = await client.hGetAll(key + ':details');
        if (Object.keys(details).length === 0) {
            return null;
        }
        
        const attributes = await client.hGetAll(key + ':attributes');
        const claims = await client.sMembers(key + ':claims');
        
        return {
            details,
            attributes,
            claims
        };
    }
    
    // Update policy premium
    async updatePremium(policyType, policyNumber, newPremium, reason) {
        const key = `${this.keyPrefix}${policyType}:${policyNumber}`;
        
        // Get current premium
        const currentPremium = await client.hGet(key + ':details', 'premium');
        
        // Update premium
        await client.hSet(key + ':details', {
            'premium': newPremium,
            'updated_at': new Date().toISOString()
        });
        
        // Update sorted set index
        await client.zAdd('policies:by_premium', {
            score: parseFloat(newPremium),
            value: policyNumber
        });
        
        // Log premium change
        await client.lPush(`${key}:premium_history`, JSON.stringify({
            old_premium: currentPremium,
            new_premium: newPremium,
            reason: reason,
            timestamp: new Date().toISOString()
        }));
        
        // Keep only last 10 premium changes
        await client.lTrim(`${key}:premium_history`, 0, 9);
        
        return { oldPremium: currentPremium, newPremium };
    }
    
    // Process policy renewal
    async renewPolicy(policyType, policyNumber, renewalData) {
        const key = `${this.keyPrefix}${policyType}:${policyNumber}`;
        
        // Check if policy exists and is active
        const status = await client.hGet(key + ':details', 'status');
        if (status !== 'ACTIVE') {
            throw new Error(`Policy ${policyNumber} is not active`);
        }
        
        // Update policy dates and premium
        const updates = {
            start_date: renewalData.start_date || new Date().toISOString(),
            end_date: renewalData.end_date,
            premium: renewalData.premium || await client.hGet(key + ':details', 'premium'),
            renewed_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
        };
        
        await client.hSet(key + ':details', updates);
        
        // Log renewal
        await client.zAdd(`${key}:renewals`, {
            score: Date.now(),
            value: JSON.stringify({
                renewed_at: updates.renewed_at,
                new_premium: updates.premium,
                term: renewalData.term || '1 year'
            })
        });
        
        return updates;
    }
    
    // Cancel policy
    async cancelPolicy(policyType, policyNumber, reason) {
        const key = `${this.keyPrefix}${policyType}:${policyNumber}`;
        
        // Update policy status
        await client.hSet(key + ':details', {
            'status': 'CANCELLED',
            'cancelled_at': new Date().toISOString(),
            'cancellation_reason': reason,
            'updated_at': new Date().toISOString()
        });
        
        // Remove from active policies
        await client.sRem(`policies:${policyType}:active`, policyNumber);
        await client.sAdd(`policies:${policyType}:cancelled`, policyNumber);
        
        // Get customer ID for notification
        const customerId = await client.hGet(key + ':details', 'customer_id');
        
        // Create cancellation notification
        await client.lPush(`notifications:${customerId}`, JSON.stringify({
            type: 'POLICY_CANCELLED',
            policy_number: policyNumber,
            reason: reason,
            timestamp: new Date().toISOString()
        }));
        
        return { policyNumber, status: 'CANCELLED', reason };
    }
    
    // Bulk policy operations
    async bulkRenewal(policyType, expiringDays = 30) {
        const policies = await client.sMembers(`policies:${policyType}:active`);
        const renewalCandidates = [];
        
        for (const policyNumber of policies) {
            const key = `${this.keyPrefix}${policyType}:${policyNumber}`;
            const endDate = await client.hGet(key + ':details', 'end_date');
            
            if (endDate) {
                const daysUntilExpiry = Math.floor((new Date(endDate) - Date.now()) / (1000 * 60 * 60 * 24));
                
                if (daysUntilExpiry <= expiringDays && daysUntilExpiry > 0) {
                    const customerId = await client.hGet(key + ':details', 'customer_id');
                    renewalCandidates.push({
                        policyNumber,
                        customerId,
                        endDate,
                        daysUntilExpiry
                    });
                }
            }
        }
        
        return renewalCandidates;
    }
}

module.exports = PolicyManager;
```

### Step 2: Test Policy Operations

Create `test-policy.js`:
```javascript
const { client, connect } = require('./config/redis-config');
const PolicyManager = require('./src/policy-manager');

async function testPolicyOperations() {
    await connect();
    const policyManager = new PolicyManager();
    
    try {
        // Create auto policy
        console.log('🚗 Creating auto policy...');
        const autoPolicy = await policyManager.createPolicy('CUST001', {
            type: 'auto',
            premium: '1200',
            coverage_amount: '50000',
            deductible: '500',
            end_date: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString(),
            attributes: {
                vehicle_make: 'Toyota',
                vehicle_model: 'Camry',
                vehicle_year: '2020',
                vin: '1HGBH41JXMN109186'
            }
        });
        console.log('Auto policy created:', autoPolicy);
        
        // Create home policy
        console.log('\\n🏠 Creating home policy...');
        const homePolicy = await policyManager.createPolicy('CUST001', {
            type: 'home',
            premium: '1800',
            coverage_amount: '500000',
            deductible: '1000',
            end_date: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString(),
            attributes: {
                property_address: '123 Main St, Dallas, TX',
                property_type: 'Single Family',
                year_built: '2005',
                square_feet: '2500'
            }
        });
        console.log('Home policy created:', homePolicy);
        
        // Update premium
        console.log('\\n💰 Updating premium...');
        const premiumUpdate = await policyManager.updatePremium(
            'auto',
            autoPolicy.policy_number,
            '1100',
            'Good driver discount'
        );
        console.log('Premium updated:', premiumUpdate);
        
        // Get policy details
        console.log('\\n📋 Fetching policy details...');
        const policyDetails = await policyManager.getPolicy('auto', autoPolicy.policy_number);
        console.log('Policy details:', JSON.stringify(policyDetails, null, 2));
        
        // Check for renewals
        console.log('\\n🔄 Checking for upcoming renewals...');
        const renewals = await policyManager.bulkRenewal('auto', 400);
        console.log('Policies needing renewal:', renewals);
        
    } catch (error) {
        console.error('❌ Test failed:', error);
    } finally {
        await client.quit();
    }
}

testPolicyOperations();
```

---

## Part 4: Integration and Performance Testing (5 minutes)

### Step 1: Combined Operations Test

Create `test-integration.js`:
```javascript
const { client, connect } = require('./config/redis-config');
const CustomerManager = require('./src/customer-manager');
const PolicyManager = require('./src/policy-manager');

async function testIntegration() {
    await connect();
    const customerManager = new CustomerManager();
    const policyManager = new PolicyManager();
    
    console.log('🚀 Starting integration test...');
    console.time('Integration Test');
    
    try {
        // Create multiple customers
        const customers = [];
        for (let i = 1; i <= 5; i++) {
            const customer = await customerManager.createCustomer(`CUST00${i}`, {
                name: `Customer ${i}`,
                email: `customer${i}@email.com`,
                phone: `555-010${i}`,
                age: String(25 + i * 5),
                address: `${i}00 Main St, Dallas, TX`
            });
            customers.push(customer);
        }
        console.log(`✅ Created ${customers.length} customers`);
        
        // Create policies for each customer
        let totalPolicies = 0;
        for (const customer of customers) {
            // Auto policy
            await policyManager.createPolicy(customer.customerId, {
                type: 'auto',
                premium: String(1000 + Math.random() * 1000),
                coverage_amount: '50000',
                deductible: '500',
                end_date: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString()
            });
            totalPolicies++;
            
            // Home policy for some customers
            if (Math.random() > 0.5) {
                await policyManager.createPolicy(customer.customerId, {
                    type: 'home',
                    premium: String(1500 + Math.random() * 1500),
                    coverage_amount: '500000',
                    deductible: '1000',
                    end_date: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString()
                });
                totalPolicies++;
            }
        }
        console.log(`✅ Created ${totalPolicies} policies`);
        
        // Calculate risk scores
        for (const customer of customers) {
            await customerManager.calculateRiskScore(customer.customerId);
        }
        console.log('✅ Calculated risk scores');
        
        // Verify data in Redis Insight
        console.log('\\n📊 Data Summary:');
        const dbSize = await client.dbSize();
        console.log(`Total keys in database: ${dbSize}`);
        
        const activeCustomers = await client.sCard('customers:active');
        console.log(`Active customers: ${activeCustomers}`);
        
        const autoPolicies = await client.sCard('policies:auto:active');
        const homePolicies = await client.sCard('policies:home:active');
        console.log(`Active policies - Auto: ${autoPolicies}, Home: ${homePolicies}`);
        
    } catch (error) {
        console.error('❌ Integration test failed:', error);
    } finally {
        console.timeEnd('Integration Test');
        await client.quit();
    }
}

testIntegration();
```

### Step 2: Performance Benchmark

Create `benchmark.js`:
```javascript
const { client, connect } = require('./config/redis-config');

async function benchmark() {
    await connect();
    
    console.log('⚡ Running performance benchmark...');
    
    // Benchmark hash operations
    console.log('\\nHash Operations:');
    console.time('1000 Hash Sets');
    for (let i = 0; i < 1000; i++) {
        await client.hSet(`bench:customer:${i}`, {
            name: `Customer ${i}`,
            email: `customer${i}@test.com`,
            status: 'ACTIVE'
        });
    }
    console.timeEnd('1000 Hash Sets');
    
    console.time('1000 Hash Gets');
    for (let i = 0; i < 1000; i++) {
        await client.hGetAll(`bench:customer:${i}`);
    }
    console.timeEnd('1000 Hash Gets');
    
    // Benchmark pipeline operations
    console.log('\\nPipeline Operations:');
    console.time('1000 Pipelined Hash Sets');
    const pipeline = client.multi();
    for (let i = 0; i < 1000; i++) {
        pipeline.hSet(`bench:policy:${i}`, {
            type: 'auto',
            premium: String(1000 + i),
            status: 'ACTIVE'
        });
    }
    await pipeline.exec();
    console.timeEnd('1000 Pipelined Hash Sets');
    
    // Cleanup
    console.log('\\nCleaning up...');
    const keys = await client.keys('bench:*');
    if (keys.length > 0) {
        await client.del(keys);
    }
    console.log(`Deleted ${keys.length} benchmark keys`);
    
    await client.quit();
}

benchmark();
```

---

## 🔍 Verification with Redis Insight

### Viewing Hash Data in Redis Insight

1. **Open Redis Insight** and connect to localhost:6379
2. **Navigate to Browser** tab
3. **View customer profiles:**
   - Search for pattern: `customer:*`
   - Click on any customer key to see hash fields
   - Notice the nested structure with :profile, :preferences, :policies

4. **View policy data:**
   - Search for pattern: `policy:*`
   - Examine the hierarchical structure
   - Check :details, :attributes, and :claims sub-keys

5. **Check indices:**
   - View `customers:active` set
   - View `policies:auto:active` set
   - View `policies:by_premium` sorted set

### Monitoring Operations

Use Redis Insight's Profiler to monitor commands:
1. Go to **Profiler** tab
2. Start profiling
3. Run any test script
4. Observe the hash commands being executed

---

## 📊 Lab Summary

### What You've Accomplished
✅ Set up JavaScript Redis client with proper error handling  
✅ Built complete customer profile management system  
✅ Implemented comprehensive policy CRUD operations  
✅ Created relationship mappings between entities  
✅ Implemented bulk operations and performance optimizations  
✅ Applied production patterns for data modeling  

### Key Commands Used
- **Hash Operations:** `HSET`, `HGET`, `HGETALL`, `HMSET`, `HINCRBY`
- **Set Operations:** `SADD`, `SREM`, `SMEMBERS`, `SCARD`
- **Sorted Set Operations:** `ZADD`, `ZRANGE`, `ZREM`
- **Key Management:** `EXISTS`, `DEL`, `EXPIRE`, `TTL`

### Production Patterns Applied
- Customer data modeling with hashes
- Policy lifecycle management
- Audit trail implementation
- Risk scoring algorithms
- Bulk renewal processing
- Performance optimization with pipelines

---

## 🆘 Troubleshooting

### Common Issues and Solutions

**Connection Issues:**
```bash
# Check if Redis is running
docker ps | grep redis-lab7

# Restart Redis if needed
docker restart redis-lab7

# Check Redis logs
docker logs redis-lab7
```

**Module Import Errors:**
```bash
# Ensure dependencies are installed
npm install

# Check package.json
cat package.json

# Clear npm cache if needed
npm cache clean --force
```

**Data Verification:**
```bash
# Check total keys
redis-cli DBSIZE

# View specific customer
redis-cli HGETALL customer:CUST001:profile

# List all policies for a customer
redis-cli SMEMBERS customer:CUST001:policies
```

---

## 🎯 Next Steps

You have completed Lab 7! You've built a production-ready customer and policy management system. 

**Next Lab:** Lab 8 - Claims Processing Queues with Lists

**To continue learning:**
1. Experiment with more complex data relationships
2. Implement additional business logic (discounts, bundles)
3. Add data validation and business rules
4. Explore Redis Streams for event-driven updates
EOF

# Create package.json
echo "📦 Creating package.json..."
cat > package.json << 'EOF'
{
  "name": "lab7-customer-profiles-policy-management",
  "version": "1.0.0",
  "description": "Customer and Policy Management System using Redis Hashes",
  "main": "test-connection.js",
  "scripts": {
    "test-connection": "node test-connection.js",
    "test-customer": "node test-customer.js",
    "test-policy": "node test-policy.js",
    "test-integration": "node test-integration.js",
    "benchmark": "node benchmark.js",
    "dev": "nodemon"
  },
  "keywords": [
    "redis",
    "hash",
    "customer-management",
    "policy-management"
  ],
  "author": "",
  "license": "MIT",
  "dependencies": {
    "redis": "^4.6.0"
  },
  "devDependencies": {
    "nodemon": "^3.0.0"
  }
}
EOF

# Create sample data loader script
echo "📊 Creating sample data loader..."
cat > scripts/load-sample-data.sh << 'EOF'
#!/bin/bash

echo "Loading sample customer and policy data..."

redis-cli << 'REDIS_EOF'
# Clear existing data
FLUSHDB

# Create sample customers
HMSET customer:CUST001:profile \
  name "John Smith" \
  email "john.smith@email.com" \
  phone "555-0123" \
  age "35" \
  address "123 Main St, Dallas, TX" \
  created_at "2024-01-15T10:00:00Z" \
  status "ACTIVE"

HMSET customer:CUST002:profile \
  name "Sarah Johnson" \
  email "sarah.j@email.com" \
  phone "555-0124" \
  age "42" \
  address "456 Oak Ave, Dallas, TX" \
  created_at "2023-06-20T10:00:00Z" \
  status "ACTIVE"

# Set customer preferences
HMSET customer:CUST001:preferences \
  communication "email" \
  paperless "true" \
  auto_renewal "true"

HMSET customer:CUST002:preferences \
  communication "sms" \
  paperless "false" \
  auto_renewal "true"

# Create sample policies
HMSET policy:auto:AUTO-000001:details \
  policy_number "AUTO-000001" \
  customer_id "CUST001" \
  type "auto" \
  status "ACTIVE" \
  premium "1200" \
  coverage_amount "50000" \
  deductible "500" \
  start_date "2024-01-15T10:00:00Z" \
  end_date "2025-01-15T10:00:00Z"

HMSET policy:auto:AUTO-000001:attributes \
  vehicle_make "Toyota" \
  vehicle_model "Camry" \
  vehicle_year "2020" \
  vin "1HGBH41JXMN109186"

HMSET policy:home:HOME-000001:details \
  policy_number "HOME-000001" \
  customer_id "CUST002" \
  type "home" \
  status "ACTIVE" \
  premium "1800" \
  coverage_amount "500000" \
  deductible "1000" \
  start_date "2023-06-20T10:00:00Z" \
  end_date "2024-06-20T10:00:00Z"

HMSET policy:home:HOME-000001:attributes \
  property_address "456 Oak Ave, Dallas, TX" \
  property_type "Single Family" \
  year_built "2005" \
  square_feet "2500"

# Link policies to customers
SADD customer:CUST001:policies "AUTO-000001"
SADD customer:CUST002:policies "HOME-000001"

# Add to indices
SADD customers:active "CUST001" "CUST002"
SADD policies:auto:active "AUTO-000001"
SADD policies:home:active "HOME-000001"

# Add to sorted sets
ZADD customers:by_date 1705318800000 "CUST001" 1687260000000 "CUST002"
ZADD policies:by_premium 1200 "AUTO-000001" 1800 "HOME-000001"

echo "Sample data loaded successfully!"
echo "Customers: 2"
echo "Policies: 2"
DBSIZE
REDIS_EOF
EOF

chmod +x scripts/load-sample-data.sh

# Create troubleshooting guide
echo "🔧 Creating troubleshooting guide..."
cat > docs/troubleshooting.md << 'EOF'
# Troubleshooting Guide - Lab 7

## Common Issues and Solutions

### 1. Connection Issues

**Problem:** Cannot connect to Redis
```
Error: Redis connection to localhost:6379 failed
```

**Solution:**
```bash
# Check if Redis is running
docker ps | grep redis

# Start Redis if not running
docker run -d --name redis-lab7 -p 6379:6379 redis:7-alpine

# Test connection
redis-cli ping
```

### 2. Module Import Errors

**Problem:** Cannot find module 'redis'
```
Error: Cannot find module 'redis'
```

**Solution:**
```bash
# Install dependencies
npm install

# Verify installation
npm list redis
```

### 3. Hash Operation Errors

**Problem:** Hash fields not updating
```javascript
// Wrong way
await client.hSet('key', 'field', {object}); // Objects not allowed

// Correct way
await client.hSet('key', {
    field1: 'value1',
    field2: 'value2'
});
```

### 4. Memory Issues

**Problem:** Redis running out of memory

**Solution:**
```bash
# Check memory usage
redis-cli INFO memory | grep used_memory_human

# Set memory limit
redis-cli CONFIG SET maxmemory 512mb
redis-cli CONFIG SET maxmemory-policy allkeys-lru

# Clear test data
redis-cli FLUSHDB
```

### 5. Async/Await Issues

**Problem:** Operations not completing

**Solution:**
```javascript
// Always use async/await
async function operation() {
    try {
        await client.connect();
        const result = await client.hGetAll('key');
        console.log(result);
    } catch (error) {
        console.error('Error:', error);
    } finally {
        await client.quit();
    }
}
```

## Debugging Commands

```bash
# Monitor Redis commands in real-time
redis-cli MONITOR

# Check Redis logs
docker logs redis-lab7

# View all keys
redis-cli KEYS "*"

# Check specific hash
redis-cli HGETALL customer:CUST001:profile

# Database statistics
redis-cli INFO stats
```

## Performance Optimization

```javascript
// Use pipelines for bulk operations
const pipeline = client.multi();
for (let i = 0; i < 1000; i++) {
    pipeline.hSet(`key:${i}`, data);
}
await pipeline.exec();

// Use HMGET for multiple fields
const fields = await client.hmGet('hash', ['field1', 'field2', 'field3']);
```
EOF

# Create README
echo "📚 Creating README.md..."
cat > README.md << 'EOF'
# Lab 7: Customer Profiles & Policy Management

**Duration:** 45 minutes  
**Focus:** JavaScript Redis client with hash data structures  
**Industry:** Customer and policy management systems

## 📁 Project Structure

```
lab7-customer-profiles-policy-management/
├── lab7.md                          # Complete lab instructions (START HERE)
├── package.json                     # Node.js project configuration
├── config/
│   └── redis-config.js             # Redis client configuration
├── src/
│   ├── customer-manager.js         # Customer management class
│   └── policy-manager.js           # Policy management class
├── scripts/
│   └── load-sample-data.sh         # Sample data loader
├── docs/
│   └── troubleshooting.md          # Troubleshooting guide
├── test-connection.js               # Connection test script
├── test-customer.js                 # Customer operations test
├── test-policy.js                   # Policy operations test
├── test-integration.js              # Integration test
├── benchmark.js                     # Performance benchmark
└── README.md                        # This file
```

## 🚀 Quick Start

1. **Install Dependencies:**
   ```bash
   npm install
   ```

2. **Start Redis:**
   ```bash
   docker run -d --name redis-lab7 -p 6379:6379 redis:7-alpine
   ```

3. **Test Connection:**
   ```bash
   npm run test-connection
   ```

4. **Load Sample Data:**
   ```bash
   ./scripts/load-sample-data.sh
   ```

5. **Run Tests:**
   ```bash
   npm run test-customer
   npm run test-policy
   npm run test-integration
   ```

## 📊 Data Model

### Customer Structure
```
customer:{id}:profile     # Customer details (hash)
customer:{id}:preferences # Customer preferences (hash)
customer:{id}:policies    # Customer's policies (set)
customer:{id}:claims      # Customer's claims (set)
```

### Policy Structure
```
policy:{type}:{number}:details    # Policy details (hash)
policy:{type}:{number}:attributes # Type-specific attributes (hash)
policy:{type}:{number}:claims     # Related claims (set)
policy:{type}:{number}:renewals   # Renewal history (sorted set)
```

## 🎯 Learning Objectives

- Implement customer profile management with Redis hashes
- Build policy CRUD operations using hash data structures
- Model complex nested data for customer preferences and history
- Implement efficient bulk operations for policy renewals
- Apply atomic field updates for risk assessments and premiums
- Create relationship mappings between customers, policies, and claims

## 📝 Available Scripts

- `npm run test-connection` - Test Redis connection
- `npm run test-customer` - Test customer operations
- `npm run test-policy` - Test policy operations
- `npm run test-integration` - Run integration tests
- `npm run benchmark` - Run performance benchmarks

## 🔍 Verification with Redis Insight

1. Connect to `localhost:6379`
2. Browse keys with patterns:
   - `customer:*` - Customer data
   - `policy:*` - Policy data
   - `customers:active` - Active customer set
   - `policies:*:active` - Active policies by type

## 🆘 Troubleshooting

See `docs/troubleshooting.md` for common issues and solutions.

## 🎓 Learning Path

This lab is part of the Redis mastery series:

1. Lab 1: Redis Environment & CLI
2. Lab 2: RESP Protocol Analysis
3. Lab 3: String Operations
4. Lab 4: Key Management & TTL
5. Lab 5: Advanced CLI Operations
6. Lab 6: JavaScript Redis Client
7. **Lab 7: Customer Profiles & Policy Management** ← You are here
8. Lab 8: Claims Processing Queues
9. Lab 9: Analytics with Sets
10. Lab 10: Advanced Caching Patterns

## 🏆 Key Achievements

By completing this lab, you will have mastered:

- **Hash Operations:** Complete CRUD operations with Redis hashes
- **Data Modeling:** Complex entity relationships in Redis
- **Performance:** Bulk operations and pipeline optimization
- **Business Logic:** Risk scoring and policy lifecycle management
- **Production Patterns:** Audit trails and data integrity
- **JavaScript Integration:** Async/await patterns with Redis client

---

**Ready to start?** Open `lab7.md` and begin building your customer and policy management system! 🚀
EOF

# Create .gitignore
cat > .gitignore << 'EOF'
# Dependencies
node_modules/
package-lock.json

# Logs
*.log
npm-debug.log*

# OS files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# IDE files
.vscode/
.idea/
*.swp
*.swo

# Environment files
.env
.env.local

# Test output
test-results/
coverage/

# Temporary files
*.tmp
*.temp
EOF

echo ""
echo "✅ Lab 7 generation complete!"
echo ""
echo "📂 Project structure created:"
echo "   ${LAB_DIR}/"
echo "   ├── lab7.md                          📋 START HERE - Complete lab guide"
echo "   ├── package.json                     📦 Node.js project configuration"
echo "   ├── config/"
echo "   │   └── redis-config.js              🔧 Redis client configuration"
echo "   ├── src/"
echo "   │   ├── customer-manager.js          👤 Customer management implementation"
echo "   │   └── policy-manager.js            📑 Policy management implementation"
echo "   ├── scripts/"
echo "   │   └── load-sample-data.sh          📊 Sample data loader"
echo "   ├── docs/"
echo "   │   └── troubleshooting.md           🆘 Troubleshooting guide"
echo "   ├── test-connection.js                🔌 Connection test"
echo "   ├── test-customer.js                  👥 Customer operations test"
echo "   ├── test-policy.js                    📋 Policy operations test"
echo "   ├── test-integration.js               🔄 Integration test"
echo "   ├── benchmark.js                      ⚡ Performance benchmark"
echo "   ├── README.md                         📖 Project documentation"
echo "   └── .gitignore                        🚫 Git ignore rules"
echo ""
echo "🎯 NEXT STEPS:"
echo "   1. cd ${LAB_DIR}"
echo "   2. npm install                        # Install dependencies"
echo "   3. docker run -d --name redis-lab7 -p 6379:6379 redis:7-alpine"
echo "   4. npm run test-connection            # Test Redis connection"
echo "   5. code lab7.md                       # Open lab instructions in VS Code"
echo "   6. Follow the lab instructions to complete all exercises"
echo ""
echo "📋 Key Exercise Areas:"
echo "   • Customer profile management with Redis hashes"
echo "   • Policy CRUD operations and lifecycle management"
echo "   • Risk scoring and premium calculations"
echo "   • Bulk operations and renewal processing"
echo "   • Integration testing and performance optimization"
echo "   • Production patterns for data integrity"
EOF
