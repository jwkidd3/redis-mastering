const Redis = require('ioredis');
const faker = require('faker');
const chalk = require('chalk');
const Table = require('cli-table3');

// Cluster connection
const cluster = new Redis.Cluster([
  { port: 9000, host: '127.0.0.1' },
  { port: 9001, host: '127.0.0.1' },
  { port: 9002, host: '127.0.0.1' }
], {
  enableReadyCheck: true,
  maxRetriesPerRequest: 3,
  commandTimeout: 5000,
  lazyConnect: true,
  retryDelayOnFailover: 100,
  natMap: {
    '172.21.0.2:9001': { host: '127.0.0.1', port: 9001 },
    '172.21.0.3:9000': { host: '127.0.0.1', port: 9000 },
    '172.21.0.4:9004': { host: '127.0.0.1', port: 9004 },
    '172.21.0.5:9005': { host: '127.0.0.1', port: 9005 },
    '172.21.0.6:9003': { host: '127.0.0.1', port: 9003 },
    '172.21.0.7:9002': { host: '127.0.0.1', port: 9002 }
  }
});

// Insurance data generators
const insuranceTypes = ['auto', 'home', 'life', 'health', 'business'];
const claimTypes = ['collision', 'theft', 'fire', 'water_damage', 'medical', 'liability'];
const customerSegments = ['standard', 'premium', 'vip', 'high_risk'];
const claimStatuses = ['pending', 'approved', 'denied', 'processing', 'paid'];

function generateCustomer() {
  return {
    first_name: faker.name.firstName(),
    last_name: faker.name.lastName(),
    email: faker.internet.email(),
    phone: faker.phone.phoneNumber(),
    address: faker.address.streetAddress(),
    city: faker.address.city(),
    state: faker.address.stateAbbr(),
    zip: faker.address.zipCode(),
    dob: faker.date.past(50, new Date(2000, 0, 1)).toISOString(),
    segment: faker.random.arrayElement(customerSegments),
    risk_score: faker.datatype.number({ min: 0, max: 100 }),
    lifetime_value: faker.datatype.number({ min: 1000, max: 100000 }),
    created_date: faker.date.past(5).toISOString()
  };
}

function generatePolicy(customerId) {
  const type = faker.random.arrayElement(insuranceTypes);
  return {
    customer_id: customerId,
    type: type,
    policy_number: `POL-${faker.datatype.number({ min: 100000, max: 999999 })}`,
    coverage_amount: faker.datatype.number({ min: 10000, max: 1000000 }),
    deductible: faker.datatype.number({ min: 250, max: 5000 }),
    premium_monthly: faker.datatype.number({ min: 50, max: 2000 }),
    start_date: faker.date.past(2).toISOString(),
    end_date: faker.date.future(2).toISOString(),
    status: faker.random.arrayElement(['active', 'inactive', 'cancelled']),
    agent_id: `AGT-${faker.datatype.number({ min: 100, max: 999 })}`
  };
}

function generateClaim(policyId, customerId) {
  return {
    policy_id: policyId,
    customer_id: customerId,
    claim_number: `CLM-${faker.datatype.number({ min: 100000, max: 999999 })}`,
    type: faker.random.arrayElement(claimTypes),
    amount: faker.datatype.number({ min: 100, max: 50000 }),
    status: faker.random.arrayElement(claimStatuses),
    filed_date: faker.date.recent(90).toISOString(),
    description: faker.lorem.sentences(2),
    adjuster_id: `ADJ-${faker.datatype.number({ min: 100, max: 999 })}`
  };
}

