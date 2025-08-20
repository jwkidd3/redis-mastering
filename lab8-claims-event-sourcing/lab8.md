# Lab 8: Claims Event Sourcing with Redis Streams

**Duration:** 45 minutes  
**Objective:** Implement complete event-driven claims processing using Redis Streams for audit trails, real-time analytics, and scalable event sourcing patterns

## 🎯 Learning Objectives

By the end of this lab, you will be able to:
- Implement event sourcing patterns for claims processing
- Create immutable audit trails using Redis Streams
- Build real-time claim processors using stream consumers
- Design event-driven architecture for scalable claims handling
- Implement claim analytics using stream aggregation
- Handle stream partitioning and consumer groups for high availability
- Create time-based claim analytics and reporting
- Validate and test Redis Streams implementations
- Monitor stream performance and troubleshoot issues

---

## ⚙️ Environment Configuration

This lab supports flexible Redis connection configuration through environment variables:

```bash
# Configure Redis connection (required for remote host)
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

## Part 1: Environment Setup (10 minutes)

### Step 1: Validate Environment

```bash
# Run validation script
./validation/validate-environment.sh

# This will check:
# - Node.js version
# - Docker availability
# - Redis connection
# - Required packages
```

### Step 2: Install Dependencies

```bash
# Install all required packages
npm install

# Verify installation
npm run validate-setup
```

### Step 3: Setup Redis Connection

```bash
# Test Redis connection
npm run test-connection

# Load initial sample data
npm run load-data

# Verify data loading
npm run verify-data
```

---

## Part 2: Event Sourcing Implementation (15 minutes)

### Step 4: Understanding Claims Event Sourcing

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

### Step 5: Build Claims Producer

```bash
# Start the claims producer service
npm run producer

# In Redis Insight, watch the claims:events stream
# Run: XREAD STREAMS claims:events $
```

### Step 6: Implement Consumer Groups

```bash
# Start all consumer services (in separate terminals)
npm run consumer:processor     # Claims business logic
npm run consumer:analytics     # Real-time analytics
npm run consumer:notifications # Customer notifications

# Monitor consumer groups in Redis Insight
# Run: XINFO GROUPS claims:events
```

### Step 7: Submit Test Claims

```bash
# Submit sample claims for processing
npm run submit-claims

# Watch real-time processing
npm run monitor-processing
```

---

## Part 3: Analytics and Monitoring (10 minutes)

### Step 8: Real-time Analytics Dashboard

```bash
# Start analytics dashboard
npm run dashboard

# Generate analytics reports
npm run generate-report

# View analytics in Redis Insight:
# ZRANGE analytics:claims:daily:$(date +%Y-%m-%d) 0 -1 WITHSCORES
```

### Step 9: Stream Monitoring

```bash
# Monitor stream health
npm run monitor-streams

# Check consumer lag
npm run check-consumer-lag

# View stream info in Redis Insight:
# XINFO STREAM claims:events
```

### Step 10: Event Replay and Recovery

```bash
# Test event replay functionality
npm run test-replay

# Test consumer recovery
npm run test-recovery

# View event history
npm run view-event-history
```

---

## Part 4: Testing and Validation (10 minutes)

### Step 11: Run Comprehensive Tests

```bash
# Run all automated tests
npm test

# Run specific test categories
npm run test:streams      # Stream operations
npm run test:consumers    # Consumer functionality
npm run test:analytics    # Analytics processing
npm run test:recovery     # Error recovery
```

### Step 12: Performance Testing

```bash
# Run performance benchmarks
npm run benchmark

# Test high-volume processing
npm run load-test

# Check memory usage
npm run memory-test
```

### Step 13: Final Validation

```bash
# Comprehensive lab validation
./validation/validate-lab-completion.sh

# This validates:
# - All streams created correctly
# - Consumer groups functioning
# - Events processed successfully
# - Analytics data generated
# - Monitoring tools working
```

---

## 🔍 Using Redis Insight

### Stream Visualization
1. Open Redis Insight
2. Connect to your Redis instance
3. Navigate to Browser → claims:events
4. View stream contents and consumer groups
5. Monitor real-time processing

### Key Commands in Redis Insight CLI:
```bash
# View stream information
XINFO STREAM claims:events

# Check consumer groups
XINFO GROUPS claims:events

# View latest events
XREAD COUNT 10 STREAMS claims:events $

# Check consumer lag
XPENDING claims:events processors

# View analytics data
ZRANGE analytics:processing_times:$(date +%Y-%m-%d) 0 -1 WITHSCORES
```

---

## 📊 Expected Outcomes

After completing this lab, you should have:

### ✅ **Functional Components:**
- Event sourcing system processing claims events
- Multiple consumer groups handling different business functions
- Real-time analytics generating business insights
- Monitoring and alerting system for stream health
- Complete audit trail with event replay capabilities

### ✅ **Technical Skills:**
- Stream creation and management with XADD
- Consumer group implementation with XREADGROUP
- Event sourcing patterns and best practices
- Real-time analytics with stream aggregation
- Error handling and recovery strategies
- Performance monitoring and optimization

### ✅ **Business Value:**
- Immutable audit trails for regulatory compliance
- Real-time claim processing reducing customer wait times
- Scalable architecture supporting business growth
- Analytics enabling data-driven business decisions
- Robust error handling ensuring business continuity

---

## 🔧 Troubleshooting

### Common Issues

1. **Consumer Lag:**
   ```bash
   # Check pending messages
   npm run check-lag
   
   # Reset consumer group if needed
   npm run reset-consumers
   ```

2. **Stream Memory Usage:**
   ```bash
   # Check stream size
   npm run check-memory
   
   # Trim old events
   npm run trim-streams
   ```

3. **Connection Issues:**
   ```bash
   # Test connection
   npm run test-connection
   
   # Verify environment variables
   npm run check-config
   ```

### Getting Help
- Check the troubleshooting guide: `docs/troubleshooting.md`
- View error logs: `logs/error.log`
- Run diagnostics: `npm run diagnose`

---

## 🎓 Lab Completion

### Verification Checklist
- [ ] All tests pass (`npm test`)
- [ ] Consumer groups processing events
- [ ] Analytics data being generated
- [ ] Monitoring tools functioning
- [ ] Event replay working correctly
- [ ] Performance benchmarks completed

### Skills Demonstrated
- **Event Sourcing:** Implemented complete event-driven architecture
- **Stream Processing:** Used Redis Streams for real-time data processing
- **Consumer Groups:** Built scalable message processing system
- **Analytics:** Created real-time business intelligence capabilities
- **Monitoring:** Implemented comprehensive system observability
- **Testing:** Built automated validation and testing frameworks

---

## 🎯 Next Steps

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

**Excellent work!** You've mastered event sourcing with Redis Streams and built a production-ready claims processing system with complete monitoring, testing, and validation capabilities. Ready for advanced analytics in Lab 9! 🚀

## 📖 Additional Resources

### Redis Streams Documentation
- [Redis Streams Introduction](https://redis.io/topics/streams-intro)
- [Consumer Groups Guide](https://redis.io/commands#stream)
- [Stream Commands Reference](https://redis.io/commands#stream)

### Event Sourcing Patterns
- Event Store patterns and best practices
- CQRS implementation with Redis
- Microservices event-driven architecture
- Stream processing for real-time analytics
