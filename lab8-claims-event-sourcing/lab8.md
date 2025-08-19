# Lab 8: Claims Event Sourcing with Redis Streams

**Duration:** 45 minutes  
**Objective:** Implement event-driven claims processing using Redis Streams for audit trails, real-time analytics, and scalable event sourcing patterns

## 🎯 Learning Objectives

By the end of this lab, you will be able to:
- Implement event sourcing patterns for claims processing
- Create immutable audit trails using Redis Streams
- Build real-time claim processors using stream consumers
- Design event-driven architecture for scalable claims handling
- Implement claim analytics using stream aggregation
- Handle stream partitioning and consumer groups for high availability
- Create time-based claim analytics and reporting

---

## ⚙️ Environment Configuration

This lab supports flexible Redis connection configuration through environment variables:

```bash
# Configure Redis connection (optional)
export REDIS_HOST=your-redis-host    # Default: localhost
export REDIS_PORT=6379               # Default: 6379
export REDIS_PASSWORD=your-password  # Default: none
```

All scripts and applications will automatically use these environment variables.

---

## 📋 Prerequisites

- Docker installed and running
- Node.js 18+ and npm installed
- Redis Insight installed
- Visual Studio Code with Redis extension
- Completion of Labs 1-7 (JavaScript client and hashes)
- Understanding of event sourcing concepts

---

## Part 1: Event Sourcing Architecture Setup (15 minutes)

### Step 1: Environment Setup

```bash
# Start Redis container with persistence
docker run -d --name redis-lab8 \
  -p 6379:6379 \
  -v redis-lab8-data:/data \
  redis:7-alpine redis-server --appendonly yes

# Install Node.js dependencies
npm install redis uuid

# Verify Redis connection
node -e "
const redis = require('redis');
const client = redis.createClient({
  host: process.env.REDIS_HOST || 'localhost',
  port: process.env.REDIS_PORT || 6379,
  password: process.env.REDIS_PASSWORD || undefined
});
client.on('connect', () => console.log('✅ Connected to Redis'));
client.on('error', (err) => console.log('❌ Redis error:', err));
"
```

### Step 2: Understanding Claims Event Sourcing

**Event Sourcing Benefits for Claims:**
- **Immutable Audit Trail:** Every claim action is recorded permanently
- **Regulatory Compliance:** Complete history for audits and investigations
- **Real-time Processing:** Multiple consumers can process events simultaneously
- **Scalability:** Stream partitioning enables horizontal scaling
- **Analytics:** Time-based aggregation for business intelligence

**Claims Event Types:**
- `claim.submitted` - Initial claim submission
- `claim.assigned` - Claim assigned to adjuster
- `claim.document.uploaded` - Supporting documents added
- `claim.investigated` - Investigation started/completed
- `claim.approved` - Claim approved for payment
- `claim.rejected` - Claim denied
- `claim.payment.initiated` - Payment processing started
- `claim.payment.completed` - Payment finalized

### Step 3: Load Sample Data

```bash
# Load initial customers and policies
node scripts/load-sample-data.js

# Verify data loaded
node -e "
const redis = require('redis');
const client = redis.createClient();
client.connect().then(async () => {
  const customers = await client.keys('customer:*');
  const policies = await client.keys('policy:*');
  console.log(\`Loaded \${customers.length} customers and \${policies.length} policies\`);
  await client.quit();
});
"
```

---

## Part 2: Claims Event Stream Implementation (15 minutes)

### Step 4: Claims Event Producer

Create the claims event producer to handle claim submissions and updates:

```bash
# Test the claims event producer
node src/services/claims-producer.js
```

**Key Features:**
- Validates claim data before creating events
- Generates unique claim IDs and event timestamps
- Handles different event types with proper schemas
- Implements retry logic for stream failures

### Step 5: Claims Event Consumers

**Consumer Architecture:**
- **Processor Consumer:** Handles claim state transitions
- **Analytics Consumer:** Aggregates data for reporting
- **Notification Consumer:** Sends alerts and notifications
- **Audit Consumer:** Creates compliance reports

```bash
# Start claims processor (in separate terminal)
node src/consumers/claims-processor.js

# Start analytics consumer (in separate terminal)
node src/consumers/analytics-consumer.js

# Start notification consumer (in separate terminal)
node src/consumers/notification-consumer.js
```

### Step 6: Stream Monitoring with Redis Insight

1. **Open Redis Insight** and connect to your Redis instance
2. **Navigate to Streams** section
3. **Examine Stream Structure:**
   - `claims:events` - Main event stream
   - `claims:analytics` - Aggregated analytics
   - `claims:notifications` - Alert stream

4. **Monitor Consumer Groups:**
   - `processors` - Claim state management
   - `analytics` - Business intelligence
   - `notifications` - Alert system

---

## Part 3: Real-time Claims Processing (10 minutes)

### Step 7: Submit Claims and Observe Events

```bash
# Submit multiple test claims
node scripts/submit-test-claims.js

# Monitor claims processing in real-time
node scripts/monitor-claims.js
```

**Processing Workflow:**
1. **Claim Submitted** → Stream event created
2. **Processors** → Validate and assign claim
3. **Analytics** → Update metrics and KPIs
4. **Notifications** → Alert stakeholders

### Step 8: Claims Analytics Dashboard

```bash
# Run analytics dashboard
node src/services/analytics-dashboard.js
```

**Analytics Features:**
- **Real-time Metrics:** Claims per hour, average processing time
- **Status Distribution:** Submitted, processing, approved, rejected
- **Amount Analysis:** Total claim values, average amounts
- **Processing Performance:** Adjuster workload, resolution times

