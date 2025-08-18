# Lab 9: Analytics with Sets and Sorted Sets

**Duration:** 45 minutes  
**Objective:** Build advanced analytics features using Redis Sets and Sorted Sets with JavaScript for business intelligence, customer segmentation, and performance tracking

## 🎯 Learning Objectives

By the end of this lab, you will be able to:
- Implement customer segmentation using Redis Sets with JavaScript
- Build agent performance leaderboards with Sorted Sets
- Create risk analysis systems using Set operations
- Develop coverage analysis tools with Set intersections and unions
- Implement real-time analytics dashboards
- Apply advanced scoring algorithms for business metrics

---

## Part 1: JavaScript Redis Client Setup for Analytics (10 minutes)

### Step 1: Environment Setup

```bash
# Install dependencies
npm install

# Start Redis with optimized configuration for analytics
docker run -d --name redis-analytics-lab9 \
  -p 6379:6379 \
  redis:7-alpine redis-server \
  --maxmemory 1gb \
  --maxmemory-policy allkeys-lru

# Test connection
npm test

# Load sample analytics data
npm run load-data
```

### Step 2: Connection Configuration

Create `.env` file:
```env
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_DB=0
```

Create `src/redis-client.js`:
```javascript
const redis = require('redis');
require('dotenv').config();

const client = redis.createClient({
    socket: {
        host: process.env.REDIS_HOST || 'localhost',
        port: process.env.REDIS_PORT || 6379
    },
    password: process.env.REDIS_PASSWORD || undefined,
    database: process.env.REDIS_DB || 0
});

client.on('error', (err) => console.error('Redis Client Error', err));
client.on('connect', () => console.log('Connected to Redis'));

module.exports = client;
```

---

## Part 2: Customer Segmentation with Sets (15 minutes)

### Step 3: Customer Risk Segmentation

Create `src/customer-segmentation.js`:
```javascript
const client = require('./redis-client');
const chalk = require('chalk');
const Table = require('cli-table3');

async function segmentCustomersByRisk() {
    await client.connect();
    
    console.log(chalk.cyan.bold('\n📊 Customer Risk Segmentation Analysis\n'));
    
    try {
        // Clear existing segments
        await client.del('customers:high_risk', 'customers:medium_risk', 'customers:low_risk');
        
        // Segment customers based on risk scores
        const customers = await client.keys('customer:*:risk_score');
        
        for (const key of customers) {
            const customerId = key.split(':')[1];
            const riskScore = parseInt(await client.get(key));
            
            if (riskScore >= 800) {
                await client.sAdd('customers:low_risk', customerId);
            } else if (riskScore >= 650) {
                await client.sAdd('customers:medium_risk', customerId);
            } else {
                await client.sAdd('customers:high_risk', customerId);
            }
        }
        
        // Analyze segments
        const highRisk = await client.sMembers('customers:high_risk');
        const mediumRisk = await client.sMembers('customers:medium_risk');
        const lowRisk = await client.sMembers('customers:low_risk');
        
        // Display results
        const table = new Table({
            head: ['Risk Segment', 'Customer Count', 'Customer IDs'],
            colWidths: [20, 20, 50]
        });
        
        table.push(
            ['High Risk', highRisk.length, highRisk.slice(0, 5).join(', ') + (highRisk.length > 5 ? '...' : '')],
            ['Medium Risk', mediumRisk.length, mediumRisk.slice(0, 5).join(', ') + (mediumRisk.length > 5 ? '...' : '')],
            ['Low Risk', lowRisk.length, lowRisk.slice(0, 5).join(', ') + (lowRisk.length > 5 ? '...' : '')]
        );
        
        console.log(table.toString());
        
        // Cross-segment analysis
        console.log(chalk.yellow.bold('\n🔍 Cross-Segment Analysis:\n'));
        
        // Customers with multiple products
        await analyzeMultiProductCustomers();
        
    } catch (error) {
        console.error(chalk.red('Error:', error));
    } finally {
        await client.quit();
    }
}

async function analyzeMultiProductCustomers() {
    // Create product-based customer sets
    const autoPolicies = await client.keys('policy:auto:*:customer');
    const homePolicies = await client.keys('policy:home:*:customer');
    const lifePolicies = await client.keys('policy:life:*:customer');
    
    // Add customers to product sets
    for (const key of autoPolicies) {
        const customerId = await client.get(key);
        await client.sAdd('customers:with_auto', customerId);
    }
    
    for (const key of homePolicies) {
        const customerId = await client.get(key);
        await client.sAdd('customers:with_home', customerId);
    }
    
    for (const key of lifePolicies) {
        const customerId = await client.get(key);
        await client.sAdd('customers:with_life', customerId);
    }
    
    // Find customers with multiple products
    const autoAndHome = await client.sInter('customers:with_auto', 'customers:with_home');
    const allThree = await client.sInter('customers:with_auto', 'customers:with_home', 'customers:with_life');
    
    console.log(`Customers with Auto AND Home: ${chalk.green(autoAndHome.length)}`);
    console.log(`Customers with ALL three products: ${chalk.green(allThree.length)}`);
}

// Run if executed directly
if (require.main === module) {
    segmentCustomersByRisk();
}

module.exports = { segmentCustomersByRisk, analyzeMultiProductCustomers };
```

