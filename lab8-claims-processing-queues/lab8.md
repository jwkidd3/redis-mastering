# Lab 8: Claims Processing Queues

**Duration:** 45 minutes  
**Objective:** Build robust claims processing queues using JavaScript and Redis Lists for efficient workflow management

## 🎯 Learning Objectives

By the end of this lab, you will be able to:
- Implement FIFO and LIFO queue patterns for claims processing
- Build priority-based claim routing systems with multiple queues
- Create reliable queue consumers with error handling and retry logic
- Implement dead letter queues for failed claim processing
- Monitor queue depths and processing rates in real-time
- Build distributed worker patterns for high-volume claim processing

---

## Part 1: Basic Queue Operations with Redis Lists (15 minutes)

### Step 1: Environment Setup

```bash
# Start Redis with optimized configuration for queue operations
docker run -d --name redis-claims-lab8 \
  -p 6379:6379 \
  redis:7-alpine redis-server \
  --maxmemory 512mb \
  --maxmemory-policy noeviction

# Initialize Node.js project
npm init -y
npm install redis dotenv

# Verify Redis connection
redis-cli ping

# Load initial claims data
./scripts/load-claims-data.sh
```

### Step 2: Basic Queue Implementation

Create `src/basic-queue.js`:

```javascript
import { createClient } from 'redis';

class ClaimsQueue {
    constructor() {
        this.client = null;
        this.queueKey = 'claims:queue:pending';
    }

    async connect() {
        this.client = createClient({
            url: 'redis://localhost:6379',
            socket: {
                connectTimeout: 5000,
                reconnectStrategy: (retries) => Math.min(retries * 100, 3000)
            }
        });

        this.client.on('error', (err) => console.error('Redis Client Error:', err));
        this.client.on('connect', () => console.log('Connected to Redis'));
        
        await this.client.connect();
    }

    // Add claim to queue (FIFO)
    async enqueueClaim(claim) {
        const claimData = JSON.stringify({
            ...claim,
            enqueuedAt: new Date().toISOString(),
            status: 'PENDING'
        });
        
        const length = await this.client.lPush(this.queueKey, claimData);
        console.log(`Claim ${claim.claimId} added to queue. Queue length: ${length}`);
        return length;
    }

    // Process claim from queue
    async dequeueClaim() {
        // Use BRPOP for blocking pop with 5-second timeout
        const result = await this.client.brPop(this.queueKey, 5);
        
        if (result) {
            const claim = JSON.parse(result.element);
            console.log(`Processing claim ${claim.claimId}`);
            return claim;
        }
        
        return null;
    }

    // Get queue statistics
    async getQueueStats() {
        const length = await this.client.lLen(this.queueKey);
        const sample = await this.client.lRange(this.queueKey, 0, 4);
        
        return {
            queueLength: length,
            oldestClaims: sample.map(item => {
                const claim = JSON.parse(item);
                return {
                    claimId: claim.claimId,
                    type: claim.type,
                    enqueuedAt: claim.enqueuedAt
                };
            })
        };
    }

    async disconnect() {
        await this.client.quit();
    }
}

// Test the basic queue
async function testBasicQueue() {
    const queue = new ClaimsQueue();
    await queue.connect();

    // Add sample claims
    const claims = [
        { claimId: 'CLM001', type: 'AUTO', amount: 5000, priority: 'NORMAL' },
        { claimId: 'CLM002', type: 'HOME', amount: 15000, priority: 'HIGH' },
        { claimId: 'CLM003', type: 'LIFE', amount: 100000, priority: 'URGENT' }
    ];

    for (const claim of claims) {
        await queue.enqueueClaim(claim);
    }

    // Display queue stats
    const stats = await queue.getQueueStats();
    console.log('\nQueue Statistics:', stats);

    // Process claims
    console.log('\nProcessing claims...');
    for (let i = 0; i < 3; i++) {
        const claim = await queue.dequeueClaim();
        if (claim) {
            console.log(`Processed: ${claim.claimId} - Type: ${claim.type} - Amount: $${claim.amount}`);
        }
    }

    await queue.disconnect();
}

// Run if executed directly
if (import.meta.url === `file://${process.argv[1]}`) {
    testBasicQueue().catch(console.error);
}