### Step 9: Event Replay and Recovery

```bash
# Demonstrate event replay capability
node scripts/replay-events.js

# Test consumer recovery after failure
node scripts/test-consumer-recovery.js
```

**Recovery Features:**
- **Stream Persistence:** Events survive Redis restarts
- **Consumer Position:** Resume from last processed message
- **Failed Message Handling:** Dead letter queue for problematic events
- **Replay Capability:** Reprocess events from any point in time

---

## Part 4: Advanced Stream Operations (5 minutes)

### Step 10: Stream Aggregation and Analysis

```bash
# Generate comprehensive analytics report
node scripts/generate-analytics-report.js

# View the generated report
cat data/claims-analytics-report.json
```

### Step 11: Stream Maintenance and Optimization

```bash
# Check stream information
node -e "
const redis = require('redis');
const client = redis.createClient();
client.connect().then(async () => {
  const info = await client.xInfo('STREAM', 'claims:events');
  console.log('Stream Info:', info);
  
  const groups = await client.xInfo('GROUPS', 'claims:events');
  console.log('Consumer Groups:', groups);
  
  await client.quit();
});
"

# Trim old events (optional, for production)
# node scripts/trim-old-events.js
```

---

## 🏆 Lab 8 Completion

### ✅ What You've Accomplished

- **Event Sourcing Mastery:** Implemented immutable audit trails for claims
- **Stream Architecture:** Built scalable, event-driven claims processing
- **Real-time Analytics:** Created live dashboards and reporting systems
- **Consumer Groups:** Implemented fault-tolerant message processing
- **Event Replay:** Designed systems for audit and recovery scenarios
- **Production Patterns:** Applied enterprise-grade event sourcing practices

### 📊 Key Metrics Achieved

- Event-driven claims processing with complete audit trails
- Multiple consumer groups processing events simultaneously
- Real-time analytics and monitoring dashboards
- Fault-tolerant message processing with recovery capabilities
- Scalable architecture supporting high-volume claim processing

### 🚀 Claims Processing Capabilities

You now have a production-ready system that can:
- Process thousands of claims events per minute
- Maintain complete audit trails for regulatory compliance
- Provide real-time analytics and business intelligence
- Scale horizontally with consumer group partitioning
- Recover gracefully from failures with event replay

---

## 🎯 Event Sourcing vs Traditional Approaches

### ✅ **Event Sourcing Advantages:**
- **Complete Audit Trail:** Every state change is recorded
- **Temporal Queries:** "What was the claim status on date X?"
- **Event Replay:** Rebuild state or test new logic
- **Scalability:** Multiple consumers process independently
- **Compliance:** Immutable records for regulatory requirements

### ⚠️ **Traditional Database Limitations:**
- **Lost History:** Updates overwrite previous state
- **Limited Scalability:** Single database bottleneck
- **Complex Auditing:** Requires separate audit tables
- **Difficult Recovery:** Hard to replay business events

---

## 📚 Advanced Concepts Covered

### Stream Commands Mastered
- `XADD` - Add events to streams
- `XREAD` - Read events from streams
- `XGROUP` - Manage consumer groups
- `XREADGROUP` - Consumer group processing
- `XINFO` - Stream information and monitoring
- `XPENDING` - Track unprocessed messages
- `XACK` - Acknowledge processed messages
- `XTRIM` - Stream maintenance and cleanup

### Event Sourcing Patterns
- **Event Store:** Stream as single source of truth
- **Projection:** Creating read models from events
- **Saga Pattern:** Coordinating multi-service transactions
- **CQRS:** Command Query Responsibility Segregation
- **Event Replay:** Reconstructing state from events

### Production Considerations
- **Stream Partitioning:** Scaling with multiple Redis instances
- **Memory Management:** Stream trimming and archival strategies
- **Monitoring:** Consumer lag and processing metrics
- **Error Handling:** Dead letter queues and retry policies

---

## 🔧 Troubleshooting

### Common Stream Issues

1. **Consumer Lag:**
   ```bash
   # Check pending messages
   redis-cli XPENDING claims:events processors
   
   # Monitor consumer group status
   redis-cli XINFO GROUPS claims:events
   ```

2. **Stream Memory Usage:**
   ```bash
   # Check stream length
   redis-cli XLEN claims:events
   
   # Monitor memory usage
   redis-cli MEMORY USAGE claims:events
   ```

3. **Event Processing Errors:**
   ```bash
   # Check failed messages
   node scripts/check-failed-messages.js
   
   # Replay failed events
   node scripts/replay-failed-events.js
   ```

---

## 🎓 Next Steps

### **Lab 9:** Insurance Analytics with Sets and Sorted Sets
- Aggregate stream data into analytical data structures
- Create customer segmentation from claim patterns
- Build agent performance leaderboards
- Implement risk scoring based on claim history

### **Lab 10:** Advanced Caching Patterns
- Cache claim processing results for faster retrieval
- Implement cache invalidation on claim status changes
- Create multi-tier caching for claim documents
- Optimize claim lookup performance

---

**Excellent work!** You've mastered event sourcing with Redis Streams and built a production-ready claims processing system. Ready for advanced analytics in Lab 9! 🚀

## 📖 Additional Resources

### Redis Streams Documentation
- [Redis Streams Introduction](https://redis.io/topics/streams-intro)
- [Consumer Groups](https://redis.io/commands#stream)
- [Stream Commands Reference](https://redis.io/commands#stream)

### Event Sourcing Patterns
- Event Store patterns and best practices
- CQRS implementation with Redis
- Microservices event-driven architecture
- Stream processing for real-time analytics
