const redis = require('redis');

class RedisClient {
    constructor() {
        this.client = null;
        this.connected = false;
    }

    async connect() {
        if (this.connected) return this.client;

        const config = {
            socket: {
                host: process.env.REDIS_HOST || 'localhost',
                port: parseInt(process.env.REDIS_PORT) || 6379
            }
        };

        if (process.env.REDIS_PASSWORD) {
            config.password = process.env.REDIS_PASSWORD;
        }

        this.client = redis.createClient(config);
        
        this.client.on('error', (err) => {
            console.error('Redis Client Error:', err);
            this.connected = false;
        });

        this.client.on('connect', () => {
            console.log(`✅ Connected to Redis at ${config.socket.host}:${config.socket.port}`);
            this.connected = true;
        });

        await this.client.connect();
        return this.client;
    }

    async disconnect() {
        if (this.client && this.connected) {
            await this.client.quit();
            this.connected = false;
        }
    }

    getClient() {
        if (!this.connected) {
            throw new Error('Redis client not connected. Call connect() first.');
        }
        return this.client;
    }
}

module.exports = new RedisClient();
