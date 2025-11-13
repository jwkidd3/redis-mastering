const express = require('express');
const Redis = require('ioredis');
const winston = require('winston');
const path = require('path');

class HealthCheckService {
    constructor() {
        this.app = express();
        this.redis = new Redis({
            host: process.env.REDIS_HOST || 'localhost',
            port: process.env.REDIS_PORT || 6379,
            password: process.env.REDIS_PASSWORD,
            retryDelayOnFailover: 100,
            maxRetriesPerRequest: 3
        });
        
        this.logger = winston.createLogger({
            level: 'info',
            format: winston.format.combine(
                winston.format.timestamp(),
                winston.format.json()
            ),
            transports: [
                new winston.transports.File({ filename: path.join(__dirname, '../logs/health-checks.log') }),
                new winston.transports.Console()
            ]
        });
        
        this.setupRoutes();
    }
    
    setupRoutes() {
        // Main health check endpoint
        this.app.get('/health', async (req, res) => {
            try {
                const health = await this.getComprehensiveHealth();
                const status = health.status === 'healthy' ? 200 : 503;
                res.status(status).json(health);
            } catch (error) {
                res.status(503).json({
                    status: 'error',
                    message: error.message,
                    timestamp: new Date().toISOString()
                });
            }
        });
        
        // Detailed business metrics endpoint
        this.app.get('/health/business', async (req, res) => {
            try {
                const metrics = await this.getBusinessMetrics();
                res.json({
                    status: 'success',
                    data: metrics,
                    timestamp: new Date().toISOString()
                });
            } catch (error) {
                res.status(500).json({
                    status: 'error',
                    message: error.message
                });
            }
        });
        
        // Performance metrics endpoint
        this.app.get('/health/performance', async (req, res) => {
            try {
                const performance = await this.getPerformanceMetrics();
                res.json({
                    status: 'success',
                    data: performance,
                    timestamp: new Date().toISOString()
                });
            } catch (error) {
                res.status(500).json({
                    status: 'error',
                    message: error.message
                });
            }
        });
        
        // Redis-specific health endpoint
        this.app.get('/health/redis', async (req, res) => {
            try {
                const redisHealth = await this.checkRedisHealth();
                res.json({
                    status: 'success',
                    data: redisHealth,
                    timestamp: new Date().toISOString()
                });
            } catch (error) {
                res.status(500).json({
                    status: 'error',
                    message: error.message
                });
            }
        });
    }
    
    async getComprehensiveHealth() {
        const [redisHealth, businessMetrics, performance] = await Promise.all([
            this.checkRedisHealth(),
            this.getBusinessMetrics(),
            this.getPerformanceMetrics()
        ]);
        
        const isHealthy = redisHealth.status === 'healthy' && 
                         performance.responseTime < 100 &&
                         performance.memoryUsage < 80;
        
        return {
            status: isHealthy ? 'healthy' : 'unhealthy',
            timestamp: new Date().toISOString(),
            redis: redisHealth,
            business: businessMetrics,
            performance: performance,
            uptime: process.uptime(),
            environment: process.env.NODE_ENV || 'development'
        };
    }
    
    async checkRedisHealth() {
        try {
            const start = Date.now();
            await this.redis.ping();
            const responseTime = Date.now() - start;
            
            const info = await this.redis.info();
            const memoryInfo = await this.redis.info('memory');
            
            return {
                status: 'healthy',
                responseTime,
                connected: true,
                memory: this.parseMemoryInfo(memoryInfo),
                uptime: await this.redis.info('server')
            };
        } catch (error) {
            this.logger.error('Redis health check failed', { error: error.message });
            return {
                status: 'unhealthy',
                connected: false,
                error: error.message
            };
        }
    }
    
    async getBusinessMetrics() {
        try {
            const [
                activeSessions,
                cacheEfficiency,
                transactionVolume,
                errorRate
            ] = await Promise.all([
                this.countActiveSessions(),
                this.calculateCacheEfficiency(),
                this.getTransactionVolume(),
                this.calculateErrorRate()
            ]);
            
            return {
                activeSessions,
                cacheEfficiency,
                transactionVolume,
                errorRate,
                lastUpdated: new Date().toISOString()
            };
        } catch (error) {
            this.logger.error('Business metrics collection failed', { error: error.message });
            throw error;
        }
    }
    
