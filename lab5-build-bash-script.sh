#!/bin/bash

# Lab 5 Content Generator Script
# Generates complete content and code for Lab 5: Redis JavaScript Integration
# Duration: 45 minutes
# Focus: JavaScript client operations, async patterns, and Redis Insight integration

set -e

LAB_DIR="lab5-redis-javascript-integration"
LAB_NUMBER="5"
LAB_TITLE="Redis JavaScript Integration"
LAB_DURATION="45"

echo "🚀 Generating Lab ${LAB_NUMBER}: ${LAB_TITLE}"
echo "📅 Duration: ${LAB_DURATION} minutes"
echo "🎯 Focus: JavaScript client operations, async patterns, and Redis Insight integration"
echo ""

# Create lab directory structure
mkdir -p ${LAB_DIR}
cd ${LAB_DIR}

echo "📁 Creating lab directory structure..."
mkdir -p {scripts,docs,examples,js-exercises,solutions,tests}

# Create main lab instructions markdown file
echo "📋 Creating lab5.md..."
cat > lab5.md << 'EOF'
# Lab 5: Redis JavaScript Integration

**Duration:** 45 minutes  
**Objective:** Master Redis JavaScript client operations, implement async patterns, and integrate with Redis Insight for monitoring

## 🎯 Learning Objectives

By the end of this lab, you will be able to:
- Connect to Redis using the Node.js client library
- Implement async/await patterns for Redis operations
- Build data processing pipelines with JavaScript
- Monitor JavaScript operations using Redis Insight
- Handle connection pooling and error management
- Create real-world application patterns with Redis and JavaScript

---

## Part 1: JavaScript Client Setup and Connection (10 minutes)

### Step 1: Environment Setup

```bash
# Start Redis container
docker run -d --name redis-lab5 \
  -p 6379:6379 \
  redis:7-alpine

# Verify Redis is running
redis-cli ping

# Initialize Node.js project
npm init -y
npm install redis dotenv

# Create project structure
mkdir src
touch src/index.js
touch .env
```

### Step 2: Basic Connection with JavaScript

Create `src/connection.js`:

```javascript
// src/connection.js
import { createClient } from 'redis';

async function connectRedis() {
    const client = createClient({
        url: process.env.REDIS_URL || 'redis://localhost:6379',
        socket: {
            reconnectStrategy: (retries) => {
                if (retries > 10) {
                    console.log('Too many reconnection attempts');
                    return new Error('Too many retries');
                }
                return retries * 100;
            }
        }
    });

    client.on('error', (err) => console.error('Redis Client Error:', err));
    client.on('connect', () => console.log('Connected to Redis'));
    client.on('ready', () => console.log('Redis client ready'));

    await client.connect();
    return client;
}

export default connectRedis;
```

Test the connection:

```javascript
// src/test-connection.js
import connectRedis from './connection.js';

(async () => {
    const client = await connectRedis();
    
    // Test basic operations
    await client.set('test:key', 'Hello Redis from JavaScript!');
    const value = await client.get('test:key');
    console.log('Retrieved value:', value);
    
    await client.disconnect();
})();
```

### Step 3: Redis Insight Setup

1. **Open Redis Insight** (already installed on your machine)
2. **Add Database Connection:**
   - Host: localhost
   - Port: 6379
   - Name: Lab5-JavaScript
3. **Navigate to Command Line Interface**
4. **Monitor JavaScript operations in real-time**

---

## Part 2: Async Operations and Data Processing (15 minutes)

### Step 1: Implement Async Data Operations

Create `src/data-operations.js`:

```javascript
// src/data-operations.js
import connectRedis from './connection.js';

class DataProcessor {
    constructor() {
        this.client = null;
    }

    async initialize() {
        this.client = await connectRedis();
    }

    async processCustomerData(customers) {
        const pipeline = this.client.multi();
        
        for (const customer of customers) {
            pipeline.hSet(`customer:${customer.id}`, {
                name: customer.name,
                email: customer.email,
                registeredAt: new Date().toISOString()
            });
            
            pipeline.sAdd('customers:active', customer.id);
            pipeline.zAdd('customers:by-registration', {
                score: Date.now(),
                value: customer.id
            });
        }
        
        const results = await pipeline.exec();
        console.log(`Processed ${customers.length} customers`);
        return results;
    }

    async getCustomerDetails(customerId) {
        const details = await this.client.hGetAll(`customer:${customerId}`);
        return details;
    }

    async getRecentCustomers(limit = 10) {
        const customerIds = await this.client.zRange(
            'customers:by-registration',
            -limit,
            -1,
            { REV: true }
        );
        
        const customers = [];
        for (const id of customerIds) {
            const details = await this.getCustomerDetails(id);
            customers.push({ id, ...details });
        }
        
        return customers;
    }

    async cleanup() {
        await this.client.disconnect();
    }
}

export default DataProcessor;
```

