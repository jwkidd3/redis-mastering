const express = require('express');
const RedisManager = require('../../shared/redis-client');
const app = express();
app.use(express.json());

const redis = new RedisManager('customer-service');
const PORT = process.env.CUSTOMER_SERVICE_PORT || 3003;

async function initService() {
    await redis.connect();
    
    // Subscribe to customer events
    await redis.subscribeToEvents('customer:events', async (data) => {
        console.log(`[Customer Service] Customer event:`, data);
    });
}

// Get customer with caching
app.get('/api/customers/:id', async (req, res) => {
    const customerId = req.params.id;
    const cacheKey = `cache:customer:${customerId}`;
    
    try {
        let customer = await redis.cacheGet(cacheKey);
        
        if (!customer) {
            // Get from Redis hash
            customer = await redis.client.hGetAll(`customer:${customerId}`);
            
            if (Object.keys(customer).length === 0) {
                return res.status(404).json({ error: 'Customer not found' });
            }
            
            // Cache for 5 minutes
            await redis.cacheSet(cacheKey, customer, 300);
        }
        
        res.json(customer);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Update customer
app.put('/api/customers/:id', async (req, res) => {
    const customerId = req.params.id;
    
    try {
        // Update in Redis hash
        await redis.client.hSet(`customer:${customerId}`, req.body);
        
        // Invalidate cache
        await redis.invalidateCache(`cache:customer:${customerId}`);
        
        // Notify other services
        await redis.publishEvent('customer:updated', {
            customerId,
            changes: req.body
        });
        
        res.json({ message: 'Customer updated', customerId });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Health check
app.get('/health', async (req, res) => {
    res.json({
        service: 'customer-service',
        status: 'healthy',
        timestamp: new Date().toISOString()
    });
});

initService().then(() => {
    app.listen(PORT, () => {
        console.log(`✅ Customer Service running on port ${PORT}`);
    });
});
