# Lab 14: Monitoring & Health Checks for Insurance Operations

**Duration:** 45 minutes  
**Objective:** Set up comprehensive monitoring for insurance Redis operations, implement health checks, and create alerting systems for production environments

## 🎯 Learning Objectives

By the end of this lab, you will be able to:
- Configure Redis Insight for production monitoring of insurance operations
- Set up comprehensive performance metric collection for insurance workloads
- Create custom health check endpoints for policy, claims, and customer systems
- Monitor key insurance business metrics (policy lookups, claim submissions, customer sessions)
- Set up alerting for critical thresholds in insurance operations
- Build monitoring dashboards for insurance business stakeholders
- Implement automated health reporting for insurance compliance

---

## 📋 Prerequisites

- Docker installed and running
- Node.js 18+ and npm installed
- Redis Insight installed
- Visual Studio Code with Redis extension
- Completion of Labs 1-13 (insurance caching patterns and production configuration)
- Understanding of insurance business metrics and SLAs

---

## Part 1: Production Monitoring Setup (15 minutes)

### Step 1: Environment Setup

```bash
# Start Redis with monitoring configuration
docker run -d --name redis-insurance-monitor \
  -p 6379:6379 \
  -v redis-insurance-data:/data \
  -v $(pwd)/config:/usr/local/etc/redis \
  redis:7-alpine redis-server \
  --appendonly yes \
  --save 900 1 \
  --slowlog-log-slower-than 10000 \
  --slowlog-max-len 128

# Verify Redis is running
docker ps | grep redis-insurance-monitor

# Install Node.js dependencies
npm init -y
npm install redis ioredis express node-cron winston

# Load sample insurance data for monitoring
node scripts/load-insurance-monitoring-data.js
```

### Step 2: Redis Insight Production Configuration

**Configure Redis Insight for Insurance Monitoring:**

1. **Open Redis Insight**
2. **Add Insurance Production Database:**
   - Host: `localhost`
   - Port: `6379`
   - Alias: "Insurance Production Monitor"
   - Enable all monitoring features

3. **Configure Monitoring Settings:**
   - Enable command monitoring
   - Set memory alerts at 80% usage
   - Configure slow query detection (>10ms)
   - Enable key expiration tracking

4. **Create Custom Dashboard:**
   - Insurance KPI widgets
   - Performance metrics panel
   - Error rate monitoring
   - Customer session tracking

### Step 3: Core Monitoring Infrastructure

Create the monitoring foundation:

