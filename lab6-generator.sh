#!/bin/bash

# Lab 6 Content Generator Script
# Generates complete content and code for Lab 6: JavaScript Redis Client for Business Systems
# Duration: 45 minutes
# Focus: First JavaScript integration, Node.js setup, redis client, basic operations

set -e

LAB_DIR="lab6-javascript-redis-client"
LAB_NUMBER="6"
LAB_TITLE="JavaScript Redis Client for Business Systems"
LAB_DURATION="45"

echo "🚀 Generating Lab ${LAB_NUMBER}: ${LAB_TITLE}"
echo "📅 Duration: ${LAB_DURATION} minutes"
echo "🎯 Focus: JavaScript Redis client setup, connection management, and basic operations"
echo ""

# Create lab directory structure
mkdir -p ${LAB_DIR}
cd ${LAB_DIR}

echo "📁 Creating lab directory structure..."
mkdir -p {scripts,docs,examples,src,test,config}

# Create main lab instructions markdown file
echo "📋 Creating lab6.md..."
cat > lab6.md << 'EOF'
# Lab 6: JavaScript Redis Client for Business Systems

**Duration:** 45 minutes  
**Objective:** Master JavaScript Redis client setup, connection management, and fundamental operations for business applications

## 🎯 Learning Objectives

By the end of this lab, you will be able to:
- Set up Node.js environment with Redis client for business applications
- Establish and manage Redis connections from JavaScript
- Implement basic CRUD operations for business entities
- Handle connection errors and implement retry logic
- Build promise-based and async/await patterns for Redis operations
- Monitor JavaScript client performance and connection pooling

---

## Part 1: JavaScript Environment Setup (15 minutes)

### Step 1: Initialize Node.js Project for Business Applications

```bash
# Create project directory
mkdir business-redis-app
cd business-redis-app

# Initialize Node.js project
npm init -y

# Install Redis client and development dependencies
npm install redis dotenv
npm install --save-dev nodemon jest

# Create project structure
mkdir -p src/{controllers,services,utils,config}
mkdir -p test/{unit,integration}
```

### Step 2: Configure Redis Connection

Create `src/config/redis.config.js`:
```javascript
const redis = require('redis');

// Redis connection configuration for business applications
const redisConfig = {
  socket: {
    host: process.env.REDIS_HOST || 'localhost',
    port: process.env.REDIS_PORT || 6379,
    reconnectStrategy: (retries) => {
      if (retries > 10) {
        console.error('Redis: Max reconnection attempts reached');
        return new Error('Max reconnection attempts reached');
      }
      const delay = Math.min(retries * 100, 3000);
      console.log(`Redis: Reconnecting in ${delay}ms (attempt ${retries})`);
      return delay;
    }
  },
  // Connection pool settings for high-volume business operations
  commandsQueueMaxLength: 100,
  disableOfflineQueue: false,
  
  // Business application specific settings
  legacyMode: false,
  name: 'business-app',
  
  // Error handling
  retryStrategy: (times) => {
    const delay = Math.min(times * 50, 2000);
    return delay;
  }
};

module.exports = redisConfig;
```

### Step 3: Create Redis Client Manager

Create `src/utils/redisClient.js`:
```javascript
const redis = require('redis');
const redisConfig = require('../config/redis.config');

class RedisClientManager {
  constructor() {
    this.client = null;
    this.isConnected = false;
  }

  async connect() {
    try {
      this.client = redis.createClient(redisConfig);
      
      // Event handlers for connection lifecycle
      this.client.on('connect', () => {
        console.log('Redis: Connection established');
      });
      
      this.client.on('ready', () => {
        console.log('Redis: Client ready for operations');
        this.isConnected = true;
      });
      
      this.client.on('error', (err) => {
        console.error('Redis Error:', err);
        this.isConnected = false;
      });
      
      this.client.on('end', () => {
        console.log('Redis: Connection closed');
        this.isConnected = false;
      });
      
      // Connect to Redis
      await this.client.connect();
      
      // Test connection
      await this.client.ping();
      console.log('Redis: Connection test successful');
      
      return this.client;
    } catch (error) {
      console.error('Redis: Failed to connect:', error);
      throw error;
    }
  }
  
  async disconnect() {
    if (this.client) {
      await this.client.quit();
      this.client = null;
      this.isConnected = false;
      console.log('Redis: Disconnected successfully');
    }
  }
  
  getClient() {
    if (!this.isConnected) {
      throw new Error('Redis client not connected');
    }
    return this.client;
  }
}

// Export singleton instance
module.exports = new RedisClientManager();
```

