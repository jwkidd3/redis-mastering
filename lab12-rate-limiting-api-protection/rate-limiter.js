// rate-limiter.js - Rate limiting implementation using Redis
const redis = require('redis');

class RateLimiter {
    constructor() {
        this.client = null;
    }

    async connect() {
        this.client = redis.createClient();
        await this.client.connect();
    }

    async disconnect() {
        if (this.client) {
            await this.client.quit();
        }
    }

    // Fixed window rate limiting
    async checkFixedWindow(identifier, limit, windowSize) {
        const key = `rate:fixed:${identifier}`;
        const current = await this.client.incr(key);

        if (current === 1) {
            await this.client.expire(key, windowSize);
        }

        return {
            allowed: current <= limit,
            current,
            limit,
            remaining: Math.max(0, limit - current)
        };
    }

    // Sliding window rate limiting
    async checkSlidingWindow(identifier, limit, windowSize) {
        const key = `rate:sliding:${identifier}`;
        const now = Date.now();
        const windowStart = now - (windowSize * 1000);

        // Remove old entries
        await this.client.zRemRangeByScore(key, 0, windowStart);

        // Count current requests
        const current = await this.client.zCard(key);

        if (current < limit) {
            // Add new request
            await this.client.zAdd(key, { score: now, value: `${now}` });
            await this.client.expire(key, windowSize);

            return {
                allowed: true,
                current: current + 1,
                limit,
                remaining: limit - current - 1
            };
        }

        return {
            allowed: false,
            current,
            limit,
            remaining: 0
        };
    }

    // Token bucket rate limiting
    async checkTokenBucket(identifier, capacity, refillRate, refillTime) {
        const key = `rate:token:${identifier}`;
        const tokensKey = `${key}:tokens`;
        const lastRefillKey = `${key}:last_refill`;

        const tokens = await this.client.get(tokensKey);
        const lastRefill = await this.client.get(lastRefillKey);

        const now = Date.now();
        let availableTokens = tokens ? parseInt(tokens) : capacity;
        const lastRefillTime = lastRefill ? parseInt(lastRefill) : now;

        // Refill tokens
        const timePassed = (now - lastRefillTime) / 1000;
        const tokensToAdd = Math.floor(timePassed / refillTime) * refillRate;
        availableTokens = Math.min(capacity, availableTokens + tokensToAdd);

        if (availableTokens > 0) {
            // Consume token
            availableTokens--;
            await this.client.set(tokensKey, availableTokens.toString());
            await this.client.set(lastRefillKey, now.toString());
            await this.client.expire(tokensKey, refillTime * capacity);
            await this.client.expire(lastRefillKey, refillTime * capacity);

            return {
                allowed: true,
                tokens: availableTokens
            };
        }

        return {
            allowed: false,
            tokens: 0
        };
    }
}

module.exports = RateLimiter;