export { ClaimsQueue };
```

### Step 3: Testing Basic Queue Operations

```bash
# Run the basic queue implementation
node src/basic-queue.js

# Monitor queue in Redis Insight
# Open Redis Insight and navigate to:
# Browser > Search for "claims:queue:*"

# Monitor using CLI
redis-cli LLEN claims:queue:pending
redis-cli LRANGE claims:queue:pending 0 -1
```

---

## Part 2: Priority-Based Claims Processing (15 minutes)

### Step 1: Implement Priority Queues

Create `src/priority-queue.js`:

```javascript
import { createClient } from 'redis';

class PriorityClaimsProcessor {
    constructor() {
        this.client = null;
        this.priorities = {
            URGENT: 'claims:queue:urgent',
            HIGH: 'claims:queue:high',
            NORMAL: 'claims:queue:normal',
            LOW: 'claims:queue:low'
        };
        this.processingKey = 'claims:processing';
        this.completedKey = 'claims:completed';
    }

    async connect() {
        this.client = createClient({
            url: 'redis://localhost:6379'
        });
        
        await this.client.connect();
        console.log('Priority processor connected to Redis');
    }

    async routeClaim(claim) {
        const queueKey = this.priorities[claim.priority] || this.priorities.NORMAL;
        const claimData = JSON.stringify({
            ...claim,
            routedAt: new Date().toISOString(),
            queueType: claim.priority
        });
        
        await this.client.lPush(queueKey, claimData);
        
        // Track metrics
        await this.client.hIncrBy('claims:metrics:routed', claim.priority, 1);
        await this.client.hIncrBy('claims:metrics:by_type', claim.type, 1);
        
        console.log(`Claim ${claim.claimId} routed to ${claim.priority} queue`);
    }

    async processNextClaim(workerId) {
        // Check queues in priority order
        for (const [priority, queueKey] of Object.entries(this.priorities)) {
            const result = await this.client.brPopLPush(
                queueKey,
                this.processingKey,
                0.1  // 100ms timeout
            );
            
            if (result) {
                const claim = JSON.parse(result);
                claim.processedBy = workerId;
                claim.processingStarted = new Date().toISOString();
                
                console.log(`Worker ${workerId} processing ${priority} claim: ${claim.claimId}`);
                
                // Simulate processing
                await this.processClaim(claim);
                
                // Move to completed
                await this.client.lRem(this.processingKey, 1, result);
                await this.completeClaim(claim);
                
                return claim;
            }
        }
        
        return null;
    }

    async processClaim(claim) {
        // Simulate processing time based on claim type
        const processingTimes = {
            AUTO: 1000,
            HOME: 2000,
            LIFE: 3000,
            HEALTH: 1500
        };
        
        const delay = processingTimes[claim.type] || 1000;
        await new Promise(resolve => setTimeout(resolve, delay));
        
        // Simulate validation and calculations
        claim.validated = true;
        claim.adjustedAmount = claim.amount * 0.95; // 5% adjustment
        claim.processingCompleted = new Date().toISOString();
    }

    async completeClaim(claim) {
        const completedData = JSON.stringify({
            ...claim,
            completedAt: new Date().toISOString(),
            status: 'COMPLETED'
        });
        
        // Store in completed list (keep last 1000)
        await this.client.lPush(this.completedKey, completedData);
        await this.client.lTrim(this.completedKey, 0, 999);
        
        // Update metrics
        await this.client.hIncrBy('claims:metrics:completed', claim.priority, 1);
        
        // Calculate processing time
        const processingTime = new Date(claim.processingCompleted) - new Date(claim.routedAt);
        await this.client.zAdd('claims:processing_times', {
            score: processingTime,
            value: claim.claimId
        });
        
        console.log(`Claim ${claim.claimId} completed in ${processingTime}ms`);
    }