### Step 4: Coverage Analysis with Set Operations

Create `src/coverage-analysis.js`:
```javascript
const client = require('./redis-client');
const chalk = require('chalk');
const ora = require('ora');

async function analyzeCoverageGaps() {
    await client.connect();
    const spinner = ora('Analyzing coverage gaps...').start();
    
    try {
        // Identify customers with incomplete coverage
        const withAuto = await client.sMembers('customers:with_auto');
        const withHome = await client.sMembers('customers:with_home');
        const withLife = await client.sMembers('customers:with_life');
        
        // Find coverage gaps
        const autoOnly = await client.sDiff('customers:with_auto', 'customers:with_home', 'customers:with_life');
        const noLife = await client.sDiff(
            await client.sUnion('customers:with_auto', 'customers:with_home'),
            'customers:with_life'
        );
        
        spinner.succeed('Coverage analysis complete');
        
        console.log(chalk.cyan.bold('\n📈 Coverage Gap Analysis\n'));
        console.log(`Customers with ONLY Auto: ${chalk.yellow(autoOnly.length)}`);
        console.log(`Customers WITHOUT Life: ${chalk.yellow(noLife.length)}`);
        
        // Upsell opportunities
        console.log(chalk.green.bold('\n💰 Upsell Opportunities:\n'));
        console.log(`Auto-only customers (target for Home): ${autoOnly.length}`);
        console.log(`Missing Life coverage: ${noLife.length}`);
        
        // Calculate potential revenue
        const avgHomePremium = 1200;
        const avgLifePremium = 600;
        const potentialRevenue = (autoOnly.length * avgHomePremium) + (noLife.length * avgLifePremium);
        
        console.log(chalk.green.bold(`\n💵 Potential Annual Revenue: $${potentialRevenue.toLocaleString()}`));
        
    } catch (error) {
        spinner.fail('Analysis failed');
        console.error(chalk.red('Error:', error));
    } finally {
        await client.quit();
    }
}

// Run if executed directly
if (require.main === module) {
    analyzeCoverageGaps();
}

module.exports = { analyzeCoverageGaps };
```

---

## Part 3: Performance Tracking with Sorted Sets (15 minutes)

### Step 5: Agent Performance Leaderboard

