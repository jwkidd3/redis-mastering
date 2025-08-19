const { execSync } = require('child_process');

class DockerRedisSetup {
    constructor() {
        this.containerName = 'lab10-redis';
        this.redisPort = 6379;
        this.redisPassword = 'lab10-password';
    }

    // Start Redis container for local testing
    async startRedisContainer() {
        console.log('🐳 Starting Redis container for local testing...');
        
        try {
            // Stop existing container if running
            this.stopRedisContainer();
            
            // Start new Redis container
            const command = `docker run -d --name ${this.containerName} \\
                -p ${this.redisPort}:6379 \\
                -e REDIS_PASSWORD=${this.redisPassword} \\
                redis:7-alpine redis-server --requirepass ${this.redisPassword}`;
            
            execSync(command);
            console.log(`✅ Redis container started on port ${this.redisPort}`);
            
            // Wait for Redis to be ready
            await this.waitForRedis();
            
            return {
                host: 'localhost',
                port: this.redisPort,
                password: this.redisPassword
            };
        } catch (error) {
            console.error('❌ Failed to start Redis container:', error.message);
            throw error;
        }
    }

    // Stop Redis container
    stopRedisContainer() {
        try {
            execSync(`docker stop ${this.containerName} 2>/dev/null || true`);
            execSync(`docker rm ${this.containerName} 2>/dev/null || true`);
            console.log('🛑 Stopped existing Redis container');
        } catch (error) {
            // Container might not exist, ignore error
        }
    }

    // Wait for Redis to be ready
    async waitForRedis() {
        const redis = require('redis');
        const client = redis.createClient({
            socket: { host: 'localhost', port: this.redisPort },
            password: this.redisPassword
        });

        let attempts = 0;
        const maxAttempts = 30;

        while (attempts < maxAttempts) {
            try {
                await client.connect();
                await client.ping();
                await client.disconnect();
                console.log('✅ Redis is ready');
                return;
            } catch (error) {
                attempts++;
                console.log(`⏳ Waiting for Redis... (${attempts}/${maxAttempts})`);
                await new Promise(resolve => setTimeout(resolve, 1000));
            }
        }

        throw new Error('Redis failed to start within timeout period');
    }

    // Create environment file for local testing
    createLocalEnv() {
        const fs = require('fs');
        const envContent = `# Local Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=${this.redisPort}
REDIS_PASSWORD=${this.redisPassword}

# Application Configuration
PORT=3000
NODE_ENV=development

# Cache Configuration
DEFAULT_TTL=300
QUOTE_CACHE_TTL=600
POLICY_CACHE_TTL=1800
`;

        fs.writeFileSync('.env.local', envContent);
        console.log('📄 Created .env.local for local testing');
    }

    // Setup complete local environment
    async setupLocalEnvironment() {
        console.log('🚀 Setting up complete local Redis environment...');
        
        const config = await this.startRedisContainer();
        this.createLocalEnv();
        
        console.log('\n✅ Local environment ready!');
        console.log('📋 Connection details:');
        console.log(`   Host: ${config.host}`);
        console.log(`   Port: ${config.port}`);
        console.log(`   Password: ${config.password}`);
        console.log('\n🔧 To use local environment:');
        console.log('   cp .env.local .env');
        console.log('   node test-connection.js');
        
        return config;
    }

    // Cleanup environment
    cleanup() {
        console.log('🧹 Cleaning up local environment...');
        this.stopRedisContainer();
        
        const fs = require('fs');
        try {
            fs.unlinkSync('.env.local');
            console.log('🗑️ Removed local environment file');
        } catch (error) {
            // File might not exist
        }
    }
}

// CLI usage
if (require.main === module) {
    const setup = new DockerRedisSetup();
    
    const command = process.argv[2];
    
    switch (command) {
        case 'start':
            setup.setupLocalEnvironment().catch(console.error);
            break;
        case 'stop':
            setup.cleanup();
            break;
        case 'restart':
            setup.cleanup();
            setTimeout(() => {
                setup.setupLocalEnvironment().catch(console.error);
            }, 2000);
            break;
        default:
            console.log('Usage: node docker-setup.js [start|stop|restart]');
            break;
    }
}

module.exports = DockerRedisSetup;
