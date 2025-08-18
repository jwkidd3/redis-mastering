#!/bin/bash

# Lab 9 Content Generator Script
# Generates complete content and code for Lab 9: Analytics with Sets and Sorted Sets
# Duration: 45 minutes
# Focus: JavaScript Redis client with Sets and Sorted Sets for business analytics

set -e

LAB_DIR="lab9-analytics-sets-sortedsets"
LAB_NUMBER="9"
LAB_TITLE="Analytics with Sets and Sorted Sets"
LAB_DURATION="45"

echo "🚀 Generating Lab ${LAB_NUMBER}: ${LAB_TITLE}"
echo "📅 Duration: ${LAB_DURATION} minutes"
echo "🎯 Focus: JavaScript Redis client with Sets and Sorted Sets for advanced analytics"
echo ""

# Create lab directory structure
mkdir -p ${LAB_DIR}
cd ${LAB_DIR}

echo "📁 Creating lab directory structure..."
mkdir -p {src,scripts,docs,examples,test-data,analytics-tools}

# Create package.json for JavaScript project
echo "📦 Creating package.json..."
cat > package.json << 'EOF'
{
  "name": "lab9-analytics-sets-sortedsets",
  "version": "1.0.0",
  "description": "Lab 9: Analytics with Sets and Sorted Sets using JavaScript Redis client",
  "main": "src/index.js",
  "scripts": {
    "start": "node src/index.js",
    "test": "node src/test-connection.js",
    "load-data": "node src/load-sample-data.js",
    "analytics": "node src/analytics-dashboard.js",
    "leaderboard": "node src/agent-leaderboard.js",
    "segmentation": "node src/customer-segmentation.js",
    "risk-analysis": "node src/risk-analysis.js",
    "coverage": "node src/coverage-analysis.js",
    "dev": "nodemon src/index.js"
  },
  "keywords": ["redis", "analytics", "sets", "sorted-sets", "javascript"],
  "author": "Redis Training",
  "license": "MIT",
  "dependencies": {
    "redis": "^4.6.0",
    "dotenv": "^16.0.3",
    "chalk": "^4.1.2",
    "cli-table3": "^0.6.3",
    "ora": "^5.4.1"
  },
  "devDependencies": {
    "nodemon": "^2.0.20"
  }
}
EOF

# Create main lab instructions markdown file
echo "📋 Creating lab9.md..."
cat > lab9.md << 'EOF'
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
EOF

# Create data loading script
echo "📊 Creating load-sample-data.js..."
cat > src/load-sample-data.js << 'EOF'
const client = require('./redis-client');
const chalk = require('chalk');
const ora = require('ora');