---

## Part 2: Basic Business Operations with JavaScript (15 minutes)

### Step 1: Customer Data Service

Create `src/services/customerService.js`:
```javascript
const redisClient = require('../utils/redisClient');

class CustomerService {
  constructor() {
    this.keyPrefix = 'customer:';
  }
  
  // Create or update customer
  async saveCustomer(customerId, customerData) {
    try {
      const client = redisClient.getClient();
      const key = `${this.keyPrefix}${customerId}`;
      
      // Store customer as JSON string
      const result = await client.set(
        key, 
        JSON.stringify(customerData),
        {
          EX: 3600 // 1 hour TTL for demo purposes
        }
      );
      
      console.log(`Customer ${customerId} saved successfully`);
      return result;
    } catch (error) {
      console.error('Error saving customer:', error);
      throw error;
    }
  }
  
  // Retrieve customer
  async getCustomer(customerId) {
    try {
      const client = redisClient.getClient();
      const key = `${this.keyPrefix}${customerId}`;
      
      const data = await client.get(key);
      
      if (!data) {
        console.log(`Customer ${customerId} not found`);
        return null;
      }
      
      return JSON.parse(data);
    } catch (error) {
      console.error('Error retrieving customer:', error);
      throw error;
    }
  }
  
  // Delete customer
  async deleteCustomer(customerId) {
    try {
      const client = redisClient.getClient();
      const key = `${this.keyPrefix}${customerId}`;
      
      const result = await client.del(key);
      
      if (result === 1) {
        console.log(`Customer ${customerId} deleted successfully`);
        return true;
      } else {
        console.log(`Customer ${customerId} not found`);
        return false;
      }
    } catch (error) {
      console.error('Error deleting customer:', error);
      throw error;
    }
  }
  
  // Check if customer exists
  async customerExists(customerId) {
    try {
      const client = redisClient.getClient();
      const key = `${this.keyPrefix}${customerId}`;
      
      const exists = await client.exists(key);
      return exists === 1;
    } catch (error) {
      console.error('Error checking customer existence:', error);
      throw error;
    }
  }
  
  // Get all customer IDs
  async getAllCustomerIds() {
    try {
      const client = redisClient.getClient();
      const pattern = `${this.keyPrefix}*`;
      
      const keys = await client.keys(pattern);
      
      // Extract customer IDs from keys
      return keys.map(key => key.replace(this.keyPrefix, ''));
    } catch (error) {
      console.error('Error retrieving customer IDs:', error);
      throw error;
    }
  }
  
  // Batch operations for multiple customers
  async saveMultipleCustomers(customers) {
    try {
      const client = redisClient.getClient();
      const multi = client.multi();
      
      customers.forEach(({ id, data }) => {
        const key = `${this.keyPrefix}${id}`;
        multi.set(key, JSON.stringify(data), 'EX', 3600);
      });
      
      const results = await multi.exec();
      console.log(`Saved ${customers.length} customers in batch`);
      return results;
    } catch (error) {
      console.error('Error in batch save:', error);
      throw error;
    }
  }
}

module.exports = new CustomerService();
```

### Step 2: Product Inventory Service