### Step 2: Test Async Operations

Create `src/test-async.js`:

```javascript
// src/test-async.js
import DataProcessor from './data-operations.js';

const sampleCustomers = [
    { id: 'C001', name: 'John Doe', email: 'john@example.com' },
    { id: 'C002', name: 'Jane Smith', email: 'jane@example.com' },
    { id: 'C003', name: 'Bob Johnson', email: 'bob@example.com' }
];

(async () => {
    const processor = new DataProcessor();
    await processor.initialize();
    
    console.log('Processing customer data...');
    await processor.processCustomerData(sampleCustomers);
    
    console.log('\nRetrieving recent customers:');
    const recent = await processor.getRecentCustomers(5);
    console.table(recent);
    
    await processor.cleanup();
})();
```

### Step 3: Monitor in Redis Insight

1. **Open Redis Insight Command Line**
2. **Execute monitoring commands:**

```redis
# Watch keys being created
KEYS customer:*

# Check hash values
HGETALL customer:C001

# View sorted set
ZRANGE customers:by-registration 0 -1 WITHSCORES

# Monitor operations in real-time
MONITOR
```

---

## Part 3: Advanced Patterns and Error Handling (15 minutes)

### Step 1: Implement Pub/Sub Pattern

Create `src/pubsub.js`:

```javascript
// src/pubsub.js
import { createClient } from 'redis';

class EventManager {
    constructor() {
        this.publisher = null;
        this.subscriber = null;
    }

    async initialize() {
        // Create separate clients for pub/sub
        this.publisher = createClient({
            url: process.env.REDIS_URL || 'redis://localhost:6379'
        });
        
        this.subscriber = this.publisher.duplicate();
        
        await this.publisher.connect();
        await this.subscriber.connect();
    }

    async subscribeToEvents(channel, callback) {
        await this.subscriber.subscribe(channel, (message) => {
            const data = JSON.parse(message);
            callback(data);
        });
        
        console.log(`Subscribed to channel: ${channel}`);
    }

    async publishEvent(channel, data) {
        const message = JSON.stringify(data);
        await this.publisher.publish(channel, message);
        console.log(`Published to ${channel}:`, data);
    }

    async cleanup() {
        await this.subscriber.disconnect();
        await this.publisher.disconnect();
    }
}

export default EventManager;
```

### Step 2: Implement Stream Processing

Create `src/streams.js`:

```javascript
// src/streams.js
import connectRedis from './connection.js';

class StreamProcessor {
    constructor() {
        this.client = null;
    }

    async initialize() {
        this.client = await connectRedis();
    }

    async addToStream(streamKey, data) {
        const id = await this.client.xAdd(
            streamKey,
            '*',
            data
        );
        console.log(`Added to stream with ID: ${id}`);
        return id;
    }

    async readStream(streamKey, count = 10) {
        const messages = await this.client.xRange(
            streamKey,
            '-',
            '+',
            { COUNT: count }
        );
        
        return messages.map(msg => ({
            id: msg.id,
            data: msg.message
        }));
    }

    async processStreamWithConsumerGroup(streamKey, groupName, consumerName) {
        // Create consumer group
        try {
            await this.client.xGroupCreate(streamKey, groupName, '0');
            console.log(`Created consumer group: ${groupName}`);
        } catch (err) {
            if (!err.message.includes('BUSYGROUP')) {
                throw err;
            }
        }

        // Read messages
        const messages = await this.client.xReadGroup(
            groupName,
            consumerName,
            {
                key: streamKey,
                id: '>'
            },
            {
                COUNT: 10,
                BLOCK: 1000
            }
        );

        if (messages && messages.length > 0) {
            for (const stream of messages) {
                for (const message of stream.messages) {
                    console.log('Processing message:', message);
                    
                    // Acknowledge message
                    await this.client.xAck(
                        streamKey,
                        groupName,
                        message.id
                    );
                }
            }
        }

        return messages;
    }

    async cleanup() {
        await this.client.disconnect();
    }
}

export default StreamProcessor;
```

