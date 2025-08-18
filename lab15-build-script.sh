#!/bin/bash

# Lab 15 Content Generator Script
# Generates complete content and code for Lab 15: Simple Microservices Pattern
# Duration: 45 minutes
# Focus: JavaScript Redis client for cross-service caching and communication

set -e

LAB_DIR="lab15-microservices-integration"
LAB_NUMBER="15"
LAB_TITLE="Simple Microservices Pattern"
LAB_DURATION="45"

echo "🚀 Generating Lab ${LAB_NUMBER}: ${LAB_TITLE}"
echo "📅 Duration: ${LAB_DURATION} minutes"
echo "🎯 Focus: JavaScript-based microservices with Redis for caching and communication"
echo ""

# Create lab directory structure
mkdir -p ${LAB_DIR}
cd ${LAB_DIR}

echo "📁 Creating lab directory structure..."
mkdir -p {src,scripts,docs,services,shared,tests,config}
mkdir -p services/{policy-service,claims-service,customer-service}

# Create package.json for JavaScript project
echo "📦 Creating package.json..."
cat > package.json << 'EOF'
{
  "name": "lab15-microservices-integration",
  "version": "1.0.0",
  "description": "Lab 15: Simple Microservices Pattern with Redis integration",
  "main": "src/index.js",
  "scripts": {
    "start": "node src/index.js",
    "start:policy": "node services/policy-service/index.js",
    "start:claims": "node services/claims-service/index.js",
    "start:customer": "node services/customer-service/index.js",
    "start:all": "npm-run-all --parallel start:policy start:claims start:customer",
    "test": "node tests/test-integration.js",
    "load-data": "bash scripts/load-sample-data.sh",
    "monitor": "node src/monitor.js",
    "dev": "nodemon src/index.js"
  },
  "keywords": ["redis", "microservices", "caching", "javascript", "distributed"],
  "author": "Redis Training",
  "license": "MIT",
  "dependencies": {
    "redis": "^4.6.0",
    "express": "^4.18.2",
    "axios": "^1.6.0",
    "dotenv": "^16.0.3",
    "uuid": "^9.0.0",
    "body-parser": "^1.20.2",
    "morgan": "^1.10.0",
    "chalk": "^4.1.2"
  },
  "devDependencies": {
    "nodemon": "^2.0.20",
    "npm-run-all": "^4.1.5"
  }
}
EOF

# Create main lab instructions markdown file
echo "📋 Creating lab15.md..."
cat > lab15.md << 'EOF'
# Lab 15: Simple Microservices Pattern

**Duration:** 45 minutes  
**Objective:** Implement basic cross-service caching and communication patterns using JavaScript and Redis for distributed business systems

## 🎯 Learning Objectives

By the end of this lab, you will be able to:
- Set up simple policy service with Redis caching
- Implement basic claims service with shared session management
- Create simple service-to-service cache invalidation patterns
- Build basic event notification between services using Redis pub/sub
- Implement simple service discovery pattern with Redis
- Apply distributed caching strategies for microservices

---

## Part 1: Microservices Infrastructure Setup (15 minutes)

### Step 1: Environment Setup with Multiple Services

```bash
# Start Redis with configuration for microservices
docker run -d --name redis-microservices-lab15 \
  -p 6379:6379 \
  redis:7-alpine redis-server \
  --maxmemory 1gb \
  --maxmemory-policy allkeys-lru \
  --save "" \
  --appendonly no

# Install dependencies
npm install

# Create environment configuration
cp .env.example .env

# Load sample data
npm run load-data
```

### Step 2: Redis Client Configuration for Microservices

