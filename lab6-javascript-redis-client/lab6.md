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
