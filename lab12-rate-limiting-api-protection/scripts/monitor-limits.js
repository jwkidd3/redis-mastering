// scripts/monitor-limits.js
const redisClient = require('../config/redis');
const RateLimitService = require('../src/services/rateLimitService');

async function monitorRateLimits() {
    try {
        await redisClient.connect();
        const rateLimitService = new RateLimitService(redisClient.getClient());
        
        console.log('🔍 Rate Limit Monitoring Dashboard');
        console.log('=====================================');
        
        // Monitor sample customers
        const customers = ['CUST001', 'CUST002', 'CUST003'];
        
        for (const customerId of customers) {
            const status = await rateLimitService.getRateLimitStatus(customerId, 'customer');
            
            if (status) {
                console.log(`\n👤 Customer: ${customerId}`);
                console.log(`   Current requests: ${status.currentCount}`);
                console.log(`   Reset in: ${status.resetIn} seconds`);
                console.log(`   Window size: ${status.windowSize} seconds`);
            }
        }
        
        console.log('\n🔍 Monitoring complete');
        
    } catch (error) {
        console.error('❌ Monitoring failed:', error.message);
    } finally {
        await redisClient.disconnect();
    }
}

// Run monitoring
monitorRateLimits();
