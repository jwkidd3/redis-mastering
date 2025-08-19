// src/routes/policies.js
const express = require('express');
const { v4: uuidv4 } = require('uuid');

function createPolicyRoutes(rateLimitMiddleware) {
    const router = express.Router();

    // Apply customer rate limiting
    router.use(rateLimitMiddleware.customerRateLimit());

    // Create new policy
    router.post('/',
        rateLimitMiddleware.endpointRateLimit(5, 60, 'policy_create'),
        async (req, res) => {
            try {
                const { customerId, quoteId, paymentInfo } = req.body;
                
                await new Promise(resolve => setTimeout(resolve, 200));
                
                const policy = {
                    policyId: uuidv4(),
                    customerId,
                    quoteId,
                    policyNumber: `POL-${Math.floor(Math.random() * 1000000)}`,
                    status: 'active',
                    effectiveDate: new Date().toISOString(),
                    expirationDate: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString(),
                    createdAt: new Date().toISOString()
                };

                console.log(`✅ Policy created: ${policy.policyNumber}`);
                
                res.json({
                    success: true,
                    policy
                });
                
            } catch (error) {
                res.status(500).json({ error: error.message });
            }
        }
    );

    // Get policy details
    router.get('/:policyId',
        rateLimitMiddleware.endpointRateLimit(30, 60, 'policy_read'),
        async (req, res) => {
            try {
                const { policyId } = req.params;
                
                const policy = {
                    policyId,
                    policyNumber: `POL-${Math.floor(Math.random() * 1000000)}`,
                    status: 'active',
                    type: 'auto',
                    premium: 1200,
                    lastAccessed: new Date().toISOString()
                };

                res.json({
                    success: true,
                    policy
                });
                
            } catch (error) {
                res.status(500).json({ error: error.message });
            }
        }
    );

    // Update policy
    router.put('/:policyId',
        rateLimitMiddleware.endpointRateLimit(10, 60, 'policy_update'),
        async (req, res) => {
            try {
                const { policyId } = req.params;
                const updateData = req.body;
                
                await new Promise(resolve => setTimeout(resolve, 150));
                
                console.log(`✅ Policy updated: ${policyId}`);
                
                res.json({
                    success: true,
                    policyId,
                    updated: Object.keys(updateData),
                    timestamp: new Date().toISOString()
                });
                
            } catch (error) {
                res.status(500).json({ error: error.message });
            }
        }
    );

    return router;
}

module.exports = createPolicyRoutes;
