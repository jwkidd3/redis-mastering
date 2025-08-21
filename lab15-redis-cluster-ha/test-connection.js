const Redis = require('ioredis');

async function testConnection() {
  console.log('Testing Redis cluster connection and sharding...\n');
  
  // Use same simple config that works
  const cluster = new Redis.Cluster([
    { port: 9000, host: '127.0.0.1' },
    { port: 9001, host: '127.0.0.1' },
    { port: 9002, host: '127.0.0.1' }
  ], {
    enableReadyCheck: false,
    lazyConnect: false,
    redisOptions: {
      commandTimeout: 3000
    }
  });

  try {
    console.log('✓ Cluster created');
    
    // Test basic operations
    await cluster.set('test:connection', 'working');
    console.log('✓ SET operation successful');
    
    const value = await cluster.get('test:connection');
    console.log(`✓ GET operation successful: ${value}`);
    
    // Test sharding - write keys to different slots
    console.log('\n--- Testing Key Distribution ---');
    const keys = ['user:1', 'user:2', 'user:3', 'product:1', 'order:1'];
    
    for (const key of keys) {
      await cluster.set(key, `value-${key}`, 'EX', 60);
      console.log(`✓ Set ${key}`);
    }
    
    // Verify reads
    console.log('\n--- Verifying Reads ---');
    for (const key of keys) {
      const val = await cluster.get(key);
      console.log(`✓ ${key} = ${val}`);
    }
    
    // Test hash tags
    console.log('\n--- Testing Hash Tags ---');
    const hashTagKeys = ['{user:123}:profile', '{user:123}:settings'];
    for (const key of hashTagKeys) {
      await cluster.set(key, 'hash-tag-value');
      console.log(`✓ Set ${key} (same slot)`);
    }
    
    // Cleanup
    await cluster.del('test:connection', ...keys, ...hashTagKeys);
    console.log('\n✓ Cleanup complete');
    
  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    await cluster.quit();
    console.log('✓ Connection closed');
  }
}

testConnection().catch(console.error);