Create `src/services/inventoryService.js`:
```javascript
const redisClient = require('../utils/redisClient');

class InventoryService {
  constructor() {
    this.keyPrefix = 'inventory:';
  }
  
  // Atomic increment for stock levels
  async addStock(productId, quantity) {
    try {
      const client = redisClient.getClient();
      const key = `${this.keyPrefix}${productId}:stock`;
      
      const newStock = await client.incrBy(key, quantity);
      console.log(`Product ${productId} stock increased by ${quantity}. New stock: ${newStock}`);
      return newStock;
    } catch (error) {
      console.error('Error adding stock:', error);
      throw error;
    }
  }
  
  // Atomic decrement with validation
  async removeStock(productId, quantity) {
    try {
      const client = redisClient.getClient();
      const key = `${this.keyPrefix}${productId}:stock`;
      
      // Get current stock
      const currentStock = await client.get(key);
      
      if (!currentStock || parseInt(currentStock) < quantity) {
        throw new Error(`Insufficient stock for product ${productId}`);
      }
      
      const newStock = await client.decrBy(key, quantity);
      console.log(`Product ${productId} stock decreased by ${quantity}. New stock: ${newStock}`);
      return newStock;
    } catch (error) {
      console.error('Error removing stock:', error);
      throw error;
    }
  }
  
  // Get current stock level
  async getStock(productId) {
    try {
      const client = redisClient.getClient();
      const key = `${this.keyPrefix}${productId}:stock`;
      
      const stock = await client.get(key);
      return stock ? parseInt(stock) : 0;
    } catch (error) {
      console.error('Error getting stock:', error);
      throw error;
    }
  }
  
  // Set stock level
  async setStock(productId, quantity) {
    try {
      const client = redisClient.getClient();
      const key = `${this.keyPrefix}${productId}:stock`;
      
      await client.set(key, quantity);
      console.log(`Product ${productId} stock set to ${quantity}`);
      return quantity;
    } catch (error) {
      console.error('Error setting stock:', error);
      throw error;
    }
  }
  
  // Get low stock products
  async getLowStockProducts(threshold = 10) {
    try {
      const client = redisClient.getClient();
      const pattern = `${this.keyPrefix}*:stock`;
      
      const keys = await client.keys(pattern);
      const lowStockProducts = [];
      
      for (const key of keys) {
        const stock = await client.get(key);
        if (parseInt(stock) < threshold) {
          const productId = key.replace(this.keyPrefix, '').replace(':stock', '');
          lowStockProducts.push({
            productId,
            stock: parseInt(stock)
          });
        }
      }
      
      return lowStockProducts;
    } catch (error) {
      console.error('Error finding low stock products:', error);
      throw error;
    }
  }
}

module.exports = new InventoryService();
```

---

## Part 3: Testing and Monitoring (15 minutes)

### Step 1: Create Test Application

Create `src/app.js`:
```javascript
const redisClient = require('./utils/redisClient');
const customerService = require('./services/customerService');
const inventoryService = require('./services/inventoryService');

// Sample data for testing
const sampleCustomers = [
  {
    id: 'CUST001',
    data: {
      name: 'John Smith',
      email: 'john.smith@example.com',
      tier: 'premium',
      accountBalance: 5000
    }
  },
  {
    id: 'CUST002',
    data: {
      name: 'Jane Doe',
      email: 'jane.doe@example.com',
      tier: 'standard',
      accountBalance: 2500
    }
  },
  {
    id: 'CUST003',
    data: {
      name: 'Bob Johnson',
      email: 'bob.johnson@example.com',
      tier: 'premium',
      accountBalance: 7500
    }
  }
];

const sampleProducts = [
  { id: 'PROD001', initialStock: 100 },
  { id: 'PROD002', initialStock: 50 },
  { id: 'PROD003', initialStock: 5 },
  { id: 'PROD004', initialStock: 200 }
];

async function runCustomerOperations() {
  console.log('\n=== Customer Operations ===\n');
  
  // Save single customer
  await customerService.saveCustomer(
    sampleCustomers[0].id,
    sampleCustomers[0].data
  );
  
  // Retrieve customer
  const customer = await customerService.getCustomer('CUST001');
  console.log('Retrieved customer:', customer);
  
  // Check existence
  const exists = await customerService.customerExists('CUST001');
  console.log('Customer CUST001 exists:', exists);
  
  // Batch save
  await customerService.saveMultipleCustomers(sampleCustomers);
  
  // Get all customer IDs
  const allIds = await customerService.getAllCustomerIds();
  console.log('All customer IDs:', allIds);
  
  // Delete customer
  await customerService.deleteCustomer('CUST003');
}

async function runInventoryOperations() {
  console.log('\n=== Inventory Operations ===\n');
  
  // Initialize stock levels
  for (const product of sampleProducts) {
    await inventoryService.setStock(product.id, product.initialStock);
  }
  
  // Add stock
  await inventoryService.addStock('PROD001', 20);
  
  // Remove stock
  await inventoryService.removeStock('PROD002', 10);
  
  // Get stock level
  const stock = await inventoryService.getStock('PROD001');
  console.log('PROD001 current stock:', stock);
  
  // Find low stock products
  const lowStock = await inventoryService.getLowStockProducts(20);
  console.log('Low stock products:', lowStock);
  
  // Test insufficient stock error
  try {
    await inventoryService.removeStock('PROD003', 100);
  } catch (error) {
    console.log('Expected error:', error.message);
  }
}

async function monitorPerformance() {
  console.log('\n=== Performance Monitoring ===\n');
  
  const client = redisClient.getClient();
  
  // Measure latency of operations
  const iterations = 1000;
  const startTime = Date.now();
  
  for (let i = 0; i < iterations; i++) {
    await client.set(`perf:test:${i}`, `value${i}`);
  }
  
  const endTime = Date.now();
  const duration = endTime - startTime;
  const opsPerSecond = (iterations / (duration / 1000)).toFixed(2);
  
  console.log(`Completed ${iterations} SET operations in ${duration}ms`);
  console.log(`Performance: ${opsPerSecond} ops/second`);
  
  // Clean up test keys
  const testKeys = await client.keys('perf:test:*');
  if (testKeys.length > 0) {
    await client.del(testKeys);
    console.log(`Cleaned up ${testKeys.length} test keys`);
  }
  
  // Get Redis info
  const info = await client.info('stats');
  console.log('\nRedis Statistics:', info);
}

async function main() {
  try {
    // Connect to Redis
    await redisClient.connect();
    
    // Run operations
    await runCustomerOperations();
    await runInventoryOperations();
    await monitorPerformance();
    
    // Monitor Redis Insight
    console.log('\n=== Redis Insight ===\n');
    console.log('Open Redis Insight at http://localhost:8001');
    console.log('Connect to localhost:6379 to view:');
    console.log('- Key browser with customer and inventory data');
    console.log('- Real-time command monitoring');
    console.log('- Memory analysis and profiler');
    console.log('- Slow log analysis');
    
  } catch (error) {
    console.error('Application error:', error);
  } finally {
    // Disconnect from Redis
    await redisClient.disconnect();
  }
}

// Run the application
main();
```

