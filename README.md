# Lab 8: Claims Event Sourcing with Redis Streams

## 🎯 Overview

This lab demonstrates implementing event-driven claims processing using Redis Streams for immutable audit trails, real-time analytics, and scalable event sourcing patterns in insurance applications.

## ⚙️ Environment Configuration

Configure Redis connection using environment variables:

```bash
export REDIS_HOST=your-redis-host    # Default: localhost
export REDIS_PORT=6379               # Default: 6379
export REDIS_PASSWORD=your-password  # Default: none
```

## 🚀 Quick Start

1. **Install Dependencies:**
   ```bash
   npm install
   ```

2. **Load Sample Data:**
   ```bash
   npm run load-data
   ```

3. **Start Consumers (in separate terminals):**
   ```bash
   npm run processor     # Claims processor
   npm run analytics     # Analytics consumer
   npm run notifications # Notification consumer
   ```

4. **Submit Test Claims:**
   ```bash
   npm run submit-claims
   ```

5. **Monitor in Real-time:**
   ```bash
   npm run monitor      # Stream monitoring
   npm run dashboard    # Analytics dashboard
   ```

## 📂 Project Structure

```
lab8-claims-event-sourcing/
├── src/
│   ├── models/
│   │   └── claim.js                 # Claim domain model
│   ├── services/
│   │   ├── claims-producer.js       # Event producer
│   │   └── analytics-dashboard.js   # Real-time dashboard
│   ├── consumers/
│   │   ├── claims-processor.js      # Business logic consumer
│   │   ├── analytics-consumer.js    # Metrics aggregation
│   │   └── notification-consumer.js # Alert system
│   └── utils/
│       └── redis-client.js          # Connection management
├── scripts/
│   ├── load-sample-data.js          # Test data setup
│   ├── submit-test-claims.js        # Claim submission
│   ├── monitor-claims.js            # Real-time monitoring
│   ├── replay-events.js             # Event replay demo
│   ├── generate-analytics-report.js # Comprehensive reporting
│   └── test-consumer-recovery.js    # Recovery testing
├── tests/
│   └── test-claims-streams.js       # Automated test suite
├── docs/
│   └── streams-architecture.md      # Architecture documentation
└── data/                            # Generated reports
```

## 🔧 Key Components

### Event Producer (`claims-producer.js`)
- Submit new claims to the event stream
- Handle claim status updates
- Manage event schema and validation
- Support different event types

### Consumer Groups
- **Processors:** Business logic and state transitions
- **Analytics:** Real-time metrics and reporting
- **Notifications:** Customer and stakeholder alerts

### Analytics Dashboard
- Real-time processing metrics
- Claims status distribution
- Performance analytics
- Stream health monitoring

## 📊 Event Types

### Core Claim Events
- `claim.submitted` - Initial claim creation
- `claim.assigned` - Assigned to adjuster
- `claim.document.uploaded` - Supporting docs added
- `claim.investigated` - Investigation activities
- `claim.approved` - Approval decision
- `claim.rejected` - Denial with reasons
- `claim.payment.initiated` - Payment processing
- `claim.payment.completed` - Final settlement

## 🎓 Learning Outcomes

### Event Sourcing Concepts
- Immutable event logs
- Event replay capabilities
- Temporal queries
- Audit trail creation

### Redis Streams Features
- Stream operations (`XADD`, `XREAD`, `XREADGROUP`)
- Consumer groups and load balancing
- Message acknowledgment patterns
- Stream monitoring and maintenance

### Production Patterns
- Error handling and recovery
- Consumer scaling strategies
- Performance monitoring
- Data consistency patterns

## 🧪 Testing

### Automated Tests
```bash
npm test
```

### Manual Testing Scenarios
```bash
# Test event replay
node scripts/replay-events.js

# Test consumer recovery
node scripts/test-consumer-recovery.js

# Generate analytics report
node scripts/generate-analytics-report.js
```

## 📈 Monitoring

### Real-time Dashboard
```bash
npm run dashboard
```

### Stream Monitoring
```bash
npm run monitor
```

### Redis Insight Integration
1. Connect Redis Insight to your Redis instance
2. Navigate to Streams section
3. Monitor `claims:events` stream
4. Examine consumer groups and processing lag

## 🔄 Event Replay Capabilities

This implementation supports complete event replay for:
- **Debugging:** Reproduce production issues
- **Testing:** Validate new business logic
- **Auditing:** Investigate claim decisions
- **Migration:** Rebuild data from events

## 📚 Advanced Features

### Consumer Recovery
- Automatic detection of failed consumers
- Message claiming from idle consumers
- Dead letter queue handling
- Exponential backoff for retries

### Analytics Engine
- Real-time metrics aggregation
- Historical trend analysis
- Performance benchmarking
- Compliance reporting

### Scalability Patterns
- Consumer group partitioning
- Load balancing strategies
- Memory optimization
- Stream maintenance

## 🔧 Production Considerations

### Stream Management
- Configure appropriate stream lengths
- Implement stream trimming policies
- Monitor memory usage
- Plan for data archival

### Error Handling
- Implement circuit breakers
- Design retry policies
- Create dead letter queues
- Monitor error rates

### Performance Optimization
- Batch message processing
- Optimize consumer throughput
- Cache frequently accessed data
- Minimize Redis round trips

This lab provides a comprehensive foundation for building event-driven insurance applications with Redis Streams, emphasizing production-ready patterns and enterprise-scale considerations.
