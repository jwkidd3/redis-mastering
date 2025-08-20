# Lab 14: Monitoring & Health Checks for Production Operations

**Duration:** 45 minutes  
**Objective:** Set up comprehensive monitoring for production Redis operations, implement health checks, and create alerting systems for production environments

## 🎯 Learning Objectives

By the end of this lab, you will be able to:
- Configure Redis Insight for production monitoring of business operations
- Set up comprehensive performance metric collection for production workloads
- Create custom health check endpoints for policy, claims, and customer systems
- Monitor key business metrics (data lookups, transaction submissions, user sessions)
- Set up alerting for critical thresholds in production operations
- Build monitoring dashboards for business stakeholders
- Implement automated health reporting for compliance requirements

---

## 📋 Prerequisites

- Docker installed and running
- Node.js 18+ and npm installed
- Redis Insight installed
- Visual Studio Code with Redis extension
- Completion of Labs 1-13 (caching patterns and production configuration)
- Understanding of business metrics and SLAs

---

## Part 1: Production Monitoring Setup (15 minutes)

### Step 1: Environment Setup

**Important:** Connect to your assigned remote Redis host (replace with actual values provided by instructor).

```bash
# Set connection variables (replace with your assigned values)
export REDIS_HOST="localhost"
export REDIS_PORT="6379"


# Test connection
redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD ping

# Install Node.js dependencies
npm init -y
npm install redis ioredis express node-cron winston

# Load sample business data for monitoring
node scripts/load-production-monitoring-data.js
```

### Step 2: Redis Insight Production Configuration

**Configure Redis Insight for Production Monitoring:**

1. **Open Redis Insight**
2. **Connect to Remote Host:**
   - Host: Your assigned Redis host
   - Port: Your assigned port
   - Password: Your assigned password
   - Name: "Production Monitoring Lab"

3. **Enable Monitoring Features:**
   - Navigate to **Tools > Slowlog**
   - Set slow query threshold: 10ms


---

## Part 2: Health Check Service Implementation (15 minutes)

### Step 3: Core Health Check Service

Create a comprehensive health monitoring service:

```javascript
// File: src/health-check-service.js
const express = require('express');
const Redis = require('ioredis');
const winston = require('winston');

class HealthCheckService {
    constructor() {
        this.app = express();
        this.redis = new Redis({
            host: process.env.REDIS_HOST || 'redis.training.local',
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
                new winston.transports.File({ filename: 'logs/health-checks.log' }),
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
                clientConnections: await this.getClientCount()
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
        const sessionKeys = await this.redis.keys('session:*');
        return sessionKeys.length;
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
        return 0;
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
```

---

## Part 3: Alerting System Implementation (15 minutes)

### Step 4: Production Alerting System