Create `src/agent-leaderboard.js`:
```javascript
const client = require('./redis-client');
const chalk = require('chalk');
const Table = require('cli-table3');

async function buildAgentLeaderboard() {
    await client.connect();
    
    console.log(chalk.cyan.bold('\n🏆 Agent Performance Leaderboard\n'));
    
    try {
        // Clear existing leaderboards
        await client.del('leaderboard:sales:monthly', 'leaderboard:customer_satisfaction', 'leaderboard:revenue');
        
        // Build sales leaderboard
        const agents = await client.keys('agent:*:name');
        
        for (const key of agents) {
            const agentId = key.split(':')[1];
            
            // Calculate performance metrics
            const policiesSold = parseInt(await client.get(`metrics:agent:${agentId}:policies_sold`) || 0);
            const revenue = parseFloat(await client.get(`metrics:agent:${agentId}:revenue`) || 0);
            const satisfaction = parseFloat(await client.get(`metrics:agent:${agentId}:satisfaction`) || 0);
            
            // Add to sorted sets
            await client.zAdd('leaderboard:sales:monthly', {
                score: policiesSold,
                value: agentId
            });
            
            await client.zAdd('leaderboard:revenue', {
                score: revenue,
                value: agentId
            });
            
            await client.zAdd('leaderboard:customer_satisfaction', {
                score: satisfaction,
                value: agentId
            });
        }
        
        // Display top performers
        await displayLeaderboard('Sales (Policies)', 'leaderboard:sales:monthly');
        await displayLeaderboard('Revenue Generated', 'leaderboard:revenue');
        await displayLeaderboard('Customer Satisfaction', 'leaderboard:customer_satisfaction');
        
        // Identify top overall performer
        await calculateOverallPerformance();
        
    } catch (error) {
        console.error(chalk.red('Error:', error));
    } finally {
        await client.quit();
    }
}

async function displayLeaderboard(title, key) {
    console.log(chalk.yellow.bold(`\n📊 ${title}:\n`));
    
    const topAgents = await client.zRangeWithScores(key, -5, -1);
    const table = new Table({
        head: ['Rank', 'Agent ID', 'Score', 'Name'],
        colWidths: [10, 15, 15, 30]
    });
    
    let rank = topAgents.length;
    for (const agent of topAgents) {
        const name = await client.get(`agent:${agent.value}:name`);
        table.push([
            rank,
            agent.value,
            agent.score.toFixed(2),
            name || 'Unknown'
        ]);
        rank--;
    }
    
    console.log(table.toString());
}

async function calculateOverallPerformance() {
    console.log(chalk.green.bold('\n🌟 Overall Performance Ranking:\n'));
    
    // Weight different metrics
    const weights = {
        sales: 0.4,
        revenue: 0.4,
        satisfaction: 0.2
    };
    
    const agents = await client.sMembers('all_agents');
    const overallScores = [];
    
    for (const agentId of agents) {
        const salesRank = await client.zRevRank('leaderboard:sales:monthly', agentId) || 0;
        const revenueRank = await client.zRevRank('leaderboard:revenue', agentId) || 0;
        const satisfactionRank = await client.zRevRank('leaderboard:customer_satisfaction', agentId) || 0;
        
        const overallScore = (salesRank * weights.sales) + 
                           (revenueRank * weights.revenue) + 
                           (satisfactionRank * weights.satisfaction);
        
        overallScores.push({ agentId, score: overallScore });
    }
    
    // Sort and display top overall performers
    overallScores.sort((a, b) => b.score - a.score);
    
    console.log('Top 3 Overall Performers:');
    for (let i = 0; i < Math.min(3, overallScores.length); i++) {
        const agent = overallScores[i];
        const name = await client.get(`agent:${agent.agentId}:name`);
        console.log(`${i + 1}. ${name} (${agent.agentId}) - Score: ${agent.score.toFixed(2)}`);
    }
}

// Run if executed directly
if (require.main === module) {
    buildAgentLeaderboard();
}

module.exports = { buildAgentLeaderboard, displayLeaderboard };
```

### Step 6: Risk Scoring System

Create `src/risk-analysis.js`:
```javascript
const client = require('./redis-client');
const chalk = require('chalk');
const Table = require('cli-table3');

async function analyzeRiskDistribution() {
    await client.connect();
    
    console.log(chalk.cyan.bold('\n📊 Risk Distribution Analysis\n'));
    
    try {
        // Build risk score sorted set
        await client.del('risk:distribution');
        
        const customers = await client.keys('customer:*:risk_score');
        
        for (const key of customers) {
            const customerId = key.split(':')[1];
            const riskScore = parseInt(await client.get(key));
            
            await client.zAdd('risk:distribution', {
                score: riskScore,
                value: customerId
            });
        }
        
        // Analyze risk distribution
        const totalCustomers = await client.zCard('risk:distribution');
        const highRisk = await client.zCount('risk:distribution', 0, 649);
        const mediumRisk = await client.zCount('risk:distribution', 650, 799);
        const lowRisk = await client.zCount('risk:distribution', 800, 1000);
        
        // Display distribution
        const table = new Table({
            head: ['Risk Category', 'Score Range', 'Count', 'Percentage'],
            colWidths: [20, 20, 15, 15]
        });
        
        table.push(
            ['High Risk', '0-649', highRisk, `${((highRisk/totalCustomers)*100).toFixed(1)}%`],
            ['Medium Risk', '650-799', mediumRisk, `${((mediumRisk/totalCustomers)*100).toFixed(1)}%`],
            ['Low Risk', '800-1000', lowRisk, `${((lowRisk/totalCustomers)*100).toFixed(1)}%`]
        );
        
        console.log(table.toString());
        
        // Identify outliers
        const bottom5 = await client.zRange('risk:distribution', 0, 4, { withScores: true });
        const top5 = await client.zRange('risk:distribution', -5, -1, { withScores: true });
        
        console.log(chalk.red.bold('\n⚠️ Highest Risk Customers:'));
        for (const customer of bottom5) {
            console.log(`  ${customer.value}: Score ${customer.score}`);
        }
        
        console.log(chalk.green.bold('\n✅ Lowest Risk Customers:'));
        for (const customer of top5) {
            console.log(`  ${customer.value}: Score ${customer.score}`);
        }
        
    } catch (error) {
        console.error(chalk.red('Error:', error));
    } finally {
        await client.quit();
    }
}

// Run if executed directly
if (require.main === module) {
    analyzeRiskDistribution();
}

module.exports = { analyzeRiskDistribution };
```

