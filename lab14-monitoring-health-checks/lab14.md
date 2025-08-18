# Lab 14: Monitoring & Health Checks for Business Operations

**Duration:** 45 minutes  
**Objective:** Set up comprehensive monitoring and health checks for production Redis operations

## 🎯 Learning Objectives

By the end of this lab, you will be able to:
- Configure Redis Insight for production monitoring
- Implement health check endpoints with business metrics
- Set up performance metric collection for key operations
- Monitor critical business metrics (policy lookups, claim submissions)
- Create alerting for critical thresholds and anomalies
- Build real-time monitoring dashboards with JavaScript

---

## Part 1: Redis Insight Configuration & Health Check Infrastructure (15 minutes)

### Step 1: Environment Setup with Monitoring

```bash
# Start Redis with monitoring-optimized configuration
docker run -d --name redis-monitoring-lab14 \
  -p 6379:6379 \
  redis:7-alpine redis-server \
  --maxmemory 512mb \
  --maxmemory-policy allkeys-lru \
  --latency-monitor-threshold 100 \
  --slowlog-log-slower-than 10000 \
  --slowlog-max-len 128 \
  --notify-keyspace-events AKE

# Verify Redis is running
redis-cli ping

# Install project dependencies
npm init -y
npm install redis express prom-client
npm install --save-dev nodemon

# Configure Redis Insight (if not already connected)
# Open Redis Insight and connect to localhost:6379
```

### Step 2: Create Basic Health Check System

