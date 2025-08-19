// config/redis.js
const redis = require('redis');
require('dotenv').config();

class RedisClient {
    constructor() {
        this.client = null;
        this.isConnected = false;
    }

    async connect() {
        try {
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
                console.error('❌ Redis Client Error:', err);
                this.isConnected = false;
            });

            this.client.on('connect', () => {
                console.log('🔗 Redis client connected');
                this.isConnected = true;
            });

            await this.client.connect();
            return this.client;
        } catch (error) {
            console.error('💥 Failed to connect to Redis:', error.message);
            throw error;
        }
    }

    getClient() {
        if (!this.isConnected) {
            throw new Error('Redis client not connected');
        }
        return this.client;
    }

    async disconnect() {
        if (this.client) {
            await this.client.quit();
            this.isConnected = false;
        }
    }
}

module.exports = new RedisClient();
