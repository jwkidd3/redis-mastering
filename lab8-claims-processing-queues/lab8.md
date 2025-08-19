# Lab 8: Claims Processing Queues with Lists

**Duration:** 45 minutes  
**Objective:** Implement claims processing and workflow system using Redis lists

## 🎯 Learning Objectives

By the end of this lab, you will be able to:
- Build claims submission queues using Redis lists
- Implement FIFO processing for standard claims
- Create priority queues for urgent claims
- Use blocking operations for real-time processing
- Monitor claims workflow and status tracking
- Handle error scenarios with dead letter queues

---

## Part 1: Environment Setup (5 minutes)

### Step 1: Project Initialization

Create your working directory and initialize the Node.js project:

```bash
# Create project directory
mkdir claims-processing-system
cd claims-processing-system

# Initialize Node.js project
npm init -y

# Install required dependencies
npm install redis uuid
```

### Step 2: Connection Configuration

Create the Redis connection module:

**File: `src/redis-client.js`**
```javascript
const redis = require('redis');

class RedisClient {
    constructor() {
        this.client = redis.createClient({
            host: 'redis-server.training.com',  // Replace with your server
            port: 6379,
            retry_strategy: (options) => {
                if (options.error && options.error.code === 'ECONNREFUSED') {
                    return new Error('Redis server refused connection');
                }
                if (options.total_retry_time > 1000 * 60 * 60) {
                    return new Error('Retry time exhausted');
                }
                return Math.min(options.attempt * 100, 3000);
            }
        });

        this.client.on('error', (err) => {
            console.error('Redis Client Error:', err);
        });

        this.client.on('connect', () => {
            console.log('✅ Connected to Redis server');
        });
    }

    async connect() {
        if (!this.client.connected) {
            await this.client.connect();
        }
        return this.client;
    }

    async disconnect() {
        await this.client.quit();
    }

    getClient() {
        return this.client;
    }
}

module.exports = RedisClient;
```

### Step 3: Test Connection

```bash
# Test Redis connection
node -e "
const RedisClient = require('./src/redis-client');
const client = new RedisClient();
client.connect().then(() => {
    console.log('Connection test successful');
    client.disconnect();
}).catch(console.error);
"
```

---

## Part 2: Claims Submission System (15 minutes)

### Step 1: Claims Data Model

Create the claims model and submission system:

**File: `src/claims-model.js`**
```javascript
const { v4: uuidv4 } = require('uuid');

class Claim {
    constructor(data) {
        this.id = data.id || uuidv4();
        this.policyNumber = data.policyNumber;
        this.customerName = data.customerName;
        this.claimType = data.claimType; // 'auto', 'home', 'life', 'health'
        this.priority = data.priority || 'standard'; // 'urgent', 'standard'
        this.amount = parseFloat(data.amount);
        this.description = data.description;
        this.submittedAt = data.submittedAt || new Date().toISOString();
        this.status = data.status || 'submitted';
        this.assignedTo = data.assignedTo || null;
        this.documents = data.documents || [];
    }

    toJSON() {
        return {
            id: this.id,
            policyNumber: this.policyNumber,
            customerName: this.customerName,
            claimType: this.claimType,
            priority: this.priority,
            amount: this.amount,
            description: this.description,
            submittedAt: this.submittedAt,
            status: this.status,
            assignedTo: this.assignedTo,
            documents: this.documents
        };
    }

    static fromJSON(jsonString) {
        const data = JSON.parse(jsonString);
        return new Claim(data);
    }
}

module.exports = Claim;
```

### Step 2: Claims Queue Manager

