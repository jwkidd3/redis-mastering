const redis = require('redis');
require('dotenv').config({ path: './config/.env' });

const redisConfig = {
    host: process.env.REDIS_HOST || 'localhost',
    port: process.env.REDIS_PORT || 6379,
    db: process.env.REDIS_DB || 0,
    retryDelayOnFailover: 100,
    enableReadyCheck: false,
    maxRetriesPerRequest: null,
};

let client;

async function getRedisClient() {
    if (!client) {
        client = redis.createClient({
            socket: {
                host: redisConfig.host,
                port: redisConfig.port
            },
            database: redisConfig.db
        });

        client.on('error', (err) => {
            console.error('Redis Client Error:', err);
        });

        client.on('connect', () => {
            console.log('✅ Connected to Redis server');
        });

        await client.connect();
    }
    return client;
}

module.exports = { getRedisClient, redisConfig };
