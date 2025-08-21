const Redis = require('ioredis');

async function debugConnection() {
  console.log('Creating cluster connection...');
  
  const cluster = new Redis.Cluster([
    { port: 9000, host: '127.0.0.1' },
    { port: 9001, host: '127.0.0.1' },
    { port: 9002, host: '127.0.0.1' }
  ], {
    enableReadyCheck: false,
    lazyConnect: false,
    connectTimeout: 5000,
    redisOptions: {
      connectTimeout: 5000,
      commandTimeout: 5000
    }
  });

  cluster.on('connect', () => console.log('Connected'));
  cluster.on('ready', () => console.log('Ready'));
  cluster.on('error', (err) => console.log('Error:', err.message));
  cluster.on('close', () => console.log('Closed'));

  try {
    console.log('Testing ping...');
    const result = await cluster.ping();
    console.log('Ping result:', result);
    
    console.log('Testing simple set...');
    await cluster.set('test', 'value');
    console.log('Set successful');
    
    console.log('Testing simple get...');
    const value = await cluster.get('test');
    console.log('Get result:', value);
    
  } catch (error) {
    console.error('Operation failed:', error.message);
  } finally {
    await cluster.quit();
    console.log('Disconnected');
  }
}

debugConnection().catch(console.error);