**File: `src/claims-queue.js`**
```javascript
const RedisClient = require('./redis-client');
const Claim = require('./claims-model');

class ClaimsQueue {
    constructor() {
        this.redisClient = new RedisClient();
        this.client = null;
        
        // Queue names
        this.STANDARD_QUEUE = 'claims:queue:standard';
        this.URGENT_QUEUE = 'claims:queue:urgent';
        this.PROCESSING_QUEUE = 'claims:queue:processing';
        this.COMPLETED_QUEUE = 'claims:queue:completed';
        this.FAILED_QUEUE = 'claims:queue:failed';
        
        // Claim storage
        this.CLAIMS_HASH = 'claims:data';
    }

    async connect() {
        this.client = await this.redisClient.connect();
    }

    async disconnect() {
        await this.redisClient.disconnect();
    }

    async submitClaim(claimData) {
        const claim = new Claim(claimData);
        
        try {
            // Store claim data in hash
            await this.client.hSet(this.CLAIMS_HASH, claim.id, JSON.stringify(claim.toJSON()));
            
            // Add to appropriate queue based on priority
            const queueName = claim.priority === 'urgent' ? this.URGENT_QUEUE : this.STANDARD_QUEUE;
            await this.client.lPush(queueName, claim.id);
            
            console.log(`✅ Claim ${claim.id} submitted to ${queueName}`);
            return claim.id;
        } catch (error) {
            console.error('Error submitting claim:', error);
            throw error;
        }
    }

    async getClaimData(claimId) {
        try {
            const claimJson = await this.client.hGet(this.CLAIMS_HASH, claimId);
            return claimJson ? Claim.fromJSON(claimJson) : null;
        } catch (error) {
            console.error('Error retrieving claim data:', error);
            return null;
        }
    }

    async updateClaimStatus(claimId, status, assignedTo = null) {
        try {
            const claim = await this.getClaimData(claimId);
            if (claim) {
                claim.status = status;
                if (assignedTo) claim.assignedTo = assignedTo;
                
                await this.client.hSet(this.CLAIMS_HASH, claimId, JSON.stringify(claim.toJSON()));
                console.log(`📝 Claim ${claimId} status updated to: ${status}`);
            }
        } catch (error) {
            console.error('Error updating claim status:', error);
        }
    }

    async getQueueLength(queueName) {
        return await this.client.lLen(queueName);
    }

    async getQueueStats() {
        return {
            standardQueue: await this.getQueueLength(this.STANDARD_QUEUE),
            urgentQueue: await this.getQueueLength(this.URGENT_QUEUE),
            processing: await this.getQueueLength(this.PROCESSING_QUEUE),
            completed: await this.getQueueLength(this.COMPLETED_QUEUE),
            failed: await this.getQueueLength(this.FAILED_QUEUE)
        };
    }

    async viewQueue(queueName, count = 10) {
        const claimIds = await this.client.lRange(queueName, 0, count - 1);
        const claims = [];
        
        for (const id of claimIds) {
            const claim = await this.getClaimData(id);
            if (claim) claims.push(claim);
        }
        
        return claims;
    }
}

module.exports = ClaimsQueue;
```

### Step 3: Test Claims Submission

**File: `examples/submit-claims.js`**
```javascript
const ClaimsQueue = require('../src/claims-queue');

async function submitTestClaims() {
    const queue = new ClaimsQueue();
    await queue.connect();

    // Sample claims data
    const sampleClaims = [
        {
            policyNumber: 'POL-2024-001',
            customerName: 'John Smith',
            claimType: 'auto',
            priority: 'standard',
            amount: 5000,
            description: 'Rear-end collision damage'
        },
        {
            policyNumber: 'POL-2024-002',
            customerName: 'Sarah Johnson',
            claimType: 'home',
            priority: 'urgent',
            amount: 15000,
            description: 'Water damage from burst pipe'
        },
        {
            policyNumber: 'POL-2024-003',
            customerName: 'Mike Davis',
            claimType: 'health',
            priority: 'standard',
            amount: 2500,
            description: 'Emergency room visit'
        },
        {
            policyNumber: 'POL-2024-004',
            customerName: 'Lisa Brown',
            claimType: 'auto',
            priority: 'urgent',
            amount: 8000,
            description: 'Total loss from accident'
        }
    ];

    try {
        for (const claimData of sampleClaims) {
            const claimId = await queue.submitClaim(claimData);
            console.log(`Submitted claim: ${claimId} (${claimData.priority})`);
        }

        // Display queue statistics
        const stats = await queue.getQueueStats();
        console.log('\n📊 Queue Statistics:');
        console.log(`Standard Queue: ${stats.standardQueue} claims`);
        console.log(`Urgent Queue: ${stats.urgentQueue} claims`);
        
    } finally {
        await queue.disconnect();
    }
}

submitTestClaims().catch(console.error);
```

