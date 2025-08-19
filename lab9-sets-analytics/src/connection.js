const redis = require('redis');

const client = redis.createClient({
    host: process.env.REDIS_HOST || 'your-redis-host',
    port: process.env.REDIS_PORT || 6379,
    // password: process.env.REDIS_PASSWORD,  // Uncomment if authentication required
});

client.on('error', (err) => {
    console.error('Redis connection error:', err);
});

client.on('connect', () => {
    console.log('Connected to Redis server for Lab 9');
});

client.on('ready', () => {
    console.log('Redis client ready for analytics operations');
});

module.exports = client;