```javascript
// File: src/alerting-system.js
const cron = require('node-cron');
const winston = require('winston');

class ProductionAlertingSystem {
    constructor(monitoring) {
        this.monitoring = monitoring;
        this.alerts = [];
        this.alertThresholds = {
            responseTime: 100, // ms
            memoryUsage: 80, // percentage
            errorRate: 5, // percentage
            cacheEfficiency: 85, // percentage
            slowQueries: 10, // count per check
            clientConnections: 100
        };
        
        this.logger = winston.createLogger({
            level: 'info',
            format: winston.format.combine(
                winston.format.timestamp(),
                winston.format.json()
            ),
            transports: [
                new winston.transports.File({ filename: 'logs/alerts.log' }),
                new winston.transports.Console()
            ]
        });
        
        this.startMonitoring();
    }
    
    startMonitoring() {
        // Check every minute for critical issues
        cron.schedule('* * * * *', async () => {
            await this.checkCriticalMetrics();
        });
        
        // Check every 5 minutes for performance issues
        cron.schedule('*/5 * * * *', async () => {
            await this.checkPerformanceMetrics();
        });
        
        // Generate hourly summary reports
        cron.schedule('0 * * * *', async () => {
            await this.generateHourlySummary();
        });
        
        console.log('🚨 Alerting system started');
        console.log('📊 Monitoring schedules:');
        console.log('   • Critical checks: Every minute');
        console.log('   • Performance checks: Every 5 minutes');
        console.log('   • Summary reports: Every hour');
    }
    
    async checkCriticalMetrics() {
        try {
            const health = await this.monitoring.getComprehensiveHealth();
            
            // Check Redis connectivity
            if (health.redis.status !== 'healthy') {
                this.triggerAlert('CRITICAL', 'Redis connectivity lost', {
                    error: health.redis.error,
                    timestamp: new Date().toISOString()
                });
            }
            
            // Check response time
            if (health.redis.responseTime > this.alertThresholds.responseTime) {
                this.triggerAlert('WARNING', 'High Redis response time', {
                    responseTime: health.redis.responseTime,
                    threshold: this.alertThresholds.responseTime
                });
            }
            
            // Check error rate
            if (parseFloat(health.business.errorRate) > this.alertThresholds.errorRate) {
                this.triggerAlert('WARNING', 'High error rate detected', {
                    errorRate: health.business.errorRate,
                    threshold: this.alertThresholds.errorRate
                });
            }
            
        } catch (error) {
            this.triggerAlert('CRITICAL', 'Monitoring system failure', {
                error: error.message
            });
        }
    }
    
    async checkPerformanceMetrics() {
        try {
            const performance = await this.monitoring.getPerformanceMetrics();
            
            // Check memory usage
            if (parseFloat(performance.memoryUsage) > this.alertThresholds.memoryUsage) {
                this.triggerAlert('WARNING', 'High memory usage', {
                    memoryUsage: performance.memoryUsage,
                    threshold: this.alertThresholds.memoryUsage
                });
            }
            
            // Check slow queries
            if (performance.slowQueries > this.alertThresholds.slowQueries) {
                this.triggerAlert('INFO', 'Elevated slow query count', {
                    slowQueries: performance.slowQueries,
                    threshold: this.alertThresholds.slowQueries
                });
            }
            
            // Check cache efficiency
            const business = await this.monitoring.getBusinessMetrics();
            if (parseFloat(business.cacheEfficiency) < this.alertThresholds.cacheEfficiency) {
                this.triggerAlert('WARNING', 'Low cache efficiency', {
                    cacheEfficiency: business.cacheEfficiency,
                    threshold: this.alertThresholds.cacheEfficiency
                });
            }
            
        } catch (error) {
            this.logger.error('Performance metrics check failed', { error: error.message });
        }
    }
    
    triggerAlert(severity, message, data = {}) {
        const alert = {
            id: `alert_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
            severity,
            message,
            data,
            timestamp: new Date().toISOString(),
            acknowledged: false
        };
        
        this.alerts.push(alert);
        
        // Log alert
        this.logger.log(severity.toLowerCase(), `ALERT: ${message}`, alert);
        
        // Keep only last 100 alerts
        if (this.alerts.length > 100) {
            this.alerts = this.alerts.slice(-100);
        }
        
        // Send notifications (in production, integrate with email/Slack/PagerDuty)
        this.sendNotification(alert);
        
        return alert;
    }
    
    sendNotification(alert) {
        // In production, integrate with your notification system
        console.log(`🚨 ${alert.severity}: ${alert.message}`);
        
        if (alert.severity === 'CRITICAL') {
            console.log('🔥 CRITICAL ALERT - Immediate action required!');
        }
    }
    
    async generateHourlySummary() {
        try {
            const now = new Date();
            const oneHourAgo = new Date(now.getTime() - 60 * 60 * 1000);
            
            const recentAlerts = this.alerts.filter(alert => 
                new Date(alert.timestamp) > oneHourAgo
            );
            
            const alertsBySeverity = recentAlerts.reduce((acc, alert) => {
                acc[alert.severity] = (acc[alert.severity] || 0) + 1;
                return acc;
            }, {});
            
            const health = await this.monitoring.getComprehensiveHealth();
            
            const summary = {
                timestamp: now.toISOString(),
                period: 'Last 1 hour',
                alertsSummary: alertsBySeverity,
                currentHealth: {
                    status: health.status,
                    redisResponseTime: health.redis.responseTime,
                    memoryUsage: health.performance?.memoryUsage || 'N/A',
                    activeSessions: health.business?.activeSessions || 0,
                    cacheEfficiency: health.business?.cacheEfficiency || 'N/A'
                },
                totalAlerts: recentAlerts.length
            };
            
            this.logger.info('Hourly monitoring summary', summary);
            
            return summary;
            
        } catch (error) {
            this.logger.error('Failed to generate hourly summary', { error: error.message });
        }
    }
    
    getRecentAlerts(count = 10) {
        return this.alerts.slice(-count).reverse();
    }
    
    acknowledgeAlert(alertId) {
        const alert = this.alerts.find(a => a.id === alertId);
        if (alert) {
            alert.acknowledged = true;
            alert.acknowledgedAt = new Date().toISOString();
            this.logger.info(`Alert acknowledged: ${alertId}`);
            return alert;
        }
        return null;
    }
    
    getAlertStats() {
        const last24Hours = this.alerts.filter(alert => 
            new Date(alert.timestamp) > new Date(Date.now() - 24 * 60 * 60 * 1000)
        );
        
        const statsBySeverity = last24Hours.reduce((acc, alert) => {
            acc[alert.severity] = (acc[alert.severity] || 0) + 1;
            return acc;
        }, {});
        
        return {
            last24Hours: last24Hours.length,
            statsBySeverity,
            acknowledged: last24Hours.filter(a => a.acknowledged).length,
            unacknowledged: last24Hours.filter(a => !a.acknowledged).length
        };
    }
}