Run the submission test:
```bash
node examples/submit-claims.js
```

---

## Part 3: Claims Processing System (15 minutes)

### Step 1: Claims Processor

**File: `src/claims-processor.js`**
```javascript
const ClaimsQueue = require('./claims-queue');

class ClaimsProcessor extends ClaimsQueue {
    constructor(processorId) {
        super();
        this.processorId = processorId;
        this.isProcessing = false;
        this.processedCount = 0;
    }

    async processNextClaim() {
        try {
            // Try urgent queue first, then standard queue
            let claimId = await this.client.rPop(this.URGENT_QUEUE);
            let queueType = 'urgent';
            
            if (!claimId) {
                claimId = await this.client.rPop(this.STANDARD_QUEUE);
                queueType = 'standard';
            }

            if (!claimId) {
                console.log('📭 No claims in queue');
                return null;
            }

            // Move claim to processing queue
            await this.client.lPush(this.PROCESSING_QUEUE, claimId);
            await this.updateClaimStatus(claimId, 'processing', this.processorId);

            console.log(`🔄 Processing claim ${claimId} from ${queueType} queue`);

            // Simulate processing time
            const processingTime = queueType === 'urgent' ? 2000 : 5000;
            await new Promise(resolve => setTimeout(resolve, processingTime));

            // Get claim details for processing
            const claim = await this.getClaimData(claimId);
            if (claim) {
                const success = await this.processClaim(claim);
                
                if (success) {
                    await this.completeClaim(claimId);
                } else {
                    await this.failClaim(claimId);
                }
            }

            this.processedCount++;
            return claimId;

        } catch (error) {
            console.error('Error processing claim:', error);
            return null;
        }
    }

    async processClaim(claim) {
        console.log(`📋 Processing ${claim.claimType} claim for ${claim.customerName}`);
        console.log(`   Amount: $${claim.amount.toLocaleString()}`);
        console.log(`   Policy: ${claim.policyNumber}`);

        // Simulate claim validation logic
        const isValid = claim.amount > 0 && claim.policyNumber && claim.customerName;
        
        // Simulate approval logic (90% approval rate)
        const isApproved = Math.random() > 0.1;

        return isValid && isApproved;
    }

    async completeClaim(claimId) {
        try {
            // Remove from processing queue
            await this.client.lRem(this.PROCESSING_QUEUE, 1, claimId);
            
            // Add to completed queue
            await this.client.lPush(this.COMPLETED_QUEUE, claimId);
            
            // Update status
            await this.updateClaimStatus(claimId, 'completed');
            
            console.log(`✅ Claim ${claimId} completed successfully`);
        } catch (error) {
            console.error('Error completing claim:', error);
        }
    }

    async failClaim(claimId) {
        try {
            // Remove from processing queue
            await this.client.lRem(this.PROCESSING_QUEUE, 1, claimId);
            
            // Add to failed queue
            await this.client.lPush(this.FAILED_QUEUE, claimId);
            
            // Update status
            await this.updateClaimStatus(claimId, 'failed');
            
            console.log(`❌ Claim ${claimId} failed processing`);
        } catch (error) {
            console.error('Error failing claim:', error);
        }
    }

    async startProcessing() {
        this.isProcessing = true;
        console.log(`🚀 Claims processor ${this.processorId} started`);

        while (this.isProcessing) {
            const claimId = await this.processNextClaim();
            
            if (!claimId) {
                // No claims available, wait before checking again
                await new Promise(resolve => setTimeout(resolve, 3000));
            }
        }
    }

    async stopProcessing() {
        this.isProcessing = false;
        console.log(`🛑 Claims processor ${this.processorId} stopped`);
        console.log(`📊 Processed ${this.processedCount} claims`);
    }

    // Blocking pop operation for real-time processing
    async waitForClaim(timeout = 30) {
        try {
            // Use BRPOP to wait for claims (checks urgent queue first)
            const result = await this.client.brPop([this.URGENT_QUEUE, this.STANDARD_QUEUE], timeout);
            
            if (result) {
                const { key, element: claimId } = result;
                const queueType = key.includes('urgent') ? 'urgent' : 'standard';
                
                console.log(`🔔 New claim ${claimId} received from ${queueType} queue`);
                
                // Move to processing queue
                await this.client.lPush(this.PROCESSING_QUEUE, claimId);
                await this.updateClaimStatus(claimId, 'processing', this.processorId);
                
                return { claimId, queueType };
            }
            
            return null;
        } catch (error) {
            console.error('Error in blocking pop:', error);
            return null;
        }
    }
}

module.exports = ClaimsProcessor;
```