### Step 2: Create Integration Tests

Create `test/integration/redis.test.js`:
```javascript
const redisClient = require('../../src/utils/redisClient');
const customerService = require('../../src/services/customerService');
const inventoryService = require('../../src/services/inventoryService');

describe('Redis Integration Tests', () => {
  beforeAll(async () => {
    await redisClient.connect();
  });
  
  afterAll(async () => {
    // Clean up test data
    const client = redisClient.getClient();
    const testKeys = await client.keys('test:*');
    if (testKeys.length > 0) {
      await client.del(testKeys);
    }
    await redisClient.disconnect();
  });
  
  describe('Customer Service', () => {
    test('should save and retrieve customer', async () => {
      const customerId = 'test:customer:001';
      const customerData = {
        name: 'Test User',
        email: 'test@example.com'
      };
      
      await customerService.saveCustomer(customerId, customerData);
      const retrieved = await customerService.getCustomer(customerId);
      
      expect(retrieved).toEqual(customerData);
    });
    
    test('should return null for non-existent customer', async () => {
      const result = await customerService.getCustomer('non-existent');
      expect(result).toBeNull();
    });
    
    test('should delete customer successfully', async () => {
      const customerId = 'test:customer:delete';
      await customerService.saveCustomer(customerId, { name: 'Delete Me' });
      
      const deleted = await customerService.deleteCustomer(customerId);
      expect(deleted).toBe(true);
      
      const exists = await customerService.customerExists(customerId);
      expect(exists).toBe(false);
    });
  });
  
  describe('Inventory Service', () => {
    test('should manage stock levels correctly', async () => {
      const productId = 'test:product:001';
      
      await inventoryService.setStock(productId, 100);
      let stock = await inventoryService.getStock(productId);
      expect(stock).toBe(100);
      
      await inventoryService.addStock(productId, 50);
      stock = await inventoryService.getStock(productId);
      expect(stock).toBe(150);
      
      await inventoryService.removeStock(productId, 30);
      stock = await inventoryService.getStock(productId);
      expect(stock).toBe(120);
    });
    
    test('should throw error for insufficient stock', async () => {
      const productId = 'test:product:002';
      await inventoryService.setStock(productId, 10);
      
      await expect(
        inventoryService.removeStock(productId, 20)
      ).rejects.toThrow('Insufficient stock');
    });
  });
});
```

### Step 3: Create Performance Monitoring Script

