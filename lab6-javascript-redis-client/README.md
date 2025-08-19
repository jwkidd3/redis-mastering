# Lab 6: JavaScript Redis Client Setup

**Duration:** 45 minutes  
**Focus:** Node.js Redis integration and basic data operations  
**Platform:** Node.js + Redis client + Visual Studio Code  
**Learning Objective:** Master JavaScript Redis client development for customer and policy management

## 🏗️ Project Structure

```
lab6-javascript-redis-client/
├── lab6.md                           # Complete lab instructions (START HERE)
├── src/                              # Source code directory
│   ├── config/redis.js              # Redis connection configuration
│   ├── clients/redisClient.js        # Redis client wrapper
│   ├── models/                       # Data models
│   │   ├── customer.js               # Customer operations
│   │   └── policy.js                 # Policy operations
│   └── app.js                        # Main application
├── examples/                         # Example scripts
│   ├── basic-operations.js           # Basic Redis operations
│   └── performance-test.js           # Performance testing
├── tests/                            # Test files
│   └── connection-test.js            # Connection testing
├── docs/                             # Documentation
│   ├── javascript-patterns.md        # JS Redis patterns
│   └── troubleshooting.md           # Troubleshooting guide
├── scripts/                          # Setup scripts
│   ├── setup-lab.sh                 # Environment setup
│   └── quick-start.sh                # Quick start script
├── package.json.template             # Node.js dependencies template
├── .env.template                     # Environment variables template
└── README.md                         # This file
```

## 🚀 Quick Start

1. **Check prerequisites:**
   ```bash
   ./scripts/setup-lab.sh
   ```

2. **Initialize project:**
   ```bash
   cp package.json.template package.json
   npm install
   ```

3. **Configure environment:**
   ```bash
   cp .env.template .env
   # Edit .env with Redis server details from instructor
   ```

4. **Test connection:**
   ```bash
   npm run test
   ```

5. **Follow lab instructions:**
   Open `lab6.md` for complete guidance

## 📋 Prerequisites

- **Node.js 16+** installed
- **npm** package manager
- **Redis server details** from instructor
- **Visual Studio Code** (recommended)
- **Basic JavaScript knowledge**

## 🎯 Learning Objectives

After completing this lab, you will:
- **Set up Node.js Redis client** with remote server connection
- **Create connection management** utilities for production applications
- **Implement CRUD operations** for customer and policy data in JavaScript
- **Handle errors and testing** for reliable Redis applications
- **Use environment configuration** for development and production
- **Master async/await patterns** with Redis operations

## 🔧 Key Technologies

### Node.js Packages
```json
{
  "redis": "^4.6.0",         // Official Redis client
  "dotenv": "^16.3.0",       // Environment variables
  "nodemon": "^3.0.0"        // Development auto-restart
}
```

### Essential Patterns
```javascript
// Connection with error handling
const client = redis.createClient({
    socket: { host: 'hostname', port: 6379 },
    password: 'password'
});

// Async operations with try-catch
try {
    await client.set('key', 'value');
    const result = await client.get('key');
} catch (error) {
    console.error('Redis error:', error);
}

// JSON data storage
await client.set('user', JSON.stringify(userData));
const user = JSON.parse(await client.get('user'));
```

## 📊 What You'll Build

### Customer Management System
- **Customer CRUD operations** with JSON storage
- **Policy associations** with relationship tracking
- **Data validation** and error handling
- **Performance testing** with batch operations

### Redis Client Wrapper
- **Connection management** with auto-reconnect
- **Health checking** and monitoring
- **Error handling** patterns
- **Environment configuration**

### Example Applications
- **Basic operations** script for learning
- **Performance testing** for optimization
- **Interactive examples** for experimentation

## 🧪 Available Scripts

```bash
npm start         # Run main application
npm run dev       # Development with auto-restart
npm test          # Test Redis connection
npm run examples  # Run example operations
npm run performance # Performance testing
```

## 🆘 Troubleshooting

### Common Issues

1. **Connection refused:** Check hostname and port in .env
2. **Module not found:** Run `npm install`
3. **Auth required:** Add password to .env file
4. **Syntax errors:** Ensure Node.js 16+ and proper async/await usage

### Diagnostic Tools

```bash
# Test environment
./scripts/setup-lab.sh

# Quick connection test
node tests/connection-test.js

# Manual Redis CLI test
redis-cli -h [hostname] -p [port] ping
```

See `docs/troubleshooting.md` for comprehensive solutions.

## 📖 Reference Materials

- **`docs/javascript-patterns.md`** - Redis JavaScript patterns and best practices
- **`docs/troubleshooting.md`** - Comprehensive problem-solving guide
- **`examples/`** - Practical code examples and performance tests
- **Official Redis Node.js docs** - https://github.com/redis/node-redis

## 🏁 Success Criteria

By the end of this lab, you should:
- [ ] Successfully connect to Redis server via Node.js
- [ ] Create and retrieve customer and policy records
- [ ] Implement error handling for all operations
- [ ] Use environment variables for configuration
- [ ] Run performance tests with multiple operations
- [ ] Integrate with Redis Insight for data visualization
- [ ] Understand production-ready Redis client patterns

## ⏭️ Next Steps

**Lab 7 Preview:** Advanced data structures using Redis Hashes for complex customer profiles and nested policy management.

This lab establishes the foundation for JavaScript-based Redis development that will be expanded in subsequent labs.

---

**🎯 Ready to start? Open `lab6.md` and begin your JavaScript Redis journey!**