async function loadSampleData() {
    const spinner = ora('Loading sample analytics data...').start();
    
    try {
        await client.connect();
        
        // Clear existing data
        spinner.text = 'Clearing existing data...';
        await client.flushDb();
        
        // Load customers with risk scores
        spinner.text = 'Loading customer data...';
        const customers = [
            { id: 'CUST001', name: 'John Smith', riskScore: 750 },
            { id: 'CUST002', name: 'Jane Doe', riskScore: 820 },
            { id: 'CUST003', name: 'Bob Johnson', riskScore: 620 },
            { id: 'CUST004', name: 'Alice Brown', riskScore: 890 },
            { id: 'CUST005', name: 'Charlie Wilson', riskScore: 550 },
            { id: 'CUST006', name: 'Diana Prince', riskScore: 780 },
            { id: 'CUST007', name: 'Eve Adams', riskScore: 680 },
            { id: 'CUST008', name: 'Frank Castle', riskScore: 920 },
            { id: 'CUST009', name: 'Grace Lee', riskScore: 710 },
            { id: 'CUST010', name: 'Henry Ford', riskScore: 850 }
        ];
        
        for (const customer of customers) {
            await client.set(`customer:${customer.id}:name`, customer.name);
            await client.set(`customer:${customer.id}:risk_score`, customer.riskScore);
            await client.sAdd('all_customers', customer.id);
        }
        
        // Load policies
        spinner.text = 'Loading policy data...';
        const policies = [
            { id: 'auto:100001', customer: 'CUST001', premium: 1200 },
            { id: 'home:200001', customer: 'CUST001', premium: 1500 },
            { id: 'auto:100002', customer: 'CUST002', premium: 1000 },
            { id: 'life:300001', customer: 'CUST002', premium: 600 },
            { id: 'auto:100003', customer: 'CUST003', premium: 1400 },
            { id: 'home:200002', customer: 'CUST004', premium: 1800 },
            { id: 'life:300002', customer: 'CUST004', premium: 800 },
            { id: 'auto:100004', customer: 'CUST005', premium: 1600 },
            { id: 'home:200003', customer: 'CUST006', premium: 1300 },
            { id: 'life:300003', customer: 'CUST006', premium: 700 }
        ];
        
        for (const policy of policies) {
            await client.set(`policy:${policy.id}:customer`, policy.customer);
            await client.set(`policy:${policy.id}:premium`, policy.premium);
            await client.set(`policy:${policy.id}:status`, 'ACTIVE');
        }
        
        // Load agent performance data
        spinner.text = 'Loading agent performance data...';
        const agents = [
            { id: 'AG001', name: 'Michael Scott', sales: 25, revenue: 45000, satisfaction: 4.5 },
            { id: 'AG002', name: 'Dwight Schrute', sales: 32, revenue: 58000, satisfaction: 4.2 },
            { id: 'AG003', name: 'Jim Halpert', sales: 28, revenue: 52000, satisfaction: 4.8 },
            { id: 'AG004', name: 'Pam Beesly', sales: 22, revenue: 40000, satisfaction: 4.9 },
            { id: 'AG005', name: 'Stanley Hudson', sales: 18, revenue: 35000, satisfaction: 3.8 }
        ];
        
        for (const agent of agents) {
            await client.set(`agent:${agent.id}:name`, agent.name);
            await client.set(`metrics:agent:${agent.id}:policies_sold`, agent.sales);
            await client.set(`metrics:agent:${agent.id}:revenue`, agent.revenue);
            await client.set(`metrics:agent:${agent.id}:satisfaction`, agent.satisfaction);
            await client.sAdd('all_agents', agent.id);
        }
        
        // Load quotes
        spinner.text = 'Loading quote data...';
        for (let i = 1; i <= 10; i++) {
            await client.setEx(`quote:auto:Q${i.toString().padStart(3, '0')}`, 300, 
                JSON.stringify({ amount: 1000 + (i * 100), customer: `CUST${i.toString().padStart(3, '0')}` }));
        }
        
        // Load claims
        spinner.text = 'Loading claims data...';
        const claims = [
            { id: 'CLM001', amount: 5000, status: 'PENDING' },
            { id: 'CLM002', amount: 2500, status: 'APPROVED' },
            { id: 'CLM003', amount: 8000, status: 'UNDER_REVIEW' },
            { id: 'CLM004', amount: 1500, status: 'PAID' },
            { id: 'CLM005', amount: 3500, status: 'PENDING' }
        ];
        
        for (const claim of claims) {
            await client.set(`claim:${claim.id}:amount`, claim.amount);
            await client.set(`claim:${claim.id}:status`, claim.status);
        }
        
        spinner.succeed(chalk.green('Sample data loaded successfully!'));
        
        console.log(chalk.cyan('\n📊 Data Summary:'));
        console.log(`  • Customers: ${customers.length}`);
        console.log(`  • Policies: ${policies.length}`);
        console.log(`  • Agents: ${agents.length}`);
        console.log(`  • Quotes: 10`);
        console.log(`  • Claims: ${claims.length}`);
        
    } catch (error) {
        spinner.fail('Failed to load sample data');
        console.error(chalk.red('Error:', error));
    } finally {
        await client.quit();
    }
}

// Run if executed directly
if (require.main === module) {
    loadSampleData();
}

module.exports = { loadSampleData };
EOF

# Create test connection script
echo "🔧 Creating test-connection.js..."
cat > src/test-connection.js << 'EOF'
const client = require('./redis-client');
const chalk = require('chalk');

async function testConnection() {
    console.log(chalk.cyan('\n🔌 Testing Redis connection...\n'));
    
    try {
        await client.connect();
        
        // Test basic operations
        const pingResult = await client.ping();
        console.log(chalk.green('✅ PING:', pingResult));
        
        // Test write
        await client.set('test:key', 'test value');
        console.log(chalk.green('✅ SET: test:key'));
        
        // Test read
        const value = await client.get('test:key');
        console.log(chalk.green('✅ GET:', value));
        
        // Test delete
        await client.del('test:key');
        console.log(chalk.green('✅ DEL: test:key'));
        
        // Get server info
        const info = await client.info('server');
        const version = info.match(/redis_version:([^\r\n]+)/)[1];
        console.log(chalk.green(`\n✅ Connected to Redis ${version}`));
        
        console.log(chalk.green('\n🎉 All tests passed! Redis is ready.\n'));
        
    } catch (error) {
        console.error(chalk.red('❌ Connection failed:', error.message));
        console.log(chalk.yellow('\nTroubleshooting:'));
        console.log('1. Ensure Redis is running: docker ps | grep redis');
        console.log('2. Check Redis port: redis-cli ping');
        console.log('3. Verify environment variables in .env file');
    } finally {
        await client.quit();
    }
}

