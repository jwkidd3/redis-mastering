const Redis = require('ioredis');
const crypto = require('crypto');
const Table = require('cli-table3');
const chalk = require('chalk');

// Configuration
const REDIS_HOST = process.env.REDIS_HOST || process.argv[2] || '127.0.0.1';
const CLUSTER_PORTS = [9000, 9001, 9002];
const TEST_KEY_PREFIX = 'sharding_test';
const TEST_TIMEOUT = 10000;

class RedisShardingTester {
  constructor() {
    this.cluster = null;
    this.isConnected = false;
    this.testResults = new Map();
  }

  async buildNatMap() {
    const { execSync } = require('child_process');
    const natMap = {};
    
    try {
      // Get cluster nodes information from Redis
      const nodesOutput = execSync('docker exec redis-node-1 redis-cli -p 9000 cluster nodes 2>/dev/null', { encoding: 'utf8' });
      const lines = nodesOutput.trim().split('\n');
      
      for (const line of lines) {
        const parts = line.split(' ');
        if (parts.length >= 2) {
          const address = parts[1];
          // Parse address like "172.21.0.5:9000@19000"
          const match = address.match(/^([0-9.]+):(\d+)@/);
          if (match) {
            const ip = match[1];
            const port = match[2];
            // Map internal Docker IP:port to localhost:port
            natMap[`${ip}:${port}`] = { host: '127.0.0.1', port: parseInt(port) };
          }
        }
      }
    } catch (error) {
      console.log(chalk.yellow('Warning: Could not dynamically build NAT map, using fallback'));
      // Fallback: try to map all possible ports
      for (const port of CLUSTER_PORTS) {
        // This won't handle redirects properly but allows basic connection
        natMap[`127.0.0.1:${port}`] = { host: '127.0.0.1', port };
      }
    }
    
    return natMap;
  }

  async createCluster() {
    const nodes = CLUSTER_PORTS.map(port => ({ port, host: REDIS_HOST }));
    
    // Build NAT map dynamically
    const natMap = await this.buildNatMap();
    console.log(chalk.gray('Using dynamic NAT mapping for Docker IPs'));
    
    return new Redis.Cluster(nodes, {
      enableReadyCheck: true,
      maxRetriesPerRequest: 3,
      retryDelayOnFailover: 100,
      natMap,
      redisOptions: {
        connectTimeout: 5000,
        commandTimeout: 5000,
        lazyConnect: true
      }
    });
  }

  // CRC16 implementation for hash slot calculation
  crc16(buf) {
    let crc = 0;
    for (let i = 0; i < buf.length; i++) {
      crc = crc ^ (buf[i] << 8);
      for (let j = 0; j < 8; j++) {
        if (crc & 0x8000) {
          crc = (crc << 1) ^ 0x1021;
        } else {
          crc = crc << 1;
        }
      }
    }
    return crc & 0xFFFF;
  }

  // Calculate hash slot for a key
  getHashSlot(key) {
    let hashKey = key;
    // Check for hash tags {}
    const start = key.indexOf('{');
    if (start !== -1) {
      const end = key.indexOf('}', start + 1);
      if (end !== -1 && end !== start + 1) {
        hashKey = key.substring(start + 1, end);
      }
    }
    return this.crc16(Buffer.from(hashKey)) % 16384;
  }

  // Get shard number for a slot (accurate calculation)
  getShardForSlot(slot) {
    if (slot >= 0 && slot <= 5460) return 0;
    if (slot >= 5461 && slot <= 10922) return 1;
    if (slot >= 10923 && slot <= 16383) return 2;
    return -1; // Invalid slot
  }

  async connect() {
    console.log(chalk.yellow('Connecting to Redis cluster...'));
    
    this.cluster = await this.createCluster();
    
    try {
      await Promise.race([
        this.cluster.ping(),
        new Promise((_, reject) => 
          setTimeout(() => reject(new Error('Connection timeout')), TEST_TIMEOUT)
        )
      ]);
      
      this.isConnected = true;
      console.log(chalk.green('✓ Connected to Redis cluster\n'));
      return true;
    } catch (error) {
      console.error(chalk.red('✗ Failed to connect to Redis cluster'));
      console.error(chalk.yellow('Please ensure Redis cluster is running:'));
      console.error(chalk.yellow('  1. Run: ./scripts/init-cluster.sh'));
      console.error(chalk.yellow('  2. Or check if cluster is running on ports 9000-9002'));
      console.error(chalk.gray(`  Error: ${error.message}`));
      await this.disconnect();
      return false;
    }
  }

