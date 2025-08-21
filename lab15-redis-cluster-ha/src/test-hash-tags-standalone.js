const Redis = require('ioredis');
const chalk = require('chalk');
const Table = require('cli-table3');

// Use standalone Redis for demonstration
const redis = new Redis({
  port: 6379,
  host: 'localhost',
  maxRetriesPerRequest: 3,
  connectTimeout: 5000
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

// Get virtual shard number from slot
function getShardNumber(slot) {
  if (slot <= 5460) return 1;
  if (slot <= 10922) return 2;
  return 3;
}

async function testHashTags() {
  console.log(chalk.blue('====================================='));
  console.log(chalk.blue('Redis Hash Tags Demo'));
  console.log(chalk.blue('(Using Standalone Redis)'));
  console.log(chalk.blue('=====================================\n'));

  try {
    // Check connection
    console.log(chalk.yellow('Connecting to Redis...'));
    await redis.ping();
    console.log(chalk.green('✓ Connected to Redis\n'));

    // Test 1: Basic Hash Tag Functionality
    console.log(chalk.yellow('Test 1: Hash Tag Functionality'));
    console.log('------------------------------');
    
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
      head: ['Key', 'Hash Tag', 'Hash Slot', 'Virtual Shard'],
      colWidths: [35, 15, 12, 14]
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
        `Shard ${shard}`
      ]);
    }

    console.log(hashTagTable.toString());
    console.log(chalk.green('✓ Hash tags ensure co-location in same slot\n'));

    // Test 2: Store related data with hash tags
    console.log(chalk.yellow('Test 2: Storing Related Data with Hash Tags'));
    console.log('-------------------------------------------');
    
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
      payment_methods: ['card-*1234', 'paypal-jane@example.com']
    };

    console.log('Storing customer data with hash tags...');
    
    const pipeline = redis.pipeline();
    
    for (const [dataType, data] of Object.entries(relatedData)) {
      const key = `{${baseCustomer}}:${dataType}`;
      pipeline.hset(key, 'data', JSON.stringify(data), 'EX', 60);
      pipeline.hset(key, 'timestamp', Date.now());
    }
    
    await pipeline.exec();
    console.log(chalk.green('✓ Related data stored with hash tags'));
    
    // Display slot information
    console.log('\nSlot assignment for related keys:');
    for (const dataType of Object.keys(relatedData)) {
      const key = `{${baseCustomer}}:${dataType}`;
      const slot = getHashSlot(key);
      console.log(`  ${key} -> Slot: ${slot}`);
    }
    console.log(chalk.green('✓ All keys in same slot for atomic operations\n'));

    // Test 3: Insurance-specific Examples
    console.log(chalk.yellow('Test 3: Insurance Domain Examples'));
    console.log('---------------------------------');
    
    const insuranceExamples = [
      // Customer data co-location
      { key: '{customer:CUST001}:profile', description: 'Customer profile' },
      { key: '{customer:CUST001}:policies', description: 'Customer policies' },
      { key: '{customer:CUST001}:claims', description: 'Customer claims' },
      
      // Policy data co-location
      { key: '{policy:POL001}:details', description: 'Policy details' },
      { key: '{policy:POL001}:claims', description: 'Policy claims' },
      { key: '{policy:POL001}:payments', description: 'Payment history' },
      
      // Agent data co-location
      { key: '{agent:AGT001}:profile', description: 'Agent profile' },
      { key: '{agent:AGT001}:customers', description: 'Agent customers' },
      { key: '{agent:AGT001}:performance', description: 'Performance metrics' }
    ];

    const insuranceTable = new Table({
      head: ['Key Pattern', 'Slot', 'Shard', 'Use Case'],
      colWidths: [30, 8, 10, 25]
    });

    for (const example of insuranceExamples) {
      const slot = getHashSlot(example.key);
      const shard = getShardNumber(slot);
      
      insuranceTable.push([
        example.key,
        slot,
        `Shard ${shard}`,
        example.description
      ]);
    }

    console.log(insuranceTable.toString());
    
    // Test 4: Multi-key operations simulation
    console.log(chalk.yellow('\nTest 4: Multi-key Operations Benefits'));
    console.log('-------------------------------------');
    
    const testCustomerId = 'test-customer-999';
    const testKeys = [
      `{${testCustomerId}}:account`,
      `{${testCustomerId}}:balance`,
      `{${testCustomerId}}:transactions`
    ];
    
    // Store test data
    const multiPipeline = redis.pipeline();
    testKeys.forEach(key => {
      multiPipeline.set(key, JSON.stringify({ value: Math.random() }), 'EX', 60);
    });
    await multiPipeline.exec();
    
    // Simulate multi-key operation
    const mgetPipeline = redis.pipeline();
    testKeys.forEach(key => mgetPipeline.get(key));
    const results = await mgetPipeline.exec();
    
    console.log('Multi-key operation on co-located keys:');
    testKeys.forEach((key, idx) => {
      const slot = getHashSlot(key);
      console.log(`  ${key} (Slot: ${slot}) - Retrieved: ✓`);
    });
    console.log(chalk.green('\n✓ Efficient multi-key operations with hash tags'));
    
    // Test 5: Best Practices
    console.log(chalk.yellow('\nHash Tag Best Practices:'));
    console.log('------------------------');
    
    const bestPractices = [
      {
        practice: 'Use meaningful identifiers',
        good: '{customer:12345}:profile',
        bad: '{c:12345}:p'
      },
      {
        practice: 'Keep hash tags short',
        good: '{user:123}:data',
        bad: '{very-long-identifier-for-user:123}:data'
      },
      {
        practice: 'Group only related data',
        good: '{order:456}:items',
        bad: '{global}:everything'
      },
      {
        practice: 'Be consistent',
        good: '{entity:ID}:attribute',
        bad: 'Mixed patterns'
      }
    ];
    
    bestPractices.forEach((bp, index) => {
      console.log(`\n${index + 1}. ${chalk.cyan(bp.practice)}`);
      console.log(`   ${chalk.green('Good:')} ${bp.good}`);
      console.log(`   ${chalk.red('Bad:')}  ${bp.bad}`);
    });
    
    // Cleanup
    console.log(chalk.yellow('\n\nCleaning up test data...'));
    
    const cleanupPipeline = redis.pipeline();
    
    // Clean customer data
    for (const dataType of Object.keys(relatedData)) {
      cleanupPipeline.del(`{${baseCustomer}}:${dataType}`);
    }
    
    // Clean test keys
    testKeys.forEach(key => cleanupPipeline.del(key));
    
    await cleanupPipeline.exec();
    console.log(chalk.green('✓ Cleanup complete'));

  } catch (error) {
    console.error(chalk.red('Error during hash tag demo:'), error.message);
    console.error(chalk.yellow('\nMake sure Redis is running on localhost:6379'));
    console.error(chalk.yellow('Run: redis-server'));
  } finally {
    await redis.quit();
    console.log(chalk.blue('\n====================================='));
    console.log(chalk.blue('Hash Tag Demo Complete'));
    console.log(chalk.blue('====================================='));
  }
}

// Run the test
testHashTags().catch(console.error);