### Step 2: Processing Example

**File: `examples/process-claims.js`**
```javascript
const ClaimsProcessor = require('../src/claims-processor');

async function startClaimsProcessor() {
    const processor = new ClaimsProcessor('PROCESSOR-001');
    await processor.connect();

    console.log('🎯 Starting claims processor...');
    console.log('Press Ctrl+C to stop processing\n');

    // Handle graceful shutdown
    process.on('SIGINT', async () => {
        console.log('\n🛑 Shutting down processor...');
        await processor.stopProcessing();
        await processor.disconnect();
        process.exit(0);
    });

    try {
        // Process any existing claims first
        console.log('📋 Processing existing claims...');
        let claimId;
        do {
            claimId = await processor.processNextClaim();
            if (claimId) {
                await new Promise(resolve => setTimeout(resolve, 1000));
            }
        } while (claimId);

        console.log('\n⏳ Waiting for new claims...');
        
        // Then wait for new claims with blocking operations
        while (true) {
            const result = await processor.waitForClaim(10);
            
            if (result) {
                const claim = await processor.getClaimData(result.claimId);
                if (claim) {
                    const success = await processor.processClaim(claim);
                    
                    if (success) {
                        await processor.completeClaim(result.claimId);
                    } else {
                        await processor.failClaim(result.claimId);
                    }
                }
            } else {
                console.log('⏰ No new claims received, continuing to wait...');
            }
        }

    } catch (error) {
        console.error('Processing error:', error);
    } finally {
        await processor.disconnect();
    }
}

startClaimsProcessor().catch(console.error);
```

### Step 3: Test Processing

```bash
# In terminal 1: Start the processor
node examples/process-claims.js

# In terminal 2: Submit more claims
node examples/submit-claims.js
```

---

## Part 4: Monitoring and Analytics (10 minutes)

### Step 1: Queue Monitor