```javascript
// src/monitoring-core.js
const Redis = require('ioredis');
const winston = require('winston');

class InsuranceMonitoring {
    constructor() {
        this.redis = new Redis({
            host: 'localhost',
            port: 6379,
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
                new winston.transports.File({ filename: 'logs/insurance-monitoring.log' }),
                new winston.transports.Console()
            ]
        });
        
        this.metrics = {
            policyLookups: 0,
            claimSubmissions: 0,
            customerSessions: 0,
            cacheHitRate: 0,
            averageResponseTime: 0,
            errorRate: 0
        };
        
        this.alerts = [];
        this.healthStatus = 'healthy';
    }
    
    // Start monitoring insurance operations
    async startMonitoring() {
        console.log('🔍 Starting insurance Redis monitoring...');
        
        // Monitor Redis connection health
        setInterval(() => this.checkRedisHealth(), 30000); // Every 30 seconds
        
        // Collect performance metrics
        setInterval(() => this.collectPerformanceMetrics(), 60000); // Every minute
        
        // Monitor insurance business metrics
        setInterval(() => this.monitorBusinessMetrics(), 120000); // Every 2 minutes
        
        // Check alert conditions
        setInterval(() => this.checkAlertConditions(), 45000); // Every 45 seconds
        
        this.logger.info('Insurance monitoring system started');
    }
    
    // Check Redis health and connectivity
    async checkRedisHealth() {
        try {
            const start = Date.now();
            await this.redis.ping();
            const responseTime = Date.now() - start;
            
            const info = await this.redis.info();
            const memoryInfo = await this.redis.info('memory');
            const statsInfo = await this.redis.info('stats');
            
            const healthData = {
                timestamp: new Date().toISOString(),
                responseTime,
                memory: this.parseMemoryInfo(memoryInfo),
                stats: this.parseStatsInfo(statsInfo),
                connections: await this.redis.info('clients')
            };
            
            // Log health status
            this.logger.info('Redis health check completed', healthData);
            
            // Update health status
            this.updateHealthStatus(healthData);
            
            return healthData;
            
        } catch (error) {
            this.logger.error('Redis health check failed', { error: error.message });
            this.healthStatus = 'unhealthy';
            this.triggerAlert('redis_connection_failed', error.message);
        }
    }
    
    // Collect comprehensive performance metrics
    async collectPerformanceMetrics() {
        try {
            const info = await this.redis.info();
            const slowlog = await this.redis.slowlog('get', 10);
            
            const metrics = {
                timestamp: new Date().toISOString(),
                commandsProcessed: await this.getCommandCount(),
                memoryUsage: await this.getMemoryUsage(),
                keyspaceInfo: await this.getKeyspaceInfo(),
                slowQueries: slowlog.length,
                avgSlowQueryTime: this.calculateAvgSlowQueryTime(slowlog),
                connectedClients: await this.getConnectedClients(),
                cacheHitRatio: await this.calculateCacheHitRatio()
            };
            
            // Store metrics for trend analysis
            await this.storeMetrics(metrics);
            
            this.logger.info('Performance metrics collected', metrics);
            
            return metrics;
            
        } catch (error) {
            this.logger.error('Failed to collect performance metrics', { error: error.message });
        }
    }
    
    // Monitor insurance-specific business metrics
    async monitorBusinessMetrics() {
        try {
            const businessMetrics = {
                timestamp: new Date().toISOString(),
                activePolicies: await this.redis.scard('policies:active'),
                pendingClaims: await this.redis.llen('queue:claims:pending'),
                activeSessions: await this.countActiveSessions(),
                quotesGenerated: await this.redis.hget('analytics:daily', 'quotes_generated') || 0,
                policiesCreated: await this.redis.hget('analytics:daily', 'policies_created') || 0,
                claimsProcessed: await this.redis.hget('analytics:daily', 'claims_processed') || 0,
                customerLogins: await this.redis.hget('analytics:daily', 'customer_logins') || 0,
                cacheEfficiency: await this.calculateInsuranceCacheEfficiency()
            };
            
            // Check business metric thresholds
            await this.checkBusinessThresholds(businessMetrics);
            
            // Store business metrics
            await this.storeBusinessMetrics(businessMetrics);
            
            this.logger.info('Insurance business metrics collected', businessMetrics);
            
            return businessMetrics;
            
        } catch (error) {
            this.logger.error('Failed to collect business metrics', { error: error.message });
        }
    }
    
    // Create comprehensive health check endpoint
    async getHealthCheck() {
        const healthData = {
            status: this.healthStatus,
            timestamp: new Date().toISOString(),
            redis: await this.checkRedisHealth(),
            insurance: await this.getInsuranceSystemHealth(),
            alerts: this.alerts.slice(-5), // Last 5 alerts
            uptime: process.uptime(),
            environment: 'production'
        };
        
        return healthData;
    }
    
    // Get insurance system specific health
    async getInsuranceSystemHealth() {
        try {
            return {
                policySystemHealth: await this.checkPolicySystemHealth(),
                claimsSystemHealth: await this.checkClaimsSystemHealth(),
                customerSystemHealth: await this.checkCustomerSystemHealth(),
                cacheSystemHealth: await this.checkCacheSystemHealth()
            };
        } catch (error) {
            this.logger.error('Insurance system health check failed', { error: error.message });
            return { status: 'error', message: error.message };
        }
    }
    
    // Helper methods for monitoring operations
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
    
    async calculateInsuranceCacheEfficiency() {
        const hits = parseInt(await this.redis.hget('cache:stats', 'hits') || 0);
        const misses = parseInt(await this.redis.hget('cache:stats', 'misses') || 0);
        const total = hits + misses;
        return total > 0 ? ((hits / total) * 100).toFixed(2) : 0;
    }
    
    // Alert management
    triggerAlert(type, message) {
        const alert = {
            id: `alert_${Date.now()}`,
            type,
            message,
            timestamp: new Date().toISOString(),
            severity: this.getAlertSeverity(type)
        };
        
        this.alerts.push(alert);
        this.logger.warn('Alert triggered', alert);
        
        // Keep only last 50 alerts
        if (this.alerts.length > 50) {
            this.alerts = this.alerts.slice(-50);
        }
    }
    
    getAlertSeverity(type) {
        const severityMap = {
            'redis_connection_failed': 'critical',
            'high_memory_usage': 'warning',
            'slow_query_detected': 'warning',
            'high_error_rate': 'critical',
            'business_metric_threshold': 'warning'
        };
        return severityMap[type] || 'info';
    }
}

module.exports = InsuranceMonitoring;
```

---

## Part 2: Health Check Implementation (15 minutes)

### Step 1: Create Health Check Service

