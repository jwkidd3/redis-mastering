const redis = require('redis');
const chalk = require('chalk');

async function monitorRedis() {
    const client = redis.createClient({
        url: 'redis://localhost:6379'
    });

    await client.connect();

    console.log(chalk.blue.bold('📊 Redis Production Monitoring Dashboard\n'));

    setInterval(async () => {
        try {
            // Get server info
            const info = await client.info();
            const sections = info.split('\r\n\r\n');
            
            console.clear();
            console.log(chalk.blue.bold('📊 Redis Production Monitoring Dashboard'));
            console.log(chalk.gray('=' .repeat(50)));
            
            // Parse and display key metrics
            sections.forEach(section => {
                const lines = section.split('\r\n');
                const header = lines[0];
                
                if (header.includes('Server') || header.includes('Memory') || 
                    header.includes('Stats') || header.includes('Persistence')) {
                    console.log(chalk.yellow(`\n${header}`));
                    lines.slice(1).forEach(line => {
                        if (line && line.includes(':')) {
                            const [key, value] = line.split(':');
                            if (key && value) {
                                console.log(`  ${chalk.cyan(key)}: ${value}`);
                            }
                        }
                    });
                }
            });
            
        } catch (error) {
            console.error(chalk.red('Monitoring error:'), error);
        }
    }, 2000);
}

monitorRedis().catch(console.error);
