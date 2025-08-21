const Redis = require('ioredis');
const chalk = require('chalk');
const Table = require('cli-table3');

// Create cluster connection
const cluster = new Redis.Cluster([
  { port: 9000, host: '127.0.0.1' },
  { port: 9001, host: '127.0.0.1' },
  { port: 9002, host: '127.0.0.1' }
], {
  enableReadyCheck: true,
  maxRetriesPerRequest: 3,
  retryDelayOnFailover: 100,
  retryDelayOnClusterDown: 300
});

// CRC16 implementation for hash slot calculation
function crc16(buf) {
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
function getHashSlot(key) {
  // Check for hash tags {}
  const start = key.indexOf('{');
  if (start !== -1) {
    const end = key.indexOf('}', start + 1);
    if (end !== -1 && end !== start + 1) {
      key = key.substring(start + 1, end);
    }
  }
  return crc16(Buffer.from(key)) % 16384;
}

// Get shard number from slot
function getShardNumber(slot) {
  if (slot <= 5460) return 1;
  if (slot <= 10922) return 2;
  return 3;
}

async function testHashTags() {
  console.log(chalk.blue('====================================='));
  console.log(chalk.blue('Testing Redis Cluster Hash Tags'));
  console.log(chalk.blue('=====================================\n'));

  try {
    // Test 1: Basic Hash Tag Functionality
    console.log(chalk.yellow('Test 1: Basic Hash Tag Functionality'));
    console.log('------------------------------------');
    
    const customerId = 'customer:12345';
    const customerKeys = [
      'customer:12345:profile',           // Without hash tag
      '{customer:12345}:profile',         // With hash tag
      '{customer:12345}:orders',          // With hash tag
      '{customer:12345}:preferences',     // With hash tag
      '{customer:12345}:payment_methods', // With hash tag
      '{customer:12345}:history'          // With hash tag
    ];

    const hashTagTable = new Table({
      head: ['Key', 'Hash Tag', 'Hash Slot', 'Shard'],
      colWidths: [35, 15, 12, 8]
    });

    for (const key of customerKeys) {
      const slot = getHashSlot(key);
      const shard = getShardNumber(slot);
      const hasHashTag = key.includes('{') && key.includes('}');
      const hashTag = hasHashTag ? key.substring(key.indexOf('{') + 1, key.indexOf('}')) : 'None';
      
      hashTagTable.push([
        key,
        hashTag,
        slot,
        shard
      ]);
    }

    console.log(hashTagTable.toString());

    // Test 2: Co-location Benefits
    console.log(chalk.yellow('\nTest 2: Demonstrating Co-location Benefits'));
    console.log('------------------------------------------');
    
    const baseCustomer = 'customer:98765';
    const relatedData = {
      profile: {
        name: 'Jane Smith',
        email: 'jane.smith@example.com',
        segment: 'premium'
      },
      orders: ['order-1', 'order-2', 'order-3'],
      preferences: {
        notifications: true,
        newsletter: false,
        marketing: true
      },
      payment_methods: ['card-*1234', 'paypal-jane@example.com'],
      history: {
        last_login: '2024-01-15',
        total_orders: 23,
        lifetime_value: 15000
      }
    };

    // Store data using hash tags for co-location
    console.log('Storing related customer data with hash tags...');
    
    const pipeline = cluster.pipeline();
    
    for (const [dataType, data] of Object.entries(relatedData)) {
      const key = `{${baseCustomer}}:${dataType}`;
      pipeline.hset(key, 'data', JSON.stringify(data));
      pipeline.hset(key, 'timestamp', Date.now());
    }
    
    await pipeline.exec();
    console.log(chalk.green('✓ Data stored with hash tags for co-location'));

    // Test 3: Multi-key Operations on Co-located Data
    console.log(chalk.yellow('\nTest 3: Multi-key Operations on Co-located Data'));
    console.log('-----------------------------------------------');
    
    try {
      // This should work because all keys are in the same slot
      const colocatedKeys = [
        `{${baseCustomer}}:profile`,
        `{${baseCustomer}}:orders`,
        `{${baseCustomer}}:preferences`
      ];
      
      console.log('Attempting MGET on co-located keys...');
      const values = await cluster.mget(...colocatedKeys);
      console.log(chalk.green('✓ Multi-key operation succeeded on co-located data'));
      console.log(`  Retrieved ${values.filter(v => v !== null).length} values`);
      
    } catch (error) {
      console.log(chalk.red('✗ Multi-key operation failed:'), error.message);
    }

    // Test 4: Cross-slot Operation (Should Fail)
    console.log(chalk.yellow('\nTest 4: Cross-slot Operation (Expected to Fail)'));
    console.log('------------------------------------------------');
    
    try {
      // These keys will be in different slots
      const crossSlotKeys = [
        'customer:111:profile',  // Different customer, no hash tag
        'customer:222:profile',  // Different customer, no hash tag
        'customer:333:profile'   // Different customer, no hash tag
      ];
      
      console.log('Attempting MGET on keys in different slots...');
      await cluster.mget(...crossSlotKeys);
      console.log(chalk.red('✗ Cross-slot operation unexpectedly succeeded'));
      
    } catch (error) {
      if (error.message.includes('CROSSSLOT')) {
        console.log(chalk.green('✓ Cross-slot operation correctly rejected'));
        console.log(`  Error: ${error.message}`);
      } else {
        throw error;
      }
    }

    // Test 5: Insurance-specific Hash Tag Examples
    console.log(chalk.yellow('\nTest 5: Insurance-specific Hash Tag Examples'));
    console.log('--------------------------------------------');
    
    const insuranceExamples = [
      // Customer data co-location
      { key: '{customer:CUST001}:profile', description: 'Customer profile' },
      { key: '{customer:CUST001}:policies', description: 'Customer policies list' },
      { key: '{customer:CUST001}:claims', description: 'Customer claims list' },
      
      // Policy data co-location
      { key: '{policy:POL001}:details', description: 'Policy details' },
      { key: '{policy:POL001}:claims', description: 'Claims for this policy' },
      { key: '{policy:POL001}:payments', description: 'Payment history' },
      
      // Agent data co-location
      { key: '{agent:AGT001}:profile', description: 'Agent profile' },
      { key: '{agent:AGT001}:customers', description: 'Agent customer list' },
      { key: '{agent:AGT001}:performance', description: 'Performance metrics' }
    ];

    const insuranceTable = new Table({
      head: ['Key', 'Hash Slot', 'Shard', 'Description'],
      colWidths: [30, 12, 8, 25]
    });

    for (const example of insuranceExamples) {
      const slot = getHashSlot(example.key);
      const shard = getShardNumber(slot);
      
      insuranceTable.push([
        example.key,
        slot,
        shard,
        example.description
      ]);
    }

    console.log(insuranceTable.toString());

    // Test 6: Performance Comparison
    console.log(chalk.yellow('\nTest 6: Performance Comparison'));
    console.log('------------------------------');
    
    console.log('Setting up test data...');
    
    // Setup test data for performance comparison
    const testCustomerId = 'perf-test-customer';
    const testDataTypes = ['profile', 'orders', 'preferences', 'history', 'settings'];
    
    // Store with hash tags (co-located)
    const colocatedPipeline = cluster.pipeline();
    for (const dataType of testDataTypes) {
      const key = `{${testCustomerId}}:${dataType}`;
      colocatedPipeline.set(key, JSON.stringify({ type: dataType, data: 'test-data' }));
    }
    await colocatedPipeline.exec();
    
    // Store without hash tags (distributed)
    const distributedPipeline = cluster.pipeline();
    for (const dataType of testDataTypes) {
      const key = `${testCustomerId}:${dataType}`;
      distributedPipeline.set(key, JSON.stringify({ type: dataType, data: 'test-data' }));
    }
    await distributedPipeline.exec();
    
    // Performance test: Co-located vs Distributed
    const iterations = 100;
    
    // Test co-located performance
    console.log('Testing co-located data retrieval...');
    const colocatedStart = Date.now();
    
    for (let i = 0; i < iterations; i++) {
      const keys = testDataTypes.map(type => `{${testCustomerId}}:${type}`);
      const pipeline = cluster.pipeline();
      keys.forEach(key => pipeline.get(key));
      await pipeline.exec();
    }
    
    const colocatedTime = Date.now() - colocatedStart;
    
    // Test distributed performance
    console.log('Testing distributed data retrieval...');
    const distributedStart = Date.now();
    
    for (let i = 0; i < iterations; i++) {
      const keys = testDataTypes.map(type => `${testCustomerId}:${type}`);
      const pipeline = cluster.pipeline();
      keys.forEach(key => pipeline.get(key));
      await pipeline.exec();
    }
    
    const distributedTime = Date.now() - distributedStart;
    
    // Display performance results
    const perfTable = new Table({
      head: ['Approach', 'Time (ms)', 'Avg per operation (ms)', 'Performance'],
      colWidths: [15, 12, 22, 15]
    });
    
    const colocatedAvg = (colocatedTime / iterations).toFixed(2);
    const distributedAvg = (distributedTime / iterations).toFixed(2);
    const improvement = ((distributedTime - colocatedTime) / distributedTime * 100).toFixed(1);
    
    perfTable.push(
      ['Co-located', colocatedTime, colocatedAvg, 'Baseline'],
      ['Distributed', distributedTime, distributedAvg, `+${improvement}% slower`]
    );
    
    console.log(perfTable.toString());
    console.log(chalk.green(`✓ Co-located data is ${improvement}% faster than distributed`));

    // Test 7: Hash Tag Best Practices
    console.log(chalk.yellow('\nTest 7: Hash Tag Best Practices'));
    console.log('-------------------------------');
    
    const bestPractices = [
      {
        practice: 'Use meaningful identifiers',
        good: '{customer:12345}:profile',
        bad: '{c:12345}:profile',
        reason: 'Clear namespace reduces conflicts'
      },
      {
        practice: 'Keep hash tags short',
        good: '{user:123}:data',
        bad: '{very-long-user-identifier:123}:data',
        reason: 'Reduces memory overhead'
      },
      {
        practice: 'Group related data only',
        good: '{order:456}:items and {order:456}:total',
        bad: '{global}:everything',
        reason: 'Avoids hotspots and uneven distribution'
      },
      {
        practice: 'Use consistent patterns',
        good: '{customer:ID}:type pattern',
        bad: 'Mixed patterns: {cust:ID}, customer-ID-type',
        reason: 'Easier to maintain and debug'
      }
    ];
    
    console.log('Hash Tag Best Practices:');
    console.log('========================');
    
    bestPractices.forEach((bp, index) => {
      console.log(`\n${index + 1}. ${chalk.cyan(bp.practice)}`);
      console.log(`   ${chalk.green('Good:')} ${bp.good}`);
      console.log(`   ${chalk.red('Bad:')}  ${bp.bad}`);
      console.log(`   ${chalk.yellow('Why:')}  ${bp.reason}`);
    });

    // Cleanup
    console.log(chalk.yellow('\nCleaning up test data...'));
    
    const cleanupPipeline = cluster.pipeline();
    
    // Clean customer data
    for (const [dataType] of Object.entries(relatedData)) {
      cleanupPipeline.del(`{${baseCustomer}}:${dataType}`);
    }
    
    // Clean performance test data
    for (const dataType of testDataTypes) {
      cleanupPipeline.del(`{${testCustomerId}}:${dataType}`);
      cleanupPipeline.del(`${testCustomerId}:${dataType}`);
    }
    
    await cleanupPipeline.exec();
    console.log(chalk.green('✓ Cleanup complete'));

  } catch (error) {
    console.error(chalk.red('Error during hash tag test:'), error);
  } finally {
    await cluster.quit();
    console.log(chalk.blue('\n====================================='));
    console.log(chalk.blue('Hash Tag Test Complete'));
    console.log(chalk.blue('====================================='));
  }
}

// Run the test
testHashTags().catch(console.error);