Create `scripts/monitor-performance.js`:
```javascript
const redis = require('redis');

async function monitorRedisPerformance() {
  const client = redis.createClient({
    socket: { host: 'localhost', port: 6379 }
  });
  
  await client.connect();
  
  console.log('Redis Performance Monitor');
  console.log('=========================\n');
  
  // Monitor different operation types
  const operations = [
    { name: 'SET', command: async (key, value) => client.set(key, value) },
    { name: 'GET', command: async (key) => client.get(key) },
    { name: 'INCR', command: async (key) => client.incr(key) },
    { name: 'HSET', command: async (key, field, value) => client.hSet(key, field, value) },
    { name: 'HGET', command: async (key, field) => client.hGet(key, field) }
  ];
  
  for (const op of operations) {
    const iterations = 10000;
    const startTime = process.hrtime.bigint();
    
    for (let i = 0; i < iterations; i++) {
      if (op.name === 'SET') {
        await op.command(`bench:${i}`, `value${i}`);
      } else if (op.name === 'GET') {
        await op.command(`bench:${i % 100}`);
      } else if (op.name === 'INCR') {
        await op.command('bench:counter');
      } else if (op.name === 'HSET') {
        await op.command('bench:hash', `field${i}`, `value${i}`);
      } else if (op.name === 'HGET') {
        await op.command('bench:hash', `field${i % 100}`);
      }
    }
    
    const endTime = process.hrtime.bigint();
    const duration = Number(endTime - startTime) / 1000000; // Convert to milliseconds
    const opsPerSecond = (iterations / (duration / 1000)).toFixed(0);
    
    console.log(`${op.name.padEnd(6)} - ${iterations} ops in ${duration.toFixed(2)}ms (${opsPerSecond} ops/sec)`);
  }
  
  // Clean up benchmark keys
  const benchKeys = await client.keys('bench:*');
  if (benchKeys.length > 0) {
    await client.del(benchKeys);
  }
  
  // Display connection info
  console.log('\nConnection Statistics:');
  const clientList = await client.clientList();
  console.log(`Active connections: ${clientList.split('\n').length}`);
  
  const info = await client.info('clients');
  console.log(info);
  
  await client.quit();
}

// Run the monitor
monitorRedisPerformance().catch(console.error);
```

---

## Summary & Key Takeaways

### What You've Learned
✅ Set up Node.js environment with Redis client for business applications  
✅ Implemented connection management with retry logic and error handling  
✅ Built service layers for customer and inventory management  
✅ Created promise-based and async/await patterns for Redis operations  
✅ Implemented batch operations for improved performance  
✅ Developed integration tests for Redis operations  
✅ Monitored performance and connection statistics  

### Best Practices Applied
- **Connection Management**: Singleton pattern for Redis client
- **Error Handling**: Comprehensive try-catch blocks with meaningful logs
- **Service Layer**: Separation of concerns with dedicated services
- **Testing**: Integration tests for critical operations
- **Performance**: Batch operations and connection pooling
- **Monitoring**: Performance metrics and connection tracking

### Next Steps
- Implement advanced data structures (Hashes, Lists, Sets)
- Add connection pooling for high-concurrency scenarios
- Implement caching strategies with TTL management
- Build pub/sub patterns for real-time updates
- Add transaction support for complex operations

---

## Appendix: Troubleshooting

### Common Issues and Solutions

1. **Connection Refused Error**
```bash
# Check if Redis is running
docker ps | grep redis

# Start Redis if not running
docker run -d --name redis-lab -p 6379:6379 redis:7-alpine
```

2. **Module Not Found Error**
```bash
# Ensure dependencies are installed
npm install redis dotenv
npm install --save-dev nodemon jest
```

3. **Async/Await Issues**
```javascript
// Always use try-catch with async operations
try {
  const result = await redisOperation();
} catch (error) {
  console.error('Operation failed:', error);
}
```

4. **Memory Issues with Large Datasets**
```javascript
// Use streams for large datasets
const stream = client.scanStream({
  match: 'pattern:*',
  count: 100
});

stream.on('data', (keys) => {
  // Process batch of keys
});
```

5. **Connection Pool Exhaustion**
```javascript
// Configure appropriate pool size
const client = redis.createClient({
  socket: {
    host: 'localhost',
    port: 6379
  },
  poolSize: 50 // Adjust based on load
});
```

## Useful Commands for Debugging

```bash
# Monitor Redis commands in real-time
redis-cli monitor

# Check Redis memory usage
redis-cli INFO memory

# View slow queries
redis-cli SLOWLOG GET 10

# Check client connections
redis-cli CLIENT LIST
```
EOF

