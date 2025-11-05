// health-check.js - Redis health check utility
const redis = require('redis');

class HealthCheck {
    constructor() {
        this.client = null;
    }

    async connect() {
        this.client = redis.createClient({
            socket: {
                host: process.env.REDIS_HOST || 'localhost',
                port: process.env.REDIS_PORT || 6379
            }
        });
        await this.client.connect();
    }

    async disconnect() {
        if (this.client) {
            await this.client.quit();
        }
    }

    async checkHealth() {
        try {
            // Ping test
            const start = Date.now();
            const pingResult = await this.client.ping();
            const latency = Date.now() - start;

            if (pingResult !== 'PONG') {
                return {
                    status: 'unhealthy',
                    message: 'PING failed',
                    checks: {
                        ping: false
                    }
                };
            }

            // Get server info
            const info = await this.client.info();
            const memory = await this.client.info('memory');
            const stats = await this.client.info('stats');

            // Parse memory usage
            const usedMemory = this.parseInfoField(memory, 'used_memory_human');
            const maxMemory = this.parseInfoField(memory, 'maxmemory_human');

            // Parse stats
            const connectedClients = this.parseInfoField(info, 'connected_clients');
            const totalOps = this.parseInfoField(stats, 'total_commands_processed');

            return {
                status: 'healthy',
                latency: `${latency}ms`,
                checks: {
                    ping: true,
                    connection: true
                },
                metrics: {
                    connected_clients: connectedClients,
                    used_memory: usedMemory,
                    max_memory: maxMemory,
                    total_commands: totalOps
                }
            };

        } catch (error) {
            return {
                status: 'unhealthy',
                message: error.message,
                checks: {
                    connection: false
                }
            };
        }
    }

    parseInfoField(info, field) {
        const lines = info.split('\r\n');
        for (const line of lines) {
            if (line.startsWith(field + ':')) {
                return line.split(':')[1];
            }
        }
        return 'N/A';
    }
}

async function runHealthCheck() {
    const healthCheck = new HealthCheck();

    try {
        await healthCheck.connect();
        const result = await healthCheck.checkHealth();

        console.log('=== Redis Health Check ===');
        console.log(`Status: ${result.status}`);
        console.log(`Latency: ${result.latency || 'N/A'}`);

        if (result.metrics) {
            console.log('\nMetrics:');
            console.log(`  Connected Clients: ${result.metrics.connected_clients}`);
            console.log(`  Memory Usage: ${result.metrics.used_memory}`);
            console.log(`  Max Memory: ${result.metrics.max_memory}`);
            console.log(`  Total Commands: ${result.metrics.total_commands}`);
        }

        if (result.status === 'unhealthy') {
            console.error(`\nError: ${result.message}`);
            process.exit(1);
        }

    } finally {
        await healthCheck.disconnect();
    }
}

if (require.main === module) {
    runHealthCheck();
}

module.exports = HealthCheck;
