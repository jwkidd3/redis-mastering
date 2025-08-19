# Lab 9: Advanced Data Structures & Analytics

**Duration:** 45 minutes  
**Objective:** Master Redis sets and sorted sets for analytics applications  
**Focus:** Customer segmentation, risk analysis, and performance tracking

## 🎯 Learning Objectives

By the end of this lab, you will be able to:
- Use Redis sets for customer segmentation and grouping
- Implement sorted sets for ranking and scoring systems
- Perform set operations for analytics (union, intersection, difference)
- Build real-time leaderboards and performance tracking
- Create customer analytics dashboards with JavaScript
- Optimize analytics queries for performance

---

## Part 1: Environment Setup (5 minutes)

### Step 1: Connection Setup

Update your connection configuration:

```javascript
// src/connection.js
const redis = require('redis');

const client = redis.createClient({
    host: 'your-redis-host',     // Replace with your Redis server
    port: 6379,                  // Replace with your Redis port
    // password: 'your-password'  // Uncomment if authentication required
});

client.on('error', (err) => {
    console.error('Redis connection error:', err);
});

client.on('connect', () => {
    console.log('Connected to Redis server');
});

module.exports = client;
```

### Step 2: Test Connection

```bash
# Test basic connection
node -e "
const client = require('./src/connection.js');
client.ping((err, reply) => {
    console.log('Redis PING:', reply);
    client.quit();
});
"
```

### Step 3: Initialize Lab Environment

Run the setup script:

```bash
node scripts/setup-lab9.js
```

---

## Part 2: Customer Segmentation with Sets (15 minutes)

### Step 1: Create Customer Segments

Create customer segmentation system:

```javascript
// src/customer-segments.js
const client = require('./connection');

class CustomerSegments {
    constructor() {
        this.segments = {
            premium: 'customers:premium',
            standard: 'customers:standard',
            new: 'customers:new',
            highrisk: 'customers:high_risk',
            lowrisk: 'customers:low_risk',
            active: 'customers:active',
            inactive: 'customers:inactive'
        };
    }

    // Add customer to segment
    async addToSegment(customerId, segmentName) {
        if (!this.segments[segmentName]) {
            throw new Error(`Invalid segment: ${segmentName}`);
        }
        
        const result = await client.sadd(this.segments[segmentName], customerId);
        console.log(`Customer ${customerId} added to ${segmentName}: ${result ? 'new' : 'existing'}`);
        return result;
    }

    // Remove customer from segment
    async removeFromSegment(customerId, segmentName) {
        if (!this.segments[segmentName]) {
            throw new Error(`Invalid segment: ${segmentName}`);
        }
        
        const result = await client.srem(this.segments[segmentName], customerId);
        console.log(`Customer ${customerId} removed from ${segmentName}: ${result ? 'success' : 'not found'}`);
        return result;
    }

    // Check if customer is in segment
    async isInSegment(customerId, segmentName) {
        if (!this.segments[segmentName]) {
            throw new Error(`Invalid segment: ${segmentName}`);
        }
        
        const result = await client.sismember(this.segments[segmentName], customerId);
        return result === 1;
    }

    // Get all customers in segment
    async getSegmentMembers(segmentName) {
        if (!this.segments[segmentName]) {
            throw new Error(`Invalid segment: ${segmentName}`);
        }
        
        const members = await client.smembers(this.segments[segmentName]);
        console.log(`${segmentName} segment has ${members.length} customers:`, members);
        return members;
    }

    // Get segment size
    async getSegmentSize(segmentName) {
        if (!this.segments[segmentName]) {
            throw new Error(`Invalid segment: ${segmentName}`);
        }
        
        const size = await client.scard(this.segments[segmentName]);
        console.log(`${segmentName} segment size: ${size}`);
        return size;
    }

    // Get all segments for a customer
    async getCustomerSegments(customerId) {
        const customerSegments = [];
        
        for (const [segmentName, segmentKey] of Object.entries(this.segments)) {
            const isMember = await client.sismember(segmentKey, customerId);
            if (isMember) {
                customerSegments.push(segmentName);
            }
        }
        
        console.log(`Customer ${customerId} segments:`, customerSegments);
        return customerSegments;
    }
}

module.exports = CustomerSegments;
```

### Step 2: Test Customer Segmentation

