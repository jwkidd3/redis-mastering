/**
 * Redis Configuration for Claims Event Sourcing
 */

require('dotenv').config();

const redisConfig = {
    connection: {
        host: process.env.REDIS_HOST || 'localhost',
        port: parseInt(process.env.REDIS_PORT) || 6379,
        password: process.env.REDIS_PASSWORD || undefined,
        retryDelayOnFailover: 100,
        retryTimes: 3,
        maxRetriesPerRequest: 3,
        connectTimeout: 5000,
        lazyConnect: true
    },
    
    streams: {
        claimsEvents: process.env.STREAM_NAME || 'claims:events',
        failedClaims: process.env.FAILED_STREAM || 'claims:failed',
        consumerGroup: process.env.CONSUMER_GROUP || 'claims-processors'
    },
    
    settings: {
        maxMemoryUsage: process.env.MAX_MEMORY_USAGE || '512mb',
        analyticsWindow: parseInt(process.env.ANALYTICS_WINDOW) || 3600
    }
};

module.exports = redisConfig;