Create `src/health-check.js`:
```javascript
const redis = require('redis');
const express = require('express');

class HealthCheckSystem {
    constructor() {
        this.client = null;
        this.app = express();
        this.healthStatus = {
            redis: 'unknown',
            memory: {},
            performance: {},
            business: {},
            lastCheck: null
        };
    }

    async connect() {
        this.client = redis.createClient({
            socket: { host: 'localhost', port: 6379 }
        });
        
        this.client.on('error', (err) => {
            console.error('Redis Client Error:', err);
            this.healthStatus.redis = 'error';
        });
        
        this.client.on('ready', () => {
            console.log('Redis Client Ready');
            this.healthStatus.redis = 'healthy';
        });
        
        await this.client.connect();
        this.setupRoutes();
    }

    setupRoutes() {
        // Basic health endpoint
        this.app.get('/health', async (req, res) => {
            const health = await this.performHealthCheck();
            const statusCode = health.status === 'healthy' ? 200 : 503;
            res.status(statusCode).json(health);
        });

        // Detailed health endpoint
        this.app.get('/health/detailed', async (req, res) => {
            const detailed = await this.performDetailedHealthCheck();
            res.json(detailed);
        });

        // Ready check endpoint
        this.app.get('/ready', async (req, res) => {
            const isReady = await this.checkReadiness();
            res.status(isReady ? 200 : 503).json({ ready: isReady });
        });

        // Live check endpoint
        this.app.get('/live', (req, res) => {
            res.status(200).json({ live: true });
        });
    }

    async performHealthCheck() {
        try {
            // Check Redis connection
            await this.client.ping();
            
            // Get basic metrics
            const info = await this.client.info('server');
            const dbSize = await this.client.dbSize();
            
            return {
                status: 'healthy',
                timestamp: new Date().toISOString(),
                checks: {
                    redis: 'connected',
                    database_size: dbSize
                }
            };
        } catch (error) {
            return {
                status: 'unhealthy',
                timestamp: new Date().toISOString(),
                error: error.message
            };
        }
    }

    async performDetailedHealthCheck() {
        const checks = {};
        
        // Memory health
        checks.memory = await this.checkMemoryHealth();
        
        // Performance health
        checks.performance = await this.checkPerformanceHealth();
        
        // Business metrics health
        checks.business = await this.checkBusinessHealth();
        
        // Connection pool health
        checks.connections = await this.checkConnectionHealth();
        
        return {
            timestamp: new Date().toISOString(),
            status: this.calculateOverallHealth(checks),
            checks
        };
    }

    async checkMemoryHealth() {
        const info = await this.client.info('memory');
        const lines = info.split('\r\n');
        const metrics = {};
        
        lines.forEach(line => {
            if (line.includes(':')) {
                const [key, value] = line.split(':');
                metrics[key] = value;
            }
        });
        
        const usedMemory = parseInt(metrics.used_memory || 0);
        const maxMemory = parseInt(metrics.maxmemory || 0);
        const usage = maxMemory > 0 ? (usedMemory / maxMemory) * 100 : 0;
        
        return {
            used_memory: usedMemory,
            max_memory: maxMemory,
            usage_percentage: usage.toFixed(2),
            status: usage > 90 ? 'critical' : usage > 75 ? 'warning' : 'healthy'
        };
    }

    async checkPerformanceHealth() {
        // Get slow log entries
        const slowLog = await this.client.slowlogGet(10);
        
        // Get latency stats
        const latencyStats = await this.client.sendCommand(['LATENCY', 'LATEST']);
        
        return {
            slow_queries: slowLog.length,
            latest_slow_query: slowLog[0] || null,
            latency_events: latencyStats.length,
            status: slowLog.length > 5 ? 'warning' : 'healthy'
        };
    }

    async checkBusinessHealth() {
        // Check key business metrics
        const metrics = {};
        
        // Policy lookups in last minute
        const policyLookups = await this.client.get('metrics:policy:lookups:minute') || 0;
        metrics.policy_lookups_per_minute = parseInt(policyLookups);
        
        // Claims queue length
        const claimsQueueLength = await this.client.lLen('claims:pending');
        metrics.pending_claims = claimsQueueLength;
        
        // Active sessions
        const sessions = await this.client.keys('session:*');
        metrics.active_sessions = sessions.length;
        
        // Calculate status
        const status = claimsQueueLength > 100 ? 'warning' : 'healthy';
        
        return {
            ...metrics,
            status
        };
    }

    async checkConnectionHealth() {
        const info = await this.client.info('clients');
        const lines = info.split('\r\n');
        const metrics = {};
        
        lines.forEach(line => {
            if (line.includes(':')) {
                const [key, value] = line.split(':');
                metrics[key] = value;
            }
        });
        
        return {
            connected_clients: parseInt(metrics.connected_clients || 0),
            blocked_clients: parseInt(metrics.blocked_clients || 0),
            status: 'healthy'
        };
    }

    calculateOverallHealth(checks) {
        const statuses = Object.values(checks).map(check => check.status);
        
        if (statuses.includes('critical')) return 'critical';
        if (statuses.includes('warning')) return 'warning';
        return 'healthy';
    }

    async checkReadiness() {
        try {
            await this.client.ping();
            const dbSize = await this.client.dbSize();
            return dbSize >= 0;
        } catch {
            return false;
        }
    }

    async start(port = 3000) {
        await this.connect();
        
        this.app.listen(port, () => {
            console.log(`Health check server running on port ${port}`);
            console.log(`  - Basic health: http://localhost:${port}/health`);
            console.log(`  - Detailed health: http://localhost:${port}/health/detailed`);
            console.log(`  - Readiness: http://localhost:${port}/ready`);
            console.log(`  - Liveness: http://localhost:${port}/live`);
        });
    }
}

// Run if executed directly
if (require.main === module) {
    const healthCheck = new HealthCheckSystem();
    healthCheck.start().catch(console.error);
}

module.exports = { HealthCheckSystem };
```

**Exercise:** Run the health check server and access the endpoints in your browser or with curl.

---

## Part 2: Metrics Collection & Performance Monitoring (15 minutes)

### Step 1: Create Metrics Collector

Create `src/metrics-collector.js`:
```javascript
const redis = require('redis');
const { register, Counter, Histogram, Gauge } = require('prom-client');

