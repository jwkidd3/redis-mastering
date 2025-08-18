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
