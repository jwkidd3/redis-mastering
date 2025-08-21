const Redis = require('ioredis');

async function simpleTest() {
  console.log('Testing Redis cluster connection...');
  
  const cluster = new Redis.Cluster([
    { port: 9000, host: '127.0.0.1' },
    { port: 9001, host: '127.0.0.1' },
    { port: 9002, host: '127.0.0.1' }
  ], {
    enableReadyCheck: true,
    maxRetriesPerRequest: 3,
    connectTimeout: 5000,
    natMap: {
      '172.21.0.5:9000': { host: '127.0.0.1', port: 9000 },
      '172.21.0.6:9001': { host: '127.0.0.1', port: 9001 },
      '172.21.0.7:9002': { host: '127.0.0.1', port: 9002 },
      '172.21.0.3:9003': { host: '127.0.0.1', port: 9003 },
      '172.21.0.2:9004': { host: '127.0.0.1', port: 9004 },
      '172.21.0.4:9005': { host: '127.0.0.1', port: 9005 }
    }
  });

  try {
    await cluster.ping();
    console.log('✓ Connected to cluster');

    // Simple SET operation
    await cluster.set('test:simple', 'hello');
    console.log('✓ SET operation successful');

    // Simple GET operation  
    const value = await cluster.get('test:simple');
    console.log(`✓ GET operation successful: ${value}`);

    // Clean up
    await cluster.del('test:simple');
    console.log('✓ Cleanup successful');

  } catch (error) {
    console.error('✗ Error:', error.message);
  } finally {
    await cluster.quit();
    console.log('Connection closed');
  }
}

simpleTest().catch(console.error);