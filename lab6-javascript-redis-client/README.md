# Lab 6: JavaScript Redis Client for Business Systems

**Duration:** 45 minutes  
**Focus:** JavaScript Redis client setup, connection management, and fundamental operations  
**Language:** JavaScript (Node.js)

## 📁 Project Structure

```
lab6-javascript-redis-client/
├── lab6.md                              # Complete lab instructions (START HERE)
├── package.json                         # Node.js project configuration
├── .env.example                         # Environment variables template
├── src/
│   ├── app.js                          # Main application entry point
│   ├── config/
│   │   └── redis.config.js            # Redis connection configuration
│   ├── utils/
│   │   └── redisClient.js             # Redis client manager
│   └── services/
│       ├── customerService.js         # Customer data operations
│       └── inventoryService.js        # Inventory management operations
├── test/
│   └── integration/
│       └── redis.test.js              # Integration tests
├── scripts/
│   ├── load-sample-data.sh            # Sample data loader
│   └── monitor-performance.js         # Performance monitoring script
├── docs/
│   └── troubleshooting.md             # Troubleshooting guide
└── README.md                           # This file
```

## 🚀 Quick Start

1. **Read Instructions:** Open `lab6.md` for complete lab guidance
2. **Start Redis:** `docker run -d --name redis-lab -p 6379:6379 redis:7-alpine`
3. **Install Dependencies:** `npm install`
4. **Load Sample Data:** `./scripts/load-sample-data.sh`
5. **Run Application:** `npm start`
6. **Run Tests:** `npm test`
7. **Monitor Performance:** `npm run monitor`

## 🎯 Lab Objectives

✅ Set up Node.js environment with Redis client  
✅ Establish and manage Redis connections from JavaScript  
✅ Implement basic CRUD operations for business entities  
✅ Handle connection errors and implement retry logic  
✅ Build promise-based and async/await patterns  
✅ Monitor JavaScript client performance  

## 🔧 Key JavaScript Patterns Covered

### Connection Management
```javascript
const client = redis.createClient({
  socket: { host: 'localhost', port: 6379 },
  reconnectStrategy: (retries) => Math.min(retries * 100, 3000)
});
```

### Async/Await Operations
```javascript
async function saveCustomer(id, data) {
  await client.set(`customer:${id}`, JSON.stringify(data));
}
```

### Error Handling
```javascript
try {
  const result = await client.get(key);
} catch (error) {
  console.error('Redis operation failed:', error);
}
```

### Batch Operations
```javascript
const multi = client.multi();
customers.forEach(c => multi.set(c.key, c.value));
await multi.exec();
```

## 📝 Available Scripts

- `npm start` - Run the main application
- `npm run dev` - Run with nodemon for development
- `npm test` - Run integration tests
- `npm run monitor` - Run performance monitoring

## 🆘 Troubleshooting

**Connection Issues:**
```bash
# Check Redis status
docker ps | grep redis
redis-cli ping

# Restart if needed
docker restart redis-lab
```

**Module Issues:**
```bash
# Clear node_modules and reinstall
rm -rf node_modules package-lock.json
npm install
```

**Async Issues:**
- Always use try-catch with async/await
- Ensure proper connection before operations
- Handle promise rejections

## 🎓 Learning Path

This lab is part of the Redis JavaScript series:

1. **Lab 1-5:** CLI and fundamentals
2. **Lab 6:** JavaScript Redis Client ← *You are here*
3. **Lab 7:** Customer Profiles & Policy Management
4. **Lab 8:** Claims Processing Queues
5. **Lab 9:** Analytics with Sets

---

**Ready to start?** Open `lab6.md` and begin building JavaScript Redis applications! 🚀