class MetricsCollector {
    constructor() {
        this.client = null;
        this.setupMetrics();
    }

    setupMetrics() {
        // Clear default metrics
        register.clear();
        
        // Business operation counters
        this.policyLookups = new Counter({
            name: 'policy_lookups_total',
            help: 'Total number of policy lookups',
            labelNames: ['type', 'status']
        });
        
        this.claimSubmissions = new Counter({
            name: 'claim_submissions_total',
            help: 'Total number of claim submissions',
            labelNames: ['type', 'priority']
        });
        
        this.customerQueries = new Counter({
            name: 'customer_queries_total',
            help: 'Total number of customer queries',
            labelNames: ['operation']
        });
        
        // Performance histograms
        this.operationDuration = new Histogram({
            name: 'redis_operation_duration_seconds',
            help: 'Redis operation duration in seconds',
            labelNames: ['operation'],
            buckets: [0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1]
        });
        
        // System gauges
        this.memoryUsage = new Gauge({
            name: 'redis_memory_usage_bytes',
            help: 'Redis memory usage in bytes'
        });
        
        this.connectedClients = new Gauge({
            name: 'redis_connected_clients',
            help: 'Number of connected Redis clients'
        });
        
        this.queueLength = new Gauge({
            name: 'queue_length',
            help: 'Length of various queues',
            labelNames: ['queue_name']
        });
    }

    async connect() {
        this.client = redis.createClient({
            socket: { host: 'localhost', port: 6379 }
        });
        
        await this.client.connect();
        console.log('Metrics collector connected to Redis');
    }

    // Track policy lookup
    async trackPolicyLookup(policyType, found = true) {
        const end = this.operationDuration.startTimer({ operation: 'policy_lookup' });
        
        try {
            // Simulate policy lookup
            const key = `policy:${policyType}:sample`;
            await this.client.get(key);
            
            this.policyLookups.inc({ 
                type: policyType, 
                status: found ? 'found' : 'not_found' 
            });
            
            // Track in Redis for time-based metrics
            await this.client.incr(`metrics:policy:lookups:minute`);
            await this.client.expire(`metrics:policy:lookups:minute`, 60);
            
        } finally {
            end();
        }
    }

    // Track claim submission
    async trackClaimSubmission(claimType, priority = 'normal') {
        const end = this.operationDuration.startTimer({ operation: 'claim_submission' });
        
        try {
            // Simulate claim submission
            const claim = {
                id: `CLM-${Date.now()}`,
                type: claimType,
                priority: priority,
                timestamp: new Date().toISOString()
            };
            
            await this.client.lPush('claims:pending', JSON.stringify(claim));
            
            this.claimSubmissions.inc({ 
                type: claimType, 
                priority: priority 
            });
            
            // Track in Redis
            await this.client.incr(`metrics:claims:submissions:minute`);
            await this.client.expire(`metrics:claims:submissions:minute`, 60);
            
        } finally {
            end();
        }
    }

    // Collect system metrics
    async collectSystemMetrics() {
        try {
            // Memory metrics
            const memoryInfo = await this.client.info('memory');
            const usedMemory = this.extractMetric(memoryInfo, 'used_memory');
            if (usedMemory) {
                this.memoryUsage.set(parseInt(usedMemory));
            }
            
            // Client metrics
            const clientInfo = await this.client.info('clients');
            const clients = this.extractMetric(clientInfo, 'connected_clients');
            if (clients) {
                this.connectedClients.set(parseInt(clients));
            }
            
            // Queue metrics
            const queues = [
                'claims:pending',
                'claims:processing',
                'notifications:queue',
                'events:queue'
            ];
            
            for (const queue of queues) {
                const length = await this.client.lLen(queue);
                this.queueLength.set({ queue_name: queue }, length);
            }
            
        } catch (error) {
            console.error('Error collecting system metrics:', error);
        }
    }