module.exports = ProductionAlertingSystem;
```

---

## Part 4: Monitoring Dashboard (Optional Enhancement)

### Step 5: Real-time Monitoring Dashboard

```javascript
// File: src/monitoring-dashboard.js
const express = require('express');
const path = require('path');

class MonitoringDashboard {
    constructor(monitoring, alerting) {
        this.monitoring = monitoring;
        this.alerting = alerting;
        this.app = express();
        
        this.setupRoutes();
    }
    
    setupRoutes() {
        // Serve static dashboard files
        this.app.use(express.static(path.join(__dirname, '../dashboards')));
        
        // API endpoints for dashboard data
        this.app.get('/api/metrics/realtime', async (req, res) => {
            try {
                const [health, performance, business] = await Promise.all([
                    this.monitoring.getComprehensiveHealth(),
                    this.monitoring.getPerformanceMetrics(),
                    this.monitoring.getBusinessMetrics()
                ]);
                
                res.json({
                    timestamp: new Date().toISOString(),
                    health,
                    performance,
                    business,
                    alerts: this.alerting.getRecentAlerts(5)
                });
            } catch (error) {
                res.status(500).json({ error: error.message });
            }
        });
        
        // Alert management endpoints
        this.app.get('/api/alerts', (req, res) => {
            const count = parseInt(req.query.count) || 20;
            res.json(this.alerting.getRecentAlerts(count));
        });
        
        this.app.get('/api/alerts/stats', (req, res) => {
            res.json(this.alerting.getAlertStats());
        });
        
        this.app.post('/api/alerts/:id/acknowledge', (req, res) => {
            const alert = this.alerting.acknowledgeAlert(req.params.id);
            if (alert) {
                res.json(alert);
            } else {
                res.status(404).json({ error: 'Alert not found' });
            }
        });
    }
    
    start(port = 4000) {
        this.server = this.app.listen(port, () => {
            console.log(`📊 Monitoring Dashboard running on port ${port}`);
            console.log(`🔗 Dashboard URL: http://localhost:${port}`);
            console.log(`📡 Real-time API: http://localhost:${port}/api/metrics/realtime`);
        });
    }
    
    stop() {
        if (this.server) {
            this.server.close();
        }
    }
}

module.exports = MonitoringDashboard;
```

---

## Part 5: Integration and Testing

### Step 6: Load Sample Data for Monitoring

```javascript
// File: scripts/load-production-monitoring-data.js
const Redis = require('ioredis');

class ProductionMonitoringDataLoader {
    constructor() {
        this.redis = new Redis({
            host: process.env.REDIS_HOST || 'redis.training.local',
            port: process.env.REDIS_PORT || 6379,
            password: process.env.REDIS_PASSWORD,
            retryDelayOnFailover: 100
        });
    }
    
    async loadData() {
        console.log('🔄 Loading production monitoring data...');
        
        try {
            // Clear existing data
            await this.redis.flushdb();
            
            // Load business data for monitoring
            await this.loadBusinessData();
            
            // Initialize monitoring counters
            await this.initializeCounters();
            
            // Create sample sessions
            await this.createSampleSessions();
            
            // Load test cache data
            await this.loadCacheTestData();
            
            console.log('✅ Production monitoring data loaded successfully');
            
            // Display data summary
            await this.displayDataSummary();
            
        } catch (error) {
            console.error('❌ Failed to load monitoring data:', error.message);
            throw error;
        } finally {
            await this.redis.disconnect();
        }
    }
    
