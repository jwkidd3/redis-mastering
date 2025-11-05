// redis-client.js - Simple Redis client wrapper for Lab 6
const redis = require('redis');

class RedisClient {
    constructor() {
        this.client = null;
        this.isConnected = false;
    }

    async connect() {
        try {
            // Create Redis client with default configuration
            this.client = redis.createClient({
                socket: {
                    host: process.env.REDIS_HOST || 'localhost',
                    port: process.env.REDIS_PORT || 6379
                }
            });

            // Set up event handlers
            this.client.on('error', (err) => {
                console.error('Redis client error:', err.message);
                this.isConnected = false;
            });

            // Connect to Redis
            await this.client.connect();
            this.isConnected = true;

            // Test connection
            await this.client.ping();
            console.log('✓ Connected to Redis');

            return this.client;
        } catch (error) {
            console.error('Failed to connect to Redis:', error.message);
            throw error;
        }
    }

    async disconnect() {
        if (this.client && this.isConnected) {
            await this.client.quit();
            this.isConnected = false;
        }
    }

    getClient() {
        if (!this.isConnected) {
            throw new Error('Redis client not connected. Call connect() first.');
        }
        return this.client;
    }
}

module.exports = RedisClient;