```javascript
// src/health-check-service.js
const express = require('express');
const InsuranceMonitoring = require('./monitoring-core');

class HealthCheckService {
    constructor() {
        this.app = express();
        this.monitoring = new InsuranceMonitoring();
        this.setupRoutes();
    }
    
    setupRoutes() {
        // Basic health endpoint
        this.app.get('/health', async (req, res) => {
            try {
                const health = await this.monitoring.getHealthCheck();
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
        
        // Detailed insurance metrics endpoint
        this.app.get('/health/insurance', async (req, res) => {
            try {
                const metrics = await this.monitoring.monitorBusinessMetrics();
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
                const performance = await this.monitoring.collectPerformanceMetrics();
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
                const redisHealth = await this.monitoring.checkRedisHealth();
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
        
        // Alerts endpoint
        this.app.get('/health/alerts', (req, res) => {
            res.json({
                status: 'success',
                alerts: this.monitoring.alerts,
                alertCount: this.monitoring.alerts.length,
                timestamp: new Date().toISOString()
            });
        });
        
        // Metrics history endpoint
        this.app.get('/health/history', async (req, res) => {
            try {
                const hours = parseInt(req.query.hours) || 24;
                const history = await this.getMetricsHistory(hours);
                res.json({
                    status: 'success',
                    data: history,
                    period: `${hours} hours`,
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
    
    async start(port = 3000) {
        await this.monitoring.startMonitoring();
        
        this.app.listen(port, () => {
            console.log(`🏥 Insurance Health Check Service running on port ${port}`);
            console.log(`📊 Health endpoints available:`);
            console.log(`   • http://localhost:${port}/health`);
            console.log(`   • http://localhost:${port}/health/insurance`);
            console.log(`   • http://localhost:${port}/health/performance`);
            console.log(`   • http://localhost:${port}/health/redis`);
            console.log(`   • http://localhost:${port}/health/alerts`);
            console.log(`   • http://localhost:${port}/health/history`);
        });
    }
    
    async getMetricsHistory(hours) {
        // Implementation to retrieve historical metrics
        const endTime = Date.now();
        const startTime = endTime - (hours * 60 * 60 * 1000);
        
        // This would typically query a time-series database
        // For demo purposes, we'll return sample data structure
        return {
            timeRange: { start: new Date(startTime), end: new Date(endTime) },
            metrics: {
                memoryUsage: [], // Historical memory usage
                commandRate: [], // Commands per second over time
                cacheHitRate: [], // Cache efficiency over time
                businessMetrics: [] // Insurance KPIs over time
            }
        };
    }
}

module.exports = HealthCheckService;
```

### Step 2: Alerting System Implementation

```javascript
// src/alerting-system.js
const cron = require('node-cron');
const winston = require('winston');

class InsuranceAlertingSystem {
    constructor(monitoring) {
        this.monitoring = monitoring;
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
        
        this.thresholds = {
            memoryUsage: 85, // 85% memory usage
            responseTime: 1000, // 1 second response time
            errorRate: 5, // 5% error rate
            slowQueryCount: 10, // 10 slow queries per minute
            cacheHitRate: 70, // Below 70% cache hit rate
            activeSessions: 1000, // More than 1000 active sessions
            pendingClaims: 100 // More than 100 pending claims
        };
        
        this.setupAlertSchedules();
    }
    
    setupAlertSchedules() {
        // Check critical metrics every minute
        cron.schedule('* * * * *', () => {
            this.checkCriticalAlerts();
        });
        
        // Generate hourly reports
        cron.schedule('0 * * * *', () => {
            this.generateHourlyReport();
        });
        
        // Daily insurance business summary
        cron.schedule('0 9 * * *', () => {
            this.generateDailyInsuranceSummary();
        });
    }
    
    async checkCriticalAlerts() {
        try {
            // Check Redis performance alerts
            await this.checkRedisPerformanceAlerts();
            
            // Check insurance business alerts
            await this.checkInsuranceBusinessAlerts();
            
            // Check system resource alerts
            await this.checkSystemResourceAlerts();
            
        } catch (error) {
            this.logger.error('Alert checking failed', { error: error.message });
        }
    }
    
    async checkRedisPerformanceAlerts() {
        const performance = await this.monitoring.collectPerformanceMetrics();
        
        // Memory usage alert
        if (performance.memoryUsage > this.thresholds.memoryUsage) {
            this.sendAlert('high_memory_usage', {
                current: performance.memoryUsage,
                threshold: this.thresholds.memoryUsage,
                message: `Redis memory usage is ${performance.memoryUsage}%, exceeding threshold of ${this.thresholds.memoryUsage}%`
            });
        }
        
        // Slow query alert
        if (performance.slowQueries > this.thresholds.slowQueryCount) {
            this.sendAlert('slow_query_detected', {
                count: performance.slowQueries,
                threshold: this.thresholds.slowQueryCount,
                message: `${performance.slowQueries} slow queries detected in the last minute`
            });
        }
        
        // Cache hit rate alert
        if (performance.cacheHitRatio < this.thresholds.cacheHitRate) {
            this.sendAlert('low_cache_hit_rate', {
                current: performance.cacheHitRatio,
                threshold: this.thresholds.cacheHitRate,
                message: `Cache hit rate is ${performance.cacheHitRatio}%, below threshold of ${this.thresholds.cacheHitRate}%`
            });
        }
    }
    
