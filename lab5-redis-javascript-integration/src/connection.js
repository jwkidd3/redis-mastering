// src/connection.js
import { createClient } from 'redis';

async function connectRedis() {
    const client = createClient({
        url: process.env.REDIS_URL || 'redis://localhost:6379',
        socket: {
            reconnectStrategy: (retries) => {
                if (retries > 10) {
                    console.log('Too many reconnection attempts');
                    return new Error('Too many retries');
                }
                return retries * 100;
            }
        }
    });

    client.on('error', (err) => console.error('Redis Client Error:', err));
    client.on('connect', () => console.log('Connected to Redis'));
    client.on('ready', () => console.log('Redis client ready'));

    await client.connect();
    return client;
}

export default connectRedis;
