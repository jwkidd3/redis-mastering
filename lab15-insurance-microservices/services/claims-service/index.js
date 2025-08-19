const express = require('express');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');
const winston = require('winston');
const DistributedCacheManager = require('../../shared/cache/distributedCacheManager');

const app = express();
const PORT = process.env.PORT || 3002;

// Setup logging
const logger = winston.createLogger({
    level: 'info',
    format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.json()
    ),
    transports: [
        new winston.transports.Console(),
        new winston.transports.File({ filename: 'claims-service.log' })
    ]
});

app.use(cors());
app.use(express.json());

// Initialize cache manager
const cacheManager = new DistributedCacheManager({
    host: process.env.REDIS_HOST || 'localhost',
    port: process.env.REDIS_PORT || 6379,
    password: process.env.REDIS_PASSWORD || '',
    serviceName: 'claims-service',
    keyPrefix: 'claims',
    defaultTTL: 3600
});

// In-memory storage for demo
const claims = new Map();

// Initialize service
async function initializeService() {
    try {
        await cacheManager.connect();
        
        // Listen to policy events
        cacheManager.on('event:received', async (eventData) => {
            if (eventData.channel === 'policy:events') {
                await handlePolicyEvent(eventData.event);
            }
        });

        logger.info('Claims service initialized successfully');
    } catch (error) {
        logger.error('Failed to initialize claims service', error);
        process.exit(1);
    }
}

// Handle policy events
async function handlePolicyEvent(event) {
    try {
        switch (event.type) {
            case 'POLICY_DELETED':
                // Invalidate claims cache for deleted policy
                await cacheManager.invalidatePattern(`policy:${event.policyId}:*`);
                logger.info('Invalidated claims cache for deleted policy', { policyId: event.policyId });
                break;
            case 'POLICY_UPDATED':
                // Update policy reference in claims cache
                const policyClaims = Array.from(claims.values()).filter(c => c.policyNumber === event.policyId);
                for (const claim of policyClaims) {
                    await cacheManager.set(`claim:${claim.id}`, claim, { ttl: 3600 });
                }
                logger.info('Updated claims cache for policy update', { policyId: event.policyId, claimsCount: policyClaims.length });
                break;
        }
    } catch (error) {
        logger.error('Error handling policy event', error);
    }
}

// Middleware for logging
app.use((req, res, next) => {
    logger.info(`${req.method} ${req.path}`, { 
        body: req.body, 
        query: req.query,
        timestamp: new Date().toISOString()
    });
    next();
});

// Health check endpoint
app.get('/health', async (req, res) => {
    try {
        const healthStatus = await cacheManager.healthCheck();
        const services = await cacheManager.getRegisteredServices();
        
        res.json({
            service: 'claims-service',
            status: 'healthy',
            timestamp: new Date().toISOString(),
            cache: healthStatus,
            registeredServices: services.length,
            uptime: process.uptime()
        });
    } catch (error) {
        res.status(500).json({
            service: 'claims-service',
            status: 'unhealthy',
            error: error.message,
            timestamp: new Date().toISOString()
        });
    }
});

// Helper function to validate policy exists
async function validatePolicy(policyNumber) {
    try {
        // Try to get policy from cache first
        const policyCacheManager = new DistributedCacheManager({
            host: process.env.REDIS_HOST || 'localhost',
            port: process.env.REDIS_PORT || 6379,
            password: process.env.REDIS_PASSWORD || '',
            serviceName: 'claims-policy-validator',
            keyPrefix: 'policy'
        });
        
        await policyCacheManager.connect();
        const policy = await policyCacheManager.get(policyNumber);
        await policyCacheManager.disconnect();
        
        return policy !== null;
    } catch (error) {
        logger.warn('Policy validation failed, assuming valid', { policyNumber, error: error.message });
        return true; // Assume valid if can't validate
    }
}

