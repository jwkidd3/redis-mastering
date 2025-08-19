const express = require('express');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');
const winston = require('winston');
const DistributedCacheManager = require('../../shared/cache/distributedCacheManager');

const app = express();
const PORT = process.env.PORT || 3001;

// Setup logging
const logger = winston.createLogger({
    level: 'info',
    format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.json()
    ),
    transports: [
        new winston.transports.Console(),
        new winston.transports.File({ filename: 'policy-service.log' })
    ]
});

app.use(cors());
app.use(express.json());

// Initialize cache manager
const cacheManager = new DistributedCacheManager({
    host: process.env.REDIS_HOST || 'localhost',
    port: process.env.REDIS_PORT || 6379,
    password: process.env.REDIS_PASSWORD || '',
    serviceName: 'policy-service',
    keyPrefix: 'policy',
    defaultTTL: 3600
});

// In-memory storage for demo (in production, use database)
const policies = new Map();

// Initialize service
async function initializeService() {
    try {
        await cacheManager.connect();
        
        // Setup event listeners
        cacheManager.on('cache:invalidated', (event) => {
            logger.info('Cache invalidated by another service', event);
        });

        cacheManager.on('event:received', (event) => {
            logger.info('Event received from another service', event);
        });

        logger.info('Policy service initialized successfully');
    } catch (error) {
        logger.error('Failed to initialize policy service', error);
        process.exit(1);
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
            service: 'policy-service',
            status: 'healthy',
            timestamp: new Date().toISOString(),
            cache: healthStatus,
            registeredServices: services.length,
            uptime: process.uptime()
        });
    } catch (error) {
        res.status(500).json({
            service: 'policy-service',
            status: 'unhealthy',
            error: error.message,
            timestamp: new Date().toISOString()
        });
    }
});

// Create policy
app.post('/policies', async (req, res) => {
    try {
        const policyId = req.body.policyNumber || `POL-${Date.now()}`;
        const policy = {
            id: policyId,
            ...req.body,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
            version: 1
        };

        // Store in memory and cache
        policies.set(policyId, policy);
        await cacheManager.set(policyId, policy, { ttl: 7200 });

        // Publish policy created event
        await cacheManager.publishEvent('policy:events', {
            type: 'POLICY_CREATED',
            policyId,
            customerName: policy.customerName,
            policyType: policy.policyType,
            premium: policy.premium,
            timestamp: new Date().toISOString()
        });

        logger.info('Policy created', { policyId, customerName: policy.customerName });
        res.status(201).json(policy);
    } catch (error) {
        logger.error('Error creating policy', error);
        res.status(500).json({ error: 'Failed to create policy' });
    }
});

// Get policy
app.get('/policies/:id', async (req, res) => {
    try {
        const policyId = req.params.id;
        
        // Try cache first
        let policy = await cacheManager.get(policyId);
        let source = 'cache';
        
        if (!policy) {
            // Fallback to in-memory storage
            policy = policies.get(policyId);
            source = 'storage';
            
            if (policy) {
                // Cache the policy for future requests
                await cacheManager.set(policyId, policy, { ttl: 3600 });
            }
        }

        if (!policy) {
            return res.status(404).json({ error: 'Policy not found' });
        }

        logger.info('Policy retrieved', { policyId, source });
        res.json({ ...policy, _source: source });
    } catch (error) {
        logger.error('Error retrieving policy', error);
        res.status(500).json({ error: 'Failed to retrieve policy' });
    }
});

// Update policy
app.put('/policies/:id', async (req, res) => {
    try {
        const policyId = req.params.id;
        const existingPolicy = policies.get(policyId);
        
        if (!existingPolicy) {
            return res.status(404).json({ error: 'Policy not found' });
        }

        const updatedPolicy = {
            ...existingPolicy,
            ...req.body,
            id: policyId,
            updatedAt: new Date().toISOString(),
            version: existingPolicy.version + 1
        };

        // Update storage and cache
        policies.set(policyId, updatedPolicy);
        await cacheManager.set(policyId, updatedPolicy, { ttl: 7200 });

        // Invalidate related caches
        await cacheManager.invalidatePattern(`claims:policy:${policyId}:*`);

        // Publish policy updated event
        await cacheManager.publishEvent('policy:events', {
            type: 'POLICY_UPDATED',
            policyId,
            changes: req.body,
            version: updatedPolicy.version,
            timestamp: new Date().toISOString()
        });

        logger.info('Policy updated', { policyId, version: updatedPolicy.version });
        res.json(updatedPolicy);
    } catch (error) {
        logger.error('Error updating policy', error);
        res.status(500).json({ error: 'Failed to update policy' });
    }
});

// Get all policies
app.get('/policies', async (req, res) => {
    try {
        const allPolicies = Array.from(policies.values());
        
        // Cache the policy list
        await cacheManager.set('all_policies', allPolicies, { ttl: 600 });
        
        res.json(allPolicies);
    } catch (error) {
        logger.error('Error retrieving policies', error);
        res.status(500).json({ error: 'Failed to retrieve policies' });
    }
});

// Delete policy
app.delete('/policies/:id', async (req, res) => {
    try {
        const policyId = req.params.id;
        
        if (!policies.has(policyId)) {
            return res.status(404).json({ error: 'Policy not found' });
        }

        policies.delete(policyId);
        await cacheManager.del(policyId);
        await cacheManager.invalidatePattern(`claims:policy:${policyId}:*`);

        // Publish policy deleted event
        await cacheManager.publishEvent('policy:events', {
            type: 'POLICY_DELETED',
            policyId,
            timestamp: new Date().toISOString()
        });

        logger.info('Policy deleted', { policyId });
        res.status(204).send();
    } catch (error) {
        logger.error('Error deleting policy', error);
        res.status(500).json({ error: 'Failed to delete policy' });
    }
});

// Get policy statistics
app.get('/policies/stats/summary', async (req, res) => {
    try {
        const allPolicies = Array.from(policies.values());
        
        const stats = {
            totalPolicies: allPolicies.length,
            activePolicies: allPolicies.filter(p => p.status === 'Active').length,
            totalPremium: allPolicies.reduce((sum, p) => sum + (p.premium || 0), 0),
            policyTypes: {},
            timestamp: new Date().toISOString()
        };

        // Count policy types
        allPolicies.forEach(policy => {
            const type = policy.policyType || 'Unknown';
            stats.policyTypes[type] = (stats.policyTypes[type] || 0) + 1;
        });

        // Cache stats
        await cacheManager.set('policy_stats', stats, { ttl: 300 });

        res.json(stats);
    } catch (error) {
        logger.error('Error generating policy stats', error);
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
    logger.info(`Policy service running on port ${PORT}`);
    await initializeService();
});

module.exports = app;
