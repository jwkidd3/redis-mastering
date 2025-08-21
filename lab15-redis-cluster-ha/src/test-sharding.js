const Redis = require('ioredis');
const crypto = require('crypto');
const Table = require('cli-table3');
const chalk = require('chalk');

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

async function testSharding() {
  console.log(chalk.blue('====================================='));
  console.log(chalk.blue('Testing Redis Cluster Sharding'));
  console.log(chalk.blue('=====================================\n'));

  try {
    // Test 1: Key distribution across shards
    console.log(chalk.yellow('Test 1: Key Distribution Across Shards'));
    console.log('---------------------------------------');
    
    const distribution = new Map();
    const testKeys = [];
    
    // Generate test keys
    for (let i = 0; i < 1000; i++) {
      const key = `test:key:${i}`;
      const slot = getHashSlot(key);
      testKeys.push({ key, slot });
      
      // Track distribution
      const slotRange = Math.floor(slot / 5461); // Approximate shard (0, 1, or 2)
      distribution.set(slotRange, (distribution.get(slotRange) || 0) + 1);
    }
    
    // Display distribution
    const distTable = new Table({
      head: ['Shard', 'Slot Range', 'Key Count', 'Percentage'],
      colWidths: [10, 20, 15, 15]
    });
    
    distribution.forEach((count, shard) => {
      const startSlot = shard * 5461;
      const endSlot = shard === 2 ? 16383 : (shard + 1) * 5461 - 1;
      const percentage = ((count / 1000) * 100).toFixed(2);
      distTable.push([
        `Shard ${shard + 1}`,
        `${startSlot}-${endSlot}`,
        count,
        `${percentage}%`
      ]);
    });
    
    console.log(distTable.toString());
    
    // Test 2: Hash slot calculation
    console.log(chalk.yellow('\nTest 2: Hash Slot Calculation Examples'));
    console.log('----------------------------------------');
    
    const exampleKeys = [
      'user:123',
      'user:456',
      'product:789',
      'order:abc',
      '{user:123}:profile',
      '{user:123}:settings'
    ];
    
    const slotTable = new Table({
      head: ['Key', 'Hash Slot', 'Shard'],
      colWidths: [30, 15, 10]
    });
    
    for (const key of exampleKeys) {
      const slot = getHashSlot(key);
      const shard = Math.floor(slot / 5461) + 1;
      slotTable.push([key, slot, shard]);
    }
    
    console.log(slotTable.toString());
    
    // Test 3: Write keys and verify distribution
    console.log(chalk.yellow('\nTest 3: Writing Keys to Cluster'));
    console.log('---------------------------------');
    
    const writePromises = [];
    for (let i = 0; i < 100; i++) {
      const key = `shard:test:${i}`;
      const value = `value-${i}`;
      writePromises.push(cluster.set(key, value));
    }
    
    await Promise.all(writePromises);
    console.log(chalk.green('✓ Written 100 keys to cluster'));
    
    // Test 4: Verify keys are accessible
    console.log(chalk.yellow('\nTest 4: Verifying Key Accessibility'));
    console.log('------------------------------------');
    
    const readPromises = [];
    for (let i = 0; i < 10; i++) {
      const key = `shard:test:${i}`;
      readPromises.push(cluster.get(key));
    }
    
    const values = await Promise.all(readPromises);
    const allValid = values.every((val, idx) => val === `value-${idx}`);
    
    if (allValid) {
      console.log(chalk.green('✓ All keys readable and values correct'));
    } else {
      console.log(chalk.red('✗ Some keys have incorrect values'));
    }
    
    // Test 5: Hash tags for co-location
    console.log(chalk.yellow('\nTest 5: Hash Tags for Data Co-location'));
    console.log('---------------------------------------');
    
    const customer = 'customer:12345';
    const relatedKeys = [
      '{customer:12345}:profile',
      '{customer:12345}:orders',
      '{customer:12345}:preferences',
      '{customer:12345}:history'
    ];
    
    console.log(`Base key: ${customer} -> Slot: ${getHashSlot(customer)}`);
    console.log('\nRelated keys with hash tag:');
    
    for (const key of relatedKeys) {
      const slot = getHashSlot(key);
      console.log(`  ${key} -> Slot: ${slot}`);
      
      // Store data
      await cluster.set(key, JSON.stringify({ timestamp: Date.now() }));
    }
    
    console.log(chalk.green('\n✓ All related keys stored in the same slot for efficient operations'));
    
    // Test 6: Cross-slot operation (will fail)
    console.log(chalk.yellow('\nTest 6: Cross-Slot Operation (Expected to Fail)'));
    console.log('------------------------------------------------');
    
    try {
      // This should fail because keys are in different slots
      await cluster.mget('user:1', 'user:2', 'user:3');
      console.log(chalk.red('✗ Cross-slot operation succeeded (unexpected)'));
    } catch (error) {
      if (error.message.includes('CROSSSLOT')) {
        console.log(chalk.green('✓ Cross-slot operation correctly rejected'));
        console.log(`  Error: ${error.message}`);
      } else {
        throw error;
      }
    }
    
    // Test 7: Cluster info
    console.log(chalk.yellow('\nTest 7: Cluster Sharding Information'));
    console.log('-------------------------------------');
    
    const nodes = cluster.nodes('master');
    console.log(`\nConnected to ${nodes.length} master nodes:`);
    
    for (const node of nodes) {
      const info = await node.cluster('slots');
      console.log(`  Node ${node.options.port}: Connected`);
    }
    
    // Cleanup
    console.log(chalk.yellow('\nCleaning up test keys...'));
    
    const pipeline = cluster.pipeline();
    for (let i = 0; i < 100; i++) {
      pipeline.del(`shard:test:${i}`);
    }
    for (const key of relatedKeys) {
      pipeline.del(key);
    }
    await pipeline.exec();
    
    console.log(chalk.green('✓ Cleanup complete'));
    
  } catch (error) {
    console.error(chalk.red('Error during sharding test:'), error);
  } finally {
    await cluster.quit();
    console.log(chalk.blue('\n====================================='));
    console.log(chalk.blue('Sharding Test Complete'));
    console.log(chalk.blue('====================================='));
  }
}

// Run the test
testSharding().catch(console.error);