const client = require('./redis-client');
const chalk = require('chalk');

async function testConnection() {
    console.log(chalk.cyan('\n🔌 Testing Redis connection...\n'));
    
    try {
        await client.connect();
        
        // Test basic operations
        const pingResult = await client.ping();
        console.log(chalk.green('✅ PING:', pingResult));
        
        // Test write
        await client.set('test:key', 'test value');
        console.log(chalk.green('✅ SET: test:key'));
        
        // Test read
        const value = await client.get('test:key');
        console.log(chalk.green('✅ GET:', value));
        
        // Test delete
        await client.del('test:key');
        console.log(chalk.green('✅ DEL: test:key'));
        
        // Get server info
        const info = await client.info('server');
        const version = info.match(/redis_version:([^\r\n]+)/)[1];
        console.log(chalk.green(`\n✅ Connected to Redis ${version}`));
        
        console.log(chalk.green('\n🎉 All tests passed! Redis is ready.\n'));
        
    } catch (error) {
        console.error(chalk.red('❌ Connection failed:', error.message));
        console.log(chalk.yellow('\nTroubleshooting:'));
        console.log('1. Ensure Redis is running: docker ps | grep redis');
        console.log('2. Check Redis port: redis-cli ping');
        console.log('3. Verify environment variables in .env file');
    } finally {
        await client.quit();
    }
}

// Run if executed directly
if (require.main === module) {
    testConnection();
}

module.exports = { testConnection };
