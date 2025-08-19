const express = require('express');
const cors = require('cors');
const { createProxyMiddleware } = require('http-proxy-middleware');
const winston = require('winston');
const DistributedCacheManager = require('../../shared/cache/distributedCacheManager');

const app = express();
const PORT = process.env.PORT || 3000;

// Setup logging
const logger = winston.createLogger({
    level: 'info',
    format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.json()
    ),
    transports: [
        new winston.transports.Console(),
        new winston.transports.File({ filename: 'api-gateway.log' })
    ]
});

app.use(cors());
app.use(express.json());

// Initialize cache manager for service discovery
const cacheManager = new DistributedCacheManager({
    host: process.env.REDIS_HOST || 'localhost',
    port: process.env.REDIS_PORT || 6379,
    password: process.env.REDIS_PASSWORD || '',
    serviceName: 'api-gateway',
    keyPrefix: 'gateway',
    defaultTTL: 300
});

// Service registry and load balancing
const serviceRegistry = {
    'policy-service': [{ host: 'localhost', port: 3001, weight: 1, healthy: true }],
    'claims-service': [{ host: 'localhost', port: 3002, weight: 1, healthy: true }],
    'customer-service': [{ host: 'localhost', port: 3003, weight: 1, healthy: true }]
};

// Initialize gateway
async function initializeGateway() {
    try {
        await cacheManager.connect();
        
        // Monitor service health
        setInterval(checkServiceHealth, 30000); // Check every 30 seconds
        
        logger.info('API Gateway initialized successfully');
    } catch (error) {
        logger.error('Failed to initialize API Gateway', error);
        process.exit(1);
    }
}

// Service health checking
async function checkServiceHealth() {
    for (const [serviceName, instances] of Object.entries(serviceRegistry)) {
        for (const instance of instances) {
            try {
                const healthUrl = `http://${instance.host}:${instance.port}/health`;
                const response = await fetch(healthUrl, { timeout: 5000 });
                instance.healthy = response.ok;
                instance.lastCheck = new Date().toISOString();
                
                if (instance.healthy) {
                    logger.debug(`✅ ${serviceName} health check passed`);
                } else {
                    logger.warn(`❌ ${serviceName} health check failed`);
                }
            } catch (error) {
                instance.healthy = false;
                instance.lastCheck = new Date().toISOString();
                logger.warn(`❌ ${serviceName} health check error:`, error.message);
            }
        }
    }
    
    // Cache service registry state
    await cacheManager.set('service_registry', serviceRegistry, { ttl: 60 });
}

// Load balancer - simple round robin
const roundRobinCounters = {};

function getServiceInstance(serviceName) {
    const instances = serviceRegistry[serviceName];
    if (!instances || instances.length === 0) {
        return null;
    }
    
    // Filter healthy instances
    const healthyInstances = instances.filter(instance => instance.healthy);
    if (healthyInstances.length === 0) {
        logger.warn(`No healthy instances for ${serviceName}`);
        return null;
    }
    
    // Round robin selection
    if (!roundRobinCounters[serviceName]) {
        roundRobinCounters[serviceName] = 0;
    }
    
    const instance = healthyInstances[roundRobinCounters[serviceName] % healthyInstances.length];
    roundRobinCounters[serviceName]++;
    
    return instance;
}

// Middleware for request logging and metrics
app.use((req, res, next) => {
    const startTime = Date.now();
    
    logger.info('API Gateway request', {
        method: req.method,
        path: req.path,
        userAgent: req.get('User-Agent'),
        ip: req.ip,
        timestamp: new Date().toISOString()
    });
    
    res.on('finish', () => {
        const duration = Date.now() - startTime;
        logger.info('API Gateway response', {
            method: req.method,
            path: req.path,
            statusCode: res.statusCode,
            duration: `${duration}ms`,
            timestamp: new Date().toISOString()
        });
    });
    
    next();
});

// Health check endpoint
app.get('/health', async (req, res) => {
    try {
        const healthStatus = await cacheManager.healthCheck();
        const services = await cacheManager.getRegisteredServices();
        
        // Check registered services health
        const serviceHealthChecks = {};
        for (const [serviceName, instances] of Object.entries(serviceRegistry)) {
            serviceHealthChecks[serviceName] = {
                total: instances.length,
                healthy: instances.filter(i => i.healthy).length,
                instances: instances.map(i => ({
                    host: i.host,
                    port: i.port,
                    healthy: i.healthy,
                    lastCheck: i.lastCheck
                }))
            };
        }
        
        res.json({
            service: 'api-gateway',
            status: 'healthy',
            timestamp: new Date().toISOString(),
            cache: healthStatus,
            registeredServices: services.length,
            microservices: serviceHealthChecks,
            uptime: process.uptime()
        });
    } catch (error) {
        res.status(500).json({
            service: 'api-gateway',
            status: 'unhealthy',
            error: error.message,
            timestamp: new Date().toISOString()
        });
    }
});

// Service discovery endpoint
app.get('/services', async (req, res) => {
    try {
        const services = await cacheManager.getRegisteredServices();
        const registry = await cacheManager.get('service_registry') || serviceRegistry;
        
        res.json({
            registeredServices: services,
            serviceRegistry: registry,
            timestamp: new Date().toISOString()
        });
    } catch (error) {
        logger.error('Error retrieving services', error);
        res.status(500).json({ error: 'Failed to retrieve services' });
    }
});