    async checkInsuranceBusinessAlerts() {
        const business = await this.monitoring.monitorBusinessMetrics();
        
        // High pending claims alert
        if (business.pendingClaims > this.thresholds.pendingClaims) {
            this.sendAlert('high_pending_claims', {
                count: business.pendingClaims,
                threshold: this.thresholds.pendingClaims,
                message: `${business.pendingClaims} claims pending processing, exceeding threshold of ${this.thresholds.pendingClaims}`
            });
        }
        
        // High active sessions alert
        if (business.activeSessions > this.thresholds.activeSessions) {
            this.sendAlert('high_session_count', {
                count: business.activeSessions,
                threshold: this.thresholds.activeSessions,
                message: `${business.activeSessions} active sessions, exceeding threshold of ${this.thresholds.activeSessions}`
            });
        }
    }
    
    sendAlert(type, details) {
        const alert = {
            id: `alert_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
            type,
            severity: this.getAlertSeverity(type),
            timestamp: new Date().toISOString(),
            details,
            environment: 'production',
            service: 'insurance-redis'
        };
        
        // Log the alert
        this.logger.warn('Alert triggered', alert);
        
        // Store alert in Redis for dashboard
        this.storeAlert(alert);
        
        // Send notifications based on severity
        this.sendNotification(alert);
        
        return alert;
    }
    
    async storeAlert(alert) {
        try {
            // Store in Redis for real-time dashboard
            await this.monitoring.redis.lpush('alerts:recent', JSON.stringify(alert));
            await this.monitoring.redis.ltrim('alerts:recent', 0, 99); // Keep last 100 alerts
            
            // Store in time-series for historical analysis
            const timestamp = Math.floor(Date.now() / 1000);
            await this.monitoring.redis.zadd('alerts:timeline', timestamp, JSON.stringify(alert));
            
        } catch (error) {
            this.logger.error('Failed to store alert', { error: error.message, alert });
        }
    }
    
    sendNotification(alert) {
        // Implementation would integrate with notification systems
        // For demo purposes, we'll log different notification types
        
        switch (alert.severity) {
            case 'critical':
                console.log(`🚨 CRITICAL ALERT: ${alert.details.message}`);
                // Would send to PagerDuty, SMS, etc.
                break;
            case 'warning':
                console.log(`⚠️  WARNING: ${alert.details.message}`);
                // Would send to Slack, email, etc.
                break;
            case 'info':
                console.log(`ℹ️  INFO: ${alert.details.message}`);
                // Would log to dashboard only
                break;
        }
    }
    
    getAlertSeverity(type) {
        const severityMap = {
            'high_memory_usage': 'critical',
            'slow_query_detected': 'warning',
            'low_cache_hit_rate': 'warning',
            'high_pending_claims': 'critical',
            'high_session_count': 'warning',
            'redis_connection_failed': 'critical'
        };
        return severityMap[type] || 'info';
    }
    
    async generateHourlyReport() {
        const report = {
            timestamp: new Date().toISOString(),
            period: 'hourly',
            performance: await this.monitoring.collectPerformanceMetrics(),
            business: await this.monitoring.monitorBusinessMetrics(),
            alerts: await this.getRecentAlerts(60), // Last hour
            summary: await this.generatePerformanceSummary()
        };
        
        this.logger.info('Hourly monitoring report generated', report);
        
        // Store report for historical analysis
        await this.storeReport('hourly', report);
    }
    
    async generateDailyInsuranceSummary() {
        const summary = {
            date: new Date().toISOString().split('T')[0],
            totalPolicies: await this.monitoring.redis.scard('policies:active'),
            newPolicies: await this.monitoring.redis.hget('analytics:daily', 'policies_created') || 0,
            claimsProcessed: await this.monitoring.redis.hget('analytics:daily', 'claims_processed') || 0,
            customerLogins: await this.monitoring.redis.hget('analytics:daily', 'customer_logins') || 0,
            systemUptime: process.uptime(),
            alerts: await this.getRecentAlerts(1440), // Last 24 hours
            performance: await this.getDailyPerformanceAverage()
        };
        
        console.log('📊 Daily Insurance Summary Generated:');
        console.log(`   • Total Active Policies: ${summary.totalPolicies}`);
        console.log(`   • New Policies Today: ${summary.newPolicies}`);
        console.log(`   • Claims Processed: ${summary.claimsProcessed}`);
        console.log(`   • Customer Logins: ${summary.customerLogins}`);
        console.log(`   • System Uptime: ${(summary.systemUptime / 3600).toFixed(2)} hours`);
        console.log(`   • Alerts in 24h: ${summary.alerts.length}`);
        
        await this.storeReport('daily', summary);
    }
}

module.exports = InsuranceAlertingSystem;
```

---

## Part 3: Advanced Monitoring Dashboard (15 minutes)

### Step 1: Create Monitoring Dashboard

```javascript
// src/monitoring-dashboard.js
const express = require('express');
const path = require('path');

class MonitoringDashboard {
    constructor(monitoring, alerting) {
        this.app = express();
        this.monitoring = monitoring;
        this.alerting = alerting;
        this.setupMiddleware();
        this.setupRoutes();
    }
    
    setupMiddleware() {
        this.app.use(express.static('dashboards'));
        this.app.use(express.json());
    }
    
    setupRoutes() {
        // Dashboard home page
        this.app.get('/', (req, res) => {
            res.sendFile(path.join(__dirname, '../dashboards/index.html'));
        });
        
        // Real-time metrics API
        this.app.get('/api/metrics/realtime', async (req, res) => {
            try {
                const data = {
                    redis: await this.monitoring.checkRedisHealth(),
                    performance: await this.monitoring.collectPerformanceMetrics(),
                    business: await this.monitoring.monitorBusinessMetrics(),
                    alerts: this.monitoring.alerts.slice(-10),
                    timestamp: new Date().toISOString()
                };
                res.json(data);
            } catch (error) {
                res.status(500).json({ error: error.message });
            }
        });
        
        // Historical data API
        this.app.get('/api/metrics/history', async (req, res) => {
            try {
                const hours = parseInt(req.query.hours) || 24;
                const history = await this.getHistoricalMetrics(hours);
                res.json(history);
            } catch (error) {
                res.status(500).json({ error: error.message });
            }
        });
        
        // Insurance KPIs API
        this.app.get('/api/insurance/kpis', async (req, res) => {
            try {
                const kpis = await this.getInsuranceKPIs();
                res.json(kpis);
            } catch (error) {
                res.status(500).json({ error: error.message });
            }
        });
    }
    
    async getInsuranceKPIs() {
        return {
            policies: {
                total: await this.monitoring.redis.scard('policies:active'),
                newToday: await this.monitoring.redis.hget('analytics:daily', 'policies_created') || 0,
                renewalsToday: await this.monitoring.redis.hget('analytics:daily', 'policies_renewed') || 0
            },
            claims: {
                pending: await this.monitoring.redis.llen('queue:claims:pending'),
                processedToday: await this.monitoring.redis.hget('analytics:daily', 'claims_processed') || 0,
                averageProcessingTime: await this.getAverageClaimProcessingTime()
            },
            customers: {
                activeToday: await this.monitoring.redis.hget('analytics:daily', 'active_customers') || 0,
                loginsToday: await this.monitoring.redis.hget('analytics:daily', 'customer_logins') || 0,
                activeSessions: await this.monitoring.countActiveSessions()
            },
            performance: {
                cacheHitRate: await this.monitoring.calculateInsuranceCacheEfficiency(),
                averageResponseTime: await this.getAverageResponseTime(),
                systemUptime: process.uptime()
            }
        };
    }
    
    start(port = 4000) {
        this.app.listen(port, () => {
            console.log(`📊 Insurance Monitoring Dashboard running on port ${port}`);
            console.log(`🌐 Dashboard URL: http://localhost:${port}`);
            console.log(`📈 Real-time metrics: http://localhost:${port}/api/metrics/realtime`);
            console.log(`📊 Insurance KPIs: http://localhost:${port}/api/insurance/kpis`);
        });
    }
}