---

## Part 4: Real-Time Analytics Dashboard (5 minutes)

### Step 7: Integrated Analytics Dashboard

Create `src/analytics-dashboard.js`:
```javascript
const client = require('./redis-client');
const chalk = require('chalk');
const ora = require('ora');
const { segmentCustomersByRisk } = require('./customer-segmentation');
const { buildAgentLeaderboard } = require('./agent-leaderboard');
const { analyzeRiskDistribution } = require('./risk-analysis');
const { analyzeCoverageGaps } = require('./coverage-analysis');

async function runFullAnalytics() {
    console.log(chalk.cyan.bold('\n🎯 COMPREHENSIVE ANALYTICS DASHBOARD\n'));
    console.log(chalk.gray('═'.repeat(60)));
    
    const spinner = ora('Loading analytics modules...').start();
    
    try {
        spinner.text = 'Running customer segmentation...';
        await segmentCustomersByRisk();
        
        spinner.text = 'Building agent leaderboards...';
        await buildAgentLeaderboard();
        
        spinner.text = 'Analyzing risk distribution...';
        await analyzeRiskDistribution();
        
        spinner.text = 'Identifying coverage gaps...';
        await analyzeCoverageGaps();
        
        spinner.succeed('All analytics completed successfully!');
        
        // Summary metrics
        await displaySummaryMetrics();
        
    } catch (error) {
        spinner.fail('Analytics failed');
        console.error(chalk.red('Error:', error));
    }
}

async function displaySummaryMetrics() {
    await client.connect();
    
    console.log(chalk.cyan.bold('\n📈 EXECUTIVE SUMMARY\n'));
    
    try {
        const totalCustomers = await client.dbSize();
        const highRiskCount = await client.sCard('customers:high_risk');
        const topAgent = await client.zRange('leaderboard:revenue', -1, -1);
        
        console.log(`Total Database Keys: ${chalk.yellow(totalCustomers)}`);
        console.log(`High Risk Customers: ${chalk.red(highRiskCount)}`);
        console.log(`Top Revenue Agent: ${chalk.green(topAgent[0] || 'N/A')}`);
        
        // Calculate business metrics
        const quotes = await client.keys('quote:*');
        const activePolicies = await client.keys('policy:*:status');
        const pendingClaims = await client.keys('claim:*:status');
        
        console.log(`\n📊 Business Metrics:`);
        console.log(`  Active Quotes: ${quotes.length}`);
        console.log(`  Active Policies: ${activePolicies.length}`);
        console.log(`  Pending Claims: ${pendingClaims.length}`);
        
    } catch (error) {
        console.error(chalk.red('Summary error:', error));
    } finally {
        await client.quit();
    }
}

// Run if executed directly
if (require.main === module) {
    runFullAnalytics();
}

module.exports = { runFullAnalytics, displaySummaryMetrics };
```

---

## Lab Exercises

### Exercise 1: Advanced Segmentation (10 minutes)
1. Create customer segments based on multiple criteria (age, location, products)
2. Use Set intersections to find specific customer groups
3. Implement dynamic segmentation based on real-time data

### Exercise 2: Time-Based Leaderboards (10 minutes)
1. Create daily, weekly, and monthly leaderboards
2. Implement leaderboard archiving
3. Build comparative performance analytics

### Exercise 3: Fraud Detection System (10 minutes)
1. Use Sets to track suspicious activities
2. Build risk scoring with Sorted Sets
3. Implement real-time fraud alerts

---

## 🎯 Key Takeaways

- **Sets** are perfect for segmentation and membership tracking
- **Sorted Sets** excel at rankings and score-based analytics
- **Set operations** (union, intersection, difference) enable powerful analytics
- **JavaScript async/await** simplifies Redis operations
- **Real-time analytics** can be built efficiently with Redis data structures

---

## 📚 Additional Resources

- [Redis Sets Documentation](https://redis.io/docs/data-types/sets/)
- [Redis Sorted Sets Documentation](https://redis.io/docs/data-types/sorted-sets/)
- [Node Redis Client Documentation](https://github.com/redis/node-redis)
- [Business Analytics with Redis](https://redis.io/docs/use-cases/analytics/)

---

## ✅ Lab Completion Checklist

- [ ] Set up JavaScript Redis client environment
- [ ] Implemented customer segmentation with Sets
- [ ] Built agent leaderboards with Sorted Sets
- [ ] Created risk analysis system
- [ ] Developed coverage gap analysis
- [ ] Integrated full analytics dashboard
- [ ] Completed all three exercises

**Congratulations!** You've mastered analytics with Redis Sets and Sorted Sets using JavaScript! 🎉
