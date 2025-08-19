// scripts/reset-limits.js
const redisClient = require('../config/redis');
const RateLimitService = require('../src/services/rateLimitService');

async function resetAllLimits() {
    try {
        await redisClient.connect();
        const rateLimitService = new RateLimitService(redisClient.getClient());
        
        console.log('🔄 Resetting all rate limits...');
        
        // Get all rate limit keys
        const redis = redisClient.getClient();
        const keys = await redis.keys('rate_limit:*');
        
        if (keys.length > 0) {
            await redis.del(keys);
            console.log(`✅ Deleted ${keys.length} rate limit entries`);
        } else {
            console.log('ℹ️ No rate limit entries found');
        }
        
        // Also clean up violations
        const violationKeys = await redis.keys('violations:*');
        if (violationKeys.length > 0) {
            await redis.del(violationKeys);
            console.log(`✅ Deleted ${violationKeys.length} violation records`);
        }
        
        console.log('🔄 Rate limit reset complete');
        
    } catch (error) {
        console.error('❌ Reset failed:', error.message);
    } finally {
        await redisClient.disconnect();
    }
}

// Run reset
resetAllLimits();
