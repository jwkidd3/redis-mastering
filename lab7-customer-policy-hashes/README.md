# Lab 7: Customer Profiles & Policy Management with Hashes

**Duration:** 45 minutes  
**Focus:** Redis Hash operations with JavaScript for structured data management  
**Prerequisites:** Lab 6 completed (JavaScript Redis client setup)

## 🏗️ Project Structure

```
lab7-customer-policy-hashes/
├── lab7.md                              # Complete lab instructions (START HERE)
├── package.json                         # Node.js project configuration
├── test-connection.js                   # Redis connection test
├── setup-lab.sh                        # Environment setup script
├── src/
│   ├── redis-client.js                 # Redis connection management
│   ├── customer-manager.js             # Customer CRUD operations
│   ├── policy-manager.js               # Policy management system
│   └── crm-system.js                   # Integrated CRM system
├── examples/
│   ├── test-customers.js               # Customer operations demo
│   ├── test-policies.js                # Policy operations demo
│   ├── test-integrated-system.js       # Full CRM system demo
│   ├── advanced-hash-operations.js     # Advanced hash techniques
│   ├── hash-performance-test.js        # Performance analysis
│   └── customer-search-example.js      # Search and indexing
├── reference/
│   └── redis-hash-commands.md          # Complete hash commands reference
└── README.md                           # This file
```

## 🚀 Quick Start

1. **Run setup script:**
   ```bash
   ./setup-lab.sh
   ```

2. **Test Redis connection:**
   ```bash
   npm test
   ```

3. **Follow lab instructions:**
   Open `lab7.md` for complete guidance

4. **Run example demos:**
   ```bash
   npm run test-customers      # Customer management
   npm run test-policies       # Policy management
   npm run test-integrated     # Complete CRM system
   ```

## 📋 Prerequisites

- **Node.js** installed (v14+ recommended)
- **npm** package manager
- **Redis server** accessible (connection details in `src/redis-client.js`)
- **Lab 6 completed** (JavaScript Redis client knowledge)

## 🎯 Learning Objectives

After completing this lab, you will:
- **Master Redis hashes** for structured data storage
- **Build customer management** systems with JavaScript
- **Implement policy management** with complex data structures
- **Handle JSON data** in Redis hash fields
- **Create integrated systems** combining multiple data types
- **Optimize hash operations** for performance

## 🔧 Key Technologies

### Redis Hash Operations
```javascript
// Store structured data
await client.hSet('customer:123', {
    'firstName': 'John',
    'lastName': 'Doe',
    'email': 'john@example.com'
});

// Retrieve specific fields
const email = await client.hGet('customer:123', 'email');

// Get all data
const customer = await client.hGetAll('customer:123');
```

### JavaScript Classes
- **CustomerManager**: CRUD operations for customer profiles
- **PolicyManager**: Policy lifecycle management
- **CRMSystem**: Integrated customer relationship management

## 📊 What You'll Build

1. **Customer Profile System**
   - Create, read, update, delete customer records
   - Store contact information and preferences
   - Track customer lifecycle and status

2. **Policy Management System**
   - Manage multiple policy types (auto, home, life)
   - Store policy details, premiums, and coverage
   - Track policy relationships to customers

3. **Integrated CRM System**
   - Combined customer and policy operations
   - Generate customer reports and summaries
   - Handle complex business logic

## 🧪 Available Tests

### Core Functionality
```bash
npm run test-customers      # Customer CRUD operations
npm run test-policies       # Policy management features
npm run test-integrated     # Complete CRM workflow
```

### Advanced Features
```bash
npm run test-advanced       # Advanced hash operations
node examples/hash-performance-test.js      # Performance analysis
node examples/customer-search-example.js    # Search and indexing
```

## 📖 Reference Materials

- **`reference/redis-hash-commands.md`** - Complete Redis hash command reference
- **`src/` directory** - Well-documented source code examples
- **`examples/` directory** - Practical usage demonstrations

## 🔍 Redis Insight Integration

This lab extensively uses Redis Insight for:
- **Visual hash inspection** - See hash structure and fields
- **CLI operations** - Execute commands directly in the GUI
- **Memory analysis** - Monitor hash memory usage
- **Real-time monitoring** - Watch operations as they happen

## 🆘 Troubleshooting

### Connection Issues
```bash
# Test connection
npm test

# Check Redis server details
cat src/redis-client.js
```

### Common Hash Issues
```javascript
// Always check if field exists
const exists = await client.hExists('key', 'field');

// Handle JSON data properly
const data = JSON.stringify(complexObject);
await client.hSet('key', 'field', data);
```

## 🏁 Success Criteria

By the end of this lab, you should:
- [ ] Successfully connect to Redis with JavaScript
- [ ] Create and manage customer profiles using hashes
- [ ] Implement policy management with complex data
- [ ] Build integrated systems combining multiple features
- [ ] Use Redis Insight to visualize hash data structures
- [ ] Understand hash performance characteristics

## ⏭️ Next Steps

**Lab 8 Preview:** Redis Lists for implementing task queues and workflow management systems.

## 💡 Key Takeaways

- **Hashes are perfect for structured data** like profiles and records
- **Field-level operations** provide granular control and efficiency
- **JavaScript integration** makes Redis powerful for web applications
- **Memory efficiency** makes hashes ideal for large datasets
- **Real-world applications** demonstrate practical Redis usage patterns

## 🌟 Pro Tips

- **Use consistent key naming** (`customer:ID`, `policy:NUMBER`)
- **Store JSON in hash fields** for complex nested data
- **Leverage HMGET** for retrieving multiple fields efficiently
- **Use HINCRBY** for atomic numeric operations
- **Monitor memory usage** with Redis Insight for optimization