    async getPerformanceMetrics() {
        try {
            const slowlog = await this.redis.slowlog('get', 10);
            const keyspaceInfo = await this.redis.info('keyspace');
            const statsInfo = await this.redis.info('stats');
            
            return {
                slowQueries: slowlog.length,
                avgResponseTime: this.calculateAvgResponseTime(slowlog),
                commandsPerSecond: await this.getCommandsPerSecond(),
                memoryUsage: await this.getMemoryUsagePercent(),
                keyspaceHits: await this.getKeyspaceHitRatio(),
                clientConnections: await this.getClientCount(),
                responseTime: 50 // Mock value for demo
            };
        } catch (error) {
            this.logger.error('Performance metrics collection failed', { error: error.message });
            throw error;
        }
    }
    
    // Helper methods
    parseMemoryInfo(memoryInfo) {
        const lines = memoryInfo.split('\r\n');
        const memory = {};
        lines.forEach(line => {
            if (line.includes(':')) {
                const [key, value] = line.split(':');
                memory[key] = value;
            }
        });
        return memory;
    }
    
    async countActiveSessions() {
        // Use SCAN instead of KEYS to avoid blocking Redis in production
        let cursor = '0';
        let count = 0;
        do {
            const result = await this.redis.scan(cursor, 'MATCH', 'session:*', 'COUNT', 100);
            cursor = result[0];
            count += result[1].length;
        } while (cursor !== '0');
        return count;
    }
    
    async calculateCacheEfficiency() {
        const hits = parseInt(await this.redis.hget('cache:stats', 'hits') || 0);
        const misses = parseInt(await this.redis.hget('cache:stats', 'misses') || 0);
        const total = hits + misses;
        return total > 0 ? ((hits / total) * 100).toFixed(2) : 0;
    }
    
    async getTransactionVolume() {
        return parseInt(await this.redis.get('metrics:transactions:total') || 0);
    }
    
    async calculateErrorRate() {
        const errors = parseInt(await this.redis.get('metrics:errors:total') || 0);
        const total = parseInt(await this.redis.get('metrics:requests:total') || 1);
        return ((errors / total) * 100).toFixed(2);
    }
    
    calculateAvgResponseTime(slowlog) {
        if (slowlog.length === 0) return 0;
        const totalTime = slowlog.reduce((sum, entry) => sum + entry[2], 0);
        return (totalTime / slowlog.length / 1000).toFixed(2); // Convert to ms
    }
    
    async getCommandsPerSecond() {
        const stats = await this.redis.info('stats');
        const commandsProcessed = stats.match(/total_commands_processed:(\d+)/);
        const uptime = stats.match(/uptime_in_seconds:(\d+)/);
        
        if (commandsProcessed && uptime) {
            return (parseInt(commandsProcessed[1]) / parseInt(uptime[1])).toFixed(2);
        }
        return 0;
    }
    
    async getMemoryUsagePercent() {
        const info = await this.redis.info('memory');
        const usedMemory = info.match(/used_memory:(\d+)/);
        const maxMemory = info.match(/maxmemory:(\d+)/);
        
        if (usedMemory && maxMemory && parseInt(maxMemory[1]) > 0) {
            return ((parseInt(usedMemory[1]) / parseInt(maxMemory[1])) * 100).toFixed(2);
        }
        // Return mock value if maxmemory not set
        return 45;
    }
    
    async getKeyspaceHitRatio() {
        const stats = await this.redis.info('stats');
        const hits = stats.match(/keyspace_hits:(\d+)/);
        const misses = stats.match(/keyspace_misses:(\d+)/);
        
        if (hits && misses) {
            const totalRequests = parseInt(hits[1]) + parseInt(misses[1]);
            if (totalRequests > 0) {
                return ((parseInt(hits[1]) / totalRequests) * 100).toFixed(2);
            }
        }
        return 0;
    }
    
    async getClientCount() {
        const clients = await this.redis.info('clients');
        const connected = clients.match(/connected_clients:(\d+)/);
        return connected ? parseInt(connected[1]) : 0;
    }
    
    async start(port = 3000) {
        return new Promise((resolve) => {
            this.server = this.app.listen(port, () => {
                console.log(`🔍 Health Check Service running on port ${port}`);
                console.log(`📊 Health endpoint: http://localhost:${port}/health`);
                console.log(`📈 Business metrics: http://localhost:${port}/health/business`);
                console.log(`⚡ Performance metrics: http://localhost:${port}/health/performance`);
                resolve();
            });
        });
    }
    
    async stop() {
        if (this.server) {
            this.server.close();
        }
        await this.redis.disconnect();
    }
}

module.exports = HealthCheckService;