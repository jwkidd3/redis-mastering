const Redis = require('ioredis');
const chalk = require('chalk');

class ClusterClient {
  constructor() {
    this.cluster = new Redis.Cluster([
      { port: 9000, host: '127.0.0.1' },
      { port: 9001, host: '127.0.0.1' },
      { port: 9002, host: '127.0.0.1' }
    ], {
      redisOptions: {
        password: process.env.REDIS_PASSWORD
      },
      enableReadyCheck: true,
      maxRetriesPerRequest: 3,
      retryDelayOnFailover: 100,
      retryDelayOnClusterDown: 300,
      enableOfflineQueue: true,
      clusterRetryStrategy: (times) => {
        console.log(chalk.yellow(`Retrying cluster connection... Attempt ${times}`));
        return Math.min(100 * times, 2000);
      }
    });

    this.setupEventHandlers();
  }

  setupEventHandlers() {
    this.cluster.on('connect', () => {
      console.log(chalk.green('✓ Connected to Redis Cluster'));
    });

    this.cluster.on('ready', () => {
      console.log(chalk.green('✓ Redis Cluster is ready'));
    });

    this.cluster.on('error', (err) => {
      console.error(chalk.red('Cluster Error:'), err.message);
    });

    this.cluster.on('close', () => {
      console.log(chalk.yellow('Cluster connection closed'));
    });

    this.cluster.on('reconnecting', () => {
      console.log(chalk.yellow('Reconnecting to cluster...'));
    });

    this.cluster.on('node error', (err, node) => {
      console.error(chalk.red(`Node ${node.options.port} error:`), err.message);
    });

    this.cluster.on('+node', (node) => {
      console.log(chalk.green(`✓ New node added: ${node.options.port}`));
    });

    this.cluster.on('-node', (node) => {
      console.log(chalk.yellow(`Node removed: ${node.options.port}`));
    });
  }

  // Insurance-specific operations
  async createCustomer(customerId, customerData) {
    const key = `customer:${customerId}`;
    const pipeline = this.cluster.pipeline();
    
    // Store customer profile
    pipeline.hset(`${key}:profile`, customerData);

    // Add to customer index
    pipeline.sAdd('customers:all', customerId);

    // Add to segment if provided
    if (customerData.segment) {
      pipeline.sAdd(`customers:segment:${customerData.segment}`, customerId);
    }
    
    // Set creation timestamp
    pipeline.hset(`${key}:metadata`, 'created', Date.now());
    
    const results = await pipeline.exec();
    return results.every(([err, result]) => !err);
  }

  async createPolicy(policyId, customerId, policyData) {
    // Use hash tags to keep customer and policy data together
    const customerKey = `{customer:${customerId}}:profile`;
    const policyKey = `{customer:${customerId}}:policy:${policyId}`;
    
    const pipeline = this.cluster.pipeline();
    
    // Store policy data
    pipeline.hset(policyKey, policyData);

    // Link policy to customer
    pipeline.sAdd(`{customer:${customerId}}:policies`, policyId);

    // Add to policy index
    pipeline.sAdd('policies:all', policyId);
    pipeline.sAdd(`policies:type:${policyData.type}`, policyId);
    
    // Update customer's total coverage
    if (policyData.coverage) {
      pipeline.hincrby(customerKey, 'total_coverage', parseInt(policyData.coverage));
    }
    
    const results = await pipeline.exec();
    return results.every(([err, result]) => !err);
  }

  async processClaim(claimId, policyId, customerId, claimData) {
    const claimKey = `{customer:${customerId}}:claim:${claimId}`;
    
    const pipeline = this.cluster.pipeline();
    
    // Store claim data
    pipeline.hset(claimKey, {
      ...claimData,
      policy_id: policyId,
      customer_id: customerId,
      status: 'pending',
      created: Date.now()
    });
    
    // Add to claims queue
    pipeline.lPush('claims:pending', claimId);

    // Link claim to customer and policy
    pipeline.sAdd(`{customer:${customerId}}:claims`, claimId);
    pipeline.sAdd(`policy:${policyId}:claims`, claimId);
    
    // Increment statistics
    pipeline.hincrby('stats:claims', 'total', 1);
    pipeline.hincrby('stats:claims', `type:${claimData.type}`, 1);
    
    const results = await pipeline.exec();
    return results.every(([err, result]) => !err);
  }

  async getCustomerProfile(customerId) {
    const pipeline = this.cluster.pipeline();

    // Get customer profile
    pipeline.hGetAll(`customer:${customerId}:profile`);

    // Get policies (using hash tags for co-location)
    pipeline.sMembers(`{customer:${customerId}}:policies`);

    // Get claims
    pipeline.sMembers(`{customer:${customerId}}:claims`);

    // Get metadata
    pipeline.hGetAll(`customer:${customerId}:metadata`);
    
    const [[, profile], [, policies], [, claims], [, metadata]] = await pipeline.exec();
    
    return {
      profile,
      policies,
      claims,
      metadata
    };
  }