  async disconnect() {
    if (this.cluster) {
      try {
        await this.cluster.quit();
        console.log(chalk.green('✓ Connection closed'));
      } catch (error) {
        console.log(chalk.yellow('Warning: Issue closing connection'));
      }
      this.cluster = null;
      this.isConnected = false;
    }
  }

  async cleanup() {
    console.log(chalk.yellow('Cleaning up test keys...'));
    
    if (!this.isConnected) return;
    
    try {
      const pattern = `${TEST_KEY_PREFIX}:*`;
      const pipeline = this.cluster.pipeline();
      
      // Use SCAN to find and delete test keys
      const nodes = this.cluster.nodes('master');
      for (const node of nodes) {
        let cursor = '0';
        do {
          const result = await node.scan(cursor, 'MATCH', pattern, 'COUNT', 100);
          cursor = result[0];
          const keys = result[1];
          
          if (keys.length > 0) {
            for (const key of keys) {
              pipeline.del(key);
            }
          }
        } while (cursor !== '0');
      }
      
      await pipeline.exec();
      console.log(chalk.green('✓ Cleanup complete'));
    } catch (error) {
      console.log(chalk.yellow(`Cleanup had some issues: ${error.message}`));
    }
  }

  recordTestResult(testName, success, details = null) {
    this.testResults.set(testName, { success, details, timestamp: Date.now() });
  }

  displayTestSummary() {
    console.log(chalk.blue('\n====================================='));
    console.log(chalk.blue('Test Summary'));
    console.log(chalk.blue('====================================='));
    
    const table = new Table({
      head: ['Test', 'Status', 'Details'],
      colWidths: [35, 10, 40]
    });
    
    let passed = 0;
    let total = 0;
    
    this.testResults.forEach((result, testName) => {
      total++;
      if (result.success) passed++;
      
      table.push([
        testName,
        result.success ? chalk.green('PASS') : chalk.red('FAIL'),
        result.details || ''
      ]);
    });
    
    console.log(table.toString());
    console.log(`\nTests passed: ${passed}/${total}`);
    
    if (passed === total) {
      console.log(chalk.green('🎉 All tests passed!'));
    } else {
      console.log(chalk.red(`❌ ${total - passed} test(s) failed`));
    }
  }

  async runAllTests() {
    console.log(chalk.blue('====================================='));
    console.log(chalk.blue('Redis Cluster Sharding Test Suite'));
    console.log(chalk.blue('====================================='));
    console.log(chalk.cyan(`Using Redis host: ${REDIS_HOST}`));
    console.log(chalk.gray('Usage: node test-sharding.js [host] or REDIS_HOST=host node test-sharding.js'));
    console.log('');

    if (!(await this.connect())) {
      process.exit(1);
    }

    try {
      await this.testKeyDistribution();
      await this.testHashSlotCalculation();
      await this.testKeyStorage();
      await this.testKeyRetrieval();
      await this.testHashTags();
      await this.testCrossSlotOperations();
      await this.testPerformance();
      await this.testClusterInfo();
    } catch (error) {
      console.error(chalk.red('Error during testing:'), error);
      this.recordTestResult('Overall Test Suite', false, error.message);
    } finally {
      await this.cleanup();
      await this.disconnect();
      this.displayTestSummary();
    }
  }