module.exports = MonitoringDashboard;
```

### Step 2: Create Dashboard HTML

```html
<!-- dashboards/index.html -->
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Insurance Redis Monitoring Dashboard</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #f5f5f5;
        }
        
        .dashboard {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            max-width: 1400px;
            margin: 0 auto;
        }
        
        .widget {
            background: white;
            border-radius: 8px;
            padding: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        
        .widget h3 {
            margin: 0 0 15px 0;
            color: #333;
            border-bottom: 2px solid #007acc;
            padding-bottom: 5px;
        }
        
        .metric {
            display: flex;
            justify-content: space-between;
            margin: 10px 0;
            padding: 10px;
            background: #f8f9fa;
            border-radius: 4px;
        }
        
        .metric-value {
            font-weight: bold;
            color: #007acc;
        }
        
        .alert {
            padding: 10px;
            margin: 5px 0;
            border-radius: 4px;
            border-left: 4px solid;
        }
        
        .alert.critical {
            background: #fdeaea;
            border-color: #dc3545;
        }
        
        .alert.warning {
            background: #fff3cd;
            border-color: #ffc107;
        }
        
        .status-healthy {
            color: #28a745;
            font-weight: bold;
        }
        
        .status-warning {
            color: #ffc107;
            font-weight: bold;
        }
        
        .status-critical {
            color: #dc3545;
            font-weight: bold;
        }
        
        #refreshIndicator {
            position: fixed;
            top: 20px;
            right: 20px;
            background: #007acc;
            color: white;
            padding: 10px 15px;
            border-radius: 4px;
            display: none;
        }
    </style>
