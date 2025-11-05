// middleware.js - Express middleware for rate limiting
const RateLimiter = require('./rate-limiter');

class RateLimitMiddleware {
    constructor(strategy = 'fixed', options = {}) {
        this.rateLimiter = new RateLimiter();
        this.strategy = strategy;
        this.options = {
            limit: options.limit || 100,
            windowSize: options.windowSize || 60,
            identifierFn: options.identifierFn || ((req) => req.ip),
            ...options
        };
    }

    async connect() {
        await this.rateLimiter.connect();
    }

    async disconnect() {
        await this.rateLimiter.disconnect();
    }

    // Middleware function
    async middleware(req, res, next) {
        const identifier = this.options.identifierFn(req);

        let result;
        if (this.strategy === 'sliding') {
            result = await this.rateLimiter.checkSlidingWindow(
                identifier,
                this.options.limit,
                this.options.windowSize
            );
        } else {
            result = await this.rateLimiter.checkFixedWindow(
                identifier,
                this.options.limit,
                this.options.windowSize
            );
        }

        // Set rate limit headers
        res.setHeader('X-RateLimit-Limit', result.limit);
        res.setHeader('X-RateLimit-Remaining', result.remaining);

        if (!result.allowed) {
            return res.status(429).json({
                error: 'Rate limit exceeded',
                limit: result.limit,
                current: result.current
            });
        }

        next();
    }
}

module.exports = RateLimitMiddleware;