// Create claim
app.post('/claims', async (req, res) => {
    try {
        const { policyNumber, claimType, amount, description, incidentDate } = req.body;
        
        if (!policyNumber) {
            return res.status(400).json({ error: 'Policy number is required' });
        }

        // Validate policy exists
        const policyExists = await validatePolicy(policyNumber);
        if (!policyExists) {
            return res.status(400).json({ error: 'Invalid policy number' });
        }

        const claimId = `CLM-${Date.now()}`;
        const claim = {
            id: claimId,
            policyNumber,
            claimType: claimType || 'General',
            amount: amount || 0,
            description: description || '',
            incidentDate: incidentDate || new Date().toISOString(),
            status: 'Submitted',
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
            version: 1
        };

        // Store in memory and cache
        claims.set(claimId, claim);
        await cacheManager.set(`claim:${claimId}`, claim, { ttl: 7200 });
        await cacheManager.set(`policy:${policyNumber}:claims:${claimId}`, claim, { ttl: 7200 });

        // Update policy cache to include claim reference
        try {
            const policyCacheManager = new DistributedCacheManager({
                host: process.env.REDIS_HOST || 'localhost',
                port: process.env.REDIS_PORT || 6379,
                password: process.env.REDIS_PASSWORD || '',
                serviceName: 'claims-policy-updater',
                keyPrefix: 'policy'
            });
            
            await policyCacheManager.connect();
            const policy = await policyCacheManager.get(policyNumber);
            
            if (policy) {
                policy.claims = policy.claims || [];
                policy.claims.push(claimId);
                policy.lastClaimDate = new Date().toISOString();
                await policyCacheManager.set(policyNumber, policy, { ttl: 7200 });
            }
            
            await policyCacheManager.disconnect();
        } catch (error) {
            logger.warn('Failed to update policy cache with claim reference', error);
        }

        // Publish claim created event
        await cacheManager.publishEvent('claims:events', {
            type: 'CLAIM_CREATED',
            claimId,
            policyNumber,
            claimType,
            amount,
            timestamp: new Date().toISOString()
        });

        logger.info('Claim created', { claimId, policyNumber, amount });
        res.status(201).json(claim);
    } catch (error) {
        logger.error('Error creating claim', error);
        res.status(500).json({ error: 'Failed to create claim' });
    }
});

// Get claim
app.get('/claims/:id', async (req, res) => {
    try {
        const claimId = req.params.id;
        
        // Try cache first
        let claim = await cacheManager.get(`claim:${claimId}`);
        let source = 'cache';
        
        if (!claim) {
            // Fallback to in-memory storage
            claim = claims.get(claimId);
            source = 'storage';
            
            if (claim) {
                // Cache the claim for future requests
                await cacheManager.set(`claim:${claimId}`, claim, { ttl: 3600 });
            }
        }

        if (!claim) {
            return res.status(404).json({ error: 'Claim not found' });
        }

        logger.info('Claim retrieved', { claimId, source });
        res.json({ ...claim, _source: source });
    } catch (error) {
        logger.error('Error retrieving claim', error);
        res.status(500).json({ error: 'Failed to retrieve claim' });
    }
});

// Get claims by policy
app.get('/claims/by-policy/:policyNumber', async (req, res) => {
    try {
        const policyNumber = req.params.policyNumber;
        
        // Get all claims for this policy
        const policyClaims = Array.from(claims.values()).filter(c => c.policyNumber === policyNumber);
        
        // Cache the result
        await cacheManager.set(`policy:${policyNumber}:all_claims`, policyClaims, { ttl: 600 });
        
        logger.info('Claims retrieved for policy', { policyNumber, claimsCount: policyClaims.length });
        res.json(policyClaims);
    } catch (error) {
        logger.error('Error retrieving claims for policy', error);
        res.status(500).json({ error: 'Failed to retrieve claims for policy' });
    }
});