```javascript
// Test segmentation functionality
const CustomerSegments = require('./src/customer-segments');

async function testSegmentation() {
    const segments = new CustomerSegments();
    
    console.log('=== Testing Customer Segmentation ===');
    
    // Add customers to segments
    await segments.addToSegment('CUST001', 'premium');
    await segments.addToSegment('CUST001', 'active');
    await segments.addToSegment('CUST001', 'lowrisk');
    
    await segments.addToSegment('CUST002', 'standard');
    await segments.addToSegment('CUST002', 'active');
    await segments.addToSegment('CUST002', 'highrisk');
    
    await segments.addToSegment('CUST003', 'new');
    await segments.addToSegment('CUST003', 'standard');
    
    // Check segment membership
    const isPremium = await segments.isInSegment('CUST001', 'premium');
    console.log('CUST001 is premium:', isPremium);
    
    // Get segment members
    await segments.getSegmentMembers('active');
    await segments.getSegmentMembers('premium');
    
    // Get customer segments
    await segments.getCustomerSegments('CUST001');
    await segments.getCustomerSegments('CUST002');
}

testSegmentation().catch(console.error);
```

### Step 3: Advanced Set Operations

```javascript
// src/set-analytics.js
const client = require('./connection');

class SetAnalytics {
    // Find customers in multiple segments (intersection)
    async findCustomersInBothSegments(segment1, segment2) {
        const intersection = await client.sinter(`customers:${segment1}`, `customers:${segment2}`);
        console.log(`Customers in both ${segment1} and ${segment2}:`, intersection);
        return intersection;
    }

    // Find customers in either segment (union)
    async findCustomersInEitherSegment(segment1, segment2) {
        const union = await client.sunion(`customers:${segment1}`, `customers:${segment2}`);
        console.log(`Customers in ${segment1} or ${segment2}:`, union);
        return union;
    }

    // Find customers in first segment but not second (difference)
    async findCustomersInFirstNotSecond(segment1, segment2) {
        const difference = await client.sdiff(`customers:${segment1}`, `customers:${segment2}`);
        console.log(`Customers in ${segment1} but not ${segment2}:`, difference);
        return difference;
    }

    // Store intersection result for later use
    async storeIntersection(segment1, segment2, resultKey) {
        const count = await client.sinterstore(resultKey, `customers:${segment1}`, `customers:${segment2}`);
        console.log(`Stored intersection of ${segment1} and ${segment2} in ${resultKey}: ${count} customers`);
        return count;
    }

    // Advanced analytics: Find high-value low-risk customers
    async findHighValueLowRiskCustomers() {
        const resultKey = 'analytics:high_value_low_risk';
        const count = await client.sinterstore(
            resultKey,
            'customers:premium',
            'customers:lowrisk',
            'customers:active'
        );
        
        const customers = await client.smembers(resultKey);
        console.log('High-value low-risk active customers:', customers);
        
        // Set expiration for analytics result
        await client.expire(resultKey, 3600); // 1 hour
        
        return customers;
    }
}

module.exports = SetAnalytics;
```

---

## Part 3: Performance Tracking with Sorted Sets (20 minutes)

### Step 1: Agent Performance Leaderboard