Create `shared/redis-client.js`:
```javascript
const redis = require('redis');

class RedisManager {
    constructor(serviceName) {
        this.serviceName = serviceName;
        this.client = null;
        this.pubClient = null;
        this.subClient = null;
    }

    async connect() {
        // Main client for data operations
        this.client = redis.createClient({
            url: process.env.REDIS_URL || 'redis://localhost:6379',
            socket: {
                reconnectStrategy: (retries) => {
                    if (retries > 10) return new Error('Max retries reached');
                    return Math.min(retries * 100, 3000);
                }
            }
        });

        // Separate clients for pub/sub
        this.pubClient = this.client.duplicate();
        this.subClient = this.client.duplicate();

        this.client.on('error', err => 
            console.error(`[${this.serviceName}] Redis Error:`, err));
        this.client.on('connect', () => 
            console.log(`[${this.serviceName}] Connected to Redis`));

        await this.client.connect();
        await this.pubClient.connect();
        await this.subClient.connect();

        // Register service in Redis
        await this.registerService();
    }

    async registerService() {
        const serviceKey = `service:${this.serviceName}`;
        const serviceData = {
            name: this.serviceName,
            host: process.env.SERVICE_HOST || 'localhost',
            port: process.env.SERVICE_PORT || 3000,
            status: 'active',
            startTime: new Date().toISOString()
        };

        await this.client.hSet(serviceKey, serviceData);
        await this.client.expire(serviceKey, 30); // 30 second TTL
        
        // Keep service registered with heartbeat
        setInterval(async () => {
            await this.client.expire(serviceKey, 30);
            await this.client.hSet(serviceKey, 'lastHeartbeat', new Date().toISOString());
        }, 10000); // Every 10 seconds
    }

    async cacheSet(key, value, ttl = 300) {
        await this.client.setEx(key, ttl, JSON.stringify(value));
    }

    async cacheGet(key) {
        const data = await this.client.get(key);
        return data ? JSON.parse(data) : null;
    }

    async invalidateCache(pattern) {
        const keys = await this.client.keys(pattern);
        if (keys.length > 0) {
            await this.client.del(keys);
        }
        // Notify other services about cache invalidation
        await this.publishEvent('cache:invalidated', { pattern, service: this.serviceName });
    }

    async publishEvent(channel, data) {
        await this.pubClient.publish(channel, JSON.stringify({
            ...data,
            timestamp: Date.now(),
            source: this.serviceName
        }));
    }

    async subscribeToEvents(channel, callback) {
        await this.subClient.subscribe(channel, (message) => {
            const data = JSON.parse(message);
            callback(data);
        });
    }

    async getActiveServices() {
        const keys = await this.client.keys('service:*');
        const services = [];
        
        for (const key of keys) {
            const service = await this.client.hGetAll(key);
            if (service.status === 'active') {
                services.push(service);
            }
        }
        
        return services;
    }
}

module.exports = RedisManager;
```

---

## Part 2: Policy Service Implementation (10 minutes)

### Step 1: Create Policy Service

Create `services/policy-service/index.js`:
```javascript
const express = require('express');
const RedisManager = require('../../shared/redis-client');
const app = express();
app.use(express.json());

const redis = new RedisManager('policy-service');
const PORT = process.env.POLICY_SERVICE_PORT || 3001;

// Initialize service
async function initService() {
    await redis.connect();
    
    // Subscribe to cache invalidation events
    await redis.subscribeToEvents('cache:invalidated', async (data) => {
        console.log(`[Policy Service] Cache invalidation received:`, data);
        if (data.pattern.includes('policy:')) {
            console.log('Refreshing policy cache...');
        }
    });

    // Subscribe to policy events
    await redis.subscribeToEvents('policy:events', async (data) => {
        console.log(`[Policy Service] Policy event:`, data);
    });
}

// Get policy with caching
app.get('/api/policies/:id', async (req, res) => {
    const policyId = req.params.id;
    const cacheKey = `cache:policy:${policyId}`;
    
    try {
        // Check cache first
        let policy = await redis.cacheGet(cacheKey);
        
        if (!policy) {
            // Simulate database fetch
            policy = {
                id: policyId,
                type: 'AUTO',
                customerId: `CUST${Math.floor(Math.random() * 1000)}`,
                premium: Math.floor(Math.random() * 2000) + 500,
                coverage: 100000,
                status: 'active',
                startDate: new Date().toISOString(),
                fetchedFrom: 'database',
                fetchedAt: new Date().toISOString()
            };
            
            // Cache for 5 minutes
            await redis.cacheSet(cacheKey, policy, 300);
            console.log(`[Policy Service] Cached policy ${policyId}`);
        } else {
            policy.fetchedFrom = 'cache';
        }
        
        res.json(policy);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Update policy and invalidate cache
app.put('/api/policies/:id', async (req, res) => {
    const policyId = req.params.id;
    
    try {
        // Update in "database" (simulated)
        const updatedPolicy = {
            id: policyId,
            ...req.body,
            updatedAt: new Date().toISOString()
        };
        
        // Invalidate cache
        await redis.invalidateCache(`cache:policy:${policyId}`);
        
        // Notify other services
        await redis.publishEvent('policy:updated', {
            policyId,
            changes: req.body
        });
        
        res.json({ message: 'Policy updated', policy: updatedPolicy });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Health check
app.get('/health', async (req, res) => {
    const services = await redis.getActiveServices();
    res.json({
        service: 'policy-service',
        status: 'healthy',
        connectedServices: services.length,
        timestamp: new Date().toISOString()
    });
});

initService().then(() => {
    app.listen(PORT, () => {
        console.log(`✅ Policy Service running on port ${PORT}`);
    });
});
```

