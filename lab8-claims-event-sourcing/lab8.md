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

## Part 1: Project Setup and Validation (10 minutes)

### Step 1: Initialize Lab Environment

```bash
# Navigate to the lab directory
cd lab8-claims-event-sourcing

# Run setup script
./scripts/setup-lab.sh

# Validate environment setup
node validation/validate-setup.js

# Or use the validation module
npm run validate
```

### Step 2: Configure Environment

```bash
# Copy environment template
cp .env.template .env

# Edit with your Redis connection details
nano .env
```

Example `.env` configuration:
```env
REDIS_HOST=your-redis-server.com
REDIS_PORT=6379
REDIS_PASSWORD=your-password
STREAM_NAME=claims:events
CONSUMER_GROUP=claims-processors
```

### Step 3: Install Dependencies and Validate

```bash
# Install all dependencies
npm install

# Run complete validation
node validation/validate-setup.js

# Quick health check
node validation/health-check.js
```

---

## Part 2: Understanding Redis Streams for Claims (10 minutes)

### Step 1: Stream Basics in Redis Insight

Open Redis Insight and connect to your Redis instance.

1. **Navigate to CLI tab**
2. **Create a test stream:**

```redis
# Add claim events to stream
XADD claims:events * type "claim_submitted" claim_id "CLM-001" customer_id "CUST-123" amount "5000" status "pending"

XADD claims:events * type "claim_reviewed" claim_id "CLM-001" reviewer "agent_001" status "approved" notes "Valid claim"

XADD claims:events * type "claim_paid" claim_id "CLM-001" amount "5000" payment_method "bank_transfer"

# View stream contents
XREAD STREAMS claims:events 0

# Get stream information
XINFO STREAM claims:events
```

### Step 2: Consumer Groups for Processing

```redis
# Create consumer group
XGROUP CREATE claims:events claims-processors $ MKSTREAM

# Read as consumer
XREADGROUP GROUP claims-processors processor1 STREAMS claims:events >

# Check pending messages
XPENDING claims:events claims-processors
```

---

## Part 3: Implementing Claims Event Sourcing (15 minutes)

### Step 1: Test the Claim Model

```bash
# Test basic claim operations
node tests/claim.test.js

# Test with sample data
node scripts/load-sample-data.js
```

### Step 2: Run Claim Producer

```bash
# Start producing claim events
node src/services/claimProducer.js
```

Sample operations in another terminal:
```bash
# Submit new claims
curl -X POST http://localhost:3001/claims \
  -H "Content-Type: application/json" \
  -d '{
    "customer_id": "CUST-456", 
    "policy_number": "POL-789",
    "amount": 7500,
    "description": "Vehicle accident damage",
    "incident_date": "2024-08-15"
  }'
```

### Step 3: Process Claims with Consumers

```bash
# Start claim processor (in separate terminal)
node src/consumers/claimProcessor.js

# Monitor processing in Redis Insight CLI:
XINFO CONSUMERS claims:events claims-processors
XLEN claims:events
```

---

## Part 4: Advanced Stream Operations (10 minutes)

### Step 1: Analytics and Aggregation

```bash
# Run analytics script
node src/services/claimAnalytics.js
```

### Step 2: Monitor Real-time Processing

In Redis Insight CLI, monitor stream activity:

```redis
# Monitor new entries
MONITOR

# In another CLI session, add test data:
XADD claims:events * type "high_value_claim" claim_id "CLM-999" amount "50000" priority "urgent"

# Check stream length growth
XLEN claims:events

# View recent entries
XREVRANGE claims:events + - COUNT 5
```

### Step 3: Error Handling and Dead Letter Queues

```bash
# Test error scenarios
node tests/error-handling.test.js

# Check dead letter processing
XINFO STREAM claims:failed
```

---

## Part 5: Performance and Scaling (5 minutes)

### Step 1: Load Testing

```bash
# Run performance tests
node tests/performance.test.js

# Monitor memory usage in Redis Insight
INFO memory
```

### Step 2: Consumer Group Scaling

```redis
# Add more consumers to group
XREADGROUP GROUP claims-processors processor2 STREAMS claims:events >
XREADGROUP GROUP claims-processors processor3 STREAMS claims:events >

# Check consumer distribution
XINFO CONSUMERS claims:events claims-processors
```

---

## Part 6: Validation and Completion (5 minutes)

### Step 1: Run Complete Validation

```bash
# Full environment validation
node validation/validate-setup.js

# Runtime health check
node validation/health-check.js

# Completion verification
node scripts/verify-completion.js
```

### Step 2: Lab Completion Checklist

- [ ] Environment setup validated
- [ ] Redis Streams configured for claims
- [ ] Consumer groups processing events
- [ ] Claim lifecycle events tracked
- [ ] Analytics working correctly
- [ ] Error handling implemented
- [ ] Performance testing completed

---

## 🎯 Lab Summary

You have successfully implemented:

1. **Event Sourcing Architecture**: Claims lifecycle as immutable events
2. **Real-time Processing**: Consumer groups for scalable claim processing  
3. **Audit Trails**: Complete claim history preservation
4. **Analytics**: Stream-based claim metrics and reporting
5. **Error Handling**: Dead letter queues and retry mechanisms
6. **Scalability**: Multiple consumer pattern for high throughput

### Key Redis Streams Commands Used:
- `XADD` - Add events to stream
- `XREAD` - Read stream events
- `XGROUP` - Manage consumer groups
- `XREADGROUP` - Read as part of consumer group
- `XINFO` - Stream and consumer information
- `XPENDING` - Check unacknowledged messages

### Next Steps:
- **Lab 9**: Redis Pub/Sub for Real-time Notifications
- Explore stream partitioning strategies
- Implement claim workflow orchestration
- Add claim document management with Redis

---

## 🔧 Troubleshooting

### Common Issues:

1. **Stream not found error**:
   ```bash
   # Recreate stream
   XADD claims:events * type "init" message "stream created"
   ```

2. **Consumer group exists error**:
   ```bash
   # Delete and recreate
   XGROUP DESTROY claims:events claims-processors
   XGROUP CREATE claims:events claims-processors $ MKSTREAM
   ```

3. **Connection issues**:
   ```bash
   # Check connection
   node validation/health-check.js
   # Update .env file with correct Redis details
   ```

4. **Validation failures**:
   ```bash
   # Run full validation with details
   node validation/validate-setup.js
   # Follow the recommendations provided
   ```

For additional help, check the generated documentation in `docs/` or contact your instructor.