# Create package.json
echo "📦 Creating package.json..."
cat > package.json << 'EOF'
{
  "name": "business-redis-app",
  "version": "1.0.0",
  "description": "JavaScript Redis client for business applications",
  "main": "src/app.js",
  "scripts": {
    "start": "node src/app.js",
    "dev": "nodemon src/app.js",
    "test": "jest",
    "test:watch": "jest --watch",
    "monitor": "node scripts/monitor-performance.js"
  },
  "keywords": ["redis", "nodejs", "business", "database"],
  "author": "",
  "license": "MIT",
  "dependencies": {
    "redis": "^4.6.0",
    "dotenv": "^16.0.0"
  },
  "devDependencies": {
    "nodemon": "^3.0.0",
    "jest": "^29.0.0"
  },
  "jest": {
    "testEnvironment": "node",
    "coverageDirectory": "coverage",
    "collectCoverageFrom": [
      "src/**/*.js"
    ]
  }
}
EOF

# Create .env template
echo "🔐 Creating .env.example..."
cat > .env.example << 'EOF'
# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379
# REDIS_PASSWORD=your_password_here

# Application Configuration
NODE_ENV=development
LOG_LEVEL=info
EOF

# Create load sample data script
echo "📊 Creating scripts/load-sample-data.sh..."
mkdir -p scripts
cat > scripts/load-sample-data.sh << 'EOF'
#!/bin/bash

echo "🚀 Loading JavaScript Lab Sample Data..."
echo "====================================="

# Connect to Redis and load business data
redis-cli << 'REDIS_EOF'

# Clear any existing lab data
DEL customer:CUST001 customer:CUST002 customer:CUST003
DEL inventory:PROD001:stock inventory:PROD002:stock inventory:PROD003:stock inventory:PROD004:stock

# Sample customer data
SET customer:CUST001 '{"name":"John Smith","email":"john.smith@example.com","tier":"premium","accountBalance":5000}' EX 3600
SET customer:CUST002 '{"name":"Jane Doe","email":"jane.doe@example.com","tier":"standard","accountBalance":2500}' EX 3600
SET customer:CUST003 '{"name":"Bob Johnson","email":"bob.johnson@example.com","tier":"premium","accountBalance":7500}' EX 3600

# Sample inventory data
SET inventory:PROD001:stock 100
SET inventory:PROD002:stock 50
SET inventory:PROD003:stock 5
SET inventory:PROD004:stock 200

# Sample product details (using hashes)
HSET product:PROD001 name "Widget A" price 29.99 category "electronics"
HSET product:PROD002 name "Gadget B" price 49.99 category "electronics"
HSET product:PROD003 name "Tool C" price 19.99 category "hardware"
HSET product:PROD004 name "Device D" price 99.99 category "electronics"

# Sample order queue (using lists)
LPUSH orders:pending '{"orderId":"ORD001","customerId":"CUST001","total":149.95}'
LPUSH orders:pending '{"orderId":"ORD002","customerId":"CUST002","total":79.99}'
LPUSH orders:pending '{"orderId":"ORD003","customerId":"CUST003","total":229.95}'

# Sample metrics (using sorted sets)
ZADD sales:daily:20240818 150.00 "PROD001"
ZADD sales:daily:20240818 200.00 "PROD002"
ZADD sales:daily:20240818 75.00 "PROD003"
ZADD sales:daily:20240818 500.00 "PROD004"

echo "Sample data loaded successfully!"
echo ""
echo "Data Summary:"
echo "============="
echo "Customers: 3"
KEYS customer:*
echo ""
echo "Products: 4"
KEYS product:*
echo ""
echo "Inventory: 4 items"
KEYS inventory:*
echo ""
echo "Pending Orders: 3"
LLEN orders:pending
echo ""
echo "Database Size:"
DBSIZE

REDIS_EOF

echo ""
echo "✅ JavaScript lab data loaded successfully!"
EOF

chmod +x scripts/load-sample-data.sh

# Create README
echo "📚 Creating README.md..."
cat > README.md << 'EOF'
# Lab 6: JavaScript Redis Client for Business Systems

**Duration:** 45 minutes  
**Focus:** JavaScript Redis client setup, connection management, and fundamental operations  
**Language:** JavaScript (Node.js)

## 📁 Project Structure

```
lab6-javascript-redis-client/
├── lab6.md                              # Complete lab instructions (START HERE)
├── package.json                         # Node.js project configuration
├── .env.example                         # Environment variables template
├── src/
│   ├── app.js                          # Main application entry point
│   ├── config/
│   │   └── redis.config.js            # Redis connection configuration
│   ├── utils/
│   │   └── redisClient.js             # Redis client manager
│   └── services/
│       ├── customerService.js         # Customer data operations
│       └── inventoryService.js        # Inventory management operations
├── test/
│   └── integration/
│       └── redis.test.js              # Integration tests
├── scripts/
│   ├── load-sample-data.sh            # Sample data loader
│   └── monitor-performance.js         # Performance monitoring script
├── docs/
│   └── troubleshooting.md             # Troubleshooting guide
└── README.md                           # This file
```

