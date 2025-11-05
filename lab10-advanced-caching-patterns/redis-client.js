// redis-client.js - Redis client wrapper for Lab 10
const redis = require('redis');

let client = null;

async function getRedisClient() {
    if (!client) {
        client = redis.createClient({
            socket: {
                host: process.env.REDIS_HOST || 'localhost',
                port: process.env.REDIS_PORT || 6379
            }
        });
        await client.connect();
    }
    return client;
}

async function disconnect() {
    if (client) {
        await client.quit();
        client = null;
    }
}

module.exports = { getRedisClient, disconnect };