    extractMetric(info, key) {
        const lines = info.split('\r\n');
        for (const line of lines) {
            if (line.startsWith(key + ':')) {
                return line.split(':')[1];
            }
        }
        return null;
    }

    // Get Prometheus metrics
    async getMetrics() {
        await this.collectSystemMetrics();
        return register.metrics();
    }

    // Start automatic collection
    startAutoCollection(intervalMs = 10000) {
        setInterval(() => {
            this.collectSystemMetrics().catch(console.error);
        }, intervalMs);
        
        console.log(`Auto-collecting metrics every ${intervalMs}ms`);
    }
}

// Run if executed directly
if (require.main === module) {
    async function runMetricsDemo() {
        const collector = new MetricsCollector();
        await collector.connect();
        
        // Start auto-collection
        collector.startAutoCollection(5000);
        
        // Simulate some operations
        console.log('Simulating business operations...\n');
        
        // Simulate policy lookups
        for (let i = 0; i < 10; i++) {
            const types = ['AUTO', 'HOME', 'LIFE'];
            const type = types[Math.floor(Math.random() * types.length)];
            await collector.trackPolicyLookup(type, Math.random() > 0.1);
            await new Promise(resolve => setTimeout(resolve, 100));
        }
        
        // Simulate claim submissions
        for (let i = 0; i < 5; i++) {
            const types = ['AUTO', 'HOME', 'HEALTH'];
            const priorities = ['low', 'normal', 'high'];
            const type = types[Math.floor(Math.random() * types.length)];
            const priority = priorities[Math.floor(Math.random() * priorities.length)];
            await collector.trackClaimSubmission(type, priority);
            await new Promise(resolve => setTimeout(resolve, 200));
        }
        
        // Display metrics
        const metrics = await collector.getMetrics();
        console.log('\nPrometheus Metrics Output:');
        console.log('===========================');
        console.log(metrics);
    }
    
    runMetricsDemo().catch(console.error);
}

module.exports = { MetricsCollector };
```

**Exercise:** Run the metrics collector and observe the Prometheus-format output.

---

## Part 3: Real-time Monitoring Dashboard (15 minutes)

### Step 1: Create Monitoring Dashboard

Create `src/monitoring-dashboard.js`:
```javascript
const redis = require('redis');
const express = require('express');
const { MetricsCollector } = require('./metrics-collector');
const { HealthCheckSystem } = require('./health-check');

class MonitoringDashboard {
    constructor() {
        this.client = null;
        this.app = express();
        this.metricsCollector = new MetricsCollector();
        this.port = 3001;
    }

    async connect() {
        this.client = redis.createClient({
            socket: { host: 'localhost', port: 6379 }
        });
        
        await this.client.connect();
        await this.metricsCollector.connect();
        
        this.setupRoutes();
        this.startMonitoring();
    }

    setupRoutes() {
        // Serve static dashboard
        this.app.use(express.static('public'));
        
        // Metrics endpoint for Prometheus
        this.app.get('/metrics', async (req, res) => {
            const metrics = await this.metricsCollector.getMetrics();
            res.set('Content-Type', register.contentType);
            res.end(metrics);
        });
        
        // Real-time stats endpoint
        this.app.get('/api/stats', async (req, res) => {
            const stats = await this.collectRealTimeStats();
            res.json(stats);
        });
        
        // Alert status endpoint
        this.app.get('/api/alerts', async (req, res) => {
            const alerts = await this.checkAlerts();
            res.json(alerts);
        });
        
        // Performance data endpoint
        this.app.get('/api/performance', async (req, res) => {
            const perf = await this.collectPerformanceData();
            res.json(perf);
        });
    }

