const express = require('express');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');
const winston = require('winston');
const DistributedCacheManager = require('../../shared/cache/distributedCacheManager');

const app = express();
const PORT = process.env.PORT || 3003;

// Setup logging
const logger = winston.createLogger({
    level: 'info',
    format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.json()
    ),
    transports: [
        new winston.transports.Console(),
        new winston.transports.File({ filename: 'customer-service.log' })
    ]
});

app.use(cors());
app.use(express.json());

// Initialize cache manager
const cacheManager = new DistributedCacheManager({
    host: process.env.REDIS_HOST || 'localhost',
    port: process.env.REDIS_PORT || 6379,
    password: process.env.REDIS_PASSWORD || '',
    serviceName: 'customer-service',
    keyPrefix: 'customer',
    defaultTTL: 3600
});

// In-memory storage for demo
const customers = new Map();

// Initialize service
async function initializeService() {
    try {
        await cacheManager.connect();
        
        // Listen to policy and claims events to update customer data
        cacheManager.on('event:received', async (eventData) => {
            if (eventData.channel === 'policy:events' || eventData.channel === 'claims:events') {
                await handleBusinessEvent(eventData.event);
            }
        });

        logger.info('Customer service initialized successfully');
    } catch (error) {
        logger.error('Failed to initialize customer service', error);
        process.exit(1);
    }
}

// Handle business events from other services
async function handleBusinessEvent(event) {
    try {
        switch (event.type) {
            case 'POLICY_CREATED':
                // Update customer with new policy reference
                const customerName = event.customerName;
                if (customerName) {
                    const customer = Array.from(customers.values()).find(c => c.name === customerName);
                    if (customer) {
                        customer.policies = customer.policies || [];
                        customer.policies.push(event.policyId);
                        customer.lastPolicyDate = event.timestamp;
                        await cacheManager.set(customer.id, customer, { ttl: 7200 });
                        logger.info('Updated customer with new policy', { customerId: customer.id, policyId: event.policyId });
                    }
                }
                break;
            case 'CLAIM_CREATED':
                // Update customer activity
                const policyNumber = event.policyNumber;
                if (policyNumber) {
                    const customer = Array.from(customers.values()).find(c => 
                        c.policies && c.policies.includes(policyNumber)
                    );
                    if (customer) {
                        customer.claims = customer.claims || [];
                        customer.claims.push(event.claimId);
                        customer.lastClaimDate = event.timestamp;
                        await cacheManager.set(customer.id, customer, { ttl: 7200 });
                        logger.info('Updated customer with new claim', { customerId: customer.id, claimId: event.claimId });
                    }
                }
                break;
        }
    } catch (error) {
        logger.error('Error handling business event', error);
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
            service: 'customer-service',
            status: 'healthy',
            timestamp: new Date().toISOString(),
            cache: healthStatus,
            registeredServices: services.length,
            uptime: process.uptime()
        });
    } catch (error) {
        res.status(500).json({
            service: 'customer-service',
            status: 'unhealthy',
            error: error.message,
            timestamp: new Date().toISOString()
        });
    }
});

// Create customer
app.post('/customers', async (req, res) => {
    try {
        const customerId = req.body.customerId || `CUST-${Date.now()}`;
        const customer = {
            id: customerId,
            ...req.body,
            policies: [],
            claims: [],
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
            version: 1
        };

        // Store in memory and cache
        customers.set(customerId, customer);
        await cacheManager.set(customerId, customer, { ttl: 7200 });

        // Publish customer created event
        await cacheManager.publishEvent('customer:events', {
            type: 'CUSTOMER_CREATED',
            customerId,
            customerName: customer.name,
            email: customer.email,
            timestamp: new Date().toISOString()
        });

        logger.info('Customer created', { customerId, name: customer.name });
        res.status(201).json(customer);
    } catch (error) {
        logger.error('Error creating customer', error);
        res.status(500).json({ error: 'Failed to create customer' });
    }
});

// Get customer
app.get('/customers/:id', async (req, res) => {
    try {
        const customerId = req.params.id;
        
        // Try cache first
        let customer = await cacheManager.get(customerId);
        let source = 'cache';
        
        if (!customer) {
            // Fallback to in-memory storage
            customer = customers.get(customerId);
            source = 'storage';
            
            if (customer) {
                // Cache the customer for future requests
                await cacheManager.set(customerId, customer, { ttl: 3600 });
            }
        }

        if (!customer) {
            return res.status(404).json({ error: 'Customer not found' });
        }

        logger.info('Customer retrieved', { customerId, source });
        res.json({ ...customer, _source: source });
    } catch (error) {
        logger.error('Error retrieving customer', error);
        res.status(500).json({ error: 'Failed to retrieve customer' });
    }
});