```javascript
// src/agent-leaderboard.js
const client = require('./connection');

class AgentLeaderboard {
    constructor() {
        this.leaderboards = {
            sales: 'leaderboard:sales',
            customer_satisfaction: 'leaderboard:satisfaction',
            policies_sold: 'leaderboard:policies',
            claims_processed: 'leaderboard:claims'
        };
    }

    // Add or update agent score
    async updateAgentScore(leaderboardType, agentId, score) {
        if (!this.leaderboards[leaderboardType]) {
            throw new Error(`Invalid leaderboard: ${leaderboardType}`);
        }

        const result = await client.zadd(this.leaderboards[leaderboardType], score, agentId);
        console.log(`Agent ${agentId} ${leaderboardType} score updated to ${score}`);
        return result;
    }

    // Increment agent score
    async incrementAgentScore(leaderboardType, agentId, increment = 1) {
        if (!this.leaderboards[leaderboardType]) {
            throw new Error(`Invalid leaderboard: ${leaderboardType}`);
        }

        const newScore = await client.zincrby(this.leaderboards[leaderboardType], increment, agentId);
        console.log(`Agent ${agentId} ${leaderboardType} score incremented by ${increment}, new score: ${newScore}`);
        return parseFloat(newScore);
    }

    // Get agent rank (1-based, 1 is highest)
    async getAgentRank(leaderboardType, agentId) {
        if (!this.leaderboards[leaderboardType]) {
            throw new Error(`Invalid leaderboard: ${leaderboardType}`);
        }

        const rank = await client.zrevrank(this.leaderboards[leaderboardType], agentId);
        const finalRank = rank !== null ? rank + 1 : null;
        console.log(`Agent ${agentId} rank in ${leaderboardType}: ${finalRank || 'Not ranked'}`);
        return finalRank;
    }

    // Get agent score
    async getAgentScore(leaderboardType, agentId) {
        if (!this.leaderboards[leaderboardType]) {
            throw new Error(`Invalid leaderboard: ${leaderboardType}`);
        }

        const score = await client.zscore(this.leaderboards[leaderboardType], agentId);
        console.log(`Agent ${agentId} ${leaderboardType} score: ${score || 'No score'}`);
        return score ? parseFloat(score) : null;
    }

    // Get top performers
    async getTopPerformers(leaderboardType, count = 10) {
        if (!this.leaderboards[leaderboardType]) {
            throw new Error(`Invalid leaderboard: ${leaderboardType}`);
        }

        const results = await client.zrevrange(
            this.leaderboards[leaderboardType],
            0,
            count - 1,
            'WITHSCORES'
        );

        const topPerformers = [];
        for (let i = 0; i < results.length; i += 2) {
            topPerformers.push({
                agentId: results[i],
                score: parseFloat(results[i + 1]),
                rank: (i / 2) + 1
            });
        }

        console.log(`Top ${count} performers in ${leaderboardType}:`, topPerformers);
        return topPerformers;
    }

    // Get performers in score range
    async getPerformersInRange(leaderboardType, minScore, maxScore) {
        if (!this.leaderboards[leaderboardType]) {
            throw new Error(`Invalid leaderboard: ${leaderboardType}`);
        }

        const results = await client.zrangebyscore(
            this.leaderboards[leaderboardType],
            minScore,
            maxScore,
            'WITHSCORES'
        );

        const performers = [];
        for (let i = 0; i < results.length; i += 2) {
            performers.push({
                agentId: results[i],
                score: parseFloat(results[i + 1])
            });
        }

        console.log(`Performers with score ${minScore}-${maxScore} in ${leaderboardType}:`, performers);
        return performers;
    }

    // Get leaderboard statistics
    async getLeaderboardStats(leaderboardType) {
        if (!this.leaderboards[leaderboardType]) {
            throw new Error(`Invalid leaderboard: ${leaderboardType}`);
        }

        const count = await client.zcard(this.leaderboards[leaderboardType]);
        
        if (count === 0) {
            return { count: 0, minScore: null, maxScore: null };
        }

        const minScoreResult = await client.zrange(this.leaderboards[leaderboardType], 0, 0, 'WITHSCORES');
        const maxScoreResult = await client.zrevrange(this.leaderboards[leaderboardType], 0, 0, 'WITHSCORES');

        const stats = {
            count,
            minScore: minScoreResult.length > 1 ? parseFloat(minScoreResult[1]) : null,
            maxScore: maxScoreResult.length > 1 ? parseFloat(maxScoreResult[1]) : null
        };

        console.log(`${leaderboardType} leaderboard stats:`, stats);
        return stats;
    }
}

module.exports = AgentLeaderboard;
```

### Step 2: Risk Scoring System

