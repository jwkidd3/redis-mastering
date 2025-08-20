const redis = require('redis');

class RedisClient {
    constructor() {
        this.client = null;
        this.isConnected = false;
    }

    async connect(options = {}) {
        try {
            // Replace with your actual Redis server details
            const config = {
                host: process.env.REDIS_HOST || 'redis-server.training.com',
                port: process.env.REDIS_PORT || 6379,
                password: process.env.REDIS_PASSWORD || undefined,
                ...options
            };

            this.client = redis.createClient(config);
            
            this.client.on('error', (err) => {
                console.error('Redis Client Error:', err);
                this.isConnected = false;
            });

            this.client.on('connect', () => {
                console.log('✅ Connected to Redis server');
                this.isConnected = true;
            });

            await this.client.connect();
            return this.client;
        } catch (error) {
            console.error('Failed to connect to Redis:', error);
            throw error;
        }
    }

    async disconnect() {
        if (this.client) {
            await this.client.disconnect();
            this.isConnected = false;
            console.log('📤 Disconnected from Redis');
        }
    }

    getClient() {
        if (!this.isConnected) {
            throw new Error('Redis client not connected');
        }
        return this.client;
    }
}

module.exports = RedisClient;