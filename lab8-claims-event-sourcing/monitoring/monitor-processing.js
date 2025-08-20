const RedisClient = require('../src/utils/redis-client');
const chalk = require('chalk');

class ProcessingMonitor {
    constructor() {
        this.redisClient = new RedisClient();
        this.monitoring = false;
    }

    async start() {
        console.log(chalk.blue('📊 Claims Processing Monitor'));
        console.log(''.padEnd(40, '='));
        
        const client = await this.redisClient.connect();
        this.monitoring = true;
        
        // Monitor every 2 seconds
        const interval = setInterval(async () => {
            if (!this.monitoring) {
                clearInterval(interval);
                return;
            }
            
            try {
                await this.displayMetrics(client);
            } catch (error) {
                console.error(chalk.red('Monitoring error:'), error.message);
            }
        }, 2000);
        
        // Handle graceful shutdown
        process.on('SIGINT', async () => {
            console.log(chalk.yellow('\n🛑 Shutting down monitor...'));
            this.monitoring = false;
            clearInterval(interval);
            await this.redisClient.disconnect();
            process.exit(0);
        });
    }

    async displayMetrics(client) {
        console.clear();
        console.log(chalk.blue('📊 Claims Processing Monitor - Real-time'));
        console.log(''.padEnd(50, '='));
        console.log(chalk.gray(`Updated: ${new Date().toLocaleTimeString()}`));
        console.log('');
        
        try {
            // Stream metrics
            const streamLength = await client.xLen('claims:events').catch(() => 0);
            console.log(chalk.blue('📈 Stream Metrics:'));
            console.log(`   Events in stream: ${chalk.yellow(streamLength)}`);
            
            // Consumer group info
            try {
                const groups = await client.xInfo('GROUPS', 'claims:events');
                console.log(chalk.blue('\n👥 Consumer Groups:'));
                
                for (const group of groups) {
                    const pending = group.pending || 0;
                    const consumers = group.consumers || 0;
                    console.log(`   ${chalk.yellow(group.name)}: ${consumers} consumers, ${pending} pending`);
                }
            } catch (error) {
                console.log(chalk.gray('   No consumer groups found'));
            }
            
            // Analytics metrics
            const today = new Date().toISOString().split('T')[0];
            const dailyCount = await client.hGet(`analytics:daily:${today}`, 'total_claims').catch(() => 0);
            
            console.log(chalk.blue('\n📊 Analytics:'));
            console.log(`   Claims processed today: ${chalk.yellow(dailyCount || 0)}`);
            
            // Recent events
            try {
                const recentEvents = await client.xRevRange('claims:events', '+', '-', { COUNT: 5 });
                console.log(chalk.blue('\n🕐 Recent Events:'));
                
                recentEvents.forEach(event => {
                    const eventData = event.message;
                    const timestamp = new Date(parseInt(event.id.split('-')[0])).toLocaleTimeString();
                    console.log(`   ${chalk.gray(timestamp)} - ${chalk.yellow(eventData.type || 'unknown')}`);
                });
            } catch (error) {
                console.log(chalk.gray('   No recent events'));
            }
            
        } catch (error) {
            console.log(chalk.red('Error fetching metrics:'), error.message);
        }
        
        console.log(chalk.gray('\nPress Ctrl+C to stop monitoring'));
    }
}

if (require.main === module) {
    const monitor = new ProcessingMonitor();
    monitor.start().catch(console.error);
}

module.exports = ProcessingMonitor;