### Step 3: Error Handling and Retry Logic

Create `src/resilient-client.js`:

```javascript
// src/resilient-client.js
import { createClient } from 'redis';

class ResilientRedisClient {
    constructor(options = {}) {
        this.options = {
            maxRetries: options.maxRetries || 3,
            retryDelay: options.retryDelay || 1000,
            ...options
        };
        this.client = null;
    }

    async connect() {
        this.client = createClient({
            url: this.options.url || 'redis://localhost:6379',
            socket: {
                reconnectStrategy: (retries) => {
                    if (retries > this.options.maxRetries) {
                        return new Error('Max retries reached');
                    }
                    return Math.min(retries * 100, 3000);
                }
            }
        });

        this.client.on('error', (err) => {
            console.error('Redis error:', err);
        });

        await this.client.connect();
    }

    async executeWithRetry(operation, ...args) {
        let lastError;
        
        for (let attempt = 1; attempt <= this.options.maxRetries; attempt++) {
            try {
                if (!this.client.isOpen) {
                    await this.connect();
                }
                
                return await operation.call(this.client, ...args);
            } catch (error) {
                lastError = error;
                console.log(`Attempt ${attempt} failed:`, error.message);
                
                if (attempt < this.options.maxRetries) {
                    await this.delay(this.options.retryDelay * attempt);
                }
            }
        }
        
        throw lastError;
    }

    delay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    async get(key) {
        return this.executeWithRetry(this.client.get, key);
    }

    async set(key, value, options) {
        return this.executeWithRetry(this.client.set, key, value, options);
    }

    async disconnect() {
        if (this.client) {
            await this.client.disconnect();
        }
    }
}

export default ResilientRedisClient;
```

---

## Part 4: Integration Testing and Monitoring (5 minutes)

### Step 1: Run Integration Tests

Create `src/integration-test.js`:

```javascript
// src/integration-test.js
import DataProcessor from './data-operations.js';
import EventManager from './pubsub.js';
import StreamProcessor from './streams.js';

async function runIntegrationTests() {
    console.log('🧪 Running Integration Tests...\n');
    
    // Test 1: Data Operations
    console.log('Test 1: Data Operations');
    const processor = new DataProcessor();
    await processor.initialize();
    
    await processor.processCustomerData([
        { id: 'TEST001', name: 'Test User', email: 'test@example.com' }
    ]);
    
    const customer = await processor.getCustomerDetails('TEST001');
    console.log('✅ Customer created:', customer);
    await processor.cleanup();
    
    // Test 2: Pub/Sub
    console.log('\nTest 2: Pub/Sub Pattern');
    const eventManager = new EventManager();
    await eventManager.initialize();
    
    await eventManager.subscribeToEvents('test:events', (data) => {
        console.log('✅ Received event:', data);
    });
    
    await eventManager.publishEvent('test:events', {
        type: 'TEST_EVENT',
        timestamp: Date.now()
    });
    
    await new Promise(resolve => setTimeout(resolve, 1000));
    await eventManager.cleanup();
    
    // Test 3: Streams
    console.log('\nTest 3: Stream Processing');
    const streamProcessor = new StreamProcessor();
    await streamProcessor.initialize();
    
    await streamProcessor.addToStream('test:stream', {
        action: 'test_action',
        value: '123'
    });
    
    const messages = await streamProcessor.readStream('test:stream');
    console.log('✅ Stream messages:', messages);
    await streamProcessor.cleanup();
    
    console.log('\n✅ All tests completed successfully!');
}

runIntegrationTests().catch(console.error);
```

### Step 2: Monitor with Redis Insight

1. **Open Redis Insight**
2. **Navigate to Browser** to view all keys
3. **Use Profiler** to monitor commands in real-time
4. **Check Memory Analysis** for key distribution
5. **Use CLI** to run custom queries:

```redis
# Check all customer keys
KEYS customer:*

# View stream entries
XRANGE test:stream - +

# Check pub/sub channels
PUBSUB CHANNELS

# Monitor memory usage
INFO memory
```

---

## 📋 Lab Summary