```javascript
// src/risk-scoring.js
const client = require('./connection');

class RiskScoring {
    constructor() {
        this.riskKey = 'risk_scores';
        this.riskCategories = {
            low: { min: 0, max: 300 },
            medium: { min: 301, max: 700 },
            high: { min: 701, max: 1000 }
        };
    }

    // Calculate and store risk score
    async calculateRiskScore(customerId, factors) {
        let score = 0;

        // Age factor (higher age = lower risk for auto, opposite for health)
        if (factors.age) {
            score += Math.max(0, 100 - factors.age);
        }

        // Claim history factor
        if (factors.claimCount) {
            score += factors.claimCount * 50;
        }

        // Credit score factor (inverse relationship)
        if (factors.creditScore) {
            score += Math.max(0, 850 - factors.creditScore) / 2;
        }

        // Driving record factor
        if (factors.violations) {
            score += factors.violations * 75;
        }

        // Policy type factor
        if (factors.policyType === 'high_risk') {
            score += 100;
        } else if (factors.policyType === 'standard') {
            score += 50;
        }

        // Ensure score is within bounds
        score = Math.min(1000, Math.max(0, Math.round(score)));

        // Store risk score
        await client.zadd(this.riskKey, score, customerId);
        
        const category = this.getRiskCategory(score);
        console.log(`Customer ${customerId} risk score: ${score} (${category})`);
        
        return { score, category };
    }

    // Get risk category
    getRiskCategory(score) {
        for (const [category, range] of Object.entries(this.riskCategories)) {
            if (score >= range.min && score <= range.max) {
                return category;
            }
        }
        return 'unknown';
    }

    // Get customers by risk level
    async getCustomersByRiskLevel(level) {
        if (!this.riskCategories[level]) {
            throw new Error(`Invalid risk level: ${level}`);
        }

        const range = this.riskCategories[level];
        const results = await client.zrangebyscore(
            this.riskKey,
            range.min,
            range.max,
            'WITHSCORES'
        );

        const customers = [];
        for (let i = 0; i < results.length; i += 2) {
            customers.push({
                customerId: results[i],
                riskScore: parseFloat(results[i + 1]),
                riskLevel: level
            });
        }

        console.log(`${level} risk customers:`, customers);
        return customers;
    }

    // Get highest risk customers
    async getHighestRiskCustomers(count = 10) {
        const results = await client.zrevrange(this.riskKey, 0, count - 1, 'WITHSCORES');
        
        const customers = [];
        for (let i = 0; i < results.length; i += 2) {
            const score = parseFloat(results[i + 1]);
            customers.push({
                customerId: results[i],
                riskScore: score,
                riskLevel: this.getRiskCategory(score),
                rank: (i / 2) + 1
            });
        }

        console.log(`Top ${count} highest risk customers:`, customers);
        return customers;
    }

    // Update risk score
    async updateRiskScore(customerId, newScore) {
        newScore = Math.min(1000, Math.max(0, Math.round(newScore)));
        await client.zadd(this.riskKey, newScore, customerId);
        
        const category = this.getRiskCategory(newScore);
        console.log(`Customer ${customerId} risk score updated to: ${newScore} (${category})`);
        
        return { score: newScore, category };
    }

    // Get customer risk score and rank
    async getCustomerRiskProfile(customerId) {
        const score = await client.zscore(this.riskKey, customerId);
        
        if (score === null) {
            console.log(`Customer ${customerId} not found in risk database`);
            return null;
        }

        const numericScore = parseFloat(score);
        const rank = await client.zrevrank(this.riskKey, customerId);
        const category = this.getRiskCategory(numericScore);

        const profile = {
            customerId,
            riskScore: numericScore,
            riskLevel: category,
            rank: rank + 1
        };

        console.log(`Customer ${customerId} risk profile:`, profile);
        return profile;
    }
}

module.exports = RiskScoring;
```

### Step 3: Analytics Dashboard Integration

```javascript
// src/analytics-dashboard.js
const CustomerSegments = require('./customer-segments');
const SetAnalytics = require('./set-analytics');
const AgentLeaderboard = require('./agent-leaderboard');
const RiskScoring = require('./risk-scoring');

class AnalyticsDashboard {
    constructor() {
        this.segments = new CustomerSegments();
        this.setAnalytics = new SetAnalytics();
        this.leaderboard = new AgentLeaderboard();
        this.riskScoring = new RiskScoring();
    }

    // Generate comprehensive analytics report
    async generateDashboard() {
        console.log('\n🔹 ANALYTICS DASHBOARD 🔹');
        console.log('='.repeat(50));

        try {
            // Customer segment overview
            console.log('\n📊 CUSTOMER SEGMENTS:');
            const segments = ['premium', 'standard', 'new', 'active', 'highrisk', 'lowrisk'];
            for (const segment of segments) {
                await this.segments.getSegmentSize(segment);
            }

            // High-value low-risk customers
            console.log('\n💎 HIGH-VALUE LOW-RISK CUSTOMERS:');
            await this.setAnalytics.findHighValueLowRiskCustomers();

            // Agent performance overview
            console.log('\n🏆 TOP PERFORMING AGENTS:');
            await this.leaderboard.getTopPerformers('sales', 5);

            // Risk distribution
            console.log('\n⚠️ RISK DISTRIBUTION:');
            const lowRisk = await this.riskScoring.getCustomersByRiskLevel('low');
            const mediumRisk = await this.riskScoring.getCustomersByRiskLevel('medium');
            const highRisk = await this.riskScoring.getCustomersByRiskLevel('high');
            
            console.log(`Risk Summary: Low(${lowRisk.length}) Medium(${mediumRisk.length}) High(${highRisk.length})`);

            // Top risk customers
            console.log('\n🚨 HIGHEST RISK CUSTOMERS:');
            await this.riskScoring.getHighestRiskCustomers(3);

        } catch (error) {
            console.error('Dashboard generation error:', error);
        }
    }

    // Real-time analytics update
    async updateAnalytics(customerId, agentId, saleAmount, riskFactors) {
        console.log(`\n🔄 Updating analytics for Customer: ${customerId}, Agent: ${agentId}`);
        
        try {
            // Update agent performance
            await this.leaderboard.incrementAgentScore('sales', agentId, saleAmount);
            await this.leaderboard.incrementAgentScore('policies_sold', agentId, 1);

            // Update customer segments based on sale amount
            if (saleAmount > 5000) {
                await this.segments.addToSegment(customerId, 'premium');
                await this.segments.removeFromSegment(customerId, 'standard');
            } else {
                await this.segments.addToSegment(customerId, 'standard');
            }

            await this.segments.addToSegment(customerId, 'active');

            // Update risk scoring
            if (riskFactors) {
                const riskResult = await this.riskScoring.calculateRiskScore(customerId, riskFactors);
                
                if (riskResult.category === 'low') {
                    await this.segments.addToSegment(customerId, 'lowrisk');
                    await this.segments.removeFromSegment(customerId, 'highrisk');
                } else if (riskResult.category === 'high') {
                    await this.segments.addToSegment(customerId, 'highrisk');
                    await this.segments.removeFromSegment(customerId, 'lowrisk');
                }
            }

            console.log('✅ Analytics updated successfully');

        } catch (error) {
            console.error('Analytics update error:', error);
        }
    }
}

module.exports = AnalyticsDashboard;
```

