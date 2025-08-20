const RedisClient = require('../src/utils/redis-client');
const chalk = require('chalk');

async function testConnection() {
    console.log(chalk.blue('🔌 Testing Redis Connection'));
    console.log(''.padEnd(40, '='));
    
    const redisClient = new RedisClient();
    
    try {
        // Test connection
        console.log(chalk.yellow('📡 Attempting to connect...'));
        const client = await redisClient.connect();
        
        // Test basic operations
        console.log(chalk.yellow('🧪 Testing basic operations...'));
        
        // Test SET/GET
        await client.set('test:connection', 'success');
        const value = await client.get('test:connection');
        
        if (value === 'success') {
            console.log(chalk.green('✅ Basic operations working'));
        } else {
            throw new Error('Basic operations failed');
        }
        
        // Test stream operations
        console.log(chalk.yellow('🌊 Testing stream operations...'));
        await client.xAdd('test:stream', '*', { test: 'value' });
        const streamLength = await client.xLen('test:stream');
        
        if (streamLength > 0) {
            console.log(chalk.green('✅ Stream operations working'));
        } else {
            throw new Error('Stream operations failed');
        }
        
        // Cleanup
        await client.del('test:connection');
        await client.del('test:stream');
        
        console.log(chalk.green('✅ Connection test successful!'));
        console.log(chalk.blue('Connection Info:'), redisClient.getConnectionInfo());
        
    } catch (error) {
        console.error(chalk.red('❌ Connection test failed:'), error.message);
        console.log(chalk.yellow('💡 Troubleshooting tips:'));
        console.log('   • Check if Redis is running');
        console.log('   • Verify REDIS_HOST and REDIS_PORT environment variables');
        console.log('   • Check network connectivity');
        console.log('   • Verify Redis password if required');
        process.exit(1);
    } finally {
        await redisClient.disconnect();
    }
}

if (require.main === module) {
    testConnection();
}

module.exports = { testConnection };