    async loadBusinessData() {
        console.log('📊 Loading business transaction data...');
        
        // Sample business entities
        const entities = [
            { id: 'ENT001', name: 'Policy Management', status: 'active', priority: 'high' },
            { id: 'ENT002', name: 'Claims Processing', status: 'active', priority: 'critical' },
            { id: 'ENT003', name: 'Customer Service', status: 'active', priority: 'medium' },
            { id: 'ENT004', name: 'Billing System', status: 'maintenance', priority: 'high' },
            { id: 'ENT005', name: 'Reporting Engine', status: 'active', priority: 'low' }
        ];
        
        for (const entity of entities) {
            await this.redis.hset(`entity:${entity.id}`, entity);
            await this.redis.sadd('entities:active', entity.id);
        }
        
        console.log(`   ✓ Loaded ${entities.length} business entities`);
    }
    
    async initializeCounters() {
        console.log('🔢 Initializing monitoring counters...');
        
        // Initialize cache statistics
        await this.redis.hset('cache:stats', {
            hits: Math.floor(Math.random() * 1000) + 500,
            misses: Math.floor(Math.random() * 200) + 50,
            lastReset: new Date().toISOString()
        });
        
        // Initialize business metrics
        await this.redis.set('metrics:transactions:total', Math.floor(Math.random() * 5000) + 1000);
        await this.redis.set('metrics:requests:total', Math.floor(Math.random() * 10000) + 5000);
        await this.redis.set('metrics:errors:total', Math.floor(Math.random() * 50) + 10);
        
        console.log('   ✓ Monitoring counters initialized');
    }
    
    async createSampleSessions() {
        console.log('👥 Creating sample user sessions...');
        
        const sessionCount = Math.floor(Math.random() * 50) + 20;
        
        for (let i = 0; i < sessionCount; i++) {
            const sessionId = `session:user_${1000 + i}`;
            const sessionData = {
                userId: `user_${1000 + i}`,
                startTime: new Date(Date.now() - Math.random() * 3600000).toISOString(),
                lastActivity: new Date().toISOString(),
                ipAddress: `192.168.1.${Math.floor(Math.random() * 254) + 1}`,
                userAgent: 'ProductionApp/1.0',
                authenticated: true
            };
            
            await this.redis.hset(sessionId, sessionData);
            await this.redis.expire(sessionId, 3600); // 1 hour expiry
        }
        
        console.log(`   ✓ Created ${sessionCount} active sessions`);
    }
    
    async loadCacheTestData() {
        console.log('💾 Loading cache test data...');
        
        // Load frequently accessed data
        const frequentData = [
            'config:app:version',
            'config:app:features',
            'config:db:settings',
            'config:api:endpoints',
            'config:ui:preferences'
        ];
        
        for (const key of frequentData) {
            await this.redis.set(key, JSON.stringify({
                value: `data_${key}`,
                lastModified: new Date().toISOString(),
                accessCount: Math.floor(Math.random() * 100) + 10
            }));
        }
        
        // Load business lookup data
        for (let i = 1; i <= 100; i++) {
            await this.redis.hset(`lookup:entity:${i}`, {
                id: i,
                name: `Entity ${i}`,
                type: ['policy', 'claim', 'customer'][i % 3],
                status: 'active',
                lastAccessed: new Date().toISOString()
            });
        }
        
        console.log('   ✓ Cache test data loaded');
    }
    
    async displayDataSummary() {
        console.log('\n📋 Data Summary:');
        
        // Count different data types
        const entityCount = await this.redis.scard('entities:active');
        const sessionCount = (await this.redis.keys('session:*')).length;
        const cacheKeys = await this.redis.keys('config:*');
        const lookupKeys = await this.redis.keys('lookup:*');
        
        console.log(`   • Business Entities: ${entityCount}`);
        console.log(`   • Active Sessions: ${sessionCount}`);
        console.log(`   • Configuration Cache: ${cacheKeys.length} keys`);
        console.log(`   • Lookup Data: ${lookupKeys.length} entries`);
        
        // Show cache efficiency
        const cacheStats = await this.redis.hgetall('cache:stats');
        const efficiency = cacheStats.hits && cacheStats.misses ? 
            ((parseInt(cacheStats.hits) / (parseInt(cacheStats.hits) + parseInt(cacheStats.misses))) * 100).toFixed(2) : 'N/A';
        console.log(`   • Cache Efficiency: ${efficiency}%`);
        
        // Show memory usage
        const memInfo = await this.redis.info('memory');
        const memUsed = memInfo.split('\r\n').find(line => line.startsWith('used_memory_human:'))?.split(':')[1]?.trim();
        console.log(`   • Memory Usage: ${memUsed || 'N/A'}`);
        
        console.log('\n✅ Ready for Lab 14 monitoring exercises!');
    }
}

// Run the data loader
async function main() {
    const loader = new ProductionMonitoringDataLoader();
    await loader.loadData();
}