</head>
<body>
    <div id="refreshIndicator">Refreshing...</div>
    
    <h1>🏢 Insurance Redis Monitoring Dashboard</h1>
    
    <div class="dashboard">
        <!-- System Health Widget -->
        <div class="widget">
            <h3>🔍 System Health</h3>
            <div id="systemHealth">
                <div class="metric">
                    <span>Redis Status:</span>
                    <span id="redisStatus" class="metric-value">Loading...</span>
                </div>
                <div class="metric">
                    <span>Response Time:</span>
                    <span id="responseTime" class="metric-value">Loading...</span>
                </div>
                <div class="metric">
                    <span>Memory Usage:</span>
                    <span id="memoryUsage" class="metric-value">Loading...</span>
                </div>
                <div class="metric">
                    <span>Connected Clients:</span>
                    <span id="connectedClients" class="metric-value">Loading...</span>
                </div>
            </div>
        </div>
        
        <!-- Insurance KPIs Widget -->
        <div class="widget">
            <h3>📊 Insurance KPIs</h3>
            <div id="insuranceKPIs">
                <div class="metric">
                    <span>Active Policies:</span>
                    <span id="activePolicies" class="metric-value">Loading...</span>
                </div>
                <div class="metric">
                    <span>Pending Claims:</span>
                    <span id="pendingClaims" class="metric-value">Loading...</span>
                </div>
                <div class="metric">
                    <span>Active Sessions:</span>
                    <span id="activeSessions" class="metric-value">Loading...</span>
                </div>
                <div class="metric">
                    <span>Cache Hit Rate:</span>
                    <span id="cacheHitRate" class="metric-value">Loading...</span>
                </div>
            </div>
        </div>
        
        <!-- Performance Metrics Widget -->
        <div class="widget">
            <h3>⚡ Performance Metrics</h3>
            <canvas id="performanceChart" width="400" height="200"></canvas>
        </div>
        
        <!-- Recent Alerts Widget -->
        <div class="widget">
            <h3>🚨 Recent Alerts</h3>
            <div id="recentAlerts">
                <p>Loading alerts...</p>
            </div>
        </div>
        
        <!-- Business Metrics Chart -->
        <div class="widget">
            <h3>📈 Business Metrics Trend</h3>
            <canvas id="businessChart" width="400" height="200"></canvas>
        </div>
        
        <!-- System Info Widget -->
        <div class="widget">
            <h3>ℹ️ System Information</h3>
            <div id="systemInfo">
                <div class="metric">
                    <span>Uptime:</span>
                    <span id="systemUptime" class="metric-value">Loading...</span>
                </div>
                <div class="metric">
                    <span>Environment:</span>
                    <span id="environment" class="metric-value">Production</span>
                </div>
                <div class="metric">
                    <span>Last Updated:</span>
                    <span id="lastUpdated" class="metric-value">Loading...</span>
                </div>
            </div>
        </div>
    </div>
    
    <script>
        // Dashboard JavaScript implementation
        class InsuranceDashboard {
            constructor() {
                this.charts = {};
                this.refreshInterval = 5000; // 5 seconds
                this.setupCharts();
                this.startAutoRefresh();
                this.loadInitialData();
            }
            
            setupCharts() {
                // Performance Chart
                const perfCtx = document.getElementById('performanceChart').getContext('2d');
                this.charts.performance = new Chart(perfCtx, {
                    type: 'line',
                    data: {
                        labels: [],
                        datasets: [{
                            label: 'Memory Usage (%)',
                            data: [],
                            borderColor: 'rgb(75, 192, 192)',
                            tension: 0.1
                        }, {
                            label: 'Cache Hit Rate (%)',
                            data: [],
                            borderColor: 'rgb(255, 99, 132)',
                            tension: 0.1
                        }]
                    },
                    options: {
                        responsive: true,
                        scales: {
                            y: {
                                beginAtZero: true,
                                max: 100
                            }
                        }
                    }
                });
                
                // Business Metrics Chart
                const bizCtx = document.getElementById('businessChart').getContext('2d');
                this.charts.business = new Chart(bizCtx, {
                    type: 'bar',
                    data: {
                        labels: ['Policies', 'Claims', 'Sessions', 'Logins'],
                        datasets: [{
                            label: 'Count',
                            data: [0, 0, 0, 0],
                            backgroundColor: [
                                'rgba(54, 162, 235, 0.8)',
                                'rgba(255, 99, 132, 0.8)',
                                'rgba(255, 205, 86, 0.8)',
                                'rgba(75, 192, 192, 0.8)'
                            ]
                        }]
                    },
                    options: {
                        responsive: true,
                        scales: {
                            y: {
                                beginAtZero: true
                            }
                        }
                    }
                });
            }
            
            async loadInitialData() {
                await this.updateDashboard();
            }
            
            startAutoRefresh() {
                setInterval(() => {
                    this.updateDashboard();
                }, this.refreshInterval);
            }
            
            async updateDashboard() {
                this.showRefreshIndicator();
                
                try {
                    // Fetch real-time metrics
                    const metricsResponse = await fetch('/api/metrics/realtime');
                    const metrics = await metricsResponse.json();
                    
                    // Fetch insurance KPIs
                    const kpisResponse = await fetch('/api/insurance/kpis');
                    const kpis = await kpisResponse.json();
                    
                    // Update system health
                    this.updateSystemHealth(metrics.redis, metrics.performance);
                    
                    // Update insurance KPIs
                    this.updateInsuranceKPIs(metrics.business, kpis);
                    
                    // Update charts
                    this.updateCharts(metrics.performance, metrics.business);
                    
                    // Update alerts
                    this.updateAlerts(metrics.alerts);
                    
                    // Update system info
                    this.updateSystemInfo(metrics.timestamp);
                    
                } catch (error) {
                    console.error('Failed to update dashboard:', error);
                } finally {
                    this.hideRefreshIndicator();
                }
            }
            
            updateSystemHealth(redis, performance) {
                document.getElementById('redisStatus').textContent = redis ? 'Healthy' : 'Unhealthy';
                document.getElementById('redisStatus').className = `metric-value status-${redis ? 'healthy' : 'critical'}`;
                
                if (redis) {
                    document.getElementById('responseTime').textContent = `${redis.responseTime}ms`;
                    document.getElementById('connectedClients').textContent = redis.connections || 'N/A';
                }
                
                if (performance) {
                    document.getElementById('memoryUsage').textContent = `${performance.memoryUsage || 0}%`;
                }
            }
            
            updateInsuranceKPIs(business, kpis) {
                if (business) {
                    document.getElementById('activePolicies').textContent = business.activePolicies || 0;
                    document.getElementById('pendingClaims').textContent = business.pendingClaims || 0;
                    document.getElementById('activeSessions').textContent = business.activeSessions || 0;
                    document.getElementById('cacheHitRate').textContent = `${business.cacheEfficiency || 0}%`;
                }
            }
            
            updateCharts(performance, business) {
                // Update performance chart
                if (performance) {
                    const now = new Date().toLocaleTimeString();
                    
                    if (this.charts.performance.data.labels.length > 20) {
                        this.charts.performance.data.labels.shift();
                        this.charts.performance.data.datasets[0].data.shift();
                        this.charts.performance.data.datasets[1].data.shift();
                    }
                    
                    this.charts.performance.data.labels.push(now);
                    this.charts.performance.data.datasets[0].data.push(performance.memoryUsage || 0);
                    this.charts.performance.data.datasets[1].data.push(performance.cacheHitRatio || 0);
                    this.charts.performance.update('none');
                }
                
                // Update business chart
                if (business) {
                    this.charts.business.data.datasets[0].data = [
                        business.activePolicies || 0,
                        business.pendingClaims || 0,
                        business.activeSessions || 0,
                        business.customerLogins || 0
                    ];
                    this.charts.business.update('none');
                }
            }
            
            updateAlerts(alerts) {
                const alertsContainer = document.getElementById('recentAlerts');
                
                if (!alerts || alerts.length === 0) {
                    alertsContainer.innerHTML = '<p>No recent alerts</p>';
                    return;
                }
                
                alertsContainer.innerHTML = alerts.slice(-5).map(alert => `
                    <div class="alert ${alert.severity}">
                        <strong>${alert.type}</strong><br>
                        ${alert.details ? alert.details.message : 'No details available'}<br>
                        <small>${new Date(alert.timestamp).toLocaleString()}</small>
                    </div>
                `).join('');
            }
            
            updateSystemInfo(timestamp) {
                document.getElementById('systemUptime').textContent = this.formatUptime(process.uptime || 0);
                document.getElementById('lastUpdated').textContent = new Date(timestamp).toLocaleString();
            }
            
            formatUptime(seconds) {
                const hours = Math.floor(seconds / 3600);
                const minutes = Math.floor((seconds % 3600) / 60);
                return `${hours}h ${minutes}m`;
            }
            
            showRefreshIndicator() {
                document.getElementById('refreshIndicator').style.display = 'block';
            }
            
            hideRefreshIndicator() {
                document.getElementById('refreshIndicator').style.display = 'none';
            }
        }
        
        // Initialize dashboard when page loads
        document.addEventListener('DOMContentLoaded', () => {
            new InsuranceDashboard();
        });
    </script>
