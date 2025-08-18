# Lab 9: Analytics with Sets and Sorted Sets

**Duration:** 45 minutes  
**Focus:** JavaScript Redis client with Sets and Sorted Sets for business analytics  
**Technologies:** Node.js, Redis, JavaScript ES6+

## 📁 Project Structure

```
lab9-analytics-sets-sortedsets/
├── lab9.md                           # Complete lab instructions (START HERE)
├── package.json                      # Node.js project configuration
├── .env                             # Environment configuration
├── src/
│   ├── index.js                     # Main application entry
│   ├── redis-client.js              # Redis connection module
│   ├── test-connection.js           # Connection testing utility
│   ├── load-sample-data.js          # Sample data loader
│   ├── customer-segmentation.js     # Customer segmentation analytics
│   ├── agent-leaderboard.js         # Agent performance tracking
│   ├── risk-analysis.js             # Risk distribution analysis
│   ├── coverage-analysis.js         # Coverage gap identification
│   └── analytics-dashboard.js       # Integrated analytics dashboard
├── scripts/                         # Utility scripts
├── docs/                           # Additional documentation
├── test-data/                      # Test data files
├── analytics-tools/                # Analytics utilities
└── README.md                       # This file
```

## 🚀 Quick Start

1. **Install Dependencies:**
   ```bash
   npm install
   ```

2. **Start Redis:**
   ```bash
   docker run -d --name redis-analytics-lab9 -p 6379:6379 redis:7-alpine
   ```

3. **Test Connection:**
   ```bash
   npm test
   ```

4. **Load Sample Data:**
   ```bash
   npm run load-data
   ```

5. **Run Analytics:**
   ```bash
   npm run analytics
   ```

## 🎯 Lab Objectives

✅ Master Sets for customer segmentation and grouping  
✅ Implement Sorted Sets for rankings and leaderboards  
✅ Use Set operations for complex analytics queries  
✅ Build real-time analytics dashboards with JavaScript  
✅ Apply scoring algorithms for business metrics  
✅ Create coverage analysis and upsell identification systems

## 🔧 Available Commands

| Command | Description |
|---------|-------------|
| `npm start` | Run the main application |
| `npm test` | Test Redis connection |
| `npm run load-data` | Load sample analytics data |
| `npm run segmentation` | Run customer segmentation analysis |
| `npm run leaderboard` | Display agent performance leaderboards |
| `npm run risk-analysis` | Analyze risk score distribution |
| `npm run coverage` | Identify coverage gaps and opportunities |
| `npm run analytics` | Run complete analytics dashboard |

## 📊 Analytics Features

### Customer Segmentation
- Risk-based segmentation (High/Medium/Low)
- Product-based grouping
- Multi-product customer identification
- Cross-segment analysis

### Agent Performance
- Sales leaderboards
- Revenue rankings
- Customer satisfaction scores
- Overall performance metrics

### Risk Analysis
- Risk score distribution
- Outlier identification
- Risk category analysis
- Predictive risk modeling

### Coverage Analysis
- Coverage gap identification
- Upsell opportunity detection
- Revenue potential calculation
- Product penetration analysis

## 🧪 Exercises

### Exercise 1: Advanced Segmentation
Create multi-dimensional customer segments based on:
- Geographic location
- Age groups
- Product combinations
- Transaction history

### Exercise 2: Time-Based Analytics
Implement temporal analytics:
- Daily/Weekly/Monthly leaderboards
- Trending risk scores
- Seasonal pattern analysis
- Historical comparisons

### Exercise 3: Fraud Detection
Build a fraud detection system:
- Suspicious activity tracking
- Anomaly detection
- Real-time alerts
- Risk scoring algorithms

## 🔍 Key Redis Commands Used

### Sets
- `SADD` - Add members to a set
- `SMEMBERS` - Get all members
- `SINTER` - Set intersection
- `SUNION` - Set union
- `SDIFF` - Set difference
- `SCARD` - Set cardinality

### Sorted Sets
- `ZADD` - Add members with scores
- `ZRANGE` - Get members by rank
- `ZRANGEBYSCORE` - Get members by score
- `ZREVRANK` - Get reverse rank
- `ZCOUNT` - Count members in score range
- `ZCARD` - Sorted set cardinality

## 🎓 Learning Outcomes

By completing this lab, you will:
1. **Understand** how Sets enable powerful segmentation
2. **Master** Sorted Sets for ranking and scoring
3. **Apply** Set operations for complex queries
4. **Build** real-time analytics systems
5. **Create** business intelligence dashboards
6. **Implement** data-driven decision systems

## 🆘 Troubleshooting

**Connection Issues:**
```bash
# Check Redis status
docker ps | grep redis

# Test connection
redis-cli ping

# View Redis logs
docker logs redis-analytics-lab9
```

**Data Issues:**
```bash
# Clear all data
redis-cli FLUSHDB

# Reload sample data
npm run load-data
```

**Performance Issues:**
```bash
# Check memory usage
redis-cli INFO memory

# Monitor commands
redis-cli MONITOR
```

## 📚 Additional Resources

- [Redis Sets Documentation](https://redis.io/docs/data-types/sets/)
- [Redis Sorted Sets Documentation](https://redis.io/docs/data-types/sorted-sets/)
- [Node Redis Client](https://github.com/redis/node-redis)
- [Analytics Best Practices](https://redis.io/docs/use-cases/analytics/)

## 🏆 Success Criteria

- ✅ All npm scripts run without errors
- ✅ Customer segmentation identifies at least 3 segments
- ✅ Agent leaderboard displays top 5 performers
- ✅ Risk analysis shows distribution across categories
- ✅ Coverage analysis identifies upsell opportunities
- ✅ Full analytics dashboard completes successfully

---

**Congratulations on completing Lab 9!** 🎉

You've successfully built a comprehensive analytics system using Redis Sets and Sorted Sets with JavaScript. These skills are directly applicable to real-world business intelligence and analytics applications.
