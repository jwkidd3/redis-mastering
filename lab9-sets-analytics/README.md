# Lab 9: Sets & Sorted Sets for Analytics

**Duration:** 45 minutes
**Focus:** Customer segmentation, risk analysis, and performance tracking
**Prerequisites:** Lab 6 completed (JavaScript Redis client)

## 🎯 Learning Objectives

- Use Sets for customer segmentation and grouping
- Implement Sorted Sets for ranking and scoring
- Perform set operations (union, intersection, difference)
- Build real-time leaderboards
- Create customer analytics dashboards

## 📁 Project Structure

```
lab9-sets-analytics/
├── README.md                    # This file
├── package.json                 # Node.js dependencies
├── src/
│   ├── connection.js           # Redis connection
│   ├── customer-segments.js    # Set operations
│   ├── risk-scoring.js         # Sorted set operations
│   └── analytics-dashboard.js  # Combined analytics
├── scripts/
│   └── setup-lab9.js           # Lab initialization
└── reference/
    └── redis-sets-commands.md  # Command reference
```

## 🚀 Quick Start

### 1. Install Dependencies

```bash
npm install
```

### 2. Test Connection

```bash
node -e "const c = require('./src/connection'); c.ping().then(r => console.log(r))"
```

### 3. Run Setup

```bash
node scripts/setup-lab9.js
```

## Part 1: Customer Segmentation with Sets

### Create Customer Segments

```javascript
// Add customers to segments
await client.sAdd('customers:premium', ['C001', 'C002', 'C003']);
await client.sAdd('customers:high_risk', ['C002', 'C005']);
```

### Check Membership

```javascript
// Check if customer is premium
const isPremium = await client.sIsMember('customers:premium', 'C001');
console.log(isPremium); // true

// Get all premium customers
const premiumCustomers = await client.sMembers('customers:premium');
```

### Set Operations

```javascript
// Find premium customers who are also high risk
const premiumHighRisk = await client.sInter([
  'customers:premium',
  'customers:high_risk'
]);

// Find all customers (premium OR standard)
const allCustomers = await client.sUnion([
  'customers:premium',
  'customers:standard'
]);

// Find premium customers who are NOT high risk
const safePremium = await client.sDiff([
  'customers:premium',
  'customers:high_risk'
]);
```

### Count Members

```javascript
// How many premium customers?
const count = await client.sCard('customers:premium');
console.log(`Premium customers: ${count}`);
```

### Complete Implementation

See: `src/customer-segments.js` for full customer segmentation system

## Part 2: Risk Scoring with Sorted Sets

### Add Customers with Risk Scores

```javascript
// Add customers with risk scores (0-100)
await client.zAdd('risk:scores', [
  { score: 25, value: 'C001' },
  { score: 85, value: 'C002' },
  { score: 45, value: 'C003' }
]);
```

### Get Customers by Risk Level

```javascript
// Get highest risk customers (top 10)
const highRisk = await client.zRevRange('risk:scores', 0, 9, {
  withScores: true
});

// Get low risk customers (score < 30)
const lowRisk = await client.zRangeByScore('risk:scores', 0, 30);

// Get medium risk customers (score 30-60)
const mediumRisk = await client.zRangeByScore('risk:scores', 30, 60);
```

### Update Risk Scores

```javascript
// Increase risk score by 10 points
await client.zIncrBy('risk:scores', 10, 'C001');

// Get customer's current score
const score = await client.zScore('risk:scores', 'C001');

// Get customer's rank (0 = lowest risk)
const rank = await client.zRank('risk:scores', 'C001');
```

### Remove Customers

```javascript
// Remove customer from risk tracking
await client.zRem('risk:scores', 'C001');

// Remove customers with score > 90 (too high risk)
await client.zRemRangeByScore('risk:scores', 90, 100);
```

### Complete Implementation

See: `src/risk-scoring.js` for full risk scoring system

## Part 3: Performance Leaderboard

### Create Agent Performance Tracker

```javascript
// Track agent performance scores
await client.zAdd('agents:performance', [
  { score: 95, value: 'agent1' },
  { score: 87, value: 'agent2' },
  { score: 92, value: 'agent3' }
]);
```

### Get Top Performers

