// src/services/rateLimitService.js
class RateLimitService {
    constructor(redisClient) {
        this.redis = redisClient;
        this.defaultConfig = {
            windowSizeSeconds: parseInt(process.env.WINDOW_SIZE_SECONDS) || 60,
            defaultLimit: parseInt(process.env.DEFAULT_RATE_LIMIT) || 100,
            premiumLimit: parseInt(process.env.PREMIUM_RATE_LIMIT) || 500,
            burstLimit: parseInt(process.env.BURST_RATE_LIMIT) || 1000
        };
    }

    /**
     * Token bucket rate limiting implementation
     * @param {string} identifier - Unique identifier (customer ID, IP, API key)
     * @param {number} limit - Request limit per window
     * @param {number} windowSeconds - Time window in seconds
     * @param {string} bucketType - Type of bucket (quote, policy, claim)
     */
    async checkRateLimit(identifier, limit = null, windowSeconds = null, bucketType = 'default') {
        try {
            const actualLimit = limit || this.defaultConfig.defaultLimit;
            const actualWindow = windowSeconds || this.defaultConfig.windowSizeSeconds;
            
            const key = `rate_limit:${bucketType}:${identifier}`;
            const now = Math.floor(Date.now() / 1000);
            const windowStart = now - actualWindow;

            // Use Redis pipeline for atomic operations
            const multi = this.redis.multi();
            
            // Remove old requests outside the window
            multi.zRemRangeByScore(key, '-inf', windowStart);
            
            // Count current requests in window
            multi.zCard(key);
            
            // Add current request
            multi.zAdd(key, { score: now, value: `${now}-${Math.random()}` });
            
            // Set expiration
            multi.expire(key, actualWindow * 2);
            
            const results = await multi.exec();
            const currentCount = results[1] || 0;

            // Check if limit exceeded
            const isAllowed = currentCount < actualLimit;
            const remaining = Math.max(0, actualLimit - currentCount - 1);
            const resetTime = now + actualWindow;

            return {
                allowed: isAllowed,
                limit: actualLimit,
                remaining: remaining,
                resetTime: resetTime,
                currentCount: currentCount + 1,
                windowSeconds: actualWindow,
                bucketType: bucketType
            };

        } catch (error) {
            console.error('❌ Rate limit check failed:', error.message);
            // Fail open - allow request if Redis is down
            return {
                allowed: true,
                limit: limit || this.defaultConfig.defaultLimit,
                remaining: 999,
                resetTime: Math.floor(Date.now() / 1000) + 60,
                currentCount: 1,
                error: error.message
            };
        }
    }

    /**
     * Get customer tier-based rate limit
     */
    getCustomerRateLimit(customerTier) {
        const limits = {
            'premium': this.defaultConfig.premiumLimit,
            'standard': this.defaultConfig.defaultLimit,
            'basic': Math.floor(this.defaultConfig.defaultLimit * 0.5),
            'trial': Math.floor(this.defaultConfig.defaultLimit * 0.2)
        };
        
        return limits[customerTier] || this.defaultConfig.defaultLimit;
    }

    /**
     * API-specific rate limiting
     */
    async checkAPIRateLimit(apiKey, endpoint, customLimit = null) {
        const identifier = `${apiKey}:${endpoint}`;
        const limit = customLimit || this.getAPIEndpointLimit(endpoint);
        
        return await this.checkRateLimit(identifier, limit, 60, 'api');
    }

    /**
     * Get endpoint-specific limits
     */
    getAPIEndpointLimit(endpoint) {
        const endpointLimits = {
            '/api/quotes': 50,           // Quote requests
            '/api/policies': 100,        // Policy operations
            '/api/claims': 75,           // Claims processing
            '/api/customers': 200,       // Customer data
            '/api/payments': 25,         // Payment processing
            '/api/reports': 10           // Heavy reporting queries
        };
        
        return endpointLimits[endpoint] || this.defaultConfig.defaultLimit;
    }

    /**
     * Abuse detection - detect suspicious patterns
     */
    async detectAbuse(identifier, threshold = 5) {
        try {
            const key = `abuse_detection:${identifier}`;
            const now = Math.floor(Date.now() / 1000);
            const windowStart = now - 300; // 5-minute window

            // Count rate limit violations in the last 5 minutes
            const violationKey = `violations:${identifier}`;
            const violations = await this.redis.zCount(violationKey, windowStart, now);

            if (violations >= threshold) {
                // Mark as suspicious
                await this.redis.setEx(`suspicious:${identifier}`, 1800, JSON.stringify({
                    detectedAt: now,
                    violationCount: violations,
                    reason: 'excessive_rate_limit_violations'
                }));

                return {
                    suspicious: true,
                    violationCount: violations,
                    action: 'temporary_block'
                };
            }

            return {
                suspicious: false,
                violationCount: violations
            };

        } catch (error) {
            console.error('❌ Abuse detection failed:', error.message);
            return { suspicious: false, error: error.message };
        }
    }

    /**
     * Record rate limit violation
     */
    async recordViolation(identifier, details = {}) {
        try {
            const key = `violations:${identifier}`;
            const now = Math.floor(Date.now() / 1000);
            
            await this.redis.zAdd(key, { 
                score: now, 
                value: JSON.stringify({ timestamp: now, ...details }) 
            });
            
            // Keep violations for 24 hours
            await this.redis.expire(key, 86400);
            
        } catch (error) {
            console.error('❌ Failed to record violation:', error.message);
        }
    }

    /**
     * Get rate limit status for monitoring
     */
    async getRateLimitStatus(identifier, bucketType = 'default') {
        try {
            const key = `rate_limit:${bucketType}:${identifier}`;
            const now = Math.floor(Date.now() / 1000);
            const windowStart = now - this.defaultConfig.windowSizeSeconds;

            const count = await this.redis.zCount(key, windowStart, now);
            const ttl = await this.redis.ttl(key);

            return {
                identifier,
                bucketType,
                currentCount: count,
                resetIn: ttl,
                windowSize: this.defaultConfig.windowSizeSeconds
            };

        } catch (error) {
            console.error('❌ Failed to get rate limit status:', error.message);
            return null;
        }
    }

    /**
     * Reset rate limits for a user (admin function)
     */
    async resetRateLimit(identifier, bucketType = 'default') {
        try {
            const key = `rate_limit:${bucketType}:${identifier}`;
            await this.redis.del(key);
            
            console.log(`✅ Rate limit reset for ${identifier} (${bucketType})`);
            return { success: true };
            
        } catch (error) {
            console.error('❌ Failed to reset rate limit:', error.message);
            return { success: false, error: error.message };
        }
    }
}

module.exports = RateLimitService;
