# Lab 6: JavaScript Redis Client Setup

**Duration:** 45 minutes  
**Objective:** Establish Node.js Redis development environment and master basic JavaScript Redis operations

## 🎯 Learning Objectives

By the end of this lab, you will be able to:
- Set up Node.js Redis client for remote server connections
- Create connection management utilities for production applications
- Implement basic CRUD operations for customer and policy data in JavaScript
- Handle errors and connection testing for reliable applications
- Configure environment variables for development and production
- Execute Redis operations using both callback and promise patterns

---

## Part 1: Project Setup (10 minutes)

### Step 1: Initialize Node.js Project

Create a new Node.js project for Redis client development:

```bash
# Create project directory
mkdir redis-js-client
cd redis-js-client

# Initialize Node.js project
npm init -y

# Install Redis client and dependencies
npm install redis dotenv

# Install development dependencies
npm install --save-dev nodemon
```

### Step 2: Project Structure

Create the following directory structure:

```
redis-js-client/
├── package.json
├── .env                     # Environment configuration
├── src/
│   ├── config/
│   │   └── redis.js         # Redis connection configuration
│   ├── clients/
│   │   └── redisClient.js   # Redis client wrapper
│   ├── models/
│   │   ├── customer.js      # Customer data operations
│   │   └── policy.js        # Policy data operations
│   └── app.js               # Main application
├── examples/
│   └── basic-operations.js  # Example operations
└── tests/
    └── connection-test.js    # Connection testing
```

### Step 3: Environment Configuration

Create `.env` file with your Redis server details:

```bash
# .env file
REDIS_HOST=redis-server.training.com
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_DATABASE=0
NODE_ENV=development
```

**Note:** Replace with actual server details provided by instructor.

---

## Part 2: Redis Client Configuration (8 minutes)

### Step 1: Create Redis Configuration

Create `src/config/redis.js`:

```javascript
// src/config/redis.js
require('dotenv').config();

const redisConfig = {
    host: process.env.REDIS_HOST || 'localhost',
    port: parseInt(process.env.REDIS_PORT) || 6379,
    password: process.env.REDIS_PASSWORD || undefined,
    database: parseInt(process.env.REDIS_DATABASE) || 0,
    retryDelayOnFailover: 100,
    maxRetriesPerRequest: 3,
    lazyConnect: true,
    connectTimeout: 10000,
    commandTimeout: 5000
};

module.exports = redisConfig;
```

### Step 2: Create Redis Client Wrapper

Create `src/clients/redisClient.js`:

```javascript
// src/clients/redisClient.js
const redis = require('redis');
const redisConfig = require('../config/redis');

class RedisClient {
    constructor() {
        this.client = null;
        this.isConnected = false;
    }

    async connect() {
        try {
            // Create Redis client with configuration
            this.client = redis.createClient({
                socket: {
                    host: redisConfig.host,
                    port: redisConfig.port,
                    connectTimeout: redisConfig.connectTimeout
                },
                password: redisConfig.password,
                database: redisConfig.database
            });

            // Set up event handlers
            this.client.on('connect', () => {
                console.log('📡 Connecting to Redis server...');
            });

            this.client.on('ready', () => {
                console.log('✅ Redis client ready');
                this.isConnected = true;
            });

            this.client.on('error', (err) => {
                console.error('❌ Redis client error:', err.message);
                this.isConnected = false;
            });

            this.client.on('end', () => {
                console.log('🔌 Redis connection closed');
                this.isConnected = false;
            });

            // Connect to Redis
            await this.client.connect();
            
            // Test connection
            const pingResult = await this.client.ping();
            console.log('🏓 Redis ping result:', pingResult);

            return this.client;
        } catch (error) {
            console.error('💥 Failed to connect to Redis:', error.message);
            throw error;
        }
    }

    async disconnect() {
        if (this.client && this.isConnected) {
            await this.client.quit();
            console.log('👋 Disconnected from Redis');
        }
    }

    getClient() {
        if (!this.isConnected) {
            throw new Error('Redis client not connected. Call connect() first.');
        }
        return this.client;
    }

    async healthCheck() {
        try {
            if (!this.isConnected) {
                return { status: 'disconnected', message: 'Not connected to Redis' };
            }

            const start = Date.now();
            await this.client.ping();
            const latency = Date.now() - start;

            const info = await this.client.info('server');
            const serverInfo = {};
            info.split('\r\n').forEach(line => {
                const [key, value] = line.split(':');
                if (key && value) {
                    serverInfo[key] = value;
                }
            });

            return {
                status: 'connected',
                latency: `${latency}ms`,
                server: serverInfo.redis_version,
                uptime: serverInfo.uptime_in_seconds + ' seconds'
            };
        } catch (error) {
            return { status: 'error', message: error.message };
        }
    }
}

module.exports = RedisClient;
```

