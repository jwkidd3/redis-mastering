const express = require('express');
const redis = require('redis');
const winston = require('winston');
const cron = require('node-cron');
const path = require('path');

// Configure logger
const logger = winston.createLogger({
    level: 'info',
    format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.json()
    ),
    transports: [
        new winston.transports.File({ filename: path.join(__dirname, '../logs/app.log') }),
        new winston.transports.Console()
    ]
});

// Redis client setup
const redisClient = redis.createClient({
    host: process.env.REDIS_HOST || 'localhost',
    port: process.env.REDIS_PORT || 6379,
    retry_strategy: (options) => {
        if (options.error && options.error.code === 'ECONNREFUSED') {
            logger.error('Redis server connection refused');
            return new Error('Redis server connection refused');
        }
        if (options.total_retry_time > 1000 * 60 * 60) {
            return new Error('Retry time exhausted');
        }
        return Math.min(options.attempt * 100, 3000);
    }
});

// Express app setup
const app = express();
const PORT = process.env.PORT || 3000;
const MONITORING_PORT = process.env.MONITORING_PORT || 4000;

app.use(express.json());

// Health check endpoint
app.get('/health', async (req, res) => {
    try {
        // Check Redis connection
        await redisClient.ping();
        
        const healthStatus = {
            status: 'healthy',
            timestamp: new Date().toISOString(),
            uptime: process.uptime(),
            redis: 'connected',
            memory: process.memoryUsage(),
            version: process.version
        };
        
        logger.info('Health check passed', healthStatus);
        res.status(200).json(healthStatus);
    } catch (error) {
        logger.error('Health check failed', { error: error.message });
        res.status(503).json({
            status: 'unhealthy',
            timestamp: new Date().toISOString(),
            error: error.message
        });
    }
});

// Redis info endpoint
app.get('/redis/info', async (req, res) => {
    try {
        const info = await redisClient.info();
        res.json({ redis_info: info });
    } catch (error) {
        logger.error('Redis info failed', { error: error.message });
        res.status(500).json({ error: error.message });
    }
});

// Metrics endpoint
app.get('/metrics', async (req, res) => {
    try {
        const info = await redisClient.info();
        const stats = parseRedisInfo(info);
        
        const metrics = {
            timestamp: new Date().toISOString(),
            redis_stats: stats,
            app_metrics: {
                uptime: process.uptime(),
                memory: process.memoryUsage(),
                pid: process.pid
            }
        };
        
        res.json(metrics);
    } catch (error) {
        logger.error('Metrics collection failed', { error: error.message });
        res.status(500).json({ error: error.message });
    }
});

// Parse Redis INFO output
function parseRedisInfo(info) {
    const stats = {};
    const lines = info.split('\r\n');
    
    for (const line of lines) {
        if (line.includes(':') && !line.startsWith('#')) {
            const [key, value] = line.split(':');
            stats[key] = isNaN(value) ? value : parseFloat(value);
        }
    }
    
    return stats;
}

// Monitoring dashboard server
const monitoringApp = express();

monitoringApp.use(express.static(path.join(__dirname, '../dashboards')));

monitoringApp.get('/api/metrics/realtime', async (req, res) => {
    try {
        const info = await redisClient.info();
        const stats = parseRedisInfo(info);
        
        const realtimeMetrics = {
            timestamp: new Date().toISOString(),
            connected_clients: stats.connected_clients || 0,
            used_memory: stats.used_memory || 0,
            used_memory_human: stats.used_memory_human || '0B',
            keyspace_hits: stats.keyspace_hits || 0,
            keyspace_misses: stats.keyspace_misses || 0,
            total_commands_processed: stats.total_commands_processed || 0,
            instantaneous_ops_per_sec: stats.instantaneous_ops_per_sec || 0
        };
        
        res.json(realtimeMetrics);
    } catch (error) {
        logger.error('Realtime metrics failed', { error: error.message });
        res.status(500).json({ error: error.message });
    }
});

// Scheduled monitoring tasks
cron.schedule('*/1 * * * *', async () => {
    try {
        const info = await redisClient.info();
        const stats = parseRedisInfo(info);
        
        // Log critical metrics every minute
        logger.info('Scheduled monitoring check', {
            connected_clients: stats.connected_clients,
            used_memory: stats.used_memory,
            keyspace_hits: stats.keyspace_hits,
            keyspace_misses: stats.keyspace_misses
        });
        
        // Alert conditions
        if (stats.connected_clients > 100) {
            logger.warn('High client connection count', { count: stats.connected_clients });
        }
        
        if (stats.used_memory > 1000000000) { // 1GB
            logger.warn('High memory usage', { memory: stats.used_memory_human });
        }
        
    } catch (error) {
        logger.error('Scheduled monitoring failed', { error: error.message });
    }
});

// Graceful shutdown
process.on('SIGTERM', () => {
    logger.info('SIGTERM received, shutting down gracefully');
    redisClient.quit();
    process.exit(0);
});

process.on('SIGINT', () => {
    logger.info('SIGINT received, shutting down gracefully');
    redisClient.quit();
    process.exit(0);
});

// Start servers
app.listen(PORT, () => {
    logger.info(`Main application server started on port ${PORT}`);
});

monitoringApp.listen(MONITORING_PORT, () => {
    logger.info(`Monitoring dashboard server started on port ${MONITORING_PORT}`);
});

// Connect to Redis
redisClient.on('connect', () => {
    logger.info('Connected to Redis server');
});

redisClient.on('error', (error) => {
    logger.error('Redis connection error', { error: error.message });
});

module.exports = { app, monitoringApp };