---

## Part 4: Redis Insight Analytics Visualization (5 minutes)

### Step 1: View Data in Redis Insight

1. **Open Redis Insight Browser tab**
2. **Search for analytics keys:**
   - `customers:*` - Customer segments
   - `leaderboard:*` - Agent performance
   - `risk_scores` - Risk scoring data

### Step 2: Analyze Set Operations in Workbench

Use Redis Insight Workbench to run analytics queries:

```redis
# View customer segments
SMEMBERS customers:premium
SMEMBERS customers:lowrisk

# Analyze set intersections
SINTER customers:premium customers:lowrisk customers:active

# Check leaderboard rankings
ZREVRANGE leaderboard:sales 0 9 WITHSCORES

# Analyze risk distribution
ZRANGEBYSCORE risk_scores 0 300 WITHSCORES
ZRANGEBYSCORE risk_scores 701 1000 WITHSCORES

# Get leaderboard statistics
ZCARD leaderboard:sales
ZCOUNT leaderboard:sales 1000 5000
```

### Step 3: Memory Analysis

1. **Go to Analysis tab in Redis Insight**
2. **Check memory usage** for different data structures
3. **Identify largest keys** and their memory consumption
4. **Monitor key expiration** and TTL settings

---

## Lab Completion Checklist

- [ ] Successfully implemented customer segmentation with sets
- [ ] Created agent performance leaderboards with sorted sets
- [ ] Built risk scoring system with score ranges
- [ ] Performed set operations for analytics (intersection, union, difference)
- [ ] Integrated all components into analytics dashboard
- [ ] Visualized analytics data in Redis Insight
- [ ] Tested real-time analytics updates
- [ ] Analyzed memory usage and performance

---

## Performance Considerations

### Set Operations Optimization

```javascript
// Use pipelining for bulk operations
const pipeline = client.pipeline();
pipeline.sadd('customers:premium', 'CUST001');
pipeline.sadd('customers:active', 'CUST001');
pipeline.sadd('customers:lowrisk', 'CUST001');
await pipeline.exec();

// Store intersection results for repeated queries
await client.sinterstore('cache:premium_lowrisk', 'customers:premium', 'customers:lowrisk');
await client.expire('cache:premium_lowrisk', 300); // 5 minutes
```

### Sorted Set Optimization

```javascript
// Use ZRANGEBYSCORE with LIMIT for pagination
const results = await client.zrevrangebyscore(
    'leaderboard:sales',
    '+inf',
    '-inf',
    'WITHSCORES',
    'LIMIT',
    0,
    10
);

// Batch score updates
const pipeline = client.pipeline();
pipeline.zincrby('leaderboard:sales', 1000, 'AGENT001');
pipeline.zincrby('leaderboard:policies', 1, 'AGENT001');
await pipeline.exec();
```

---

## Key Takeaways

🎉 **Congratulations!** You've mastered Redis sets and sorted sets for analytics:

1. **Customer Segmentation** - Used sets for flexible customer grouping
2. **Performance Tracking** - Implemented leaderboards with sorted sets
3. **Risk Analysis** - Built scoring systems with range queries
4. **Set Operations** - Leveraged intersection, union, and difference for insights
5. **Real-time Analytics** - Created live dashboard with automated updates

**Next Lab Preview:** Lab 10 will focus on advanced caching patterns and optimization strategies.