### Step 3: Test Connection

Create `tests/connection-test.js`:

```javascript
// tests/connection-test.js
const RedisClient = require('../src/clients/redisClient');

async function testConnection() {
    console.log('🧪 Testing Redis Connection...');
    console.log('================================');

    const redisClient = new RedisClient();

    try {
        // Test connection
        await redisClient.connect();
        
        // Test basic operations
        const client = redisClient.getClient();
        
        // Set and get test data
        await client.set('test:connection', 'success');
        const result = await client.get('test:connection');
        console.log('✅ Test data:', result);
        
        // Clean up test data
        await client.del('test:connection');
        
        // Health check
        const health = await redisClient.healthCheck();
        console.log('🏥 Health check:', health);
        
    } catch (error) {
        console.error('❌ Connection test failed:', error.message);
    } finally {
        await redisClient.disconnect();
    }
}

// Run test if this file is executed directly
if (require.main === module) {
    testConnection();
}

module.exports = testConnection;
```

---

## Part 3: Basic Data Operations (15 minutes)

### Step 1: Customer Data Model

Create `src/models/customer.js`:

```javascript
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
```

### Step 2: Policy Data Model

Create `src/models/policy.js`:

```javascript
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
```

### Step 3: Main Application

Create `src/app.js`:

```javascript
// src/app.js
const RedisClient = require('./clients/redisClient');
const Customer = require('./models/customer');
const Policy = require('./models/policy');

class App {
    constructor() {
        this.redisClient = new RedisClient();
        this.customer = null;
        this.policy = null;
    }

    async initialize() {
        try {
            console.log('🚀 Initializing application...');
            
            // Connect to Redis
            await this.redisClient.connect();
            
            // Initialize models
            this.customer = new Customer(this.redisClient);
            this.policy = new Policy(this.redisClient);
            
            console.log('✅ Application initialized successfully');
            
        } catch (error) {
            console.error('💥 Failed to initialize application:', error.message);
            throw error;
        }
    }

    async createSampleData() {
        console.log('📝 Creating sample data...');
        
        try {
            // Create sample customers
            await this.customer.create('CUST001', {
                name: 'John Smith',
                email: 'john.smith@email.com',
                phone: '555-0101',
                address: '123 Main St, Anytown, USA',
                dateOfBirth: '1980-05-15',
                riskScore: 'low'
            });

            await this.customer.create('CUST002', {
                name: 'Sarah Johnson',
                email: 'sarah.johnson@email.com',
                phone: '555-0102',
                address: '456 Oak Ave, Somewhere, USA',
                dateOfBirth: '1975-08-22',
                riskScore: 'medium'
            });

            // Create sample policies
            await this.policy.create('POL001', {
                customerId: 'CUST001',
                type: 'auto',
                coverage: 'Full Coverage',
                premium: 1200.00,
                deductible: 500.00,
                startDate: '2024-01-01',
                endDate: '2024-12-31',
                agent: 'Agent Smith'
            });

            await this.policy.create('POL002', {
                customerId: 'CUST001',
                type: 'home',
                coverage: 'Comprehensive',
                premium: 800.00,
                deductible: 1000.00,
                startDate: '2024-01-01',
                endDate: '2024-12-31',
                agent: 'Agent Smith'
            });

            await this.policy.create('POL003', {
                customerId: 'CUST002',
                type: 'auto',
                coverage: 'Basic Coverage',
                premium: 900.00,
                deductible: 750.00,
                startDate: '2024-02-01',
                endDate: '2025-01-31',
                agent: 'Agent Jones'
            });

            console.log('✅ Sample data created successfully');

        } catch (error) {
            console.error('❌ Error creating sample data:', error.message);
            throw error;
        }
    }

    async runExamples() {
        console.log('🎯 Running example operations...');
        console.log('================================');

        try {
            // Customer operations
            console.log('\n📋 Customer Operations:');
            const customer1 = await this.customer.get('CUST001');
            console.log('Customer CUST001:', customer1?.name);

            const customerCount = await this.customer.count();
            console.log('Total customers:', customerCount);

            // Policy operations
            console.log('\n📋 Policy Operations:');
            const policy1 = await this.policy.get('POL001');
            console.log('Policy POL001:', policy1?.type, '$' + policy1?.premium);

            const customerPolicies = await this.policy.getByCustomer('CUST001');
            console.log('CUST001 policies:', customerPolicies.length);

            const totalPremium = await this.policy.getTotalPremium('CUST001');
            console.log('CUST001 total premium: $' + totalPremium);

            // Update operations
            console.log('\n📋 Update Operations:');
            await this.customer.update('CUST001', { 
                phone: '555-9999',
                riskScore: 'medium'
            });

            await this.policy.updateStatus('POL003', 'pending');

            console.log('✅ All example operations completed');

        } catch (error) {
            console.error('❌ Error running examples:', error.message);
            throw error;
        }
    }

    async cleanup() {
        try {
            if (this.redisClient) {
                await this.redisClient.disconnect();
            }
        } catch (error) {
            console.error('Error during cleanup:', error.message);
        }
    }
}

// Main execution function
async function main() {
    const app = new App();
    
    try {
        await app.initialize();
        await app.createSampleData();
        await app.runExamples();
        
    } catch (error) {
        console.error('💥 Application error:', error.message);
    } finally {
        await app.cleanup();
    }
}

// Run if this file is executed directly
if (require.main === module) {
    main();
}

module.exports = App;
```