// Run if executed directly
if (require.main === module) {
    testConnection();
}

module.exports = { testConnection };
EOF

# Create main index.js
echo "📄 Creating index.js..."
cat > src/index.js << 'EOF'
const chalk = require('chalk');
const { runFullAnalytics } = require('./analytics-dashboard');

console.log(chalk.cyan.bold('\n🚀 Lab 9: Analytics with Sets and Sorted Sets\n'));
console.log(chalk.gray('═'.repeat(60)));
console.log('\nWelcome to the Analytics Lab!');
console.log('\nAvailable commands:');
console.log('  npm test              - Test Redis connection');
console.log('  npm run load-data     - Load sample data');
console.log('  npm run segmentation  - Run customer segmentation');
console.log('  npm run leaderboard   - Display agent leaderboards');
console.log('  npm run risk-analysis - Analyze risk distribution');
console.log('  npm run coverage      - Analyze coverage gaps');
console.log('  npm run analytics     - Run full analytics dashboard');
console.log('\nStarting full analytics dashboard...\n');

// Run analytics
runFullAnalytics().catch(console.error);
EOF

# Create .env file
echo "🔐 Creating .env file..."
cat > .env << 'EOF'
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_DB=0
EOF

# Create documentation
echo "📚 Creating README.md..."
cat > README.md << 'EOF'
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
EOF

# Create troubleshooting guide
echo "🔧 Creating troubleshooting.md..."
cat > docs/troubleshooting.md << 'EOF'
# Troubleshooting Guide - Lab 9

## Common Issues and Solutions

### 1. Connection Refused Error

**Error:**
```
Error: connect ECONNREFUSED 127.0.0.1:6379
```

**Solution:**
```bash
# Start Redis container
docker run -d --name redis-analytics-lab9 -p 6379:6379 redis:7-alpine

# Verify Redis is running
docker ps | grep redis
redis-cli ping
```

### 2. Module Not Found

**Error:**
```
Error: Cannot find module 'redis'
```

**Solution:**
```bash
# Install dependencies
npm install

# Verify installation
npm list redis
```

### 3. Empty Analytics Results

**Problem:** Analytics show no data or empty results

**Solution:**
```bash
# Load sample data first
npm run load-data

# Verify data exists
redis-cli DBSIZE
redis-cli KEYS "*"
```

### 4. Async/Await Errors

**Error:**
```
SyntaxError: await is only valid in async function
```

**Solution:**
Ensure all functions using `await` are declared as `async`:
```javascript
async function myFunction() {
    const result = await client.get('key');
    return result;
}
```

### 5. Redis Memory Issues

**Error:**
```
OOM command not allowed when used memory > 'maxmemory'
```

**Solution:**
```bash
# Increase Redis memory limit
redis-cli CONFIG SET maxmemory 2gb

# Or restart with higher limit
docker run -d --name redis-analytics-lab9 \
  -p 6379:6379 \
  redis:7-alpine redis-server --maxmemory 2gb
```

## Performance Optimization

### Batch Operations
Use pipelines for multiple operations:
```javascript
const pipeline = client.pipeline();
for (const item of items) {
    pipeline.sAdd('set:key', item);
}
await pipeline.exec();
```

### Connection Pooling
Reuse connections instead of creating new ones:
```javascript
// Good - single connection
const client = redis.createClient();
await client.connect();
// Use client for all operations

// Bad - multiple connections
async function operation1() {
    const client = redis.createClient();
    await client.connect();
    // ...
}
```

## Debugging Tips

### Enable Debug Logging
```javascript
const client = redis.createClient({
    socket: {
        host: 'localhost',
        port: 6379
    },
    legacyMode: false,
    socket: {
        reconnectStrategy: (retries) => {
            console.log(`Reconnection attempt ${retries}`);
            return Math.min(retries * 50, 1000);
        }
    }
});

client.on('error', (err) => console.error('Redis Error:', err));
client.on('connect', () => console.log('Redis Connected'));
client.on('ready', () => console.log('Redis Ready'));
client.on('reconnecting', () => console.log('Redis Reconnecting'));
```

### Monitor Redis Commands
```bash
# In terminal
redis-cli MONITOR

# See slow queries
redis-cli SLOWLOG GET 10
```

### Check Data Types
```bash
# Verify data type before operations
redis-cli TYPE key:name
```