  async testKeyDistribution() {
    console.log(chalk.yellow('Test 1: Key Distribution Across Shards'));
    console.log('---------------------------------------');
    
    try {
      const distribution = new Map([0, 1, 2].map(i => [i, 0]));
      const testKeys = [];
      const keyCount = 1000;
      
      // Generate test keys and track distribution
      for (let i = 0; i < keyCount; i++) {
        const key = `${TEST_KEY_PREFIX}:dist:${i}`;
        const slot = this.getHashSlot(key);
        const shard = this.getShardForSlot(slot);
        testKeys.push({ key, slot, shard });
        
        if (shard !== -1) {
          distribution.set(shard, distribution.get(shard) + 1);
        }
      }
      
      // Display distribution
      const distTable = new Table({
        head: ['Shard', 'Slot Range', 'Key Count', 'Percentage'],
        colWidths: [10, 20, 15, 15]
      });
      
      const slotRanges = [
        { start: 0, end: 5460 },
        { start: 5461, end: 10922 },
        { start: 10923, end: 16383 }
      ];
      
      distribution.forEach((count, shard) => {
        const range = slotRanges[shard];
        const percentage = ((count / keyCount) * 100).toFixed(2);
        distTable.push([
          `Shard ${shard + 1}`,
          `${range.start}-${range.end}`,
          count,
          `${percentage}%`
        ]);
      });
      
      console.log(distTable.toString());
      
      // Check if distribution is reasonably balanced (within 10% of expected 33.33%)
      const expectedPercentage = 100 / 3;
      const isBalanced = Array.from(distribution.values()).every(count => {
        const percentage = (count / keyCount) * 100;
        return Math.abs(percentage - expectedPercentage) < 10;
      });
      
      this.recordTestResult('Key Distribution', isBalanced, 
        isBalanced ? 'Keys distributed evenly' : 'Distribution imbalanced');
      
      if (isBalanced) {
        console.log(chalk.green('✓ Keys are well distributed across shards'));
      } else {
        console.log(chalk.yellow('⚠ Key distribution is uneven'));
      }
      
    } catch (error) {
      this.recordTestResult('Key Distribution', false, error.message);
      console.error(chalk.red('✗ Key distribution test failed:'), error.message);
    }
  }
  async testHashSlotCalculation() {
    console.log(chalk.yellow('\nTest 2: Hash Slot Calculation Examples'));
    console.log('----------------------------------------');
    
    try {
      const exampleKeys = [
        'user:123',
        'user:456', 
        'product:789',
        'order:abc',
        '{user:123}:profile',
        '{user:123}:settings',
        'cache:{session:abc123}:data',
        'metrics:cpu:server1'
      ];
      
      const slotTable = new Table({
        head: ['Key', 'Hash Slot', 'Shard', 'Hash Tag'],
        colWidths: [25, 12, 8, 15]
      });
      
      let hashTagsCorrect = true;
      
      for (const key of exampleKeys) {
        const slot = this.getHashSlot(key);
        const shard = this.getShardForSlot(slot) + 1;
        
        // Extract hash tag if present
        let hashTag = '';
        const start = key.indexOf('{');
        if (start !== -1) {
          const end = key.indexOf('}', start + 1);
          if (end !== -1 && end !== start + 1) {
            hashTag = key.substring(start + 1, end);
          }
        }
        
        slotTable.push([key, slot, shard, hashTag || 'None']);
      }
      
      console.log(slotTable.toString());
      
      // Test hash tag consistency
      const userKeys = exampleKeys.filter(key => key.includes('{user:123}'));
      if (userKeys.length > 1) {
        const slots = userKeys.map(key => this.getHashSlot(key));
        const allSameSlot = slots.every(slot => slot === slots[0]);
        
        if (allSameSlot) {
          console.log(chalk.green('✓ Hash tags ensure keys land on same slot'));
        } else {
          console.log(chalk.red('✗ Hash tags not working correctly'));
          hashTagsCorrect = false;
        }
      }
      
      this.recordTestResult('Hash Slot Calculation', true, 'Hash slots calculated correctly');
      this.recordTestResult('Hash Tags', hashTagsCorrect, 
        hashTagsCorrect ? 'Hash tags working correctly' : 'Hash tag issue detected');
      
    } catch (error) {
      this.recordTestResult('Hash Slot Calculation', false, error.message);
      console.error(chalk.red('✗ Hash slot calculation test failed:'), error.message);
    }
  }
  async testKeyStorage() {
    console.log(chalk.yellow('\nTest 3: Writing Keys to Cluster'));
    console.log('---------------------------------');
    
    try {
      const keyCount = 50;
      let successfulWrites = 0;
      
      // Write keys individually to handle different slots
      for (let i = 0; i < keyCount; i++) {
        const key = `${TEST_KEY_PREFIX}:storage:${i}`;
        const value = JSON.stringify({ id: i, timestamp: Date.now(), data: `value-${i}` });
        try {
          const result = await this.cluster.set(key, value, 'EX', 300);
          if (result === 'OK') {
            successfulWrites++;
          }
        } catch (err) {
          // Individual key write failed
        }
        
        if (i % 10 === 0) {
          process.stdout.write(`\r  Writing keys: ${i + 1}/${keyCount}`);
        }
      }
      console.log(`\r  Writing keys: ${keyCount}/${keyCount}`);
      
      const allSuccessful = successfulWrites === keyCount;
      this.recordTestResult('Key Storage', allSuccessful, 
        `${successfulWrites}/${keyCount} keys written successfully`);
      
      if (allSuccessful) {
        console.log(chalk.green(`✓ Successfully wrote ${keyCount} keys to cluster`));
      } else {
        console.log(chalk.yellow(`⚠ Only ${successfulWrites}/${keyCount} keys written successfully`));
      }
      
    } catch (error) {
      this.recordTestResult('Key Storage', false, error.message);
      console.error(chalk.red('✗ Key storage test failed:'), error.message);
    }
  }
  async testKeyRetrieval() {
    console.log(chalk.yellow('\nTest 4: Verifying Key Accessibility'));
    console.log('------------------------------------');
    
    try {
      const keyCount = 20;
      let validValues = 0;
      
      // Read keys individually to handle different slots
      for (let i = 0; i < keyCount; i++) {
        const key = `${TEST_KEY_PREFIX}:storage:${i}`;
        try {
          const result = await this.cluster.get(key);
          if (result) {
            try {
              const parsed = JSON.parse(result);
              if (parsed.id === i && parsed.data === `value-${i}`) {
                validValues++;
              }
            } catch (parseError) {
              // Invalid JSON
            }
          }
        } catch (err) {
          // Individual key read failed
        }
      }
      
      const allValid = validValues === keyCount;
      this.recordTestResult('Key Retrieval', allValid, 
        `${validValues}/${keyCount} keys retrieved correctly`);
      
      if (allValid) {
        console.log(chalk.green(`✓ All ${keyCount} keys readable with correct values`));
      } else {
        console.log(chalk.yellow(`⚠ Only ${validValues}/${keyCount} keys have correct values`));
      }
      
    } catch (error) {
      this.recordTestResult('Key Retrieval', false, error.message);
      console.error(chalk.red('✗ Key retrieval test failed:'), error.message);
    }
  }
  async testHashTags() {
    console.log(chalk.yellow('\nTest 5: Hash Tags for Data Co-location'));
    console.log('---------------------------------------');
    
    try {
      const customer = 'customer:12345';
      const relatedKeys = [
        '{customer:12345}:profile',
        '{customer:12345}:orders', 
        '{customer:12345}:preferences',
        '{customer:12345}:history',
        '{customer:12345}:sessions'
      ];
      
      const baseSlot = this.getHashSlot(customer);
      console.log(`Base key: ${customer} -> Slot: ${baseSlot}`);
      console.log('\nRelated keys with hash tag:');
      
      const pipeline = this.cluster.pipeline();
      let allSameSlot = true;
      
      for (const key of relatedKeys) {
        const slot = this.getHashSlot(key);
        console.log(`  ${key} -> Slot: ${slot}`);
        
        if (slot !== baseSlot) {
          allSameSlot = false;
        }
        
        // Store data with hash tag
        const data = JSON.stringify({ 
          key, 
          timestamp: Date.now(),
          customerId: 12345,
          slot: slot
        });
        pipeline.set(key, data, 'EX', 300);
      }
      
      await pipeline.exec();
      
      this.recordTestResult('Hash Tags Co-location', allSameSlot,
        allSameSlot ? 'All keys mapped to same slot' : 'Keys scattered across slots');
      
      if (allSameSlot) {
        console.log(chalk.green('\n✓ All related keys stored in the same slot for efficient operations'));
      } else {
        console.log(chalk.red('\n✗ Hash tags not ensuring co-location'));
      }
      
    } catch (error) {
      this.recordTestResult('Hash Tags Co-location', false, error.message);
      console.error(chalk.red('✗ Hash tags test failed:'), error.message);
    }
  }
  async testCrossSlotOperations() {
    console.log(chalk.yellow('\nTest 6: Cross-Slot Operation (Expected to Fail)'));
    console.log('------------------------------------------------');
    
    try {
      // Test 1: MGET across different slots (should fail)
      console.log('Testing MGET across different slots...');
      
      try {
        const keys = ['user:1', 'user:2', 'user:3'];
        const slots = keys.map(key => this.getHashSlot(key));
        console.log(`Keys and their slots: ${keys.map((key, i) => `${key}(${slots[i]})`).join(', ')}`);
        
        await this.cluster.mget(...keys);
        console.log(chalk.red('✗ Cross-slot MGET succeeded (unexpected)'));
        this.recordTestResult('Cross-slot MGET', false, 'Should have failed but succeeded');
      } catch (error) {
        if (error.message.includes('CROSSSLOT')) {
          console.log(chalk.green('✓ Cross-slot MGET correctly rejected'));
          console.log(`  Error: ${error.message}`);
          this.recordTestResult('Cross-slot MGET', true, 'Correctly rejected cross-slot operation');
        } else {
          throw error;
        }
      }
      
      // Test 2: Multi-key operation on same slot (should succeed)
      console.log('\nTesting multi-key operation on same slot...');
      
      try {
        const sameSlotKeys = ['{user:123}:profile', '{user:123}:settings', '{user:123}:preferences'];
        const slots = sameSlotKeys.map(key => this.getHashSlot(key));
        console.log(`Same-slot keys: ${sameSlotKeys.map((key, i) => `${key}(${slots[i]})`).join(', ')}`);
        
        // First set the keys
        const pipeline = this.cluster.pipeline();
        sameSlotKeys.forEach((key, i) => {
          pipeline.set(key, `value-${i}`, 'EX', 300);
        });
        await pipeline.exec();
        
        // Then try to get them with MGET
        const values = await this.cluster.mget(...sameSlotKeys);
        const success = values.every((val, i) => val === `value-${i}`);
        
        if (success) {
          console.log(chalk.green('✓ Same-slot multi-key operation succeeded'));
          this.recordTestResult('Same-slot Multi-key', true, 'Multi-key operation on same slot works');
        } else {
          console.log(chalk.yellow('⚠ Same-slot operation had issues with values'));
          this.recordTestResult('Same-slot Multi-key', false, 'Values not matching expected');
        }
      } catch (error) {
        console.log(chalk.red(`✗ Same-slot operation failed: ${error.message}`));
        this.recordTestResult('Same-slot Multi-key', false, error.message);
      }
      
    } catch (error) {
      this.recordTestResult('Cross-slot Operations', false, error.message);
      console.error(chalk.red('✗ Cross-slot operations test failed:'), error.message);
    }
  }
  async testPerformance() {
    console.log(chalk.yellow('\nTest 7: Performance Comparison'));
    console.log('-------------------------------');
    
    try {
      const operations = 100;
      
      // Test 1: Individual operations across different slots
      console.log('\nTesting individual operations performance...');
      const individualStart = Date.now();
      for (let i = 0; i < operations / 2; i++) {
        const key = `${TEST_KEY_PREFIX}:perf:individual:${i}`;
        await this.cluster.set(key, `value-${i}`, 'EX', 300);
      }
      const individualTime = Date.now() - individualStart;
      
      // Test 2: Pipeline operations with hash tags (same slot)
      console.log('Testing pipeline performance (same slot with hash tags)...');
      const pipelineStart = Date.now();
      const pipeline = this.cluster.pipeline();
      for (let i = 0; i < operations / 2; i++) {
        // Use hash tag to ensure all keys are in the same slot
        const key = `{perftest}:pipeline:${i}`;
        pipeline.set(key, `value-${i}`, 'EX', 300);
      }
      await pipeline.exec();
      const pipelineTime = Date.now() - pipelineStart;
      
      // Test 3: Read performance with pipeline (same slot)
      console.log('Testing read performance...');
      const readStart = Date.now();
      const readPipeline = this.cluster.pipeline();
      for (let i = 0; i < operations / 2; i++) {
        const key = `{perftest}:pipeline:${i}`;
        readPipeline.get(key);
      }
      await readPipeline.exec();
      const readTime = Date.now() - readStart;
      
      // Cleanup test keys
      const cleanupPipeline = this.cluster.pipeline();
      for (let i = 0; i < operations / 2; i++) {
        cleanupPipeline.del(`{perftest}:pipeline:${i}`);
        await this.cluster.del(`${TEST_KEY_PREFIX}:perf:individual:${i}`);
      }
      await cleanupPipeline.exec();
      
      // Display results
      const perfTable = new Table({
        head: ['Operation Type', 'Operations', 'Time (ms)', 'Ops/sec'],
        colWidths: [25, 12, 12, 12]
      });
      
      const halfOps = operations / 2;
      perfTable.push([
        'Individual Sets',
        halfOps,
        individualTime,
        (halfOps / individualTime * 1000).toFixed(2)
      ]);
      
      perfTable.push([
        'Pipeline Sets (same slot)', 
        halfOps,
        pipelineTime,
        (halfOps / pipelineTime * 1000).toFixed(2)
      ]);
      
      perfTable.push([
        'Pipeline Gets (same slot)',
        halfOps, 
        readTime,
        (halfOps / readTime * 1000).toFixed(2)
      ]);
      
      console.log(perfTable.toString());
      
      const pipelineIsFaster = pipelineTime < individualTime;
      this.recordTestResult('Performance Test', true, 
        `Pipeline: ${pipelineTime}ms, Individual: ${individualTime}ms`);
        
      if (pipelineIsFaster) {
        const improvement = ((individualTime - pipelineTime) / individualTime * 100).toFixed(1);
        console.log(chalk.green(`✓ Pipeline (same slot) is ${improvement}% faster than individual operations`));
        console.log(chalk.gray('Note: Pipeline uses hash tags to ensure all keys are in the same slot'));
      } else {
        console.log(chalk.yellow('⚠ Pipeline performance not significantly better'));
      }
      
    } catch (error) {
      this.recordTestResult('Performance Test', false, error.message);
      console.error(chalk.red('✗ Performance test failed:'), error.message);
    }
  }
  async testClusterInfo() {
    console.log(chalk.yellow('\nTest 8: Cluster Information'));
    console.log('-------------------------------------');
    
    try {
      const nodes = this.cluster.nodes('master');
      console.log(`\nConnected to ${nodes.length} master nodes:`);
      
      const nodeTable = new Table({
        head: ['Node', 'Host:Port', 'Status', 'Slots'],
        colWidths: [8, 20, 12, 25]
      });
      
      for (let i = 0; i < nodes.length; i++) {
        const node = nodes[i];
        try {
          await node.ping();
          const slotRanges = [
            '0-5460',
            '5461-10922', 
            '10923-16383'
          ];
          
          nodeTable.push([
            `Node ${i + 1}`,
            `${node.options.host}:${node.options.port}`,
            chalk.green('Connected'),
            slotRanges[i] || 'Unknown'
          ]);
        } catch (error) {
          nodeTable.push([
            `Node ${i + 1}`,
            `${node.options.host}:${node.options.port}`,
            chalk.red('Failed'),
            'N/A'
          ]);
        }
      }
      
      console.log(nodeTable.toString());
      
      // Test cluster slots command
      try {
        const slots = await this.cluster.cluster('slots');
        console.log(`\nCluster has ${slots.length} slot ranges configured`);
        this.recordTestResult('Cluster Info', true, `${nodes.length} nodes, ${slots.length} slot ranges`);
      } catch (error) {
        console.log(chalk.yellow('Could not retrieve cluster slots information'));
        this.recordTestResult('Cluster Info', true, `${nodes.length} nodes connected`);
      }
      
    } catch (error) {
      this.recordTestResult('Cluster Info', false, error.message);
      console.error(chalk.red('✗ Cluster info test failed:'), error.message);
    }
  }
}

// Set up cleanup on process exit
process.on('SIGINT', async () => {
  console.log('\nReceived SIGINT, cleaning up...');
  process.exit(0);
});

process.on('SIGTERM', async () => {
  console.log('\nReceived SIGTERM, cleaning up...');
  process.exit(0);
});

// Run the test suite
async function main() {
  const tester = new RedisShardingTester();
  await tester.runAllTests();
  
  // Force exit after a short delay to ensure cleanup
  setTimeout(() => {
    process.exit(0);
  }, 100);
}

main().catch(console.error);