---

## Part 3: Claims Service Implementation (10 minutes)

### Step 1: Create Claims Service

Create `services/claims-service/index.js`:
```javascript
const express = require('express');
const axios = require('axios');
const RedisManager = require('../../shared/redis-client');
const app = express();
app.use(express.json());

const redis = new RedisManager('claims-service');
const PORT = process.env.CLAIMS_SERVICE_PORT || 3002;

// Shared session storage
const sessions = new Map();

async function initService() {
    await redis.connect();
    
    // Subscribe to policy updates
    await redis.subscribeToEvents('policy:updated', async (data) => {
        console.log(`[Claims Service] Policy update received:`, data);
        // Invalidate related claims cache
        await redis.invalidateCache(`cache:claims:policy:${data.policyId}`);
    });

    // Subscribe to session events
    await redis.subscribeToEvents('session:events', async (data) => {
        console.log(`[Claims Service] Session event:`, data);
    });
}

// Submit new claim
app.post('/api/claims', async (req, res) => {
    const { policyId, customerId, amount, description } = req.body;
    const claimId = `CLM${Date.now()}`;
    
    try {
        // Check if policy exists (call policy service)
        const policyResponse = await axios.get(
            `http://localhost:3001/api/policies/${policyId}`
        );
        const policy = policyResponse.data;
        
        if (policy.customerId !== customerId) {
            return res.status(403).json({ error: 'Policy does not belong to customer' });
        }
        
        // Create claim
        const claim = {
            id: claimId,
            policyId,
            customerId,
            amount,
            description,
            status: 'pending',
            submittedAt: new Date().toISOString()
        };
        
        // Store in cache
        await redis.cacheSet(`cache:claim:${claimId}`, claim, 3600);
        
        // Add to processing queue
        await redis.client.lPush('claims:queue', JSON.stringify(claim));
        
        // Notify about new claim
        await redis.publishEvent('claim:submitted', {
            claimId,
            policyId,
            amount
        });
        
        res.json({ message: 'Claim submitted', claim });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Get claims for a policy