    async getQueueStatus() {
        const status = {};
        
        for (const [priority, queueKey] of Object.entries(this.priorities)) {
            status[priority] = await this.client.lLen(queueKey);
        }
        
        status.processing = await this.client.lLen(this.processingKey);
        status.completed = await this.client.lLen(this.completedKey);
        
        const metrics = {
            routed: await this.client.hGetAll('claims:metrics:routed'),
            byType: await this.client.hGetAll('claims:metrics:by_type'),
            completed: await this.client.hGetAll('claims:metrics:completed')
        };
        
        return { queues: status, metrics };
    }

    async disconnect() {
        await this.client.quit();
    }
}

// Worker simulation
class ClaimWorker {
    constructor(workerId, processor) {
        this.workerId = workerId;
        this.processor = processor;
        this.isRunning = false;
        this.processedCount = 0;
    }

    async start() {
        this.isRunning = true;
        console.log(`Worker ${this.workerId} started`);
        
        while (this.isRunning) {
            const claim = await this.processor.processNextClaim(this.workerId);
            
            if (claim) {
                this.processedCount++;
                console.log(`Worker ${this.workerId} completed claim ${claim.claimId}. Total processed: ${this.processedCount}`);
            } else {
                // No claims available, wait a bit
                await new Promise(resolve => setTimeout(resolve, 100));
            }
        }
    }

    stop() {
        this.isRunning = false;
        console.log(`Worker ${this.workerId} stopped. Processed ${this.processedCount} claims`);
    }
}

// Test priority processing
async function testPriorityQueues() {
    const processor = new PriorityClaimsProcessor();
    await processor.connect();

    // Generate test claims with different priorities
    const testClaims = [
        { claimId: 'CLM-U001', type: 'LIFE', amount: 500000, priority: 'URGENT' },
        { claimId: 'CLM-H001', type: 'HOME', amount: 50000, priority: 'HIGH' },
        { claimId: 'CLM-H002', type: 'AUTO', amount: 10000, priority: 'HIGH' },
        { claimId: 'CLM-N001', type: 'AUTO', amount: 3000, priority: 'NORMAL' },
        { claimId: 'CLM-N002', type: 'HOME', amount: 8000, priority: 'NORMAL' },
        { claimId: 'CLM-L001', type: 'AUTO', amount: 500, priority: 'LOW' },
        { claimId: 'CLM-U002', type: 'HEALTH', amount: 100000, priority: 'URGENT' }
    ];

    // Route claims to appropriate queues
    console.log('Routing claims to priority queues...\n');
    for (const claim of testClaims) {
        await processor.routeClaim(claim);
    }

    // Display initial queue status
    let status = await processor.getQueueStatus();
    console.log('\nInitial Queue Status:', JSON.stringify(status, null, 2));

    // Start workers
    const workers = [];
    for (let i = 1; i <= 3; i++) {
        const worker = new ClaimWorker(`W${i}`, processor);
        workers.push(worker);
        worker.start(); // Don't await, let them run concurrently
    }

    // Let workers process for 10 seconds
    await new Promise(resolve => setTimeout(resolve, 10000));

    // Stop workers
    workers.forEach(worker => worker.stop());

    // Final status
    await new Promise(resolve => setTimeout(resolve, 1000)); // Wait for workers to finish
    status = await processor.getQueueStatus();
    console.log('\nFinal Queue Status:', JSON.stringify(status, null, 2));

    await processor.disconnect();
}

// Run if executed directly
if (import.meta.url === `file://${process.argv[1]}`) {
    testPriorityQueues().catch(console.error);
}

export { PriorityClaimsProcessor, ClaimWorker };
```

---

## Part 3: Reliable Queue with Dead Letter Queue (15 minutes)

### Step 1: Implement Reliable Queue Pattern

Create `src/reliable-queue.js`:

```javascript
import { createClient } from 'redis';

class ReliableClaimsQueue {
    constructor() {
        this.client = null;
        this.pendingQueue = 'claims:queue:reliable:pending';
        this.processingQueue = 'claims:queue:reliable:processing';
        this.deadLetterQueue = 'claims:queue:reliable:dlq';
        this.completedSet = 'claims:completed:set';
        this.maxRetries = 3;
        this.processingTimeout = 30000; // 30 seconds
    }