async function loadInsuranceData() {
  console.log(chalk.blue('====================================='));
  console.log(chalk.blue('Loading Insurance Data into Cluster'));
  console.log(chalk.blue('=====================================\n'));

  const stats = {
    customers: 0,
    policies: 0,
    claims: 0,
    errors: 0
  };

  try {
    // Configuration
    const CUSTOMER_COUNT = 50;
    const POLICIES_PER_CUSTOMER = 2;
    const CLAIMS_PER_POLICY = 1;

    console.log(chalk.yellow('Configuration:'));
    console.log(`  Customers: ${CUSTOMER_COUNT}`);
    console.log(`  Policies per customer: ${POLICIES_PER_CUSTOMER}`);
    console.log(`  Claims per policy: ${CLAIMS_PER_POLICY}`);
    console.log(`  Total expected records: ${CUSTOMER_COUNT + (CUSTOMER_COUNT * POLICIES_PER_CUSTOMER) + (CUSTOMER_COUNT * POLICIES_PER_CUSTOMER * CLAIMS_PER_POLICY)}\n`);

    // Progress tracking
    let processed = 0;
    const total = CUSTOMER_COUNT;

    // Load customers
    console.log(chalk.yellow('Loading customers...'));
    for (let i = 0; i < CUSTOMER_COUNT; i++) {
      const customerId = `CUST-${Date.now()}-${i}`;
      const customerData = generateCustomer();

      // Generate all data first
      const policyData = [];
      const claimData = [];
      
      for (let j = 0; j < POLICIES_PER_CUSTOMER; j++) {
        const policyId = `POL-${Date.now()}-${i}-${j}`;
        const policy = generatePolicy(customerId);
        policyData.push({ id: policyId, data: policy });

        for (let k = 0; k < CLAIMS_PER_POLICY; k++) {
          const claimId = `CLM-${Date.now()}-${i}-${j}-${k}`;
          const claim = generateClaim(policyId, customerId);
          claimData.push({ id: claimId, data: claim });
        }
      }

      // Customer pipeline - all keys with same hash tag
      const customerPipeline = cluster.pipeline();
      
      // Store customer profile
      customerPipeline.hset(`{customer:${customerId}}:profile`, customerData);
      
      // Store metadata
      customerPipeline.hset(`{customer:${customerId}}:metadata`, {
        created: Date.now(),
        last_updated: Date.now()
      });

      stats.customers++;

      // Store policies with hash tags
      for (const policy of policyData) {
        customerPipeline.hset(`{customer:${customerId}}:policy:${policy.id}`, policy.data);
        customerPipeline.sAdd(`{customer:${customerId}}:policies`, policy.id);
        stats.policies++;
      }

      // Store claims with hash tags
      for (const claim of claimData) {
        customerPipeline.hset(`{customer:${customerId}}:claim:${claim.id}`, claim.data);
        customerPipeline.sAdd(`{customer:${customerId}}:claims`, claim.id);

        // Find the policy this claim belongs to
        const policy = policyData.find(p => p.id === claim.data.policy_id);
        if (policy) {
          customerPipeline.sAdd(`{customer:${customerId}}:policy:${policy.id}:claims`, claim.id);
        }
        stats.claims++;
      }

      // Execute customer pipeline
      const customerResults = await customerPipeline.exec();
      const customerErrors = customerResults.filter(([err]) => err);
      stats.errors += customerErrors.length;

      // Skip global indexes during bulk load for performance
      // They can be rebuilt later if needed

      // Update progress
      processed++;
      if (processed % 10 === 0 || processed === total) {
        const progress = ((processed / total) * 100).toFixed(1);
        process.stdout.write(`\r  Progress: ${progress}% (${processed}/${total} customers)`);
      }
    }

    console.log('\n');

    // Generate aggregate statistics
    console.log(chalk.yellow('Generating aggregate statistics...'));
    
    // Store statistics separately (different slots)
    try {
      await cluster.hset('stats:customers', {
        total: stats.customers,
        last_updated: Date.now()
      });
      
      await cluster.hset('stats:policies', {
        total: stats.policies,
        avg_per_customer: (stats.policies / stats.customers).toFixed(2),
        last_updated: Date.now()
      });
      
      await cluster.hset('stats:claims', {
        total: stats.claims,
        avg_per_policy: (stats.claims / stats.policies).toFixed(2),
        last_updated: Date.now()
      });
    } catch (statsError) {
      console.warn('Warning: Error storing statistics:', statsError.message);
      stats.errors++;
    }

    // Display summary
    console.log(chalk.green('\n✓ Data loading complete!\n'));

    const summaryTable = new Table({
      head: ['Entity', 'Count', 'Status'],
      colWidths: [20, 15, 20]
    });

    summaryTable.push(
      ['Customers', stats.customers, chalk.green('✓ Loaded')],
      ['Policies', stats.policies, chalk.green('✓ Loaded')],
      ['Claims', stats.claims, chalk.green('✓ Loaded')],
      ['Errors', stats.errors, stats.errors === 0 ? chalk.green('None') : chalk.red(`${stats.errors} errors`)]
    );

    console.log(summaryTable.toString());

    // Verify data distribution
    console.log(chalk.yellow('\nVerifying data distribution across shards...'));
    
    const nodes = cluster.nodes('master');
    const distributionTable = new Table({
      head: ['Node', 'Port', 'Approximate Keys'],
      colWidths: [15, 10, 20]
    });

    for (let i = 0; i < nodes.length; i++) {
      const node = nodes[i];
      const info = await node.info('keyspace');
      const match = info.match(/db0:keys=(\d+)/);
      const keys = match ? match[1] : '0';
      distributionTable.push([
        `Master ${i + 1}`,
        node.options.port,
        keys
      ]);
    }

    console.log(distributionTable.toString());

    // Sample queries
    console.log(chalk.yellow('\nSample queries to verify data:'));
    
    // Get random customer
    const randomCustomer = await cluster.sRandMember('customers:all');
    if (randomCustomer) {
      const profile = await cluster.hGetAll(`{customer:${randomCustomer}}:profile`);
      console.log(`\nRandom Customer: ${randomCustomer}`);
      console.log(`  Name: ${profile.first_name} ${profile.last_name}`);
      console.log(`  Segment: ${profile.segment}`);
      console.log(`  Risk Score: ${profile.risk_score}`);
    }

    // Get top risk customers
    const highRiskCustomers = await cluster.zRevRange('customers:by_risk', 0, 2, 'WITHSCORES');
    console.log('\nTop 3 High Risk Customers:');
    for (let i = 0; i < highRiskCustomers.length; i += 2) {
      console.log(`  ${highRiskCustomers[i]}: Risk Score ${highRiskCustomers[i + 1]}`);
    }

    // Get recent claims
    const recentClaims = await cluster.zRevRange('claims:by_date', 0, 2);
    console.log('\nMost Recent Claims:');
    for (const claimId of recentClaims) {
      console.log(`  ${claimId}`);
    }

  } catch (error) {
    console.error(chalk.red('\nError loading data:'), error);
    stats.errors++;
  } finally {
    await cluster.quit();
  }

  console.log(chalk.blue('\n====================================='));
  console.log(chalk.blue('Data Loading Complete'));
  console.log(chalk.blue('====================================='));

  return stats;
}

// Run if executed directly
if (require.main === module) {
  loadInsuranceData().catch(console.error);
}

module.exports = loadInsuranceData;