```javascript
// Top 5 agents
const topAgents = await client.zRevRange('agents:performance', 0, 4, {
  withScores: true
});

topAgents.forEach(({ value, score }) => {
  console.log(`${value}: ${score} points`);
});
```

### Update Performance Scores

```javascript
// Add points for closing a deal
await client.zIncrBy('agents:performance', 10, 'agent1');

// Get agent's current standing
const rank = await client.zRevRank('agents:performance', 'agent1');
console.log(`Agent rank: ${rank + 1}`); // +1 for 1-based ranking
```

## Part 4: Combined Analytics

### Build Complete Dashboard

```javascript
// src/analytics-dashboard.js
class Analytics {
  async getDashboard(customerId) {
    // Check all segments customer belongs to
    const segments = [];
    if (await client.sIsMember('customers:premium', customerId)) {
      segments.push('premium');
    }
    if (await client.sIsMember('customers:high_risk', customerId)) {
      segments.push('high-risk');
    }

    // Get risk score
    const riskScore = await client.zScore('risk:scores', customerId);
    const riskRank = await client.zRank('risk:scores', customerId);

    return {
      customerId,
      segments,
      riskScore,
      riskRank: riskRank + 1
    };
  }
}
```

## 🎓 Exercises

### Exercise 1: Customer Segmentation

1. Create segments: premium, standard, active, inactive
2. Add 50 customers across segments
3. Find customers who are premium AND active
4. Find customers who are inactive OR churned

### Exercise 2: Risk Analysis

1. Add 100 customers with random risk scores (0-100)
2. Find top 10 highest risk customers
3. Find all customers with medium risk (40-60)
4. Calculate average risk score for premium customers

### Exercise 3: Agent Leaderboard

1. Create performance tracker for 20 agents
2. Simulate 100 deal closures (add random points)
3. Display top 10 agents
4. Find your agent's rank

### Exercise 4: Combined Analytics

1. Build dashboard showing:
   - Customer segments
   - Risk score and rank
   - Policy count (use separate sorted set)
   - Lifetime value ranking

## 📋 Key Redis Commands

### Sets
```bash
SADD key member [member ...]       # Add members
SMEMBERS key                        # Get all members
SISMEMBER key member                # Check membership
SCARD key                           # Count members
SINTER key [key ...]                # Intersection
SUNION key [key ...]                # Union
SDIFF key [key ...]                 # Difference
SREM key member [member ...]        # Remove members
```

### Sorted Sets
```bash
ZADD key score member [score member ...]  # Add with score
ZRANGE key start stop [WITHSCORES]        # Get by rank (low to high)
ZREVRANGE key start stop [WITHSCORES]     # Get by rank (high to low)
ZRANGEBYSCORE key min max                 # Get by score range
ZSCORE key member                         # Get member's score
ZRANK key member                          # Get member's rank
ZINCRBY key increment member              # Increment score
ZREM key member [member ...]              # Remove members
ZCARD key                                 # Count members
```

## 💡 Best Practices

1. **Naming Convention:** Use prefixes (`customers:premium`, `risk:scores`)
2. **Score Range:** Use consistent ranges (0-100, 0-1000)
3. **Indexes:** Use sorted sets for ranking, sets for grouping
4. **Performance:** Set operations are O(N), use for small to medium sets
5. **Cleanup:** Remove inactive members regularly

## 🔍 Performance Tips

```javascript
// ❌ Bad: Multiple individual operations
for (const customer of customers) {
  await client.sAdd('customers:premium', customer);
}

// ✅ Good: Batch operation
await client.sAdd('customers:premium', customers);

// ❌ Bad: Getting full sorted set for count
const all = await client.zRange('risk:scores', 0, -1);
const count = all.length;

// ✅ Good: Use ZCARD
const count = await client.zCard('risk:scores');
```

## ✅ Lab Completion Checklist

- [ ] Customer segments created (premium, standard, high-risk, low-risk)
- [ ] Set operations performed (intersection, union, difference)
- [ ] Risk scoring system implemented
- [ ] Leaderboard created and tested
- [ ] Combined analytics dashboard built
- [ ] All exercises completed

**Estimated time:** 45 minutes

## 📚 Additional Resources

- **Redis Sets:** `https://redis.io/docs/data-types/sets/`
- **Redis Sorted Sets:** `https://redis.io/docs/data-types/sorted-sets/`
- **Full implementations:** Check `src/` directory for complete examples