    async collectRealTimeStats() {
        const stats = {
            timestamp: new Date().toISOString(),
            operations: {},
            queues: {},
            system: {}
        };
        
        // Operation rates
        const policyLookups = await this.client.get('metrics:policy:lookups:minute') || 0;
        const claimSubmissions = await this.client.get('metrics:claims:submissions:minute') || 0;
        
        stats.operations = {
            policy_lookups_per_minute: parseInt(policyLookups),
            claim_submissions_per_minute: parseInt(claimSubmissions)
        };
        
        // Queue lengths
        stats.queues = {
            pending_claims: await this.client.lLen('claims:pending'),
            processing_claims: await this.client.lLen('claims:processing'),
            notifications: await this.client.lLen('notifications:queue')
        };
        
        // System info
        const info = await this.client.info('stats');
        const cmdstat = this.extractCommandStats(info);
        
        stats.system = {
            total_commands_processed: cmdstat.total,
            instantaneous_ops_per_sec: cmdstat.ops_per_sec,
            keyspace_hits: cmdstat.keyspace_hits,
            keyspace_misses: cmdstat.keyspace_misses,
            hit_rate: cmdstat.hit_rate
        };
        
        return stats;
    }

    extractCommandStats(info) {
        const stats = {
            total: 0,
            ops_per_sec: 0,
            keyspace_hits: 0,
            keyspace_misses: 0,
            hit_rate: 0
        };
        
        const lines = info.split('\r\n');
        lines.forEach(line => {
            if (line.includes('total_commands_processed:')) {
                stats.total = parseInt(line.split(':')[1]);
            }
            if (line.includes('instantaneous_ops_per_sec:')) {
                stats.ops_per_sec = parseInt(line.split(':')[1]);
            }
            if (line.includes('keyspace_hits:')) {
                stats.keyspace_hits = parseInt(line.split(':')[1]);
            }
            if (line.includes('keyspace_misses:')) {
                stats.keyspace_misses = parseInt(line.split(':')[1]);
            }
        });
        
        // Calculate hit rate
        const total = stats.keyspace_hits + stats.keyspace_misses;
        if (total > 0) {
            stats.hit_rate = ((stats.keyspace_hits / total) * 100).toFixed(2);
        }
        
        return stats;
    }

    async checkAlerts() {
        const alerts = [];
        
        // Check memory usage
        const memInfo = await this.client.info('memory');
        const usedMemory = parseInt(this.extractMetric(memInfo, 'used_memory') || 0);
        const maxMemory = parseInt(this.extractMetric(memInfo, 'maxmemory') || 0);
        
        if (maxMemory > 0) {
            const usage = (usedMemory / maxMemory) * 100;
            if (usage > 90) {
                alerts.push({
                    level: 'critical',
                    type: 'memory',
                    message: `Memory usage critical: ${usage.toFixed(2)}%`,
                    timestamp: new Date().toISOString()
                });
            } else if (usage > 75) {
                alerts.push({
                    level: 'warning',
                    type: 'memory',
                    message: `Memory usage high: ${usage.toFixed(2)}%`,
                    timestamp: new Date().toISOString()
                });
            }
        }
        
        // Check queue lengths
        const claimsQueue = await this.client.lLen('claims:pending');
        if (claimsQueue > 100) {
            alerts.push({
                level: 'warning',
                type: 'queue',
                message: `High number of pending claims: ${claimsQueue}`,
                timestamp: new Date().toISOString()
            });
        }
        
        // Check slow queries
        const slowLog = await this.client.slowlogGet(5);
        if (slowLog.length > 0) {
            alerts.push({
                level: 'info',
                type: 'performance',
                message: `${slowLog.length} slow queries detected`,
                timestamp: new Date().toISOString()
            });
        }
        
        return alerts;
    }

    extractMetric(info, key) {
        const lines = info.split('\r\n');
        for (const line of lines) {
            if (line.startsWith(key + ':')) {
                return line.split(':')[1];
            }
        }
        return null;
    }