**File: `src/queue-monitor.js`**
```javascript
const ClaimsQueue = require('./claims-queue');

class QueueMonitor extends ClaimsQueue {
    constructor() {
        super();
        this.startTime = new Date();
    }

    async displayQueueStatus() {
        const stats = await this.getQueueStats();
        
        console.clear();
        console.log('📊 Claims Processing Dashboard');
        console.log('================================');
        console.log(`🕐 Running since: ${this.startTime.toLocaleTimeString()}`);
        console.log(`📅 Current time: ${new Date().toLocaleTimeString()}\n`);
        
        console.log('Queue Status:');
        console.log(`├─ 🟡 Urgent Queue:     ${stats.urgentQueue.toString().padStart(3)} claims`);
        console.log(`├─ 🔵 Standard Queue:   ${stats.standardQueue.toString().padStart(3)} claims`);
        console.log(`├─ ⚙️  Processing:       ${stats.processing.toString().padStart(3)} claims`);
        console.log(`├─ ✅ Completed:        ${stats.completed.toString().padStart(3)} claims`);
        console.log(`└─ ❌ Failed:           ${stats.failed.toString().padStart(3)} claims\n`);
        
        const total = stats.urgentQueue + stats.standardQueue + stats.processing + stats.completed + stats.failed;
        console.log(`📈 Total Claims: ${total}`);
        
        if (total > 0) {
            const completionRate = ((stats.completed / total) * 100).toFixed(1);
            const failureRate = ((stats.failed / total) * 100).toFixed(1);
            console.log(`📊 Completion Rate: ${completionRate}%`);
            console.log(`📊 Failure Rate: ${failureRate}%`);
        }
    }

    async showRecentActivity() {
        console.log('\n🎯 Recent Activity:');
        console.log('===================');
        
        // Show recent completed claims
        const recentCompleted = await this.viewQueue(this.COMPLETED_QUEUE, 3);
        if (recentCompleted.length > 0) {
            console.log('✅ Recently Completed:');
            recentCompleted.forEach(claim => {
                console.log(`   • ${claim.customerName} - $${claim.amount.toLocaleString()} (${claim.claimType})`);
            });
        }
        
        // Show failed claims
        const recentFailed = await this.viewQueue(this.FAILED_QUEUE, 2);
        if (recentFailed.length > 0) {
            console.log('\n❌ Recently Failed:');
            recentFailed.forEach(claim => {
                console.log(`   • ${claim.customerName} - $${claim.amount.toLocaleString()} (${claim.claimType})`);
            });
        }
        
        // Show processing claims
        const currentProcessing = await this.viewQueue(this.PROCESSING_QUEUE, 3);
        if (currentProcessing.length > 0) {
            console.log('\n⚙️ Currently Processing:');
            currentProcessing.forEach(claim => {
                console.log(`   • ${claim.customerName} - $${claim.amount.toLocaleString()} (${claim.assignedTo})`);
            });
        }
    }

    async startMonitoring(interval = 5000) {
        console.log('🖥️ Starting queue monitor...');
        console.log('Press Ctrl+C to stop monitoring\n');

        const updateDisplay = async () => {
            try {
                await this.displayQueueStatus();
                await this.showRecentActivity();
                console.log('\n⏱️ Refreshing in 5 seconds...');
            } catch (error) {
                console.error('Monitor error:', error);
            }
        };

        // Initial display
        await updateDisplay();

        // Set up recurring updates
        const monitorInterval = setInterval(updateDisplay, interval);

        // Handle graceful shutdown
        process.on('SIGINT', () => {
            console.log('\n🛑 Stopping monitor...');
            clearInterval(monitorInterval);
            this.disconnect();
            process.exit(0);
        });
    }
}

module.exports = QueueMonitor;
```

**File: `examples/monitor-queues.js`**
```javascript
const QueueMonitor = require('../src/queue-monitor');

async function startMonitoring() {
    const monitor = new QueueMonitor();
    await monitor.connect();
    
    await monitor.startMonitoring();
}

startMonitoring().catch(console.error);
```

### Step 2: Performance Analytics