</body>
</html>
```

### Step 3: Main Application Entry Point

```javascript
// src/main.js
const InsuranceMonitoring = require('./monitoring-core');
const HealthCheckService = require('./health-check-service');
const InsuranceAlertingSystem = require('./alerting-system');
const MonitoringDashboard = require('./monitoring-dashboard');

async function startInsuranceMonitoring() {
    console.log('🚀 Starting Insurance Redis Monitoring System...');
    
    // Initialize monitoring core
    const monitoring = new InsuranceMonitoring();
    
    // Initialize alerting system
    const alerting = new InsuranceAlertingSystem(monitoring);
    
    // Start health check service
    const healthService = new HealthCheckService();
    await healthService.start(3000);
    
    // Start monitoring dashboard
    const dashboard = new MonitoringDashboard(monitoring, alerting);
    dashboard.start(4000);
    
    console.log('✅ Insurance monitoring system started successfully');
    console.log('📊 Services running:');
    console.log('   • Health Check API: http://localhost:3000/health');
    console.log('   • Monitoring Dashboard: http://localhost:4000');
    console.log('   • Redis Insight: (configured separately)');
    
    // Graceful shutdown
    process.on('SIGINT', async () => {
        console.log('\n🛑 Shutting down monitoring system...');
        await monitoring.redis.disconnect();
        process.exit(0);
    });
}

