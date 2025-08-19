// src/middleware/rateLimitMiddleware.js
const RateLimitService = require('../services/rateLimitService');

class RateLimitMiddleware {
    constructor(redisClient) {
        this.rateLimitService = new RateLimitService(redisClient);
    }

    /**
     * Customer-based rate limiting middleware
     */
    customerRateLimit(options = {}) {
        return async (req, res, next) => {
            try {
                const customerId = req.headers['x-customer-id'] || req.body.customerId || 'anonymous';
                const customerTier = req.headers['x-customer-tier'] || 'standard';
                
                const limit = this.rateLimitService.getCustomerRateLimit(customerTier);
                const result = await this.rateLimitService.checkRateLimit(
                    customerId, 
                    limit, 
                    60, 
                    'customer'
                );

                // Set rate limit headers
                res.set({
                    'X-RateLimit-Limit': result.limit,
                    'X-RateLimit-Remaining': result.remaining,
                    'X-RateLimit-Reset': result.resetTime,
                    'X-RateLimit-Type': 'customer'
                });

                if (!result.allowed) {
                    // Record violation
                    await this.rateLimitService.recordViolation(customerId, {
                        type: 'customer_rate_limit',
                        endpoint: req.path,
                        method: req.method,
                        userAgent: req.get('User-Agent'),
                        ip: req.ip
                    });

                    // Check for abuse
                    const abuseCheck = await this.rateLimitService.detectAbuse(customerId);
                    
                    return res.status(429).json({
                        error: 'Rate limit exceeded',
                        message: `Too many requests. Limit: ${result.limit} per ${result.windowSeconds} seconds`,
                        retryAfter: result.resetTime,
                        customerId: customerId,
                        tier: customerTier,
                        suspicious: abuseCheck.suspicious
                    });
                }

                // Add rate limit info to request
                req.rateLimit = result;
                next();

            } catch (error) {
                console.error('❌ Customer rate limit middleware error:', error.message);
                next(); // Continue on error
            }
        };
    }

    /**
     * API key-based rate limiting
     */
    apiKeyRateLimit(options = {}) {
        return async (req, res, next) => {
            try {
                const apiKey = req.headers['x-api-key'] || req.query.apiKey;
                
                if (!apiKey) {
                    return res.status(401).json({
                        error: 'API key required',
                        message: 'Please provide a valid API key'
                    });
                }

                const result = await this.rateLimitService.checkAPIRateLimit(
                    apiKey,
                    req.route?.path || req.path,
                    options.limit
                );

                res.set({
                    'X-RateLimit-Limit': result.limit,
                    'X-RateLimit-Remaining': result.remaining,
                    'X-RateLimit-Reset': result.resetTime,
                    'X-RateLimit-Type': 'api_key'
                });

                if (!result.allowed) {
                    await this.rateLimitService.recordViolation(apiKey, {
                        type: 'api_rate_limit',
                        endpoint: req.path,
                        method: req.method
                    });

                    return res.status(429).json({
                        error: 'API rate limit exceeded',
                        message: `API limit exceeded. Limit: ${result.limit} per ${result.windowSeconds} seconds`,
                        retryAfter: result.resetTime,
                        apiKey: apiKey.substring(0, 8) + '...'
                    });
                }

                req.apiRateLimit = result;
                next();

            } catch (error) {
                console.error('❌ API rate limit middleware error:', error.message);
                next();
            }
        };
    }

    /**
     * IP-based rate limiting (basic DDoS protection)
     */
    ipRateLimit(options = { limit: 1000, windowSeconds: 60 }) {
        return async (req, res, next) => {
            try {
                const ip = req.ip || req.connection.remoteAddress;
                
                const result = await this.rateLimitService.checkRateLimit(
                    ip,
                    options.limit,
                    options.windowSeconds,
                    'ip'
                );

                res.set({
                    'X-RateLimit-Limit': result.limit,
                    'X-RateLimit-Remaining': result.remaining,
                    'X-RateLimit-Reset': result.resetTime,
                    'X-RateLimit-Type': 'ip'
                });

                if (!result.allowed) {
                    await this.rateLimitService.recordViolation(ip, {
                        type: 'ip_rate_limit',
                        endpoint: req.path,
                        method: req.method,
                        userAgent: req.get('User-Agent')
                    });

                    return res.status(429).json({
                        error: 'IP rate limit exceeded',
                        message: 'Too many requests from this IP address',
                        retryAfter: result.resetTime
                    });
                }

                req.ipRateLimit = result;
                next();

            } catch (error) {
                console.error('❌ IP rate limit middleware error:', error.message);
                next();
            }
        };
    }

    /**
     * Endpoint-specific rate limiting
     */
    endpointRateLimit(limit, windowSeconds = 60, bucketType = 'endpoint') {
        return async (req, res, next) => {
            try {
                const identifier = req.headers['x-customer-id'] || req.ip;
                const endpoint = req.route?.path || req.path;
                const fullIdentifier = `${identifier}:${endpoint}`;

                const result = await this.rateLimitService.checkRateLimit(
                    fullIdentifier,
                    limit,
                    windowSeconds,
                    bucketType
                );

                res.set({
                    'X-RateLimit-Limit': result.limit,
                    'X-RateLimit-Remaining': result.remaining,
                    'X-RateLimit-Reset': result.resetTime,
                    'X-RateLimit-Type': bucketType,
                    'X-RateLimit-Endpoint': endpoint
                });

                if (!result.allowed) {
                    return res.status(429).json({
                        error: 'Endpoint rate limit exceeded',
                        message: `Rate limit exceeded for ${endpoint}`,
                        endpoint: endpoint,
                        limit: result.limit,
                        windowSeconds: result.windowSeconds,
                        retryAfter: result.resetTime
                    });
                }

                req.endpointRateLimit = result;
                next();

            } catch (error) {
                console.error('❌ Endpoint rate limit middleware error:', error.message);
                next();
            }
        };
    }
}

module.exports = RateLimitMiddleware;