## 🚀 Quick Start

1. **Read Instructions:** Open `lab6.md` for complete lab guidance
2. **Start Redis:** `docker run -d --name redis-lab -p 6379:6379 redis:7-alpine`
3. **Install Dependencies:** `npm install`
4. **Load Sample Data:** `./scripts/load-sample-data.sh`
5. **Run Application:** `npm start`
6. **Run Tests:** `npm test`
7. **Monitor Performance:** `npm run monitor`

## 🎯 Lab Objectives

✅ Set up Node.js environment with Redis client  
✅ Establish and manage Redis connections from JavaScript  
✅ Implement basic CRUD operations for business entities  
✅ Handle connection errors and implement retry logic  
✅ Build promise-based and async/await patterns  
✅ Monitor JavaScript client performance  

## 🔧 Key JavaScript Patterns Covered

### Connection Management
```javascript
const client = redis.createClient({
  socket: { host: 'localhost', port: 6379 },
  reconnectStrategy: (retries) => Math.min(retries * 100, 3000)
});
```

### Async/Await Operations
```javascript
async function saveCustomer(id, data) {
  await client.set(`customer:${id}`, JSON.stringify(data));
}
```

### Error Handling
```javascript
try {
  const result = await client.get(key);
} catch (error) {
  console.error('Redis operation failed:', error);
}
```

### Batch Operations
```javascript
const multi = client.multi();
customers.forEach(c => multi.set(c.key, c.value));
await multi.exec();
```

## 📝 Available Scripts

- `npm start` - Run the main application
- `npm run dev` - Run with nodemon for development
- `npm test` - Run integration tests
- `npm run monitor` - Run performance monitoring

## 🆘 Troubleshooting

**Connection Issues:**
```bash
# Check Redis status
docker ps | grep redis
redis-cli ping

# Restart if needed
docker restart redis-lab
```

**Module Issues:**
```bash
# Clear node_modules and reinstall
rm -rf node_modules package-lock.json
npm install
```

**Async Issues:**
- Always use try-catch with async/await
- Ensure proper connection before operations
- Handle promise rejections

## 🎓 Learning Path

This lab is part of the Redis JavaScript series:

1. **Lab 1-5:** CLI and fundamentals
2. **Lab 6:** JavaScript Redis Client ← *You are here*
3. **Lab 7:** Customer Profiles & Policy Management
4. **Lab 8:** Claims Processing Queues
5. **Lab 9:** Analytics with Sets

---

**Ready to start?** Open `lab6.md` and begin building JavaScript Redis applications! 🚀
EOF

# Create troubleshooting guide
echo "🔧 Creating docs/troubleshooting.md..."
cat > docs/troubleshooting.md << 'EOF'
# Lab 6 Troubleshooting Guide

## Common Issues and Solutions

### 1. Redis Connection Failed

**Problem:** `Error: connect ECONNREFUSED 127.0.0.1:6379`

**Solutions:**
```bash
# Check if Redis is running
docker ps | grep redis

# Start Redis container if not running
docker run -d --name redis-lab -p 6379:6379 redis:7-alpine

# Check Redis logs
docker logs redis-lab
```

### 2. Module Not Found Error

**Problem:** `Cannot find module 'redis'`

**Solutions:**
```bash
# Install dependencies
npm install

# If issues persist, clear cache
npm cache clean --force
rm -rf node_modules package-lock.json
npm install
```

### 3. Async/Await Not Working

**Problem:** `SyntaxError: await is only valid in async functions`

**Solution:**
```javascript
// Ensure function is marked as async
async function myFunction() {
  const result = await redisOperation();
  return result;
}

// Or use .then() for promises
redisOperation().then(result => {
  console.log(result);
});
```

### 4. Connection Pool Issues

**Problem:** Too many connections or connection timeout

**Solutions:**
```javascript
// Configure connection pool
const client = redis.createClient({
  socket: {
    host: 'localhost',
    port: 6379,
    connectTimeout: 10000
  },
  commandsQueueMaxLength: 100
});

// Always close connections when done
await client.quit();
```

### 5. Memory Issues with Large Datasets

**Problem:** JavaScript heap out of memory