---

## Part 4: Testing and Examples (10 minutes)

### Step 1: Run Connection Test

Test your Redis connection:

```bash
# Run connection test
node tests/connection-test.js
```

Expected output:
```
🧪 Testing Redis Connection...
================================
📡 Connecting to Redis server...
✅ Redis client ready
🏓 Redis ping result: PONG
✅ Test data: success
🏥 Health check: { status: 'connected', latency: '5ms', server: '7.0.0', uptime: '12345 seconds' }
👋 Disconnected from Redis
```

### Step 2: Run Main Application

Execute the main application with sample data:

```bash
# Run main application
node src/app.js
```

### Step 3: Create Interactive Examples

Create `examples/basic-operations.js`:

```javascript
// examples/basic-operations.js
const RedisClient = require('../src/clients/redisClient');

async function interactiveExamples() {
    console.log('🎮 Interactive Redis Operations');
    console.log('==============================');

    const redisClient = new RedisClient();
    
    try {
        await redisClient.connect();
        const client = redisClient.getClient();

        // String operations
        console.log('\n🔤 String Operations:');
        await client.set('example:greeting', 'Hello Redis from JavaScript!');
        const greeting = await client.get('example:greeting');
        console.log('Greeting:', greeting);

        // Numeric operations
        console.log('\n🔢 Numeric Operations:');
        await client.set('example:counter', 0);
        await client.incr('example:counter');
        await client.incrBy('example:counter', 5);
        const counter = await client.get('example:counter');
        console.log('Counter value:', counter);

        // JSON operations
        console.log('\n📋 JSON Data Operations:');
        const sampleData = {
            name: 'Alice Brown',
            age: 30,
            policies: ['AUTO001', 'HOME001']
        };
        await client.set('example:customer', JSON.stringify(sampleData));
        const customerData = JSON.parse(await client.get('example:customer'));
        console.log('Customer data:', customerData);

        // Multiple operations
        console.log('\n🔄 Multiple Operations:');
        await client.mSet({
            'example:key1': 'value1',
            'example:key2': 'value2',
            'example:key3': 'value3'
        });
        const values = await client.mGet(['example:key1', 'example:key2', 'example:key3']);
        console.log('Multiple values:', values);

        // Expiration
        console.log('\n⏰ Expiration Operations:');
        await client.setEx('example:temp', 60, 'This expires in 60 seconds');
        const ttl = await client.ttl('example:temp');
        console.log('TTL for temp key:', ttl, 'seconds');

        // Cleanup
        console.log('\n🧹 Cleanup:');
        const keys = await client.keys('example:*');
        if (keys.length > 0) {
            await client.del(keys);
            console.log('Deleted', keys.length, 'example keys');
        }

    } catch (error) {
        console.error('❌ Error in examples:', error.message);
    } finally {
        await redisClient.disconnect();
    }
}

// Run examples
interactiveExamples();
```

### Step 4: Performance Testing

Create `examples/performance-test.js`:

