const redis = require('redis');
const chalk = require('chalk');

class RedisClient {
    constructor() {
        this.client = null;
        this.connected = false;
        this.config = this.buildConfig();
    }

    buildConfig() {
        const config = {
            socket: {
                host: process.env.REDIS_HOST || 'localhost',
                port: parseInt(process.env.REDIS_PORT) || 6379,
                connectTimeout: 10000,
                lazyConnect: true
            },
            retry_strategy: (options) => {
                if (options.total_retry_time > 1000 * 60 * 60) {
                    return new Error('Retry time exhausted');
                }
                if (options.attempt > 10) {
                    return new Error('Max retry attempts reached');
                }
                return Math.min(options.attempt * 100, 3000);
            }
        };

        if (process.env.REDIS_PASSWORD) {
            config.password = process.env.REDIS_PASSWORD;
        }

        return config;
    }

    async connect() {
        if (this.connected && this.client) return this.client;

        try {
            this.client = redis.createClient(this.config);
            
            this.client.on('error', (err) => {
                console.error(chalk.red('Redis Client Error:'), err.message);
                this.connected = false;
            });

            this.client.on('connect', () => {
                console.log(chalk.green(`✅ Connected to Redis at ${this.config.socket.host}:${this.config.socket.port}`));
                this.connected = true;
            });

            this.client.on('reconnecting', () => {
                console.log(chalk.yellow('🔄 Reconnecting to Redis...'));
            });

            this.client.on('end', () => {
                console.log(chalk.yellow('🔌 Redis connection closed'));
                this.connected = false;
            });

            await this.client.connect();
            
            // Test connection
            await this.client.ping();
            console.log(chalk.green('✅ Redis connection verified'));
            
            return this.client;
        } catch (error) {
            console.error(chalk.red('Failed to connect to Redis:'), error.message);
            console.error(chalk.yellow('Configuration:'), {
                host: this.config.socket.host,
                port: this.config.socket.port,
                hasPassword: !!this.config.password
            });
            throw error;
        }
    }

    async disconnect() {
        if (this.client && this.connected) {
            try {
                await this.client.quit();
                this.connected = false;
                console.log(chalk.green('✅ Redis disconnected cleanly'));
            } catch (error) {
                console.error(chalk.red('Error disconnecting from Redis:'), error.message);
            }
        }
    }

    getClient() {
        if (!this.connected || !this.client) {
            throw new Error('Redis client not connected. Call connect() first.');
        }
        return this.client;
    }

    async isHealthy() {
        try {
            if (!this.connected || !this.client) return false;
            await this.client.ping();
            return true;
        } catch (error) {
            return false;
        }
    }

    getConnectionInfo() {
        return {
            host: this.config.socket.host,
            port: this.config.socket.port,
            connected: this.connected,
            hasPassword: !!this.config.password
        };
    }
}

module.exports = RedisClient;