    async collectPerformanceData() {
        const perf = {
            latency: {},
            throughput: {},
            slow_queries: []
        };
        
        // Get latency data
        try {
            const latencyData = await this.client.sendCommand(['LATENCY', 'LATEST']);
            perf.latency = latencyData.map(item => ({
                event: item[0],
                latency_ms: item[1],
                timestamp: new Date(item[2] * 1000).toISOString()
            }));
        } catch {
            perf.latency = [];
        }
        
        // Get throughput
        const info = await this.client.info('stats');
        const opsPerSec = this.extractMetric(info, 'instantaneous_ops_per_sec');
        perf.throughput = {
            ops_per_second: parseInt(opsPerSec || 0),
            timestamp: new Date().toISOString()
        };
        
        // Get slow queries
        const slowLog = await this.client.slowlogGet(5);
        perf.slow_queries = slowLog.map(entry => ({
            id: entry.id,
            duration_microseconds: entry.duration,
            command: entry.command.join(' ').substring(0, 100),
            timestamp: new Date(entry.timestamp * 1000).toISOString()
        }));
        
        return perf;
    }

    startMonitoring() {
        // Start metrics auto-collection
        this.metricsCollector.startAutoCollection(10000);
        
        // Clear minute counters periodically
        setInterval(async () => {
            await this.client.del('metrics:policy:lookups:minute');
            await this.client.del('metrics:claims:submissions:minute');
        }, 60000);
    }

    async start() {
        await this.connect();
        
        this.app.listen(this.port, () => {
            console.log(`Monitoring Dashboard running on port ${this.port}`);
            console.log(`  - Dashboard: http://localhost:${this.port}`);
            console.log(`  - Metrics: http://localhost:${this.port}/metrics`);
            console.log(`  - Stats API: http://localhost:${this.port}/api/stats`);
            console.log(`  - Alerts API: http://localhost:${this.port}/api/alerts`);
            console.log(`  - Performance API: http://localhost:${this.port}/api/performance`);
        });
    }
}

// Run if executed directly
if (require.main === module) {
    const dashboard = new MonitoringDashboard();
    dashboard.start().catch(console.error);
}

