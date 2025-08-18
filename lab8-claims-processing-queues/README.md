# Lab 8: Claims Processing Queues

**Duration:** 45 minutes  
**Focus:** JavaScript with Redis Lists for queue-based claims processing  
**Level:** Intermediate

## 📁 Project Structure

```
lab8-claims-processing-queues/
├── lab8.md                      # Complete lab instructions (START HERE)
├── package.json                 # Node.js dependencies
├── src/
│   ├── basic-queue.js           # Basic FIFO/LIFO queue implementation
│   ├── priority-queue.js        # Priority-based queue processing
│   ├── reliable-queue.js        # Reliable queue with DLQ
│   ├── queue-monitor.js         # Real-time monitoring dashboard
│   └── test-all.js              # Test runner for all implementations
├── scripts/
│   └── load-claims-data.sh      # Sample data loader
├── test-data/                   # Test data directory
├── monitoring/                  # Monitoring utilities
└── README.md                    # This file
```

## 🚀 Quick Start

1. **Start Redis:**
   ```bash
   docker run -d --name redis-claims-lab8 -p 6379:6379 redis:7-alpine
   ```

2. **Install Dependencies:**
   ```bash
   npm install
   ```

3. **Load Sample Data:**
   ```bash
   npm run load-data
   ```

4. **Run Examples:**
   ```bash
   npm start          # Basic queue
   npm run priority   # Priority queues
   npm run reliable   # Reliable queue with DLQ
   npm run monitor    # Real-time monitoring
   ```

## 🎯 Learning Objectives

✅ Implement FIFO and LIFO queue patterns  
✅ Build priority-based claim routing systems  
✅ Create reliable queues with retry logic  
✅ Implement dead letter queues  
✅ Monitor queue health in real-time  
✅ Build distributed worker patterns  

## 🔧 Key Redis Commands

- **LPUSH/RPUSH** - Add to queue
- **LPOP/RPOP** - Remove from queue  
- **BRPOP/BLPOP** - Blocking pop operations
- **BRPOPLPUSH** - Atomic move between lists
- **LLEN** - Get queue length
- **LRANGE** - View queue contents
- **LREM** - Remove specific items

## 📊 Queue Patterns Implemented

### 1. Basic Queue (FIFO/LIFO)
- Simple enqueue/dequeue operations
- Non-blocking and blocking variants
- Queue statistics and monitoring

### 2. Priority Queue System  
- Multiple priority levels (URGENT, HIGH, NORMAL, LOW)
- Worker pool processing
- Automatic routing based on claim priority

### 3. Reliable Queue with DLQ
- Automatic retry with configurable attempts
- Dead letter queue for failed processing
- Timeout monitoring and recovery
- Processing acknowledgment pattern

## 🔍 Monitoring Features

- Real-time queue depth monitoring
- Processing rate tracking
- Dead letter queue alerts
- Worker performance metrics
- Processing time analysis

## 💡 Best Practices

1. **Use blocking operations** to reduce polling overhead
2. **Implement proper error handling** and retry logic
3. **Monitor queue depths** to prevent overflow
4. **Use DLQ** for failed message investigation
5. **Set appropriate timeouts** for processing
6. **Implement circuit breakers** for downstream failures

## 🆘 Troubleshooting

**Queue not processing:**
```bash
redis-cli LLEN claims:queue:pending
redis-cli LRANGE claims:queue:pending 0 -1
```

**Check for stuck messages:**
```bash
redis-cli LLEN claims:queue:reliable:processing
redis-cli HGETALL claims:processing:timestamps
```

**View DLQ contents:**
```bash
redis-cli LRANGE claims:queue:reliable:dlq 0 -1
```

## 🎓 Learning Path

This lab is part of the Redis Mastering Course:

1. Lab 6: JavaScript Redis Client Basics
2. Lab 7: Customer Profiles with Hashes
3. **Lab 8: Claims Processing Queues** ← *You are here*
4. Lab 9: Analytics with Sets
5. Lab 10: Advanced Caching Patterns

---

**Ready to start?** Open `lab8.md` and master queue-based processing with Redis Lists! 🚀