app.get('/api/claims/policy/:policyId', async (req, res) => {
    const policyId = req.params.policyId;
    const cacheKey = `cache:claims:policy:${policyId}`;
    
    try {
        let claims = await redis.cacheGet(cacheKey);
        
        if (!claims) {
            // Simulate database fetch
            claims = [
                {
                    id: `CLM001`,
                    policyId,
                    amount: 1500,
                    status: 'approved',
                    date: '2024-01-15'
                },
                {
                    id: `CLM002`,
                    policyId,
                    amount: 750,
                    status: 'pending',
                    date: '2024-02-01'
                }
            ];
            
            await redis.cacheSet(cacheKey, claims, 300);
        }
        
        res.json(claims);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Process claims from queue
async function processClaimsQueue() {
    while (true) {
        try {
            const claimData = await redis.client.brPop('claims:queue', 5);
            
            if (claimData) {
                const claim = JSON.parse(claimData.element);
                console.log(`[Claims Service] Processing claim ${claim.id}`);
                
                // Simulate processing
                await new Promise(resolve => setTimeout(resolve, 1000));
                
                // Update claim status
                claim.status = 'processed';
                claim.processedAt = new Date().toISOString();
                
                await redis.cacheSet(`cache:claim:${claim.id}`, claim, 3600);
                
                // Notify about processed claim
                await redis.publishEvent('claim:processed', {
                    claimId: claim.id,
                    status: claim.status
                });
            }
        } catch (error) {
            console.error('Error processing claim:', error);
        }
    }
}

// Health check
app.get('/health', async (req, res) => {
    const queueLength = await redis.client.lLen('claims:queue');
    res.json({
        service: 'claims-service',
        status: 'healthy',
        queueLength,
        timestamp: new Date().toISOString()
    });
});

initService().then(() => {
    app.listen(PORT, () => {
        console.log(`✅ Claims Service running on port ${PORT}`);
        processClaimsQueue(); // Start queue processor
    });
});
```

---

## Part 4: Service Orchestration and Testing (10 minutes)

### Step 1: Create Service Discovery

Create `src/service-discovery.js`:
```javascript
const RedisManager = require('../shared/redis-client');

class ServiceDiscovery {
    constructor() {
        this.redis = new RedisManager('service-discovery');
        this.services = new Map();
    }

    async initialize() {
        await this.redis.connect();
        
        // Monitor service registration
        setInterval(async () => {
            await this.discoverServices();
        }, 5000);
        
        // Subscribe to service events
        await this.redis.subscribeToEvents('service:*', (data) => {
            console.log('[Service Discovery] Service event:', data);
        });
    }

    async discoverServices() {
        const activeServices = await this.redis.getActiveServices();
        
        for (const service of activeServices) {
            if (!this.services.has(service.name)) {
                console.log(`[Service Discovery] New service discovered: ${service.name}`);
                this.services.set(service.name, service);
            }
        }
        
        // Check for inactive services
        for (const [name, service] of this.services) {
            const stillActive = activeServices.find(s => s.name === name);
            if (!stillActive) {
                console.log(`[Service Discovery] Service went offline: ${name}`);
                this.services.delete(name);
            }
        }
    }

    getService(name) {
        return this.services.get(name);
    }

    getAllServices() {
        return Array.from(this.services.values());
    }
}

// Usage
const discovery = new ServiceDiscovery();
discovery.initialize().then(() => {
    console.log('Service Discovery initialized');
});

module.exports = ServiceDiscovery;
```

### Step 2: Create Integration Tests

Create `tests/test-integration.js`:
```javascript
const axios = require('axios');
const chalk = require('chalk');

async function wait(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

async function testMicroservices() {
    console.log(chalk.blue('\n🧪 Testing Microservices Integration\n'));
    
    // Wait for services to start
    await wait(2000);
    
    try {
        // Test 1: Policy Service
        console.log(chalk.yellow('Test 1: Policy Service'));
        const policyResponse = await axios.get('http://localhost:3001/api/policies/POL123');
        console.log(chalk.green('✅ Policy retrieved:'), policyResponse.data.fetchedFrom);
        
        // Test 2: Claims Service
        console.log(chalk.yellow('\nTest 2: Claims Service'));
        const claimResponse = await axios.post('http://localhost:3002/api/claims', {
            policyId: 'POL123',
            customerId: 'CUST456',
            amount: 2500,
            description: 'Test claim'
        });
        console.log(chalk.green('✅ Claim submitted:'), claimResponse.data.claim.id);
        
        // Test 3: Cache Invalidation
        console.log(chalk.yellow('\nTest 3: Cache Invalidation'));
        await axios.put('http://localhost:3001/api/policies/POL123', {
            premium: 1800
        });
        console.log(chalk.green('✅ Policy updated and cache invalidated'));
        
        // Test 4: Service Health
        console.log(chalk.yellow('\nTest 4: Service Health Checks'));
        const policyHealth = await axios.get('http://localhost:3001/health');
        const claimsHealth = await axios.get('http://localhost:3002/health');
        console.log(chalk.green('✅ Policy Service:'), policyHealth.data.status);
        console.log(chalk.green('✅ Claims Service:'), claimsHealth.data.status);
        
        // Test 5: Cross-Service Communication
        console.log(chalk.yellow('\nTest 5: Cross-Service Communication'));
        const claimsForPolicy = await axios.get('http://localhost:3002/api/claims/policy/POL123');
        console.log(chalk.green('✅ Retrieved claims for policy:'), claimsForPolicy.data.length);
        
        console.log(chalk.blue('\n✅ All tests passed!\n'));
        
    } catch (error) {
        console.error(chalk.red('❌ Test failed:'), error.message);
        process.exit(1);
    }
}

// Run tests
setTimeout(() => {
    testMicroservices();
}, 3000);
```

---

## Part 5: Monitoring and Observability (5 minutes)

### Step 1: Create Service Monitor

Create `src/monitor.js`:
```javascript
const redis = require('redis');
const chalk = require('chalk');

async function monitorServices() {
    const client = redis.createClient({
        url: 'redis://localhost:6379'
    });
    
    await client.connect();
    
    console.log(chalk.blue('📊 Microservices Monitor\n'));
    
    // Monitor service registry
    setInterval(async () => {
        console.clear();
        console.log(chalk.blue('📊 Microservices Monitor'));
        console.log(chalk.gray('=' .repeat(50)));
        
        // Get all services
        const serviceKeys = await client.keys('service:*');
        console.log(chalk.yellow('\n🔧 Active Services:'));
        
        for (const key of serviceKeys) {
            const service = await client.hGetAll(key);
            const name = service.name || key.split(':')[1];
            console.log(chalk.green(`  ✅ ${name}`), 
                       chalk.gray(`Last heartbeat: ${service.lastHeartbeat || 'N/A'}`));
        }
        
        // Monitor queues
        const queueLength = await client.lLen('claims:queue');
        console.log(chalk.yellow('\n📬 Message Queues:'));
        console.log(`  Claims Queue: ${queueLength} messages`);
        
        // Monitor cache
        const cacheKeys = await client.keys('cache:*');
        console.log(chalk.yellow('\n💾 Cache Status:'));
        console.log(`  Cached Items: ${cacheKeys.length}`);
        
        // Show recent events
        console.log(chalk.yellow('\n📡 Recent Events:'));
        console.log(chalk.gray('  Monitoring pub/sub channels...'));
        
        console.log(chalk.gray('\n' + '=' .repeat(50)));
        console.log(chalk.gray('Press Ctrl+C to exit'));
        
    }, 2000);
    
    // Subscribe to all events for monitoring
    const subscriber = client.duplicate();
    await subscriber.connect();
    
    await subscriber.pSubscribe('*:*', (message, channel) => {
        const data = JSON.parse(message);
        console.log(chalk.cyan(`\n[Event] ${channel}:`), data);
    });
}

monitorServices().catch(console.error);
```

### Step 2: Test Complete System

```bash
# Terminal 1: Start Policy Service
npm run start:policy

# Terminal 2: Start Claims Service  
npm run start:claims

# Terminal 3: Start Monitor
npm run monitor

# Terminal 4: Run Integration Tests
npm test

# Or start all services at once
npm run start:all
```

---

## 📋 Lab Summary

### What You've Accomplished
✅ Set up multiple microservices with Redis integration  
✅ Implemented distributed caching with invalidation  
✅ Created service discovery pattern  
✅ Built inter-service communication with pub/sub  
✅ Developed shared session management  
✅ Implemented service health monitoring  

### Key Patterns Mastered
- **Service Discovery:** Automatic service registration and discovery
- **Distributed Caching:** Cross-service cache with invalidation
- **Event-Driven Architecture:** Pub/sub for service communication
- **Queue Processing:** Asynchronous task processing
- **Health Monitoring:** Service health checks and heartbeats
- **Session Sharing:** Cross-service session management

### Production Considerations
- Use Redis Cluster for high availability
- Implement circuit breakers for service calls
- Add distributed tracing for debugging
- Use Redis Streams for more robust event sourcing
- Implement proper authentication between services
- Add rate limiting and throttling
- Use container orchestration (Kubernetes)
- Implement proper logging and monitoring

### Next Steps
- Add API Gateway for unified entry point
- Implement distributed transactions with Saga pattern
- Add service mesh for advanced traffic management
- Implement CQRS pattern with Redis
- Add distributed locking for coordination
- Build event sourcing with Redis Streams

## 🎯 Challenge Exercises

1. **Add Customer Service:** Create a third service for customer management
2. **Implement Saga Pattern:** Add distributed transaction coordination
3. **Add Circuit Breaker:** Implement fault tolerance between services
4. **Build API Gateway:** Create unified API entry point
5. **Add Distributed Tracing:** Implement request tracing across services

## 📚 Additional Resources

- Redis Microservices Patterns
- Distributed Systems with Redis
- Event-Driven Architecture Guide
- Service Mesh Concepts
- Container Orchestration Best Practices

---

**Congratulations!** You've successfully implemented a microservices architecture with Redis for caching and communication!
EOF

# Create environment configuration
echo "🔧 Creating .env.example..."
cat > .env.example << 'EOF'
# Redis Configuration
REDIS_URL=redis://localhost:6379

# Policy Service
POLICY_SERVICE_PORT=3001
POLICY_SERVICE_HOST=localhost

# Claims Service
CLAIMS_SERVICE_PORT=3002
CLAIMS_SERVICE_HOST=localhost

# Customer Service
CUSTOMER_SERVICE_PORT=3003
CUSTOMER_SERVICE_HOST=localhost

# Service Configuration
SERVICE_HEARTBEAT_INTERVAL=10000
CACHE_TTL=300

# Environment
NODE_ENV=development
LOG_LEVEL=info
EOF

# Create sample data loader script
echo "📊 Creating scripts/load-sample-data.sh..."
mkdir -p scripts
cat > scripts/load-sample-data.sh << 'EOFSCRIPT'
#!/bin/bash

echo "📦 Loading sample data for Microservices Lab..."

# Load sample data into Redis
redis-cli <<'REDIS_EOF'
# Clear existing data
FLUSHDB

# Sample policies
HSET policy:POL001 id POL001 type AUTO customerId CUST001 premium 1200 coverage 100000 status active
HSET policy:POL002 id POL002 type HOME customerId CUST002 premium 800 coverage 250000 status active
HSET policy:POL003 id POL003 type LIFE customerId CUST003 premium 500 coverage 500000 status active

# Sample customers
HSET customer:CUST001 id CUST001 name "John Doe" email "john@example.com" tier premium
HSET customer:CUST002 id CUST002 name "Jane Smith" email "jane@example.com" tier standard
HSET customer:CUST003 id CUST003 name "Bob Johnson" email "bob@example.com" tier basic

# Sample claims
LPUSH claims:queue '{"id":"CLM001","policyId":"POL001","amount":1500,"status":"pending"}'
LPUSH claims:queue '{"id":"CLM002","policyId":"POL002","amount":3000,"status":"pending"}'

# Service registry entries (will be overwritten by services)
HSET service:registry policyService "localhost:3001" claimsService "localhost:3002"

# Configuration
SET config:cache:ttl 300
SET config:queue:timeout 30

echo "Sample data loaded successfully!"
echo ""
echo "Data Summary:"
echo "============="
echo "Policies loaded: 3"
KEYS policy:*
echo ""
echo "Customers loaded: 3"
KEYS customer:*
echo ""
echo "Claims in queue:"
LLEN claims:queue

REDIS_EOF

echo ""
echo "✅ Sample data loaded successfully!"
EOFSCRIPT

chmod +x scripts/load-sample-data.sh

# Create Customer Service (bonus service)
echo "👥 Creating services/customer-service/index.js..."
cat > services/customer-service/index.js << 'EOF'
const express = require('express');
const RedisManager = require('../../shared/redis-client');
const app = express();
app.use(express.json());

const redis = new RedisManager('customer-service');
const PORT = process.env.CUSTOMER_SERVICE_PORT || 3003;

async function initService() {
    await redis.connect();
    
    // Subscribe to customer events
    await redis.subscribeToEvents('customer:events', async (data) => {
        console.log(`[Customer Service] Customer event:`, data);
    });
}

// Get customer with caching
app.get('/api/customers/:id', async (req, res) => {
    const customerId = req.params.id;
    const cacheKey = `cache:customer:${customerId}`;
    
    try {
        let customer = await redis.cacheGet(cacheKey);
        
        if (!customer) {
            // Get from Redis hash
            customer = await redis.client.hGetAll(`customer:${customerId}`);
            
            if (Object.keys(customer).length === 0) {
                return res.status(404).json({ error: 'Customer not found' });
            }
            
            // Cache for 5 minutes
            await redis.cacheSet(cacheKey, customer, 300);
        }
        
        res.json(customer);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Update customer
app.put('/api/customers/:id', async (req, res) => {
    const customerId = req.params.id;
    
    try {
        // Update in Redis hash
        await redis.client.hSet(`customer:${customerId}`, req.body);
        
        // Invalidate cache
        await redis.invalidateCache(`cache:customer:${customerId}`);
        
        // Notify other services
        await redis.publishEvent('customer:updated', {
            customerId,
            changes: req.body
        });
        
        res.json({ message: 'Customer updated', customerId });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Health check
app.get('/health', async (req, res) => {
    res.json({
        service: 'customer-service',
        status: 'healthy',
        timestamp: new Date().toISOString()
    });
});

initService().then(() => {
    app.listen(PORT, () => {
        console.log(`✅ Customer Service running on port ${PORT}`);
    });
});
EOF

# Create README
echo "📚 Creating README.md..."
cat > README.md << 'EOF'
# Lab 15: Simple Microservices Pattern

**Duration:** 45 minutes  
**Focus:** JavaScript-based microservices with Redis for caching and communication  
**Technologies:** Node.js, Express, Redis, Axios

## 📁 Project Structure

```
lab15-microservices-integration/
├── lab15.md                    # Complete lab instructions (START HERE)
├── services/
│   ├── policy-service/         # Policy management service
│   ├── claims-service/         # Claims processing service
│   └── customer-service/       # Customer management service
├── shared/
│   └── redis-client.js         # Shared Redis client with service discovery
├── src/
│   ├── service-discovery.js    # Service discovery implementation
│   └── monitor.js              # Service monitoring dashboard
├── tests/
│   └── test-integration.js     # Integration tests
├── scripts/
│   └── load-sample-data.sh     # Sample data loader
├── package.json                # Node.js dependencies
├── .env.example                # Environment configuration template
└── README.md                   # This file
```

## 🚀 Quick Start

1. **Install Dependencies:**
   ```bash
   npm install
   ```

2. **Start Redis:**
   ```bash
   docker run -d --name redis-microservices-lab15 -p 6379:6379 redis:7-alpine
   ```

3. **Load Sample Data:**
   ```bash
   npm run load-data
   ```

4. **Start All Services:**
   ```bash
   # Option 1: Start all at once
   npm run start:all
   
   # Option 2: Start individually (in separate terminals)
   npm run start:policy
   npm run start:claims
   npm run start:customer
   ```

5. **Monitor Services:**
   ```bash
   npm run monitor
   ```

6. **Run Tests:**
   ```bash
   npm test
   ```

## 🔧 Service Endpoints

### Policy Service (Port 3001)
- `GET /api/policies/:id` - Get policy with caching
- `PUT /api/policies/:id` - Update policy and invalidate cache
- `GET /health` - Service health check

### Claims Service (Port 3002)
- `POST /api/claims` - Submit new claim
- `GET /api/claims/policy/:policyId` - Get claims for policy
- `GET /health` - Service health check

### Customer Service (Port 3003)
- `GET /api/customers/:id` - Get customer with caching
- `PUT /api/customers/:id` - Update customer
- `GET /health` - Service health check

## 📊 Key Features

- **Service Discovery:** Automatic service registration and discovery
- **Distributed Caching:** Cross-service cache with invalidation
- **Event-Driven Communication:** Pub/sub for service coordination
- **Queue Processing:** Asynchronous claim processing
- **Health Monitoring:** Service health checks and heartbeats
- **Session Sharing:** Cross-service session management

## 🎯 Learning Objectives

- ✅ Implement microservices with Redis integration
- ✅ Build distributed caching strategies
- ✅ Create service discovery patterns
- ✅ Implement event-driven architecture
- ✅ Develop inter-service communication
- ✅ Apply monitoring and observability

## 📚 Next Steps

After completing this lab, consider:
- Adding API Gateway for unified entry
- Implementing Circuit Breaker pattern
- Adding distributed tracing
- Using Redis Streams for event sourcing
- Implementing CQRS pattern
- Adding container orchestration

---

**Ready to start?** Open `lab15.md` and begin building your microservices architecture! 🚀
EOF

# Create .gitignore
echo "🚫 Creating .gitignore..."
cat > .gitignore << 'EOF'
# Dependencies
node_modules/
package-lock.json

# Environment
.env
.env.local
.env.*.local

# Logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
lerna-debug.log*

# Runtime data
pids
*.pid
*.seed
*.pid.lock

# Directory for instrumented libs
lib-cov

# Coverage directory
coverage
*.lcov
.nyc_output

# OS files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# Testing
test-results/
*.test.js.snap

# Production builds
dist/
build/

# Redis dump
dump.rdb
*.rdb
appendonly.aof

# Temporary files
*.tmp
*.temp
tmp/
temp/
EOF

echo ""
echo "✅ Lab 15 build script completed successfully!"
echo ""
echo "📂 Project structure created:"
echo "   ${LAB_DIR}/"
echo "   ├── lab15.md                    📋 Complete lab instructions"
echo "   ├── services/"
echo "   │   ├── policy-service/         🏢 Policy management"
echo "   │   ├── claims-service/         📝 Claims processing"
echo "   │   └── customer-service/       👥 Customer management"
echo "   ├── shared/"
echo "   │   └── redis-client.js         🔌 Shared Redis client"
echo "   ├── src/"
echo "   │   ├── service-discovery.js    🔍 Service discovery"
echo "   │   └── monitor.js              📊 Service monitor"
echo "   ├── tests/"
echo "   │   └── test-integration.js     🧪 Integration tests"
echo "   ├── scripts/"
echo "   │   └── load-sample-data.sh     📦 Data loader"
echo "   ├── package.json                📦 Dependencies"
echo "   ├── .env.example                🔐 Environment template"
echo "   └── README.md                   📖 Documentation"
echo ""
echo "🎯 NEXT STEPS:"
echo "   1. cd ${LAB_DIR}"
echo "   2. npm install"
echo "   3. docker run -d --name redis-microservices-lab15 -p 6379:6379 redis:7-alpine"
echo "   4. npm run load-data"
echo "   5. npm run start:all  (or start each service individually)"
echo "   6. npm run monitor    (in separate terminal)"
echo "   7. npm test          (in another terminal)"
echo ""
echo "🚀 MICROSERVICES FEATURES:"
echo "   📡 Service Discovery: Auto-registration and discovery"
echo "   💾 Distributed Cache: Cross-service caching with invalidation"
echo "   🔄 Event-Driven: Pub/sub communication between services"
echo "   📬 Queue Processing: Async task processing"
echo "   ❤️ Health Checks: Service monitoring and heartbeats"
echo ""
echo "🎉 READY TO START LAB 15!"
echo "   Open lab15.md for the complete microservices implementation!"