**Solutions:**
```bash
# Increase Node.js memory limit
node --max-old-space-size=4096 src/app.js

# Use streaming for large operations
const stream = client.scanStream({
  match: 'pattern:*',
  count: 100
});
```

### 6. Test Failures

**Problem:** Integration tests failing

**Solutions:**
```bash
# Ensure Redis is clean
redis-cli FLUSHALL

# Run tests with verbose output
npm test -- --verbose

# Run specific test file
npm test -- redis.test.js
```

## Performance Debugging

### Check Redis Performance
```bash
# Monitor commands in real-time
redis-cli monitor

# Check slow queries
redis-cli SLOWLOG GET 10

# View memory usage
redis-cli INFO memory
```

### JavaScript Profiling
```javascript
// Add timing to operations
console.time('redis-operation');
await client.set('key', 'value');
console.timeEnd('redis-operation');

// Use performance hooks
const { performance } = require('perf_hooks');
const start = performance.now();
// ... operation ...
const duration = performance.now() - start;
```

### Connection Monitoring
```javascript
// Log connection events
client.on('connect', () => console.log('Connected'));
client.on('ready', () => console.log('Ready'));
client.on('error', (err) => console.error('Error:', err));
client.on('reconnecting', () => console.log('Reconnecting'));
```

## Getting Help

If issues persist:

1. **Check Redis logs:** `docker logs redis-lab`
2. **Verify Node version:** `node --version` (should be 14+)
3. **Review error stack trace** for specific line numbers
4. **Test with redis-cli** to isolate JavaScript issues
5. **Ask instructor** for assistance

## Useful Commands

```bash
# Complete environment check
node --version
npm --version
redis-cli ping
docker ps

# Clean environment
docker stop redis-lab
docker rm redis-lab
rm -rf node_modules
npm cache clean --force

# Fresh start
docker run -d --name redis-lab -p 6379:6379 redis:7-alpine
npm install
npm start
```
EOF

# Create .gitignore
cat > .gitignore << 'EOF'
# Dependencies
node_modules/
package-lock.json

# Environment
.env
.env.local

# Logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Testing
coverage/
.nyc_output/

# IDE
.vscode/
.idea/
*.swp
*.swo
.DS_Store

# Build
dist/
build/

# Temporary
*.tmp
*.temp
temp/
tmp/
EOF

echo ""
echo "📂 Project structure created:"
echo "   ${LAB_DIR}/"
echo "   ├── lab6.md                              📋 START HERE - Complete lab guide"
echo "   ├── package.json                         📦 Node.js project configuration"
echo "   ├── src/"
echo "   │   ├── app.js                          🚀 Main application"
echo "   │   ├── config/redis.config.js          ⚙️  Redis configuration"
echo "   │   ├── utils/redisClient.js            🔌 Connection manager"
echo "   │   └── services/                       📊 Business services"
echo "   ├── test/                                🧪 Integration tests"
echo "   ├── scripts/                             📜 Utility scripts"
echo "   ├── docs/troubleshooting.md             🔧 Troubleshooting guide"
echo "   ├── README.md                            📖 Project documentation"
echo "   └── .gitignore                           🚫 Git ignore rules"
echo ""
echo "🎯 NEXT STEPS:"
echo "   1. cd ${LAB_DIR}"
echo "   2. code .                                # Open in VS Code"
echo "   3. Read lab6.md                         # Follow complete lab guide"
echo "   4. docker run -d --name redis-lab -p 6379:6379 redis:7-alpine"
echo "   5. npm install                          # Install dependencies"
echo "   6. ./scripts/load-sample-data.sh       # Load sample data"
echo "   7. npm start                            # Run application"
echo ""
echo "💻 JAVASCRIPT FOCUS:"
echo "   📊 Customer Service: CRUD operations with JSON"
echo "   📦 Inventory Service: Atomic stock management"
echo "   🔄 Async/Await: Modern JavaScript patterns"
echo "   🧪 Testing: Jest integration tests"
echo "   📈 Monitoring: Performance benchmarking"
echo "   🔌 Connection: Retry logic and error handling"
echo ""
echo "📋 Key Exercise Areas:"
echo "   • Node.js Redis client setup and configuration"
echo "   • Connection management with retry strategies"
echo "   • Service layer pattern for business operations"
echo "   • Promise-based and async/await operations"
echo "   • Batch operations and performance optimization"
echo "   • Integration testing with Jest"
echo ""
echo "🎉 READY TO START LAB 6!"
echo "   Open lab6.md for the complete 45-minute JavaScript Redis experience!"