You have successfully completed Lab 5! You've learned:

✅ **JavaScript Client Setup:** Connected to Redis using Node.js client  
✅ **Async Operations:** Implemented async/await patterns for Redis operations  
✅ **Data Processing:** Built pipelines for batch operations  
✅ **Pub/Sub Pattern:** Implemented event-driven architecture  
✅ **Stream Processing:** Worked with Redis Streams and consumer groups  
✅ **Error Handling:** Created resilient clients with retry logic  
✅ **Redis Insight:** Monitored JavaScript operations in real-time  

## 🎯 Challenge Exercise (Optional)

Build a complete rate limiter using JavaScript and Redis:

```javascript
// Challenge: Implement a sliding window rate limiter
class RateLimiter {
    constructor(client, windowSize = 60, maxRequests = 10) {
        this.client = client;
        this.windowSize = windowSize;
        this.maxRequests = maxRequests;
    }

    async checkLimit(userId) {
        // Your implementation here
        // Hint: Use sorted sets with timestamps
    }
}
```

## 🔧 Troubleshooting Guide

### Common Issues and Solutions:

1. **Connection Refused Error:**
   ```bash
   # Check if Redis is running
   docker ps | grep redis
   # Restart if needed
   docker start redis-lab5
   ```

2. **Module Import Errors:**
   ```json
   // Add to package.json
   {
     "type": "module"
   }
   ```

3. **Redis Insight Connection Issues:**
   - Verify Redis is on port 6379
   - Check firewall settings
   - Try connecting with redis-cli first

4. **Async/Await Issues:**
   - Always use try-catch blocks
   - Ensure functions are marked as async
   - Check for unhandled promise rejections

## 📚 Additional Resources