// Start the monitoring system
if (require.main === module) {
    startInsuranceMonitoring().catch(console.error);
}

module.exports = {
    InsuranceMonitoring,
    HealthCheckService,
    InsuranceAlertingSystem,
    MonitoringDashboard
};
```

### Step 4: Package Configuration

```json
{
  "name": "lab14-insurance-monitoring",
  "version": "1.0.0",
  "description": "Lab 14: Monitoring & Health Checks for Insurance Operations",
  "main": "src/main.js",
  "scripts": {
    "start": "node src/main.js",
    "dev": "nodemon src/main.js",
    "test": "npm run test:health && npm run test:monitoring",
    "test:health": "curl -f http://localhost:3000/health || exit 1",
    "test:monitoring": "curl -f http://localhost:4000/api/metrics/realtime || exit 1",
    "load-data": "node scripts/load-insurance-monitoring-data.js"
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
  "keywords": ["redis", "monitoring", "insurance", "health-checks", "alerts"],
  "author": "Insurance DevOps Team",
  "license": "MIT"
}
```

---

## 📋 Lab Summary

You have successfully completed Lab 14! You've mastered:

✅ **Production Monitoring Setup:** Comprehensive Redis monitoring for insurance operations  
✅ **Health Check Implementation:** Custom health endpoints for insurance systems  
✅ **Alerting System:** Automated alerts for critical insurance business metrics  
✅ **Redis Insight Integration:** Production monitoring dashboard configuration  
✅ **Performance Metrics:** Collection and analysis of insurance-specific KPIs  
✅ **Business Intelligence:** Insurance business metrics and trend analysis  

## 🎯 Key Skills Developed

- **Production Monitoring:** Set up comprehensive monitoring for insurance Redis operations
- **Health Checks:** Created custom health endpoints for insurance business systems
- **Alerting:** Implemented intelligent alerting based on business and technical thresholds
- **Dashboard Creation:** Built real-time monitoring dashboard for insurance stakeholders
- **Performance Analysis:** Analyzed Redis performance in insurance production environments
- **Business Metrics:** Tracked insurance-specific KPIs and operational metrics

## 🔄 Testing Your Implementation

```bash
# Start the complete monitoring system
npm start

# Test health endpoints
curl http://localhost:3000/health
curl http://localhost:3000/health/insurance
curl http://localhost:3000/health/performance

# Access monitoring dashboard
open http://localhost:4000

# Load test data for monitoring
npm run load-data

# Check system logs
tail -f logs/insurance-monitoring.log
tail -f logs/alerts.log
```

## 🚀 Next Steps: Lab 15

**Up Next:** Lab 15 - Insurance Microservices Integration (45 minutes)
- Implement cross-service caching patterns
- Create service-to-service cache invalidation
- Build event-driven architecture with Redis
- Integrate multiple insurance services
- Implement distributed session management

**Course Completion:** Lab 14 completes the production monitoring section of the Redis Mastery course for insurance applications!

---

**Excellent work mastering Redis monitoring for insurance operations! 🎉**
