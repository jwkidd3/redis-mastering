// src/clients/redisClient.js
const redis = require('redis');
const redisConfig = require('../config/redis');

class RedisClient {
    constructor() {
        this.client = null;
        this.isConnected = false;
    }

    async connect() {
        try {
            // Create Redis client with configuration
            this.client = redis.createClient({
                socket: {
                    host: redisConfig.host,
                    port: redisConfig.port,
                    connectTimeout: redisConfig.connectTimeout
                },
                password: redisConfig.password,
                database: redisConfig.database
            });

            // Set up event handlers
            this.client.on('connect', () => {
                console.log('📡 Connecting to Redis server...');
            });

            this.client.on('ready', () => {
                console.log('✅ Redis client ready');
                this.isConnected = true;
            });

            this.client.on('error', (err) => {
                console.error('❌ Redis client error:', err.message);
                this.isConnected = false;
            });

            this.client.on('end', () => {
                console.log('🔌 Redis connection closed');
                this.isConnected = false;
            });

            // Connect to Redis
            await this.client.connect();
            
            // Test connection
            const pingResult = await this.client.ping();
            console.log('🏓 Redis ping result:', pingResult);

            return this.client;
        } catch (error) {
            console.error('💥 Failed to connect to Redis:', error.message);
            throw error;
        }
    }

    async disconnect() {
        if (this.client && this.isConnected) {
            await this.client.quit();
            console.log('👋 Disconnected from Redis');
        }
    }

    getClient() {
        if (!this.isConnected) {
            throw new Error('Redis client not connected. Call connect() first.');
        }
        return this.client;
    }

    async healthCheck() {
        try {
            if (!this.isConnected) {
                return { status: 'disconnected', message: 'Not connected to Redis' };
            }

            const start = Date.now();
            await this.client.ping();
            const latency = Date.now() - start;

            const info = await this.client.info('server');
            const serverInfo = {};
            info.split('\r\n').forEach(line => {
                const [key, value] = line.split(':');
                if (key && value) {
                    serverInfo[key] = value;
                }
            });

            return {
                status: 'connected',
                latency: `${latency}ms`,
                server: serverInfo.redis_version,
                uptime: serverInfo.uptime_in_seconds + ' seconds'
            };
        } catch (error) {
            return { status: 'error', message: error.message };
        }
    }
}

module.exports = RedisClient;