// Update customer
app.put('/customers/:id', async (req, res) => {
    try {
        const customerId = req.params.id;
        const existingCustomer = customers.get(customerId);
        
        if (!existingCustomer) {
            return res.status(404).json({ error: 'Customer not found' });
        }

        const updatedCustomer = {
            ...existingCustomer,
            ...req.body,
            id: customerId,
            updatedAt: new Date().toISOString(),
            version: existingCustomer.version + 1
        };

        // Update storage and cache
        customers.set(customerId, updatedCustomer);
        await cacheManager.set(customerId, updatedCustomer, { ttl: 7200 });

        // Publish customer updated event
        await cacheManager.publishEvent('customer:events', {
            type: 'CUSTOMER_UPDATED',
            customerId,
            changes: req.body,
            version: updatedCustomer.version,
            timestamp: new Date().toISOString()
        });

        logger.info('Customer updated', { customerId, version: updatedCustomer.version });
        res.json(updatedCustomer);
    } catch (error) {
        logger.error('Error updating customer', error);
        res.status(500).json({ error: 'Failed to update customer' });
    }
});

// Get all customers
app.get('/customers', async (req, res) => {
    try {
        const allCustomers = Array.from(customers.values());
        
        // Cache the customer list
        await cacheManager.set('all_customers', allCustomers, { ttl: 600 });
        
        res.json(allCustomers);
    } catch (error) {
        logger.error('Error retrieving customers', error);
        res.status(500).json({ error: 'Failed to retrieve customers' });
    }
});

// Get customer with policies and claims
app.get('/customers/:id/complete', async (req, res) => {
    try {
        const customerId = req.params.id;
        const customer = await cacheManager.get(customerId) || customers.get(customerId);
        
        if (!customer) {
            return res.status(404).json({ error: 'Customer not found' });
        }

        // This would typically fetch from other services
        // For demo, we'll return the customer with placeholders
        const completeCustomer = {
            ...customer,
            policyDetails: customer.policies || [],
            claimDetails: customer.claims || [],
            totalPolicies: customer.policies ? customer.policies.length : 0,
            totalClaims: customer.claims ? customer.claims.length : 0
        };

        // Cache the complete customer data
        await cacheManager.set(`${customerId}_complete`, completeCustomer, { ttl: 1800 });

        res.json(completeCustomer);
    } catch (error) {
        logger.error('Error retrieving complete customer data', error);
        res.status(500).json({ error: 'Failed to retrieve complete customer data' });
    }
});

// Delete customer
app.delete('/customers/:id', async (req, res) => {
    try {
        const customerId = req.params.id;
        
        if (!customers.has(customerId)) {
            return res.status(404).json({ error: 'Customer not found' });
        }

        customers.delete(customerId);
        await cacheManager.del(customerId);
        await cacheManager.del(`${customerId}_complete`);

        // Publish customer deleted event
        await cacheManager.publishEvent('customer:events', {
            type: 'CUSTOMER_DELETED',
            customerId,
            timestamp: new Date().toISOString()
        });

        logger.info('Customer deleted', { customerId });
        res.status(204).send();
    } catch (error) {
        logger.error('Error deleting customer', error);
        res.status(500).json({ error: 'Failed to delete customer' });
    }
});

// Get customer statistics
app.get('/customers/stats/summary', async (req, res) => {
    try {
        const allCustomers = Array.from(customers.values());
        
        const stats = {
            totalCustomers: allCustomers.length,
            customersWithPolicies: allCustomers.filter(c => c.policies && c.policies.length > 0).length,
            customersWithClaims: allCustomers.filter(c => c.claims && c.claims.length > 0).length,
            averagePoliciesPerCustomer: allCustomers.length > 0 ? 
                allCustomers.reduce((sum, c) => sum + (c.policies ? c.policies.length : 0), 0) / allCustomers.length : 0,
            timestamp: new Date().toISOString()
        };

        // Cache stats
        await cacheManager.set('customer_stats', stats, { ttl: 300 });

        res.json(stats);
    } catch (error) {
        logger.error('Error generating customer stats', error);
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
    logger.info(`Customer service running on port ${PORT}`);
    await initializeService();
});

module.exports = app;