// Update claim status
app.put('/claims/:id/status', async (req, res) => {
    try {
        const claimId = req.params.id;
        const { status, notes } = req.body;
        
        const existingClaim = claims.get(claimId);
        if (!existingClaim) {
            return res.status(404).json({ error: 'Claim not found' });
        }

        const updatedClaim = {
            ...existingClaim,
            status,
            notes: notes || existingClaim.notes,
            updatedAt: new Date().toISOString(),
            version: existingClaim.version + 1
        };

        // Update storage and cache
        claims.set(claimId, updatedClaim);
        await cacheManager.set(`claim:${claimId}`, updatedClaim, { ttl: 7200 });
        await cacheManager.set(`policy:${updatedClaim.policyNumber}:claims:${claimId}`, updatedClaim, { ttl: 7200 });

        // Publish claim status updated event
        await cacheManager.publishEvent('claims:events', {
            type: 'CLAIM_STATUS_UPDATED',
            claimId,
            policyNumber: updatedClaim.policyNumber,
            oldStatus: existingClaim.status,
            newStatus: status,
            timestamp: new Date().toISOString()
        });

        logger.info('Claim status updated', { claimId, oldStatus: existingClaim.status, newStatus: status });
        res.json(updatedClaim);
    } catch (error) {
        logger.error('Error updating claim status', error);
        res.status(500).json({ error: 'Failed to update claim status' });
    }
});

// Get all claims
app.get('/claims', async (req, res) => {
    try {
        const { status, policyNumber } = req.query;
        let filteredClaims = Array.from(claims.values());
        
        if (status) {
            filteredClaims = filteredClaims.filter(c => c.status === status);
        }
        
        if (policyNumber) {
            filteredClaims = filteredClaims.filter(c => c.policyNumber === policyNumber);
        }
        
        // Cache the filtered result
        const cacheKey = `filtered_claims:${status || 'all'}:${policyNumber || 'all'}`;
        await cacheManager.set(cacheKey, filteredClaims, { ttl: 300 });
        
        res.json(filteredClaims);
    } catch (error) {
        logger.error('Error retrieving claims', error);
        res.status(500).json({ error: 'Failed to retrieve claims' });
    }
});

// Get claims statistics
app.get('/claims/stats/summary', async (req, res) => {
    try {
        const allClaims = Array.from(claims.values());
        
        const stats = {
            totalClaims: allClaims.length,
            pendingClaims: allClaims.filter(c => c.status === 'Submitted').length,
            approvedClaims: allClaims.filter(c => c.status === 'Approved').length,
            rejectedClaims: allClaims.filter(c => c.status === 'Rejected').length,
            totalClaimAmount: allClaims.reduce((sum, c) => sum + (c.amount || 0), 0),
            averageClaimAmount: allClaims.length > 0 ? allClaims.reduce((sum, c) => sum + (c.amount || 0), 0) / allClaims.length : 0,
            claimTypes: {},
            timestamp: new Date().toISOString()
        };

        // Count claim types
        allClaims.forEach(claim => {
            const type = claim.claimType || 'Unknown';
            stats.claimTypes[type] = (stats.claimTypes[type] || 0) + 1;
        });

        // Cache stats
        await cacheManager.set('claims_stats', stats, { ttl: 300 });

        res.json(stats);
    } catch (error) {
        logger.error('Error generating claims stats', error);
        res.status(500).json({ error: 'Failed to generate statistics' });
    }
});

// Graceful shutdown
process.on('SIGTERM', async () => {
    logger.info('SIGTERM received, shutting down gracefully');
    await cacheManager.disconnect();
    process.exit(0);
});

process.on('SIGINT', async () => {
    logger.info('SIGINT received, shutting down gracefully');
    await cacheManager.disconnect();
    process.exit(0);
});

// Start server
app.listen(PORT, async () => {
    logger.info(`Claims service running on port ${PORT}`);
    await initializeService();
});

module.exports = app;
