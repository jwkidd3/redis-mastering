const Redis = require('ioredis');
const chalk = require('chalk');

// Cluster connection with NAT mapping
const cluster = new Redis.Cluster([
  { port: 9000, host: '127.0.0.1' },
  { port: 9001, host: '127.0.0.1' },
  { port: 9002, host: '127.0.0.1' }
], {
  enableReadyCheck: true,
  maxRetriesPerRequest: 3,
  commandTimeout: 5000,
  natMap: {
    '172.21.0.2:9001': { host: '127.0.0.1', port: 9001 },
    '172.21.0.3:9000': { host: '127.0.0.1', port: 9000 },
    '172.21.0.4:9004': { host: '127.0.0.1', port: 9004 },
    '172.21.0.5:9005': { host: '127.0.0.1', port: 9005 },
    '172.21.0.6:9003': { host: '127.0.0.1', port: 9003 },
    '172.21.0.7:9002': { host: '127.0.0.1', port: 9002 }
  }
});

async function testCrossSlotOperations() {
  console.log(chalk.blue('====================================='));
  console.log(chalk.blue('Testing Cross-Slot Operations'));
  console.log(chalk.blue('=====================================\n'));

  try {
    // Test 1: Cross-slot MGET (should fail)
    console.log(chalk.yellow('Test 1: Cross-slot MGET operations'));
    console.log('Attempting to get multiple keys from different slots...\n');

    const testKeys = ['user:1:profile', 'product:100:details', 'session:abc123'];
    
    try {
      const values = await cluster.mget(...testKeys);
      console.log(chalk.red('❌ Unexpected success: Cross-slot MGET should have failed'));
      console.log('Values:', values);
    } catch (error) {
      console.log(chalk.green('✅ Expected failure: Cross-slot MGET correctly rejected'));
      console.log(chalk.gray(`Error: ${error.message}\n`));
    }

    // Test 2: Cross-slot DEL (should fail)
    console.log(chalk.yellow('Test 2: Cross-slot DEL operations'));
    
    // First set some keys
    await cluster.set('key1', 'value1');
    await cluster.set('key2', 'value2');
    await cluster.set('key3', 'value3');
    
    try {
      const deleted = await cluster.del('key1', 'key2', 'key3');
      console.log(chalk.red('❌ Unexpected success: Cross-slot DEL should have failed'));
      console.log('Deleted count:', deleted);
    } catch (error) {
      console.log(chalk.green('✅ Expected failure: Cross-slot DEL correctly rejected'));
      console.log(chalk.gray(`Error: ${error.message}\n`));
    }

    // Test 3: Hash tags to enable multi-key operations
    console.log(chalk.yellow('Test 3: Using hash tags for same-slot operations'));
    
    const hashTagKeys = ['{user:1}:profile', '{user:1}:settings', '{user:1}:history'];
    
    // Set values with hash tags
    await cluster.set(hashTagKeys[0], 'John Doe Profile');
    await cluster.set(hashTagKeys[1], 'Dark theme, notifications on');
    await cluster.set(hashTagKeys[2], 'Login history data');
    
    try {
      const values = await cluster.mget(...hashTagKeys);
      console.log(chalk.green('✅ Success: Hash tag MGET worked correctly'));
      console.log('Retrieved values:');
      hashTagKeys.forEach((key, index) => {
        console.log(chalk.cyan(`  ${key}: ${values[index]}`));
      });
      console.log();
    } catch (error) {
      console.log(chalk.red('❌ Hash tag MGET failed unexpectedly'));
      console.log(chalk.gray(`Error: ${error.message}\n`));
    }

    // Test 4: Hash tag DEL operations
    try {
      const deleted = await cluster.del(...hashTagKeys);
      console.log(chalk.green('✅ Success: Hash tag DEL worked correctly'));
      console.log(chalk.cyan(`Deleted ${deleted} keys\n`));
    } catch (error) {
      console.log(chalk.red('❌ Hash tag DEL failed unexpectedly'));
      console.log(chalk.gray(`Error: ${error.message}\n`));
    }

    // Test 5: Pipeline with cross-slot operations
    console.log(chalk.yellow('Test 4: Pipeline with cross-slot operations'));
    
    const pipeline = cluster.pipeline();
    pipeline.set('cross1', 'value1');
    pipeline.set('cross2', 'value2');
    pipeline.set('cross3', 'value3');
    
    try {
      const results = await pipeline.exec();
      console.log(chalk.red('❌ Unexpected success: Cross-slot pipeline should have failed'));
      console.log('Results:', results);
    } catch (error) {
      console.log(chalk.green('✅ Expected failure: Cross-slot pipeline correctly rejected'));
      console.log(chalk.gray(`Error: ${error.message}\n`));
    }

    // Test 6: Pipeline with hash tags (should work)
    console.log(chalk.yellow('Test 5: Pipeline with hash tags (same slot)'));
    
    const sameSlotPipeline = cluster.pipeline();
    sameSlotPipeline.set('{order:123}:details', 'Order details');
    sameSlotPipeline.set('{order:123}:items', 'Item list');
    sameSlotPipeline.set('{order:123}:customer', 'Customer info');
    sameSlotPipeline.get('{order:123}:details');
    sameSlotPipeline.get('{order:123}:items');
    
    try {
      const results = await sameSlotPipeline.exec();
      console.log(chalk.green('✅ Success: Same-slot pipeline worked correctly'));
      console.log('Pipeline results:');
      results.forEach((result, index) => {
        const [error, value] = result;
        if (error) {
          console.log(chalk.red(`  Operation ${index + 1}: Error - ${error.message}`));
        } else {
          console.log(chalk.cyan(`  Operation ${index + 1}: ${value || 'OK'}`));
        }
      });
      console.log();
    } catch (error) {
      console.log(chalk.red('❌ Same-slot pipeline failed unexpectedly'));
      console.log(chalk.gray(`Error: ${error.message}\n`));
    }

    // Test 7: Demonstrating slot calculation
    console.log(chalk.yellow('Test 6: Slot calculation demonstration'));
    
    const keys = ['user:1', 'user:2', '{user:1}:profile', '{user:1}:settings', 'product:100'];
    
    console.log('Key slot assignments:');
    for (const key of keys) {
      try {
        // Use CLUSTER KEYSLOT to find which slot a key belongs to
        const slot = await cluster.cluster('keyslot', key);
        console.log(chalk.cyan(`  ${key.padEnd(20)} -> Slot ${slot}`));
      } catch (error) {
        console.log(chalk.red(`  ${key.padEnd(20)} -> Error: ${error.message}`));
      }
    }
    console.log();

    // Test 8: Atomic operations within a slot
    console.log(chalk.yellow('Test 7: Atomic operations within a slot'));
    
    // Using Lua script for atomic operations on same slot
    const luaScript = `
      local key1 = KEYS[1]
      local key2 = KEYS[2]
      local value1 = ARGV[1]
      local value2 = ARGV[2]
      
      redis.call('SET', key1, value1)
      redis.call('SET', key2, value2)
      
      return {redis.call('GET', key1), redis.call('GET', key2)}
    `;
    
    try {
      const result = await cluster.eval(
        luaScript,
        2,
        '{atomic:test}:key1',
        '{atomic:test}:key2',
        'atomic_value_1',
        'atomic_value_2'
      );
      
      console.log(chalk.green('✅ Success: Atomic operations with Lua script'));
      console.log(chalk.cyan(`Results: ${result[0]}, ${result[1]}\n`));
    } catch (error) {
      console.log(chalk.red('❌ Atomic operations failed'));
      console.log(chalk.gray(`Error: ${error.message}\n`));
    }

    // Cleanup
    console.log(chalk.yellow('Cleanup: Removing test keys...'));
    try {
      await cluster.del('key1', 'key2', 'key3'); // These might fail due to cross-slot
    } catch (error) {
      // Expected to fail, clean individually
      await cluster.del('key1');
      await cluster.del('key2');
      await cluster.del('key3');
    }
    
    await cluster.del('{order:123}:details', '{order:123}:items', '{order:123}:customer');
    await cluster.del('{atomic:test}:key1', '{atomic:test}:key2');
    console.log(chalk.green('✅ Cleanup completed\n'));

  } catch (error) {
    console.error(chalk.red('Test failed:'), error);
  } finally {
    await cluster.quit();
  }

  console.log(chalk.blue('====================================='));
  console.log(chalk.blue('Cross-Slot Operations Testing Complete'));
  console.log(chalk.blue('=====================================\n'));
  
  console.log(chalk.yellow('Key Takeaways:'));
  console.log('1. Cross-slot operations (MGET, DEL multiple keys) fail by design');
  console.log('2. Use hash tags {user:123} to ensure related keys are in the same slot');
  console.log('3. Pipelines must target the same slot or will fail');
  console.log('4. Lua scripts can perform atomic operations within a slot');
  console.log('5. CLUSTER KEYSLOT command shows which slot a key belongs to');
}

// Run the test
testCrossSlotOperations().catch(console.error);