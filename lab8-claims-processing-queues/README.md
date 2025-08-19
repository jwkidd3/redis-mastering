# Lab 8: Claims Processing Queues with Lists

**Duration:** 45 minutes  
**Focus:** JavaScript Redis Lists for queue processing and workflow management  
**Platform:** Node.js + Redis Lists + Redis Insight

## 🏗️ Project Structure

```
lab8-claims-processing-queues/
├── lab8.md                           # Complete lab instructions (START HERE)
├── src/
│   ├── redis-client.js              # Redis connection management
│   ├── claims-model.js              # Claim data model
│   ├── claims-queue.js              # Queue management system
│   ├── claims-processor.js          # Claim processing logic
│   └── queue-monitor.js             # Real-time monitoring
├── examples/
│   ├── submit-claims.js             # Claim submission examples
│   ├── process-claims.js            # Processing workflow demo
│   ├── monitor-queues.js            # Queue monitoring dashboard
│   └── queue-analytics.js          # Performance analytics
├── scripts/
│   └── test-system.js               # System integration test
├── solutions/
│   └── complete-system.js           # Complete solution reference
├── reference/
│   └── redis-lists-reference.md     # Redis Lists command reference
└── README.md                        # This file
```

## 🚀 Quick Start

1. **Initialize project:**
   ```bash
   npm install
   ```

2. **Update Redis connection:**
   Edit `src/redis-client.js` with your server details

3. **Test connection:**
   ```bash
   npm test
   ```

4. **Run complete workflow:**
   ```bash
   # Terminal 1: Monitor queues
   npm run monitor
   
   # Terminal 2: Start processor
   npm run process
   
   # Terminal 3: Submit claims
   npm run submit
   ```

## 📋 Prerequisites

- **Node.js** installed on your machine
- **Redis CLI** for command-line operations
- **Redis Insight** for GUI visualization
- **Redis server** connection details from instructor
- **Completed Labs 1-7** (Redis fundamentals and JavaScript integration)

## 🎯 Learning Objectives

After completing this lab, you will:
- **Build queue systems** using Redis lists for workflow processing
- **Implement priority queues** with urgent and standard processing
- **Use blocking operations** for real-time claim processing
- **Create monitoring systems** for queue status and performance
- **Handle error scenarios** with dead letter queues
- **Analyze queue performance** with comprehensive analytics

## 🔧 Key Technologies

### Redis Lists Operations
```javascript
// Queue operations
await client.lPush(queue, item)           // Add to queue
await client.rPop(queue)                  // Process item
await client.brPop([queues], timeout)     // Wait for items
await client.lLen(queue)                  // Queue length
await client.lRange(queue, 0, -1)         // View all items
```

### Priority Queue Pattern
```javascript
// Check urgent queue first, then standard
let claimId = await client.rPop('urgent_queue')
if (!claimId) {
    claimId = await client.rPop('standard_queue')
}
```

### Workflow Management
```javascript
// Move through processing states
await client.lPush('processing_queue', claimId)  // Start processing
await client.lRem('processing_queue', 1, claimId) // Remove when done
await client.lPush('completed_queue', claimId)    // Mark complete
```

## 📊 What You'll Build

### 1. Claims Submission System
- Priority-based queue routing (urgent vs standard)
- Comprehensive claim data model
- Automatic queue assignment based on claim type

### 2. Claims Processing Engine
- Real-time processing with blocking operations
- Priority-based claim selection
- Status tracking through workflow states

### 3. Monitoring Dashboard
- Real-time queue statistics
- Recent activity display
- Performance metrics and analytics

### 4. Error Handling System
- Dead letter queues for failed processing
- Retry mechanisms with exponential backoff
- Comprehensive error logging and reporting

## 🧪 Testing Scenarios

### Basic Queue Operations
```bash
# Submit various claims
npm run submit

# Process claims in order
npm run process

# Monitor queue status
npm run monitor
```

### Priority Testing
- Submit mix of urgent and standard claims
- Verify urgent claims process first
- Monitor queue lengths and processing order

### Error Simulation
- Submit invalid claims to test error handling
- Monitor failed queue population
- Test retry and recovery mechanisms

## 📈 Performance Analytics

The system tracks:
- **Queue throughput** - Claims processed per minute
- **Success rates** - Completion vs failure percentages
- **Priority distribution** - Urgent vs standard claim ratios
- **Processing times** - Average time per claim type
- **Queue depths** - Real-time queue length monitoring

## 🔍 Redis Insight Integration

Use Redis Insight to:
1. **Visualize queue structures** - See list data in real-time
2. **Monitor queue lengths** - Track LLEN values for each queue
3. **Inspect claim data** - Browse hash entries with claim details
4. **Debug workflow issues** - Use CLI to investigate stuck claims
5. **Performance monitoring** - Watch memory usage and operation counts

## 🆘 Troubleshooting

### Connection Issues
```bash
# Test Redis connection
redis-cli -h redis-server.training.com -p 6379 PING

# Check queue exists
redis-cli -h redis-server.training.com -p 6379 EXISTS claims:queue:standard
```

### Queue Problems
```bash
# Check queue lengths
redis-cli -h redis-server.training.com -p 6379 LLEN claims:queue:standard

# View queue contents
redis-cli -h redis-server.training.com -p 6379 LRANGE claims:queue:standard 0 -1

# Clear stuck queues (if needed)
redis-cli -h redis-server.training.com -p 6379 DEL claims:queue:processing
```

### Processing Issues
- Check processor logs for error messages
- Verify claim data format in Redis hash
- Monitor blocking operation timeouts
- Review dead letter queue for failed claims

## 🏁 Success Criteria

By the end of this lab, you should:
- [ ] Successfully submit claims to priority queues
- [ ] Process claims using blocking operations
- [ ] Monitor queue status in real-time
- [ ] Handle errors with dead letter queues
- [ ] Generate performance analytics reports
- [ ] Understand Redis Lists for queue management

## ⏭️ Next Steps

**Lab 9 Preview:** Analytics with Sets and Sorted Sets for advanced data analysis and reporting

This lab establishes the foundation for understanding Redis queue patterns that are essential for building scalable, real-time processing systems.

## 💡 Key Takeaways

🌟 **Redis Lists excel at queue processing** - Perfect for FIFO workflows, priority handling, and real-time processing with blocking operations.

The patterns learned here apply to:
- **Job processing** systems
- **Event-driven** architectures  
- **Workflow management** platforms
- **Real-time notification** systems
- **Background task** processing