## Best Practices

1. **Always handle errors:**
   ```javascript
   try {
       const result = await client.get('key');
   } catch (error) {
       console.error('Operation failed:', error);
   }
   ```

2. **Close connections properly:**
   ```javascript
   try {
       // operations
   } finally {
       await client.quit();
   }
   ```

3. **Use appropriate data structures:**
   - Sets for unique values
   - Sorted Sets for rankings
   - Choose based on access patterns

4. **Implement retry logic:**
   ```javascript
   async function withRetry(operation, maxRetries = 3) {
       for (let i = 0; i < maxRetries; i++) {
           try {
               return await operation();
           } catch (error) {
               if (i === maxRetries - 1) throw error;
               await new Promise(r => setTimeout(r, 1000 * Math.pow(2, i)));
           }
       }
   }
   ```
EOF

# Create examples directory content
echo "📝 Creating analytics examples..."
cat > examples/advanced-analytics.md << 'EOF'
# Advanced Analytics Examples

## 1. Cohort Analysis

```javascript
// Group customers by signup month
async function cohortAnalysis() {
    const cohorts = {};
    const customers = await client.keys('customer:*:signup_date');
    
    for (const key of customers) {
        const signupDate = await client.get(key);
        const month = new Date(signupDate).toISOString().slice(0, 7);
        const customerId = key.split(':')[1];
        
        await client.sAdd(`cohort:${month}`, customerId);
    }
    
    // Analyze retention
    for (const cohort in cohorts) {
        const members = await client.sMembers(`cohort:${cohort}`);
        const active = await client.sInter(`cohort:${cohort}`, 'customers:active');
        console.log(`${cohort}: ${active.length}/${members.length} retained`);
    }
}
```

## 2. Product Affinity Analysis

```javascript
// Find products frequently bought together
async function productAffinity() {
    const products = await client.keys('product:*');
    const affinities = [];
    
    for (let i = 0; i < products.length; i++) {
        for (let j = i + 1; j < products.length; j++) {
            const product1 = products[i].split(':')[1];
            const product2 = products[j].split(':')[1];
            
            const customers1 = await client.sMembers(`customers:bought:${product1}`);
            const customers2 = await client.sMembers(`customers:bought:${product2}`);
            const both = await client.sInter(
                `customers:bought:${product1}`,
                `customers:bought:${product2}`
            );
            
            const affinity = both.length / Math.min(customers1.length, customers2.length);
            affinities.push({ product1, product2, affinity });
        }
    }
    
    return affinities.sort((a, b) => b.affinity - a.affinity);
}
```

## 3. Real-Time Trending

```javascript
// Track trending topics/products
async function updateTrending(item, score) {
    const now = Date.now();
    const hourBucket = Math.floor(now / 3600000); // Hour buckets
    
    // Add to current hour's trending
    await client.zIncrBy(`trending:${hourBucket}`, score, item);
    
    // Expire old buckets
    await client.expire(`trending:${hourBucket}`, 7200); // 2 hours
    
    // Calculate overall trending
    const currentBucket = `trending:${hourBucket}`;
    const prevBucket = `trending:${hourBucket - 1}`;
    
    // Weighted merge of current and previous hour
    await client.zUnionStore('trending:overall', 2,
        currentBucket, prevBucket,
        { weights: [2, 1] }
    );
    
    // Get top trending
    return await client.zRevRange('trending:overall', 0, 9, { withScores: true });
}
```

## 4. Geographic Analytics

```javascript
// Analyze customers by region
async function geographicAnalysis() {
    const regions = ['north', 'south', 'east', 'west'];
    const analysis = {};
    
    for (const region of regions) {
        const customers = await client.sMembers(`customers:region:${region}`);
        const highValue = await client.sInter(
            `customers:region:${region}`,
            'customers:high_value'
        );
        
        // Calculate metrics
        const totalRevenue = 0;
        for (const customerId of customers) {
            const revenue = await client.get(`customer:${customerId}:total_revenue`);
            totalRevenue += parseFloat(revenue || 0);
        }
        
        analysis[region] = {
            totalCustomers: customers.length,
            highValueCustomers: highValue.length,
            totalRevenue,
            avgRevenue: totalRevenue / customers.length
        };
    }
    
    return analysis;
}
```

## 5. Predictive Scoring

