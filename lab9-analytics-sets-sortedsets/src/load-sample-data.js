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