- [Redis Node.js Client Documentation](https://github.com/redis/node-redis)
- [Redis Insight User Guide](https://redis.io/docs/ui/insight/)
- [JavaScript Async Patterns](https://developer.mozilla.org/en-US/docs/Learn/JavaScript/Asynchronous)
- [Redis Best Practices](https://redis.io/docs/manual/patterns/)

---

**Congratulations!** You've mastered Redis JavaScript integration! 🎉
EOF

# Create package.json for the lab
echo "📦 Creating package.json..."
cat > package.json << 'EOF'
{
  "name": "lab5-redis-javascript",
  "version": "1.0.0",
  "description": "Lab 5: Redis JavaScript Integration",
  "type": "module",
  "main": "src/index.js",
  "scripts": {
    "start": "node src/index.js",
    "test-connection": "node src/test-connection.js",
    "test-async": "node src/test-async.js",
    "test-integration": "node src/integration-test.js",
    "monitor": "redis-cli monitor"
  },
  "dependencies": {
    "redis": "^4.6.0",
    "dotenv": "^16.0.0"
  },
  "devDependencies": {
    "nodemon": "^3.0.0"
  },
  "keywords": ["redis", "javascript", "lab", "training"],
  "author": "",
  "license": "MIT"
}
EOF

# Create JavaScript source files
echo "💻 Creating JavaScript source files..."
mkdir -p src

# Create connection.js
cat > src/connection.js << 'EOF'
// src/connection.js
import { createClient } from 'redis';

async function connectRedis() {
    const client = createClient({
        url: process.env.REDIS_URL || 'redis://localhost:6379',
        socket: {
            reconnectStrategy: (retries) => {
                if (retries > 10) {
                    console.log('Too many reconnection attempts');
                    return new Error('Too many retries');
                }
                return retries * 100;
            }
        }
    });

    client.on('error', (err) => console.error('Redis Client Error:', err));
    client.on('connect', () => console.log('Connected to Redis'));
    client.on('ready', () => console.log('Redis client ready'));

    await client.connect();
    return client;
}

export default connectRedis;
EOF

# Create data-operations.js
cat > src/data-operations.js << 'EOF'
// src/data-operations.js
import connectRedis from './connection.js';

class DataProcessor {
    constructor() {
        this.client = null;
    }

    async initialize() {
        this.client = await connectRedis();
    }

    async processCustomerData(customers) {
        const pipeline = this.client.multi();
        
        for (const customer of customers) {
            pipeline.hSet(`customer:${customer.id}`, {
                name: customer.name,
                email: customer.email,
                registeredAt: new Date().toISOString()
            });
            
            pipeline.sAdd('customers:active', customer.id);
            pipeline.zAdd('customers:by-registration', {
                score: Date.now(),
                value: customer.id
            });
        }
        
        const results = await pipeline.exec();
        console.log(`Processed ${customers.length} customers`);
        return results;
    }

    async getCustomerDetails(customerId) {
        const details = await this.client.hGetAll(`customer:${customerId}`);
        return details;
    }

    async getRecentCustomers(limit = 10) {
        const customerIds = await this.client.zRange(
            'customers:by-registration',
            -limit,
            -1,
            { REV: true }
        );
        
        const customers = [];
        for (const id of customerIds) {
            const details = await this.getCustomerDetails(id);
            customers.push({ id, ...details });
        }
        
        return customers;
    }

    async cleanup() {
        await this.client.disconnect();
    }
}

export default DataProcessor;
EOF

# Create test files
cat > src/test-connection.js << 'EOF'
// src/test-connection.js
import connectRedis from './connection.js';

(async () => {
    try {
        const client = await connectRedis();
        
        // Test basic operations
        await client.set('test:key', 'Hello Redis from JavaScript!');
        const value = await client.get('test:key');
        console.log('✅ Retrieved value:', value);
        
        // Test JSON operations
        await client.json.set('test:json', '$', {
            name: 'Lab 5',
            type: 'JavaScript Integration',
            timestamp: new Date().toISOString()
        });
        
        const jsonData = await client.json.get('test:json');
        console.log('✅ JSON data:', jsonData);
        
        await client.disconnect();
        console.log('✅ Connection test completed successfully!');
    } catch (error) {
        console.error('❌ Connection test failed:', error);
        process.exit(1);
    }
})();
EOF

# Create load script
cat > scripts/load-sample-data.sh << 'EOF'
#!/bin/bash

# Load sample data for Lab 5
echo "Loading sample data for Lab 5..."

redis-cli << 'REDIS'
# Clear existing data
FLUSHDB

# Create sample customers
HSET customer:1001 name "Alice Johnson" email "alice@example.com" tier "premium"
HSET customer:1002 name "Bob Smith" email "bob@example.com" tier "standard"
HSET customer:1003 name "Carol White" email "carol@example.com" tier "premium"

# Create sample products
HSET product:P001 name "Widget A" price "29.99" stock "150"
HSET product:P002 name "Widget B" price "49.99" stock "75"
HSET product:P003 name "Widget C" price "19.99" stock "200"

# Create sample orders
LPUSH orders:pending "ORD-2024-001"
LPUSH orders:pending "ORD-2024-002"
LPUSH orders:processing "ORD-2024-003"

# Create sets for categories
SADD customers:premium 1001 1003
SADD customers:standard 1002

# Create sorted set for customer scores
ZADD customer:scores 850 1001 720 1002 900 1003

# Create sample stream data
XADD events:customer * action "login" customer_id "1001" timestamp "1704067200"
XADD events:customer * action "purchase" customer_id "1002" amount "49.99"
XADD events:customer * action "logout" customer_id "1001" timestamp "1704070800"

# Set some TTL examples
SET session:abc123 "user:1001" EX 3600
SET cache:product:P001 "{\"name\":\"Widget A\",\"price\":29.99}" EX 300

# Display summary
echo "Sample data loaded:"
echo "  - Customers: 3"
echo "  - Products: 3"
echo "  - Orders: 3"
echo "  - Events: 3"
echo "  - Sessions: 1 (with TTL)"
echo "  - Cache entries: 1 (with TTL)"

INFO keyspace
REDIS

echo "✅ Sample data loaded successfully!"
EOF

chmod +x scripts/load-sample-data.sh

# Create README
cat > README.md << 'EOF'
# Lab 5: Redis JavaScript Integration

## 🎯 Overview

This lab focuses on integrating Redis with JavaScript applications using the Node.js client library. You'll learn async patterns, error handling, and monitoring with Redis Insight.

## 📋 Prerequisites

- Docker installed and running
- Node.js 16+ installed
- Redis Insight installed
- Visual Studio Code
- Basic JavaScript knowledge

## 🚀 Quick Start

1. **Start Redis:**
   ```bash
   docker run -d --name redis-lab5 -p 6379:6379 redis:7-alpine
   ```

2. **Install Dependencies:**
   ```bash
   npm install
   ```

3. **Load Sample Data:**
   ```bash
   ./scripts/load-sample-data.sh
   ```

4. **Test Connection:**
   ```bash
   npm run test-connection
   ```

5. **Open Redis Insight:**
   - Connect to localhost:6379
   - Monitor operations in real-time

## 📂 Project Structure

```
lab5-redis-javascript-integration/
├── lab5.md                 # Complete lab instructions
├── package.json            # Node.js dependencies
├── src/
│   ├── connection.js       # Redis connection module
│   ├── data-operations.js  # Data processing operations
│   ├── pubsub.js          # Pub/Sub implementation
│   ├── streams.js         # Stream processing
│   └── test-*.js          # Test files
├── scripts/
│   └── load-sample-data.sh # Sample data loader
└── README.md              # This file
```

## 🧪 Running Tests

```bash
# Test basic connection
npm run test-connection

# Test async operations
npm run test-async

# Run integration tests
npm run test-integration

# Monitor Redis operations
npm run monitor
```

## 🔧 Troubleshooting

### Connection Issues
- Verify Redis is running: `docker ps`
- Check port 6379: `netstat -an | grep 6379`
- Test with redis-cli: `redis-cli ping`

### Module Errors
- Ensure package.json has `"type": "module"`
- Use .js extension in imports
- Check Node.js version: `node --version`

## 📚 Key Concepts

- **Async/Await:** Modern JavaScript patterns for Redis operations
- **Connection Pooling:** Efficient client management
- **Error Handling:** Resilient Redis clients
- **Pub/Sub:** Event-driven architecture
- **Streams:** Real-time data processing
- **Redis Insight:** Visual monitoring and debugging

## ⏱️ Time Allocation

- Part 1: Setup and Connection (10 min)
- Part 2: Async Operations (15 min)
- Part 3: Advanced Patterns (15 min)
- Part 4: Testing and Monitoring (5 min)

## 🎓 Learning Outcomes

After completing this lab, you will be able to:
- ✅ Connect JavaScript applications to Redis
- ✅ Implement async Redis operations
- ✅ Handle errors and retries gracefully
- ✅ Monitor operations with Redis Insight
- ✅ Build production-ready Redis integrations

---

**Need Help?** Check the troubleshooting section in lab5.md or ask your instructor!
EOF

# Create .env example
cat > .env.example << 'EOF'
# Redis Configuration
REDIS_URL=redis://localhost:6379
REDIS_PASSWORD=
REDIS_DB=0

# Application Settings
NODE_ENV=development
LOG_LEVEL=info
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

# OS files
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
*.swp
*.swo

# Test output
coverage/
.nyc_output/

# Build
dist/
build/
EOF

echo ""
echo "✅ Lab 5 build script completed successfully!"
echo ""
echo "📂 Project structure created:"
echo "   ${LAB_DIR}/"
echo "   ├── lab5.md                    📋 Complete lab instructions"
echo "   ├── package.json               📦 Node.js configuration"
echo "   ├── src/"
echo "   │   ├── connection.js          🔌 Redis connection module"
echo "   │   ├── data-operations.js     💾 Data processing"
echo "   │   ├── pubsub.js             📡 Pub/Sub patterns"
echo "   │   ├── streams.js            🌊 Stream processing"
echo "   │   └── test-*.js             🧪 Test files"
echo "   ├── scripts/"
echo "   │   └── load-sample-data.sh   📊 Sample data loader"
echo "   ├── README.md                  📖 Quick reference"
echo "   ├── .env.example              🔐 Environment template"
echo "   └── .gitignore                🚫 Git ignore rules"
echo ""
echo "🎯 NEXT STEPS:"
echo "   1. cd ${LAB_DIR}"
echo "   2. docker run -d --name redis-lab5 -p 6379:6379 redis:7-alpine"
echo "   3. npm install"
echo "   4. ./scripts/load-sample-data.sh"
echo "   5. code ."
echo "   6. Open lab5.md and start the lab!"
echo ""
echo "💡 Quick Commands:"
echo "   npm run test-connection    # Test Redis connection"
echo "   npm run test-async        # Test async operations"
echo "   npm run test-integration  # Run all integration tests"
echo "   npm run monitor          # Monitor Redis operations"
echo ""
echo "🚀 Ready to start Lab 5: Redis JavaScript Integration!"