**File: `examples/queue-analytics.js`**
```javascript
const ClaimsQueue = require('../src/claims-queue');

class QueueAnalytics extends ClaimsQueue {
    async generateReport() {
        console.log('📊 Claims Processing Analytics Report');
        console.log('=====================================\n');

        // Queue statistics
        const stats = await this.getQueueStats();
        const total = Object.values(stats).reduce((a, b) => a + b, 0);
        
        console.log('📋 Queue Summary:');
        Object.entries(stats).forEach(([queue, count]) => {
            const percentage = total > 0 ? ((count / total) * 100).toFixed(1) : '0.0';
            console.log(`   ${queue.padEnd(15)}: ${count.toString().padStart(3)} (${percentage}%)`);
        });

        // Analyze claim types
        await this.analyzeClaimTypes();
        
        // Analyze priorities
        await this.analyzePriorities();
        
        // Performance metrics
        await this.calculatePerformanceMetrics();
    }

    async analyzeClaimTypes() {
        console.log('\n🏷️ Claims by Type:');
        
        const allQueueNames = [
            this.STANDARD_QUEUE, this.URGENT_QUEUE, 
            this.PROCESSING_QUEUE, this.COMPLETED_QUEUE, this.FAILED_QUEUE
        ];
        
        const claimTypes = {};
        
        for (const queueName of allQueueNames) {
            const claims = await this.viewQueue(queueName, 50);
            claims.forEach(claim => {
                claimTypes[claim.claimType] = (claimTypes[claim.claimType] || 0) + 1;
            });
        }
        
        Object.entries(claimTypes)
            .sort(([,a], [,b]) => b - a)
            .forEach(([type, count]) => {
                console.log(`   ${type.padEnd(10)}: ${count} claims`);
            });
    }

    async analyzePriorities() {
        console.log('\n⚡ Claims by Priority:');
        
        const urgentCount = await this.getQueueLength(this.URGENT_QUEUE);
        const standardCount = await this.getQueueLength(this.STANDARD_QUEUE);
        
        console.log(`   Urgent:    ${urgentCount} claims`);
        console.log(`   Standard:  ${standardCount} claims`);
        
        if (urgentCount + standardCount > 0) {
            const urgentPercentage = ((urgentCount / (urgentCount + standardCount)) * 100).toFixed(1);
            console.log(`   Urgent %:  ${urgentPercentage}%`);
        }
    }

    async calculatePerformanceMetrics() {
        console.log('\n⚡ Performance Metrics:');
        
        const stats = await this.getQueueStats();
        const processed = stats.completed + stats.failed;
        const pending = stats.urgentQueue + stats.standardQueue;
        
        if (processed > 0) {
            const successRate = ((stats.completed / processed) * 100).toFixed(1);
            console.log(`   Success Rate:    ${successRate}%`);
            console.log(`   Failure Rate:    ${(100 - successRate).toFixed(1)}%`);
        }
        
        console.log(`   Throughput:      ${processed} claims processed`);
        console.log(`   Backlog:         ${pending} claims pending`);
        console.log(`   Active:          ${stats.processing} claims in progress`);
    }
}

async function runAnalytics() {
    const analytics = new QueueAnalytics();
    await analytics.connect();
    
    try {
        await analytics.generateReport();
    } finally {
        await analytics.disconnect();
    }
}

runAnalytics().catch(console.error);
```

---

## Lab Completion Checklist

- [ ] Successfully connected to Redis and created claims queue system
- [ ] Implemented claims submission with priority handling
- [ ] Built claims processing system with FIFO and priority queues
- [ ] Used blocking operations for real-time claim processing
- [ ] Created monitoring dashboard for queue status
- [ ] Implemented error handling and dead letter queues
- [ ] Generated performance analytics and reports
- [ ] Tested complete workflow from submission to completion

---

## Testing Your Implementation

### Complete Workflow Test

```bash
# Terminal 1: Start the monitor
node examples/monitor-queues.js

# Terminal 2: Start the processor
node examples/process-claims.js

# Terminal 3: Submit claims
node examples/submit-claims.js

# Terminal 4: Generate analytics
node examples/queue-analytics.js
```

### Redis Insight Verification

1. **Open Redis Insight** and connect to your server
2. **Browse keys** to see queue structures:
   - `claims:queue:standard`
   - `claims:queue:urgent` 
   - `claims:queue:processing`
   - `claims:queue:completed`
   - `claims:data` (hash containing claim details)
3. **Monitor list lengths** and data flow
4. **Use CLI in Redis Insight** to inspect queues manually

---

## Key Takeaways

🎉 **Congratulations!** You've built a complete claims processing system using Redis lists. You now understand:

1. **Queue Management** - FIFO processing with Redis lists
2. **Priority Handling** - Separate queues for urgent vs standard claims
3. **Real-time Processing** - Blocking operations for immediate response
4. **Workflow Tracking** - Status management through multiple queues
5. **Error Handling** - Dead letter queues for failed processing
6. **Performance Monitoring** - Analytics and reporting systems

**Next Lab Preview:** Lab 9 will explore analytics with Sets and Sorted Sets for advanced data analysis.
