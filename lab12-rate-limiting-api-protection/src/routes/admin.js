// src/routes/admin.js
const express = require('express');

function createAdminRoutes(rateLimitMiddleware) {
    const router = express.Router();

    // Admin authentication middleware
    const requireAdminKey = (req, res, next) => {
        const adminKey = req.headers['x-admin-key'];
        if (adminKey !== process.env.ADMIN_API_KEY) {
            return res.status(403).json({ error: 'Admin access required' });
        }
        next();
    };

    // Apply admin rate limiting
    router.use(rateLimitMiddleware.apiKeyRateLimit({ limit: 1000 }));
    router.use(requireAdminKey);

    // Get rate limit statistics
    router.get('/rate-limits/stats', async (req, res) => {
        try {
            // This would typically query Redis for aggregated stats
            const stats = {
                totalRequests: Math.floor(Math.random() * 10000),
                rateLimitViolations: Math.floor(Math.random() * 100),
                suspiciousActivity: Math.floor(Math.random() * 10),
                topEndpoints: [
                    { endpoint: '/api/quotes/auto', requests: 1250, violations: 15 },
                    { endpoint: '/api/policies', requests: 800, violations: 5 },
                    { endpoint: '/api/quotes/home', requests: 600, violations: 8 }
                ],
                timestamp: new Date().toISOString()
            };

            res.json({ success: true, stats });
            
        } catch (error) {
            res.status(500).json({ error: error.message });
        }
    });

    // Reset rate limits for a customer
    router.post('/rate-limits/reset', async (req, res) => {
        try {
            const { customerId, bucketType = 'customer' } = req.body;
            
            const result = await rateLimitMiddleware.rateLimitService
                .resetRateLimit(customerId, bucketType);
            
            res.json({
                success: result.success,
                message: `Rate limit reset for ${customerId}`,
                bucketType
            });
            
        } catch (error) {
            res.status(500).json({ error: error.message });
        }
    });

    // Get suspicious activity
    router.get('/security/suspicious', async (req, res) => {
        try {
            // Mock suspicious activity data
            const suspiciousActivity = [
                {
                    identifier: 'CUST_12345',
                    type: 'excessive_rate_violations',
                    detectedAt: new Date().toISOString(),
                    violationCount: 15,
                    risk: 'high'
                }
            ];

            res.json({
                success: true,
                activity: suspiciousActivity,
                total: suspiciousActivity.length
            });
            
        } catch (error) {
            res.status(500).json({ error: error.message });
        }
    });

    // Block/unblock customer
    router.post('/security/block', async (req, res) => {
        try {
            const { customerId, action, reason } = req.body;
            
            // This would typically update a blacklist in Redis
            console.log(`🚫 Admin action: ${action} customer ${customerId} - ${reason}`);
            
            res.json({
                success: true,
                customerId,
                action,
                reason,
                timestamp: new Date().toISOString()
            });
            
        } catch (error) {
            res.status(500).json({ error: error.message });
        }
    });

    return router;
}

module.exports = createAdminRoutes;