module.exports = { MonitoringDashboard };
```

### Step 2: Create HTML Dashboard

Create `public/index.html`:
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Redis Monitoring Dashboard</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #333;
            min-height: 100vh;
            padding: 20px;
        }
        
        .container {
            max-width: 1400px;
            margin: 0 auto;
        }
        
        h1 {
            color: white;
            text-align: center;
            margin-bottom: 30px;
            font-size: 2.5em;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.2);
        }
        
        .dashboard {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
            gap: 20px;
        }
        
        .card {
            background: white;
            border-radius: 10px;
            padding: 20px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.1);
            transition: transform 0.3s ease;
        }
        
        .card:hover {
            transform: translateY(-5px);
            box-shadow: 0 15px 40px rgba(0,0,0,0.15);
        }
        
        .card h2 {
            color: #667eea;
            margin-bottom: 15px;
            font-size: 1.3em;
        }
        
        .metric {
            display: flex;
            justify-content: space-between;
            padding: 10px 0;
            border-bottom: 1px solid #eee;
        }
        
        .metric:last-child {
            border-bottom: none;
        }
        
        .metric-label {
            color: #666;
            font-size: 0.9em;
        }
        
        .metric-value {
            font-weight: bold;
            color: #333;
        }
        
        .alert {
            padding: 10px;
            margin: 10px 0;
            border-radius: 5px;
            display: flex;
            align-items: center;
        }
        
        .alert-critical {
            background: #fee;
            border-left: 4px solid #f44336;
        }
        
        .alert-warning {
            background: #ffeaa7;
            border-left: 4px solid #fdcb6e;
        }
        
        .alert-info {
            background: #e3f2fd;
            border-left: 4px solid #2196f3;
        }
        
        .status-indicator {
            display: inline-block;
            width: 10px;
            height: 10px;
            border-radius: 50%;
            margin-right: 10px;
        }
        
        .status-healthy {
            background: #4caf50;
            animation: pulse 2s infinite;
        }
        
        .status-warning {
            background: #ff9800;
        }
        
        .status-critical {
            background: #f44336;
        }
        
        @keyframes pulse {
            0% {
                box-shadow: 0 0 0 0 rgba(76, 175, 80, 0.7);
            }
            70% {
                box-shadow: 0 0 0 10px rgba(76, 175, 80, 0);
            }
            100% {
                box-shadow: 0 0 0 0 rgba(76, 175, 80, 0);
            }
        }
        
        .slow-query {
            background: #f5f5f5;
            padding: 10px;
            margin: 10px 0;
            border-radius: 5px;
            font-family: monospace;
            font-size: 0.85em;
        }
        
        .timestamp {
            color: #999;
            font-size: 0.8em;
            margin-top: 20px;
            text-align: right;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Redis Monitoring Dashboard</h1>
        
        <div class="dashboard">
            <!-- Real-time Stats -->
            <div class="card">
                <h2>📊 Real-time Statistics</h2>
                <div id="stats">
                    <div class="metric">
                        <span class="metric-label">Loading...</span>
                    </div>
                </div>
            </div>
            
            <!-- Queue Status -->
            <div class="card">
                <h2>📋 Queue Status</h2>
                <div id="queues">
                    <div class="metric">
                        <span class="metric-label">Loading...</span>
                    </div>
                </div>
            </div>
            
            <!-- System Performance -->
            <div class="card">
                <h2>⚡ Performance Metrics</h2>
                <div id="performance">
                    <div class="metric">
                        <span class="metric-label">Loading...</span>
                    </div>
                </div>
            </div>
            
            <!-- Alerts -->
            <div class="card">
                <h2>🚨 Active Alerts</h2>
                <div id="alerts">
                    <div class="alert alert-info">
                        <span>No alerts at this time</span>
                    </div>
                </div>
            </div>
            
            <!-- Slow Queries -->
            <div class="card">
                <h2>🐌 Slow Queries</h2>
                <div id="slow-queries">
                    <div class="slow-query">No slow queries detected</div>
                </div>
            </div>
            
            <!-- Health Status -->
            <div class="card">
                <h2>💚 Health Status</h2>
                <div id="health">
                    <div class="metric">
                        <span class="metric-label">Redis Connection</span>
                        <span class="metric-value">
                            <span class="status-indicator status-healthy"></span>
                            Healthy
                        </span>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <script>
        // Update dashboard every 2 seconds
        async function updateDashboard() {
            try {
                // Fetch real-time stats
                const statsResponse = await fetch('/api/stats');
                const stats = await statsResponse.json();
                updateStats(stats);
                
                // Fetch alerts
                const alertsResponse = await fetch('/api/alerts');
                const alerts = await alertsResponse.json();
                updateAlerts(alerts);
                
                // Fetch performance data
                const perfResponse = await fetch('/api/performance');
                const perf = await perfResponse.json();
                updatePerformance(perf);
                
            } catch (error) {
                console.error('Error updating dashboard:', error);
            }
        }
        
        function updateStats(stats) {
            const statsDiv = document.getElementById('stats');
            statsDiv.innerHTML = `
                <div class="metric">
                    <span class="metric-label">Policy Lookups/min</span>
                    <span class="metric-value">${stats.operations.policy_lookups_per_minute}</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Claim Submissions/min</span>
                    <span class="metric-value">${stats.operations.claim_submissions_per_minute}</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Total Commands</span>
                    <span class="metric-value">${stats.system.total_commands_processed.toLocaleString()}</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Ops/sec</span>
                    <span class="metric-value">${stats.system.instantaneous_ops_per_sec}</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Cache Hit Rate</span>
                    <span class="metric-value">${stats.system.hit_rate}%</span>
                </div>
            `;
            
            // Update queues
            const queuesDiv = document.getElementById('queues');
            queuesDiv.innerHTML = `
                <div class="metric">
                    <span class="metric-label">Pending Claims</span>
                    <span class="metric-value">${stats.queues.pending_claims}</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Processing Claims</span>
                    <span class="metric-value">${stats.queues.processing_claims}</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Notifications Queue</span>
                    <span class="metric-value">${stats.queues.notifications}</span>
                </div>
            `;
        }
        
        function updateAlerts(alerts) {
            const alertsDiv = document.getElementById('alerts');
            
            if (alerts.length === 0) {
                alertsDiv.innerHTML = '<div class="alert alert-info"><span>✅ All systems operational</span></div>';
            } else {
                alertsDiv.innerHTML = alerts.map(alert => `
                    <div class="alert alert-${alert.level}">
                        <span>${alert.message}</span>
                    </div>
                `).join('');
            }
        }
        
        function updatePerformance(perf) {
            const perfDiv = document.getElementById('performance');
            perfDiv.innerHTML = `
                <div class="metric">
                    <span class="metric-label">Throughput</span>
                    <span class="metric-value">${perf.throughput.ops_per_second} ops/sec</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Latency Events</span>
                    <span class="metric-value">${perf.latency.length}</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Slow Queries</span>
                    <span class="metric-value">${perf.slow_queries.length}</span>
                </div>
            `;
            
            // Update slow queries
            const slowDiv = document.getElementById('slow-queries');
            if (perf.slow_queries.length === 0) {
                slowDiv.innerHTML = '<div class="slow-query">✅ No slow queries detected</div>';
            } else {
                slowDiv.innerHTML = perf.slow_queries.slice(0, 3).map(query => `
                    <div class="slow-query">
                        ${query.command} (${query.duration_microseconds}μs)
                    </div>
                `).join('');
            }
        }
        
        // Initial load and periodic updates
        updateDashboard();
        setInterval(updateDashboard, 2000);
    </script>
</body>
</html>
```