// Proxy middleware factory
function createServiceProxy(serviceName, pathRewrite = {}) {
    return (req, res, next) => {
        const instance = getServiceInstance(serviceName);
        
        if (!instance) {
            return res.status(503).json({
                error: 'Service unavailable',
                service: serviceName,
                timestamp: new Date().toISOString()
            });
        }
        
        const target = `http://${instance.host}:${instance.port}`;
        
        const proxy = createProxyMiddleware({
            target,
            changeOrigin: true,
            pathRewrite,
            onError: (err, req, res) => {
                logger.error(`Proxy error for ${serviceName}:`, err);
                res.status(502).json({
                    error: 'Bad gateway',
                    service: serviceName,
                    target,
                    timestamp: new Date().toISOString()
                });
            },
            onProxyReq: (proxyReq, req, res) => {
                logger.debug(`Proxying ${req.method} ${req.path} to ${target}`);
            }
        });
        
        proxy(req, res, next);
    };
}

// API Routes with service proxying

// Policy Service routes
app.use('/api/policies', createServiceProxy('policy-service', {
    '^/api/policies': ''
}));

// Claims Service routes  
app.use('/api/claims', createServiceProxy('claims-service', {
    '^/api/claims': ''
}));

// Customer Service routes
app.use('/api/customers', createServiceProxy('customer-service', {
    '^/api/customers': ''
}));

// Aggregated endpoints
app.get('/api/dashboard/summary', async (req, res) => {
    try {
        // Aggregate data from multiple services
        const [policyStats, claimsStats, customerStats] = await Promise.all([
            fetchServiceData('policy-service', '/policies/stats/summary'),
            fetchServiceData('claims-service', '/claims/stats/summary'),
            fetchServiceData('customer-service', '/customers/stats/summary')
        ]);
        
        const summary = {
            policies: policyStats,
            claims: claimsStats,
            customers: customerStats,
            timestamp: new Date().toISOString()
        };
        
        // Cache the aggregated summary
        await cacheManager.set('dashboard_summary', summary, { ttl: 300 });
        
        res.json(summary);
    } catch (error) {
        logger.error('Error fetching dashboard summary', error);
        res.status(500).json({ error: 'Failed to fetch dashboard summary' });
    }
});

// Customer complete profile (aggregates data from multiple services)
app.get('/api/customers/:id/profile', async (req, res) => {
    try {
        const customerId = req.params.id;
        
        // Check cache first
        const cachedProfile = await cacheManager.get(`customer_profile:${customerId}`);
        if (cachedProfile) {
            return res.json({ ...cachedProfile, _source: 'cache' });
        }
        
        // Fetch from multiple services
        const [customer, customerPolicies, customerClaims] = await Promise.all([
            fetchServiceData('customer-service', `/customers/${customerId}`),
            fetchServiceData('policy-service', '/policies').then(policies => 
                policies.filter(p => p.customerName === customer?.name)
            ),
            fetchServiceData('claims-service', '/claims').then(claims =>
                claims.filter(c => customerPolicies.some(p => p.id === c.policyNumber))
            )
        ]);
        
        const profile = {
            customer,
            policies: customerPolicies || [],
            claims: customerClaims || [],
            summary: {
                totalPolicies: customerPolicies?.length || 0,
                totalClaims: customerClaims?.length || 0,
                totalPremium: customerPolicies?.reduce((sum, p) => sum + (p.premium || 0), 0) || 0,
                totalClaimAmount: customerClaims?.reduce((sum, c) => sum + (c.amount || 0), 0) || 0
            },
            timestamp: new Date().toISOString()
        };
        
        // Cache the profile
        await cacheManager.set(`customer_profile:${customerId}`, profile, { ttl: 1800 });
        
        res.json(profile);
    } catch (error) {
        logger.error('Error fetching customer profile', error);
        res.status(500).json({ error: 'Failed to fetch customer profile' });
    }
});

// Helper function to fetch data from services
async function fetchServiceData(serviceName, path) {
    const instance = getServiceInstance(serviceName);
    
    if (!instance) {
        throw new Error(`Service ${serviceName} is unavailable`);
    }
    
    try {
        const url = `http://${instance.host}:${instance.port}${path}`;
        const response = await fetch(url, { timeout: 10000 });
        
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }
        
        return await response.json();
    } catch (error) {
        logger.error(`Error fetching from ${serviceName}${path}:`, error);
        throw error;
    }
}

// Global error handler
app.use((error, req, res, next) => {
    logger.error('API Gateway error:', error);
    res.status(500).json({
        error: 'Internal server error',
        timestamp: new Date().toISOString()
    });
});

// 404 handler
app.use('*', (req, res) => {
    res.status(404).json({
        error: 'Route not found',
        path: req.originalUrl,
        timestamp: new Date().toISOString()
    });
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
    logger.info(`API Gateway running on port ${PORT}`);
    await initializeGateway();
    
    // Initial health check
    setTimeout(checkServiceHealth, 5000);
});

module.exports = app;
