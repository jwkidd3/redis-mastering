# Lab 6: JavaScript Redis Client Setup

**Duration:** 45 minutes
**Focus:** Node.js Redis integration and async/await patterns
**Prerequisites:** Lab 5 completed, Node.js 16+ installed

## 🎯 Learning Objectives

- Set up Node.js Redis client with remote server
- Use async/await patterns with Redis
- Implement CRUD operations in JavaScript
- Handle errors and connection management
- Store and retrieve JSON data

## 🚀 Quick Start

### Step 1: Install Dependencies

```bash
npm install redis dotenv
```

### Step 2: Create Connection

Create `redis-client.js`:

```javascript
const redis = require('redis');
require('dotenv').config();

const client = redis.createClient({
  socket: {
    host: process.env.REDIS_HOST,
    port: process.env.REDIS_PORT
  }
});

client.on('error', err => console.error('Redis Error:', err));

async function connect() {
  await client.connect();
  console.log('Connected to Redis');
}

connect();

module.exports = client;
```

### Step 3: Test Connection

Create `test-connection.js`:

```javascript
const client = require('./redis-client');

async function test() {
  try {
    await client.set('test:key', 'Hello Redis!');
    const value = await client.get('test:key');
    console.log('Success:', value);
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await client.quit();
  }
}

test();
```

Run: `node test-connection.js`

## Part 1: Basic Operations

### String Operations

```javascript
const client = require('./redis-client');

async function basicOperations() {
  // Set values
  await client.set('customer:1001', 'John Smith');
  await client.set('policy:AUTO-001', 'Active');

  // Get values
  const customer = await client.get('customer:1001');
  const policy = await client.get('policy:AUTO-001');

  console.log(customer, policy);

  await client.quit();
}

basicOperations();
```

### Numeric Operations

```javascript
async function counters() {
  // Initialize counter
  await client.set('visitors:count', '0');

  // Increment
  await client.incr('visitors:count');
  await client.incr('visitors:count');

  // Increment by amount
  await client.incrBy('visitors:count', 10);

  // Get value
  const count = await client.get('visitors:count');
  console.log('Total visitors:', count);

  await client.quit();
}
```

## Part 2: JSON Data Storage

### Store Complex Objects

```javascript
async function jsonOperations() {
  // Customer object
  const customer = {
    id: 'C001',
    name: 'John Smith',
    email: 'john@example.com',
    policies: ['AUTO-001', 'HOME-001']
  };

  // Store as JSON
  await client.set('customer:C001', JSON.stringify(customer));

  // Retrieve and parse
  const data = await client.get('customer:C001');
  const retrieved = JSON.parse(data);

  console.log(retrieved);

  await client.quit();
}
```

## Part 3: Error Handling

### Production-Ready Patterns

```javascript
async function safeOperations() {
  try {
    await client.connect();

    // Operations
    await client.set('key', 'value');
    const result = await client.get('key');

    console.log('Success:', result);

  } catch (error) {
    console.error('Redis Error:', error.message);

    // Handle specific errors
    if (error.code === 'ECONNREFUSED') {
      console.error('Cannot connect to Redis server');
    }

  } finally {
    await client.quit();
  }
}
```

## Part 4: Batch Operations

### Multiple Operations

```javascript
async function batchOperations() {
  // Set multiple keys
  await Promise.all([
    client.set('customer:1', 'Alice'),
    client.set('customer:2', 'Bob'),
    client.set('customer:3', 'Charlie')
  ]);

  // Get multiple keys
  const customers = await Promise.all([
    client.get('customer:1'),
    client.get('customer:2'),
    client.get('customer:3')
  ]);

  console.log(customers);

  await client.quit();
}
```

## 🎓 Exercises

### Exercise 1: Customer Manager

Create a customer management system:

```javascript
class CustomerManager {
  constructor(client) {
    this.client = client;
  }

  async createCustomer(id, data) {
    // Store customer as JSON
    await this.client.set(`customer:${id}`, JSON.stringify(data));
  }

  async getCustomer(id) {
    // Retrieve and parse customer
    const data = await this.client.get(`customer:${id}`);
    return data ? JSON.parse(data) : null;
  }

  async deleteCustomer(id) {
    // Delete customer
    await this.client.del(`customer:${id}`);
  }
}
```

### Exercise 2: Counter Service

Build a visitor counter:
1. Initialize counter
2. Increment on each visit
3. Get current count
4. Reset counter

### Exercise 3: Policy Storage

Store and retrieve policies:
1. Create 10 policies with JSON data
2. Retrieve all policies
3. Update policy status
4. Delete expired policies

## 📋 Key Patterns

```javascript
// Connection
const client = redis.createClient({...});
await client.connect();

// Basic operations
await client.set('key', 'value');
const value = await client.get('key');

// JSON storage
await client.set('key', JSON.stringify(obj));
const obj = JSON.parse(await client.get('key'));

// Error handling
try {
  await client.set('key', 'value');
} catch (error) {
  console.error(error);
} finally {
  await client.quit();
}
```

## 💡 Best Practices

1. **Always use try-catch:** Wrap Redis operations in error handling
2. **Close connections:** Use `finally` block to quit client
3. **Environment variables:** Never hardcode connection details
4. **JSON storage:** Use JSON.stringify/parse for objects
5. **Batch operations:** Use Promise.all for multiple operations

## ✅ Lab Completion Checklist

- [ ] Connected to Redis from Node.js
- [ ] Performed basic SET/GET operations
- [ ] Stored and retrieved JSON objects
- [ ] Implemented error handling
- [ ] Used async/await patterns correctly
- [ ] Completed all exercises

**Estimated time:** 45 minutes

## 📚 Additional Resources

- **Redis Node.js Client:** `https://github.com/redis/node-redis`
- **Async/Await Guide:** `https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/async_function`

## 🔧 Troubleshooting

**Connection Error:**
```javascript
// Check .env file
REDIS_HOST=your-redis-host
REDIS_PORT=6379
```

**Module Not Found:**
```bash
npm install redis dotenv
```