    async connect() {
        this.client = createClient({
            url: 'redis://localhost:6379'
        });
        
        await this.client.connect();
        console.log('Reliable queue connected to Redis');
        
        // Start monitoring for stuck messages
        this.startTimeoutMonitor();
    }

    async submitClaim(claim) {
        const envelope = {
            id: `claim_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
            claim: claim,
            attempts: 0,
            submittedAt: new Date().toISOString(),
            lastAttempt: null,
            errors: []
        };
        
        await this.client.lPush(this.pendingQueue, JSON.stringify(envelope));
        console.log(`Claim ${claim.claimId} submitted with envelope ID: ${envelope.id}`);
        
        return envelope.id;
    }

    async processNext(workerId) {
        // Atomically move from pending to processing
        const result = await this.client.brPopLPush(
            this.pendingQueue,
            this.processingQueue,
            5 // 5 second timeout
        );
        
        if (!result) {
            return null;
        }
        
        const envelope = JSON.parse(result);
        envelope.lastAttempt = new Date().toISOString();
        envelope.attempts++;
        envelope.workerId = workerId;
        
        // Set processing timestamp for timeout monitoring
        await this.client.hSet(
            'claims:processing:timestamps',
            envelope.id,
            Date.now().toString()
        );
        
        try {
            // Process the claim
            const processedClaim = await this.processClaim(envelope.claim, workerId);
            
            // Mark as completed
            await this.markCompleted(envelope, processedClaim);
            
            // Remove from processing queue
            await this.client.lRem(this.processingQueue, 1, result);
            await this.client.hDel('claims:processing:timestamps', envelope.id);
            
            return { success: true, envelope, processedClaim };
            
        } catch (error) {
            console.error(`Error processing claim ${envelope.claim.claimId}:`, error.message);
            
            // Record error
            envelope.errors.push({
                attempt: envelope.attempts,
                error: error.message,
                timestamp: new Date().toISOString(),
                workerId: workerId
            });
            
            // Check if we should retry or move to DLQ
            if (envelope.attempts >= this.maxRetries) {
                await this.moveToDeadLetter(envelope, result);
            } else {
                // Put back in pending queue for retry
                await this.client.lRem(this.processingQueue, 1, result);
                await this.client.rPush(this.pendingQueue, JSON.stringify(envelope));
                console.log(`Claim ${envelope.claim.claimId} requeued for retry (attempt ${envelope.attempts}/${this.maxRetries})`);
            }
            
            await this.client.hDel('claims:processing:timestamps', envelope.id);
            
            return { success: false, envelope, error: error.message };
        }
    }

    async processClaim(claim, workerId) {
        console.log(`Worker ${workerId} processing claim ${claim.claimId}`);
        
        // Simulate processing with potential failures
        const failureRate = 0.3; // 30% chance of failure for testing
        
        if (Math.random() < failureRate) {
            const errors = [
                'External API timeout',
                'Invalid claim data',
                'Database connection failed',
                'Validation error: Amount exceeds limit'
            ];
            throw new Error(errors[Math.floor(Math.random() * errors.length)]);
        }
        
        // Simulate processing time
        await new Promise(resolve => setTimeout(resolve, 1000 + Math.random() * 2000));
        
        return {
            ...claim,
            processedAt: new Date().toISOString(),
            processedBy: workerId,
            approvalStatus: Math.random() > 0.2 ? 'APPROVED' : 'REQUIRES_REVIEW',
            adjustedAmount: claim.amount * (0.8 + Math.random() * 0.2)
        };
    }

    async markCompleted(envelope, processedClaim) {
        const completion = {
            envelopeId: envelope.id,
            claimId: envelope.claim.claimId,
            processedClaim: processedClaim,
            attempts: envelope.attempts,
            completedAt: new Date().toISOString(),
            processingTime: Date.now() - new Date(envelope.submittedAt).getTime()
        };
        
        // Store in completed set with expiry
        await this.client.setEx(
            `claims:completed:${envelope.id}`,
            86400, // 24 hours
            JSON.stringify(completion)
        );
        
        // Add to completed set for tracking
        await this.client.sAdd(this.completedSet, envelope.id);
        
        // Update metrics
        await this.client.incrBy('claims:metrics:completed:total', 1);
        await this.client.incrBy(`claims:metrics:completed:attempts:${envelope.attempts}`, 1);
        
        console.log(`Claim ${envelope.claim.claimId} completed successfully after ${envelope.attempts} attempts`);
    }

    async moveToDeadLetter(envelope, originalData) {
        envelope.movedToDLQ = new Date().toISOString();
        envelope.dlqReason = `Max retries (${this.maxRetries}) exceeded`;
        
        // Remove from processing queue
        await this.client.lRem(this.processingQueue, 1, originalData);
        
        // Add to dead letter queue
        await this.client.lPush(this.deadLetterQueue, JSON.stringify(envelope));
        
        // Track in metrics
        await this.client.incrBy('claims:metrics:dlq:total', 1);
        await this.client.hIncrBy('claims:metrics:dlq:by_type', envelope.claim.type, 1);
        
        console.log(`Claim ${envelope.claim.claimId} moved to DLQ after ${envelope.attempts} failed attempts`);
    }

    async startTimeoutMonitor() {
        setInterval(async () => {
            try {
                const timestamps = await this.client.hGetAll('claims:processing:timestamps');
                const now = Date.now();
                
                for (const [envelopeId, timestamp] of Object.entries(timestamps)) {
                    const processingTime = now - parseInt(timestamp);
                    
                    if (processingTime > this.processingTimeout) {
                        console.log(`Claim envelope ${envelopeId} timed out after ${processingTime}ms`);
                        
                        // Find and move the timed-out claim
                        const processing = await this.client.lRange(this.processingQueue, 0, -1);
                        
                        for (const item of processing) {
                            const envelope = JSON.parse(item);
                            if (envelope.id === envelopeId) {
                                envelope.errors.push({
                                    error: 'Processing timeout',
                                    timestamp: new Date().toISOString()
                                });
                                
                                if (envelope.attempts >= this.maxRetries) {
                                    await this.moveToDeadLetter(envelope, item);
                                } else {
                                    // Requeue for retry
                                    await this.client.lRem(this.processingQueue, 1, item);
                                    await this.client.rPush(this.pendingQueue, JSON.stringify(envelope));
                                }
                                
                                await this.client.hDel('claims:processing:timestamps', envelopeId);
                                break;
                            }
                        }
                    }
                }
            } catch (error) {
                console.error('Timeout monitor error:', error);
            }
        }, 5000); // Check every 5 seconds
    }

    async getQueueHealth() {
        const [pending, processing, dlq, completed] = await Promise.all([
            this.client.lLen(this.pendingQueue),
            this.client.lLen(this.processingQueue),
            this.client.lLen(this.deadLetterQueue),
            this.client.sCard(this.completedSet)
        ]);
        
        const metrics = await this.client.hGetAll('claims:metrics:dlq:by_type');
        const completedMetrics = {
            total: await this.client.get('claims:metrics:completed:total') || '0',
            byAttempts: {}
        };
        
        for (let i = 1; i <= this.maxRetries; i++) {
            completedMetrics.byAttempts[i] = await this.client.get(`claims:metrics:completed:attempts:${i}`) || '0';
        }
        
        return {
            queues: {
                pending,
                processing,
                deadLetter: dlq,
                completed
            },
            metrics: {
                dlqByType: metrics,
                completed: completedMetrics
            },
            health: {
                isHealthy: dlq < 10 && processing < 20,
                warnings: []
            }
        };
    }

    async reprocessDLQ() {
        let reprocessed = 0;
        
        while (true) {
            const result = await this.client.rPopLPush(
                this.deadLetterQueue,
                this.pendingQueue
            );
            
            if (!result) break;
            
            const envelope = JSON.parse(result);
            envelope.attempts = 0; // Reset attempts
            envelope.reprocessedFromDLQ = new Date().toISOString();
            
            await this.client.lPush(this.pendingQueue, JSON.stringify(envelope));
            reprocessed++;
            
            console.log(`Reprocessed claim ${envelope.claim.claimId} from DLQ`);
        }
        
        return reprocessed;
    }

    async disconnect() {
        await this.client.quit();
    }
}

// Test reliable queue
async function testReliableQueue() {
    const queue = new ReliableClaimsQueue();
    await queue.connect();

    // Submit test claims
    const testClaims = [
        { claimId: 'REL-001', type: 'AUTO', amount: 5000 },
        { claimId: 'REL-002', type: 'HOME', amount: 15000 },
        { claimId: 'REL-003', type: 'LIFE', amount: 100000 },
        { claimId: 'REL-004', type: 'HEALTH', amount: 8000 },
        { claimId: 'REL-005', type: 'AUTO', amount: 3000 }
    ];

    console.log('Submitting claims to reliable queue...\n');
    for (const claim of testClaims) {
        await queue.submitClaim(claim);
    }

    // Simulate workers processing claims
    console.log('\nProcessing claims with simulated failures...\n');
    
    const processWorker = async (workerId) => {
        for (let i = 0; i < 10; i++) {
            const result = await queue.processNext(workerId);
            if (!result) {
                console.log(`Worker ${workerId}: No claims available`);
                break;
            }
        }
    };

    // Run multiple workers concurrently
    await Promise.all([
        processWorker('W1'),
        processWorker('W2')
    ]);

    // Wait for timeout monitoring to catch any stuck messages
    await new Promise(resolve => setTimeout(resolve, 3000));

    // Check queue health
    const health = await queue.getQueueHealth();
    console.log('\nQueue Health Report:');
    console.log(JSON.stringify(health, null, 2));

    // Reprocess DLQ if needed
    if (health.queues.deadLetter > 0) {
        console.log('\nReprocessing Dead Letter Queue...');
        const reprocessed = await queue.reprocessDLQ();
        console.log(`Reprocessed ${reprocessed} claims from DLQ`);
    }

    await queue.disconnect();
}

// Run if executed directly
if (import.meta.url === `file://${process.argv[1]}`) {
    testReliableQueue().catch(console.error);
}

export { ReliableClaimsQueue };
```

### Step 2: Monitor Queue Health

Create `src/queue-monitor.js`:

```javascript
import { createClient } from 'redis';

class QueueMonitor {
    constructor() {
        this.client = null;
        this.monitoringInterval = null;
    }

    async connect() {
        this.client = createClient({
            url: 'redis://localhost:6379'
        });
        
        await this.client.connect();
        console.log('Queue monitor connected');
    }

    async startMonitoring(intervalMs = 2000) {
        console.log('Starting queue monitoring dashboard...\n');
        
        this.monitoringInterval = setInterval(async () => {
            await this.displayDashboard();
        }, intervalMs);
        
        // Display immediately
        await this.displayDashboard();
    }

    async displayDashboard() {
        console.clear();
        console.log('═══════════════════════════════════════════════════════════════');
        console.log('                    CLAIMS QUEUE DASHBOARD                     ');
        console.log('═══════════════════════════════════════════════════════════════');
        console.log(`Timestamp: ${new Date().toISOString()}`);
        console.log('───────────────────────────────────────────────────────────────');
        
        // Basic queues
        const basicQueue = await this.client.lLen('claims:queue:pending');
        console.log(`\n📋 BASIC QUEUE: ${basicQueue} pending`);
        
        // Priority queues
        console.log('\n🎯 PRIORITY QUEUES:');
        const priorities = ['urgent', 'high', 'normal', 'low'];
        for (const priority of priorities) {
            const count = await this.client.lLen(`claims:queue:${priority}`);
            const emoji = priority === 'urgent' ? '🔴' : priority === 'high' ? '🟠' : priority === 'normal' ? '🟡' : '🟢';
            console.log(`  ${emoji} ${priority.toUpperCase().padEnd(8)}: ${count}`);
        }
        
        // Processing stats
        const processing = await this.client.lLen('claims:processing');
        const completed = await this.client.lLen('claims:completed');
        console.log(`\n⚙️  PROCESSING: ${processing}`);
        console.log(`✅ COMPLETED: ${completed}`);
        
        // Reliable queue stats
        const reliablePending = await this.client.lLen('claims:queue:reliable:pending');
        const reliableProcessing = await this.client.lLen('claims:queue:reliable:processing');
        const dlq = await this.client.lLen('claims:queue:reliable:dlq');
        
        console.log('\n🔒 RELIABLE QUEUE:');
        console.log(`  Pending: ${reliablePending}`);
        console.log(`  Processing: ${reliableProcessing}`);
        console.log(`  Dead Letter: ${dlq} ${dlq > 0 ? '⚠️' : '✅'}`);
        
        // Metrics
        const routed = await this.client.hGetAll('claims:metrics:routed');
        const byType = await this.client.hGetAll('claims:metrics:by_type');
        
        if (Object.keys(routed).length > 0) {
            console.log('\n📊 ROUTING METRICS:');
            for (const [priority, count] of Object.entries(routed)) {
                console.log(`  ${priority}: ${count}`);
            }
        }
        
        if (Object.keys(byType).length > 0) {
            console.log('\n📈 BY TYPE:');
            for (const [type, count] of Object.entries(byType)) {
                console.log(`  ${type}: ${count}`);
            }
        }
        
        // Processing times
        const times = await this.client.zRangeWithScores('claims:processing_times', 0, 4);
        if (times.length > 0) {
            console.log('\n⏱️  RECENT PROCESSING TIMES:');
            for (const { value, score } of times) {
                console.log(`  ${value}: ${score}ms`);
            }
        }
        
        console.log('\n═══════════════════════════════════════════════════════════════');
        console.log('Press Ctrl+C to stop monitoring');
    }

    stopMonitoring() {
        if (this.monitoringInterval) {
            clearInterval(this.monitoringInterval);
            this.monitoringInterval = null;
            console.log('\nMonitoring stopped');
        }
    }

    async disconnect() {
        this.stopMonitoring();
        await this.client.quit();
    }
}

// Run monitoring dashboard
async function runMonitor() {
    const monitor = new QueueMonitor();
    await monitor.connect();
    
    // Handle graceful shutdown
    process.on('SIGINT', async () => {
        console.log('\n\nShutting down monitor...');
        await monitor.disconnect();
        process.exit(0);
    });
    
    await monitor.startMonitoring();
}

// Run if executed directly
if (import.meta.url === `file://${process.argv[1]}`) {
    runMonitor().catch(console.error);
}

export { QueueMonitor };
```

---

## 🎯 Lab Summary

You've successfully implemented:

✅ **Basic Queue Operations** - FIFO/LIFO patterns with Redis Lists  
✅ **Priority-Based Processing** - Multi-queue routing with worker pools  
✅ **Reliable Queue Pattern** - Error handling, retries, and DLQ  
✅ **Queue Monitoring** - Real-time dashboard and health metrics  
✅ **Distributed Workers** - Concurrent processing with multiple consumers  
✅ **Production Patterns** - Timeout handling and graceful recovery

## 🔧 Key Commands Used

```bash
# List Operations
LPUSH/RPUSH     # Add to queue
LPOP/RPOP       # Remove from queue
BRPOP/BLPOP     # Blocking pop
BRPOPLPUSH      # Atomic move between lists
LLEN            # Queue length
LRANGE          # View queue contents
LREM            # Remove specific items
LTRIM           # Trim list to size

# Supporting Operations
HINCRBY         # Increment metrics
ZADD            # Track processing times
SETEX           # Store with expiry
SCARD/SADD      # Set operations for tracking
```

## 📊 Performance Tips

1. **Use blocking operations** (`BRPOP`) instead of polling
2. **Implement circuit breakers** for failing downstream services
3. **Monitor queue depths** and set alerts for thresholds
4. **Use Lua scripts** for complex atomic operations
5. **Consider Redis Streams** for more advanced queue requirements

## 🎉 Congratulations!

You've mastered claims processing queues with Redis Lists and JavaScript. These patterns form the foundation for robust, scalable queue-based architectures in production systems.

**Next Lab:** Lab 9 - Analytics with Sets & Sorted Sets