```javascript
// Calculate predictive scores
async function calculatePredictiveScore(customerId) {
    const weights = {
        recency: 0.3,
        frequency: 0.3,
        monetary: 0.4
    };
    
    // Recency score (days since last purchase)
    const lastPurchase = await client.get(`customer:${customerId}:last_purchase`);
    const daysSince = (Date.now() - new Date(lastPurchase)) / 86400000;
    const recencyScore = Math.max(0, 100 - daysSince);
    
    // Frequency score (purchases per month)
    const purchaseCount = await client.get(`customer:${customerId}:purchase_count`);
    const accountAge = await client.get(`customer:${customerId}:account_age_days`);
    const frequencyScore = (purchaseCount / (accountAge / 30)) * 10;
    
    // Monetary score (total spend)
    const totalSpend = await client.get(`customer:${customerId}:total_spend`);
    const monetaryScore = Math.min(100, totalSpend / 100);
    
    // Calculate weighted score
    const predictiveScore = 
        (recencyScore * weights.recency) +
        (frequencyScore * weights.frequency) +
        (monetaryScore * weights.monetary);
    
    // Store in sorted set
    await client.zAdd('customers:predictive_scores', {
        score: predictiveScore,
        value: customerId
    });
    
    return predictiveScore;
}
```
EOF

# Create .gitignore
cat > .gitignore << 'EOF'
# Dependencies
node_modules/
package-lock.json

# Environment
.env
.env.local
.env.*.local

# Logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# OS files
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
*.swp
*.swo

# Test coverage
coverage/
.nyc_output/

# Build
dist/
build/

# Redis
dump.rdb
*.aof

# Temporary
tmp/
temp/
EOF

echo ""
echo "📂 Project structure created:"
echo "   ${LAB_DIR}/"
echo "   ├── lab9.md                           📋 START HERE - Complete lab guide"
echo "   ├── package.json                      📦 Node.js project configuration"
echo "   ├── .env                             🔐 Environment configuration"
echo "   ├── src/"
echo "   │   ├── index.js                     🚀 Main application"
echo "   │   ├── redis-client.js              🔌 Redis connection"
echo "   │   ├── test-connection.js           🔧 Connection tester"
echo "   │   ├── load-sample-data.js          📊 Data loader"
echo "   │   ├── customer-segmentation.js     👥 Segmentation analytics"
echo "   │   ├── agent-leaderboard.js         🏆 Performance tracking"
echo "   │   ├── risk-analysis.js             ⚠️  Risk distribution"
echo "   │   ├── coverage-analysis.js         📈 Coverage gaps"
echo "   │   └── analytics-dashboard.js       📊 Full dashboard"
echo "   ├── docs/"
echo "   │   └── troubleshooting.md           🔧 Troubleshooting guide"
echo "   ├── examples/"
echo "   │   └── advanced-analytics.md        📝 Advanced examples"
echo "   ├── README.md                         📖 Project documentation"
echo "   └── .gitignore                        🚫 Git ignore rules"
echo ""
echo "🎯 NEXT STEPS:"
echo "   1. cd ${LAB_DIR}"
echo "   2. npm install                        # Install dependencies"
echo "   3. code .                             # Open in VS Code"
echo "   4. docker run -d --name redis-analytics-lab9 -p 6379:6379 redis:7-alpine"
echo "   5. npm test                           # Test connection"
echo "   6. npm run load-data                  # Load sample data"
echo "   7. npm run analytics                  # Run full dashboard"
echo ""
echo "📊 ANALYTICS FEATURES:"
echo "   👥 Customer Segmentation: Risk-based and product-based grouping"
echo "   🏆 Agent Leaderboards: Sales, revenue, and satisfaction rankings"
echo "   ⚠️  Risk Analysis: Distribution and outlier identification"
echo "   📈 Coverage Analysis: Gap identification and upsell opportunities"
echo "   📊 Integrated Dashboard: Complete business intelligence view"
echo ""
echo "🔧 KEY COMMANDS:"
echo "   npm start               # Run main application"
echo "   npm run segmentation    # Customer segmentation analysis"
echo "   npm run leaderboard     # Agent performance rankings"
echo "   npm run risk-analysis   # Risk distribution analysis"
echo "   npm run coverage        # Coverage gap analysis"
echo ""
echo "🎉 READY TO START LAB 9!"
echo "   Master analytics with Redis Sets and Sorted Sets using JavaScript!"
echo "   This lab combines powerful data structures with real-world analytics scenarios."
echo ""
echo "📈 LEARNING FOCUS:"
echo "   ✅ Sets for segmentation and membership"
echo "   ✅ Sorted Sets for rankings and scoring"
echo "   ✅ Set operations for complex queries"
echo "   ✅ JavaScript async/await patterns"
echo "   ✅ Real-time analytics implementation"
echo "   ✅ Business intelligence dashboards"