if (require.main === module) {
    main().catch(console.error);
}

module.exports = ProductionMonitoringDataLoader;
```

### Step 7: Main Application Integration

```javascript
// File: src/main.js
const HealthCheckService = require('./health-check-service');
const ProductionAlertingSystem = require('./alerting-system');
const MonitoringDashboard = require('./monitoring-dashboard');

async function startProductionMonitoring() {
    console.log('🚀 Starting Production Redis Monitoring System...');
    
    // Initialize health check service
    const healthService = new HealthCheckService();
    
    // Initialize alerting system
    const alerting = new ProductionAlertingSystem(healthService);
    
    // Start health check service
    await healthService.start(3000);
    
    // Start monitoring dashboard
    const dashboard = new MonitoringDashboard(healthService, alerting);
    dashboard.start(4000);
    
    console.log('✅ Production monitoring system started successfully');
    console.log('📊 Services running:');
    console.log('   • Health Check API: http://localhost:3000/health');
    console.log('   • Monitoring Dashboard: http://localhost:4000');
    console.log('   • Redis Insight: (configured separately)');
    
    // Graceful shutdown
    process.on('SIGINT', async () => {
        console.log('\n🛑 Shutting down monitoring system...');
        await healthService.stop();
        dashboard.stop();
        process.exit(0);
    });
}

// Start the monitoring system
if (require.main === module) {
    startProductionMonitoring().catch(console.error);
}

module.exports = {
    HealthCheckService,
    ProductionAlertingSystem,
    MonitoringDashboard
};
```

### Step 8: Package Configuration

```json
{
  "name": "lab14-production-monitoring",
  "version": "1.0.0",
  "description": "Lab 14: Monitoring & Health Checks for Production Operations",
  "main": "src/main.js",
  "scripts": {
    "start": "node src/main.js",
    "dev": "nodemon src/main.js",
    "test": "npm run test:health && npm run test:monitoring",
    "test:health": "curl -f http://localhost:3000/health || exit 1",
    "test:monitoring": "curl -f http://localhost:4000/api/metrics/realtime || exit 1",
    "load-data": "node scripts/load-production-monitoring-data.js",
    "setup": "npm install && npm run load-data"
  },
  "dependencies": {
    "redis": "^4.6.5",
    "ioredis": "^5.3.1",
    "express": "^4.18.2",
    "node-cron": "^3.0.2",
    "winston": "^3.8.2"
  },
  "devDependencies": {
    "nodemon": "^2.0.20"
  },
  "keywords": ["redis", "monitoring", "production", "health-checks", "alerts"],
  "author": "Production DevOps Team",
  "license": "MIT"
}
```

---

## 📋 Lab Summary

You have successfully completed Lab 14!

You've mastered:

✅ **Production Monitoring Setup:** Comprehensive Redis monitoring for business operations  
✅ **Health Check Implementation:** Custom health endpoints for business systems  
✅ **Alerting System:** Automated alerts for critical business metrics  
✅ **Redis Insight Integration:** Production monitoring dashboard configuration  
✅ **Performance Metrics:** Collection and analysis of business-specific KPIs  
✅ **Business Intelligence:** Business metrics and trend analysis  

## 🎯 Key Skills Developed

- **Production Monitoring:** Set up comprehensive monitoring for Redis operations
- **Health Checks:** Created custom health endpoints for business systems
- **Alerting:** Implemented intelligent alerting based on business and technical thresholds
- **Dashboard Creation:** Built real-time monitoring dashboard for stakeholders
- **Performance Analysis:** Analyzed Redis performance in production environments
- **Business Metrics:** Tracked business-specific KPIs and operational metrics

## 🔄 Testing Your Implementation

```bash
# Start the complete monitoring system
npm start

# Test health endpoints
curl http://localhost:3000/health
curl http://localhost:3000/health/business
curl http://localhost:3000/health/performance

# Access monitoring dashboard
open http://localhost:4000

# Load test data for monitoring
npm run load-data

# Check system logs
tail -f logs/health-checks.log
tail -f logs/alerts.log
```

## 🚀 Next Steps: Lab 15

**Up Next:** Lab 15 - Microservices Integration (45 minutes)
- Implement cross-service caching patterns
- Create service-to-service cache invalidation
- Build event-driven architecture with Redis
- Integrate multiple business services
- Implement distributed session management

**Course Completion:** Lab 14 completes the production monitoring section of the Redis Mastery course!

---

**Excellent work mastering Redis monitoring for production operations!**