  async getClusterStats() {
    const info = await this.cluster.cluster('info');
    const nodes = await this.cluster.cluster('nodes');
    
    const stats = {
      state: 'unknown',
      nodes: [],
      slots: {
        total: 16384,
        covered: 0
      }
    };
    
    // Parse cluster info
    const infoLines = info.split('\r\n');
    infoLines.forEach(line => {
      if (line.includes('cluster_state:')) {
        stats.state = line.split(':')[1];
      }
    });
    
    // Parse nodes info
    const nodeLines = nodes.split('\n');
    nodeLines.forEach(line => {
      if (line.trim()) {
        const parts = line.split(' ');
        const node = {
          id: parts[0].substring(0, 8),
          address: parts[1],
          role: parts[2].includes('master') ? 'master' : 'replica',
          status: parts[7] === 'connected' ? 'connected' : 'disconnected'
        };
        
        if (node.role === 'master' && parts.length > 8) {
          // Count slots for this master
          let slotCount = 0;
          for (let i = 8; i < parts.length; i++) {
            if (parts[i].includes('-')) {
              const [start, end] = parts[i].split('-').map(Number);
              slotCount += (end - start + 1);
            }
          }
          node.slots = slotCount;
          stats.slots.covered += slotCount;
        }
        
        stats.nodes.push(node);
      }
    });
    
    return stats;
  }

  async healthCheck() {
    try {
      const result = await this.cluster.ping();
      return result === 'PONG';
    } catch (error) {
      console.error(chalk.red('Health check failed:'), error.message);
      return false;
    }
  }

  async close() {
    await this.cluster.quit();
    console.log(chalk.blue('Cluster connection closed'));
  }
}

// Example usage and testing
async function testClusterClient() {
  console.log(chalk.blue('====================================='));
  console.log(chalk.blue('Testing Redis Cluster Client'));
  console.log(chalk.blue('=====================================\n'));

  const client = new ClusterClient();

  try {
    // Wait for connection
    await new Promise(resolve => setTimeout(resolve, 1000));

    // Health check
    console.log(chalk.yellow('Performing health check...'));
    const isHealthy = await client.healthCheck();
    console.log(isHealthy ? chalk.green('✓ Cluster is healthy') : chalk.red('✗ Cluster is unhealthy'));

    // Get cluster stats
    console.log(chalk.yellow('\nGetting cluster statistics...'));
    const stats = await client.getClusterStats();
    console.log('Cluster State:', stats.state);
    console.log('Total Nodes:', stats.nodes.length);
    console.log('Slots Covered:', `${stats.slots.covered}/${stats.slots.total}`);

    // Create test customer
    console.log(chalk.yellow('\nCreating test customer...'));
    const customerId = `test-${Date.now()}`;
    const customerCreated = await client.createCustomer(customerId, {
      name: 'John Doe',
      email: 'john.doe@example.com',
      segment: 'premium',
      risk_score: 75
    });
    console.log(customerCreated ? chalk.green('✓ Customer created') : chalk.red('✗ Failed to create customer'));

    // Create test policy
    console.log(chalk.yellow('\nCreating test policy...'));
    const policyId = `policy-${Date.now()}`;
    const policyCreated = await client.createPolicy(policyId, customerId, {
      type: 'auto',
      coverage: 100000,
      premium: 1200,
      start_date: new Date().toISOString()
    });
    console.log(policyCreated ? chalk.green('✓ Policy created') : chalk.red('✗ Failed to create policy'));

    // Create test claim
    console.log(chalk.yellow('\nCreating test claim...'));
    const claimId = `claim-${Date.now()}`;
    const claimCreated = await client.processClaim(claimId, policyId, customerId, {
      type: 'collision',
      amount: 5000,
      description: 'Minor fender bender'
    });
    console.log(claimCreated ? chalk.green('✓ Claim created') : chalk.red('✗ Failed to create claim'));

    // Retrieve customer profile
    console.log(chalk.yellow('\nRetrieving customer profile...'));
    const profile = await client.getCustomerProfile(customerId);
    console.log('Profile:', profile.profile);
    console.log('Policies:', profile.policies);
    console.log('Claims:', profile.claims);

    // Cleanup
    console.log(chalk.yellow('\nCleaning up test data...'));
    await client.cluster.del(
      `customer:${customerId}:profile`,
      `{customer:${customerId}}:policies`,
      `{customer:${customerId}}:claims`,
      `{customer:${customerId}}:policy:${policyId}`,
      `{customer:${customerId}}:claim:${claimId}`
    );
    console.log(chalk.green('✓ Cleanup complete'));

  } catch (error) {
    console.error(chalk.red('Error during testing:'), error);
  } finally {
    await client.close();
  }

  console.log(chalk.blue('\n====================================='));
  console.log(chalk.blue('Test Complete'));
  console.log(chalk.blue('====================================='));
}

// Export for use in other modules
module.exports = ClusterClient;

// Run test if this file is executed directly
if (require.main === module) {
  testClusterClient().catch(console.error);
}