```javascript
// examples/performance-test.js
const RedisClient = require('../src/clients/redisClient');

async function performanceTest() {
    console.log('⚡ Performance Testing');
    console.log('====================');

    const redisClient = new RedisClient();
    
    try {
        await redisClient.connect();
        const client = redisClient.getClient();

        // Test SET operations
        console.log('\n📊 SET Operations Test:');
        const setStart = Date.now();
        const setPromises = [];
        
        for (let i = 0; i < 100; i++) {
            setPromises.push(client.set(`perf:test:${i}`, `value${i}`));
        }
        
        await Promise.all(setPromises);
        const setDuration = Date.now() - setStart;
        console.log(`✅ 100 SET operations completed in ${setDuration}ms`);
        console.log(`📈 Average: ${(setDuration / 100).toFixed(2)}ms per operation`);

        // Test GET operations
        console.log('\n📊 GET Operations Test:');
        const getStart = Date.now();
        const getPromises = [];
        
        for (let i = 0; i < 100; i++) {
            getPromises.push(client.get(`perf:test:${i}`));
        }
        
        const results = await Promise.all(getPromises);
        const getDuration = Date.now() - getStart;
        console.log(`✅ 100 GET operations completed in ${getDuration}ms`);
        console.log(`📈 Average: ${(getDuration / 100).toFixed(2)}ms per operation`);
        console.log(`📋 Retrieved ${results.length} values`);

        // Cleanup
        const keys = await client.keys('perf:test:*');
        if (keys.length > 0) {
            await client.del(keys);
            console.log(`🧹 Cleaned up ${keys.length} test keys`);
        }

    } catch (error) {
        console.error('❌ Performance test error:', error.message);
    } finally {
        await redisClient.disconnect();
    }
}

performanceTest();
```

---

## Part 5: Redis Insight Integration (2 minutes)

### Step 1: View Data in Redis Insight

1. **Open Redis Insight** and connect to your server
2. **Navigate to Browser tab**
3. **Search for keys** created by your JavaScript application:
   - `customer:*` - Customer records
   - `policy:*` - Policy records
   - `customers:index` - Customer ID set
   - `policies:index` - Policy ID set

### Step 2: Execute JavaScript Operations via Workbench

1. **Go to Workbench tab** in Redis Insight
2. **Execute Redis commands** to see the data created by JavaScript:

```redis
# View customer data
GET customer:CUST001

# View policy data
GET policy:POL001

# View customer index
SMEMBERS customers:index

# View customer's policies
SMEMBERS customer:CUST001:policies

# Check key types
TYPE customer:CUST001
TYPE customers:index
```

---

## Lab Completion Checklist

- [ ] Successfully set up Node.js project with Redis client
- [ ] Created environment configuration for remote Redis server
- [ ] Implemented Redis client wrapper with connection management
- [ ] Built Customer and Policy data models with CRUD operations
- [ ] Created and retrieved customer and policy records using JavaScript
- [ ] Tested error handling and connection reliability
- [ ] Ran performance tests with multiple concurrent operations
- [ ] Integrated with Redis Insight for data visualization
- [ ] Understood JavaScript Redis client patterns and best practices

---

## Troubleshooting

### Connection Issues

**Problem:** Cannot connect to Redis server
```javascript
// Check environment variables
console.log('Redis Host:', process.env.REDIS_HOST);
console.log('Redis Port:', process.env.REDIS_PORT);

// Test with hardcoded values temporarily
const testClient = redis.createClient({
    socket: { host: 'your-redis-host', port: 6379 }
});
```

**Problem:** Authentication errors
```javascript
// Verify password in .env file
REDIS_PASSWORD=your_actual_password

// Test auth in Redis Insight first
```

### Node.js Issues

**Problem:** Module not found errors
```bash
# Reinstall dependencies
rm -rf node_modules package-lock.json
npm install

# Check Node.js version
node --version  # Should be 16+ 
```

**Problem:** Promise/async errors
```javascript
// Always use try/catch with async operations
try {
    const result = await client.get('key');
} catch (error) {
    console.error('Redis operation failed:', error);
}
```

---

## Key Takeaways

🎉 **Congratulations!** You've completed Lab 6. You should now:

1. **Understand JavaScript Redis integration** - Node.js client setup and configuration
2. **Master connection management** - Environment config, error handling, health checks
3. **Build data models** - Customer and policy CRUD operations in JavaScript
4. **Handle asynchronous operations** - Promises, async/await patterns
5. **Integrate with tools** - Redis Insight for data visualization and debugging

**Next Lab Preview:** Lab 7 will focus on advanced data structures using Hashes for complex customer profiles and policy management.

---

## Quick Reference

### Essential JavaScript Redis Patterns

**Connection:**
```javascript
const client = redis.createClient({
    socket: { host: 'hostname', port: 6379 },
    password: 'password'
});
await client.connect();
```

**Basic Operations:**
```javascript
await client.set('key', 'value');          // Store
const value = await client.get('key');     // Retrieve
await client.del('key');                   // Delete
const exists = await client.exists('key'); // Check existence
```

**JSON Data:**
```javascript
await client.set('user', JSON.stringify(userData));
const user = JSON.parse(await client.get('user'));
```

**Error Handling:**
```javascript
try {
    const result = await client.operation();
} catch (error) {
    console.error('Redis error:', error.message);
}
```
