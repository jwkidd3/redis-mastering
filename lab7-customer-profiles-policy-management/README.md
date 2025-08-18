# Lab 7: Customer Profiles & Policy Management

**Duration:** 45 minutes  
**Focus:** JavaScript Redis client with hash data structures  
**Industry:** Customer and policy management systems

## 📁 Project Structure

```
lab7-customer-profiles-policy-management/
├── lab7.md                          # Complete lab instructions (START HERE)
├── package.json                     # Node.js project configuration
├── config/
│   └── redis-config.js             # Redis client configuration
├── src/
│   ├── customer-manager.js         # Customer management class
│   └── policy-manager.js           # Policy management class
├── scripts/
│   └── load-sample-data.sh         # Sample data loader
├── docs/
│   └── troubleshooting.md          # Troubleshooting guide
├── test-connection.js               # Connection test script
├── test-customer.js                 # Customer operations test
├── test-policy.js                   # Policy operations test
├── test-integration.js              # Integration test
├── benchmark.js                     # Performance benchmark
└── README.md                        # This file
```

## 🚀 Quick Start

1. **Install Dependencies:**
   ```bash
   npm install
   ```

2. **Start Redis:**
   ```bash
   docker run -d --name redis-lab7 -p 6379:6379 redis:7-alpine
   ```

3. **Test Connection:**
   ```bash
   npm run test-connection
   ```

4. **Load Sample Data:**
   ```bash
   ./scripts/load-sample-data.sh
   ```

5. **Run Tests:**
   ```bash
   npm run test-customer
   npm run test-policy
   npm run test-integration
   ```

## 📊 Data Model

### Customer Structure
```
customer:{id}:profile     # Customer details (hash)
customer:{id}:preferences # Customer preferences (hash)
customer:{id}:policies    # Customer's policies (set)
customer:{id}:claims      # Customer's claims (set)
```

### Policy Structure
```
policy:{type}:{number}:details    # Policy details (hash)
policy:{type}:{number}:attributes # Type-specific attributes (hash)
policy:{type}:{number}:claims     # Related claims (set)
policy:{type}:{number}:renewals   # Renewal history (sorted set)
```

## 🎯 Learning Objectives

- Implement customer profile management with Redis hashes
- Build policy CRUD operations using hash data structures
- Model complex nested data for customer preferences and history
- Implement efficient bulk operations for policy renewals
- Apply atomic field updates for risk assessments and premiums
- Create relationship mappings between customers, policies, and claims

## 📝 Available Scripts

- `npm run test-connection` - Test Redis connection
- `npm run test-customer` - Test customer operations
- `npm run test-policy` - Test policy operations
- `npm run test-integration` - Run integration tests
- `npm run benchmark` - Run performance benchmarks

## 🔍 Verification with Redis Insight

1. Connect to `localhost:6379`
2. Browse keys with patterns:
   - `customer:*` - Customer data
   - `policy:*` - Policy data
   - `customers:active` - Active customer set
   - `policies:*:active` - Active policies by type

## 🆘 Troubleshooting

See `docs/troubleshooting.md` for common issues and solutions.

## 🎓 Learning Path

This lab is part of the Redis mastery series:

1. Lab 1: Redis Environment & CLI
2. Lab 2: RESP Protocol Analysis
3. Lab 3: String Operations
4. Lab 4: Key Management & TTL
5. Lab 5: Advanced CLI Operations
6. Lab 6: JavaScript Redis Client
7. **Lab 7: Customer Profiles & Policy Management** ← You are here
8. Lab 8: Claims Processing Queues
9. Lab 9: Analytics with Sets
10. Lab 10: Advanced Caching Patterns

## 🏆 Key Achievements

By completing this lab, you will have mastered:

- **Hash Operations:** Complete CRUD operations with Redis hashes
- **Data Modeling:** Complex entity relationships in Redis
- **Performance:** Bulk operations and pipeline optimization
- **Business Logic:** Risk scoring and policy lifecycle management
- **Production Patterns:** Audit trails and data integrity
- **JavaScript Integration:** Async/await patterns with Redis client

---

**Ready to start?** Open `lab7.md` and begin building your customer and policy management system! 🚀
