/**
 * Redis Client Utility for Claims Event Sourcing
 */

const { createClient } = require('redis');
const config = require('../../config/redis');

class RedisStreamClient {
    constructor() {
        this.client = null;
        this.connected = false;
    }

    async connect() {
        if (this.connected) {
            return this.client;
        }

        try {
            this.client = createClient({
                socket: {
                    host: config.connection.host,
                    port: config.connection.port,
                    connectTimeout: config.connection.connectTimeout
                },
                password: config.connection.password
            });

            this.client.on('error', (err) => {
                console.error('Redis Client Error:', err);
                this.connected = false;
            });

            this.client.on('connect', () => {
                console.log('✅ Connected to Redis for streams processing');
                this.connected = true;
            });

            this.client.on('disconnect', () => {
                console.log('⚠️  Disconnected from Redis');
                this.connected = false;
            });

            await this.client.connect();
            return this.client;
        } catch (error) {
            console.error('Failed to connect to Redis:', error);
            throw error;
        }
    }

    async disconnect() {
        if (this.client && this.connected) {
            await this.client.disconnect();
            this.connected = false;
            console.log('👋 Disconnected from Redis');
        }
    }

    getClient() {
        if (!this.connected) {
            throw new Error('Redis client not connected. Call connect() first.');
        }
        return this.client;
    }

    isConnected() {
        return this.connected;
    }

    // Stream-specific utilities
    async createStream(streamName, initialData = {}) {
        const client = this.getClient();
        try {
            await client.xAdd(streamName, '*', {
                type: 'stream_created',
                timestamp: Date.now(),
                ...initialData
            });
            console.log(`✅ Stream ${streamName} created/verified`);
        } catch (error) {
            console.error(`Failed to create stream ${streamName}:`, error);
            throw error;
        }
    }

    async createConsumerGroup(streamName, groupName, startId = '$') {
        const client = this.getClient();
        try {
            await client.xGroupCreate(streamName, groupName, startId, {
                MKSTREAM: true
            });
            console.log(`✅ Consumer group ${groupName} created for stream ${streamName}`);
        } catch (error) {
            if (error.message.includes('BUSYGROUP')) {
                console.log(`ℹ️  Consumer group ${groupName} already exists`);
            } else {
                console.error(`Failed to create consumer group:`, error);
                throw error;
            }
        }
    }

    async getStreamInfo(streamName) {
        const client = this.getClient();
        try {
            return await client.xInfoStream(streamName);
        } catch (error) {
            if (error.message.includes('no such key')) {
                return null;
            }
            throw error;
        }
    }

    async getConsumerGroupInfo(streamName, groupName) {
        const client = this.getClient();
        try {
            const groups = await client.xInfoGroups(streamName);
            return groups.find(group => group.name === groupName);
        } catch (error) {
            if (error.message.includes('no such key')) {
                return null;
            }
            throw error;
        }
    }
}

// Export singleton instance
const redisClient = new RedisStreamClient();

module.exports = redisClient;