**Exercise:** Access the dashboard at `http://localhost:3001` and observe real-time metrics.

---

## Summary

In this lab, you successfully:
1. ✅ Configured Redis Insight for production monitoring
2. ✅ Implemented comprehensive health check endpoints
3. ✅ Set up Prometheus-compatible metrics collection
4. ✅ Built a real-time monitoring dashboard
5. ✅ Created alerting for critical thresholds
6. ✅ Monitored business-specific metrics

## 🎯 Key Takeaways

- **Health checks** are critical for production readiness
- **Metrics collection** enables proactive monitoring
- **Real-time dashboards** provide immediate visibility
- **Alerting** helps prevent issues before they impact users
- **Business metrics** are as important as technical metrics

## 🚀 Next Steps

After completing this lab, you should be able to:
- Deploy production monitoring for Redis systems
- Create custom metrics for your business needs
- Build alerting rules for critical events
- Integrate with monitoring platforms (Prometheus, Grafana)
- Troubleshoot production issues effectively

## 🔧 Troubleshooting

### Common Issues

**Port already in use:**
```bash
# Kill process using port 3001
lsof -i :3001
kill -9 <PID>
```

**Redis connection issues:**
```bash
# Check Redis is running
docker ps | grep redis
redis-cli ping
```

**Metrics not updating:**
- Check the auto-collection interval
- Verify Redis operations are occurring
- Check browser console for errors

## 📚 Additional Resources

- [Redis Monitoring](https://redis.io/docs/management/monitoring/)
- [Prometheus Node.js Client](https://github.com/siimon/prom-client)
- [Redis Insight Documentation](https://redis.io/docs/stack/insight/)
- [Express Health Checks](https://expressjs.com/en/advanced/healthcheck-graceful-shutdown.html)

---

**Congratulations on completing Lab 14!** 🎉

You've successfully implemented a comprehensive monitoring and health check system for production Redis operations. These monitoring capabilities are essential for maintaining reliable business-critical systems.
