// src/routes/quotes.js
const express = require('express');
const { v4: uuidv4 } = require('uuid');

function createQuoteRoutes(rateLimitMiddleware) {
    const router = express.Router();

    // Apply customer rate limiting to all quote routes
    router.use(rateLimitMiddleware.customerRateLimit());

    // Get insurance quote - heavily rate limited
    router.post('/auto', 
        rateLimitMiddleware.endpointRateLimit(10, 60, 'auto_quote'), // 10 per minute
        async (req, res) => {
            try {
                const { customerId, vehicleInfo, coverage } = req.body;
                
                // Simulate quote calculation delay
                await new Promise(resolve => setTimeout(resolve, 100));
                
                const quote = {
                    quoteId: uuidv4(),
                    customerId,
                    type: 'auto',
                    vehicleInfo,
                    coverage,
                    premium: Math.floor(Math.random() * 2000 + 500),
                    validUntil: new Date(Date.now() + 24 * 60 * 60 * 1000), // 24 hours
                    createdAt: new Date().toISOString()
                };

                console.log(`✅ Auto quote generated for customer ${customerId}`);
                
                res.json({
                    success: true,
                    quote,
                    rateLimit: {
                        customer: req.rateLimit,
                        endpoint: req.endpointRateLimit
                    }
                });
                
            } catch (error) {
                res.status(500).json({ error: error.message });
            }
        }
    );

    // Home insurance quote
    router.post('/home',
        rateLimitMiddleware.endpointRateLimit(8, 60, 'home_quote'), // 8 per minute
        async (req, res) => {
            try {
                const { customerId, propertyInfo, coverage } = req.body;
                
                await new Promise(resolve => setTimeout(resolve, 150));
                
                const quote = {
                    quoteId: uuidv4(),
                    customerId,
                    type: 'home',
                    propertyInfo,
                    coverage,
                    premium: Math.floor(Math.random() * 1500 + 800),
                    validUntil: new Date(Date.now() + 48 * 60 * 60 * 1000), // 48 hours
                    createdAt: new Date().toISOString()
                };

                console.log(`✅ Home quote generated for customer ${customerId}`);
                
                res.json({
                    success: true,
                    quote,
                    rateLimit: {
                        customer: req.rateLimit,
                        endpoint: req.endpointRateLimit
                    }
                });
                
            } catch (error) {
                res.status(500).json({ error: error.message });
            }
        }
    );

    // Life insurance quote - most restricted
    router.post('/life',
        rateLimitMiddleware.endpointRateLimit(3, 60, 'life_quote'), // 3 per minute
        async (req, res) => {
            try {
                const { customerId, personalInfo, coverage } = req.body;
                
                await new Promise(resolve => setTimeout(resolve, 300));
                
                const quote = {
                    quoteId: uuidv4(),
                    customerId,
                    type: 'life',
                    personalInfo,
                    coverage,
                    premium: Math.floor(Math.random() * 500 + 100),
                    validUntil: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days
                    createdAt: new Date().toISOString()
                };

                console.log(`✅ Life quote generated for customer ${customerId}`);
                
                res.json({
                    success: true,
                    quote,
                    rateLimit: {
                        customer: req.rateLimit,
                        endpoint: req.endpointRateLimit
                    }
                });
                
            } catch (error) {
                res.status(500).json({ error: error.message });
            }
        }
    );

    // Get quote history
    router.get('/history/:customerId',
        rateLimitMiddleware.endpointRateLimit(20, 60, 'quote_history'),
        async (req, res) => {
            try {
                const { customerId } = req.params;
                
                // Mock quote history
                const quotes = [
                    {
                        quoteId: uuidv4(),
                        type: 'auto',
                        premium: 1200,
                        status: 'active',
                        createdAt: new Date(Date.now() - 86400000).toISOString()
                    }
                ];

                res.json({
                    success: true,
                    customerId,
                    quotes,
                    total: quotes.length
                });
                
            } catch (error) {
                res.status(500).json({ error: error.message });
            }
        }
    );

    return router;
}

module.exports = createQuoteRoutes;
