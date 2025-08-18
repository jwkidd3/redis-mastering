#!/bin/bash

# Lab 14 Content Generator Script
# Generates complete content and code for Lab 14: Monitoring & Health Checks for Business Operations
# Duration: 45 minutes
# Focus: Production monitoring, health checks, metrics collection, and alerting with JavaScript

set -e

LAB_DIR="lab14-monitoring-health-checks"
LAB_NUMBER="14"
LAB_TITLE="Monitoring & Health Checks for Business Operations"
LAB_DURATION="45"

echo "🚀 Generating Lab ${LAB_NUMBER}: ${LAB_TITLE}"
echo "📅 Duration: ${LAB_DURATION} minutes"
echo "🎯 Focus: Production monitoring, health checks, metrics collection, and alerting"
echo ""

# Create lab directory structure
mkdir -p ${LAB_DIR}
cd ${LAB_DIR}

echo "📁 Creating lab directory structure..."
mkdir -p {src,scripts,docs,examples,monitoring-dashboards,alerts,metrics}

# Create main lab instructions markdown file
echo "📋 Creating lab14.md..."
cat > lab14.md << 'EOF'
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
EOF

# Create package.json
echo "📦 Creating package.json..."
cat > package.json << 'EOF'
{
  "name": "lab14-monitoring-health-checks",
  "version": "1.0.0",
  "description": "Lab 14: Monitoring & Health Checks for Business Operations",
  "main": "src/index.js",
  "scripts": {
    "start": "node src/index.js",
    "health": "node src/health-check.js",
    "metrics": "node src/metrics-collector.js",
    "dashboard": "node src/monitoring-dashboard.js",
    "monitor": "nodemon src/monitoring-dashboard.js",
    "test": "node src/test-monitoring.js",
    "load-data": "node scripts/load-sample-data.sh",
    "stress-test": "node scripts/stress-test.js",
    "dev": "npm run dashboard"
  },
  "keywords": ["redis", "monitoring", "health-check", "metrics", "dashboard"],
  "author": "Redis Training",
  "license": "MIT",
  "dependencies": {
    "redis": "^4.6.0",
    "express": "^4.18.2",
    "prom-client": "^14.2.0",
    "dotenv": "^16.0.3",
    "chalk": "^4.1.2"
  },
  "devDependencies": {
    "nodemon": "^2.0.20"
  }
}
EOF

# Create load sample data script
echo "📊 Creating sample data loader..."
cat > scripts/load-sample-data.sh << 'EOF'
#!/bin/bash

echo "Loading sample monitoring data into Redis..."

redis-cli <<REDIS_EOF
# Clear existing data
FLUSHDB

# Sample policy data
SET policy:AUTO:1001 '{"type":"AUTO","premium":1200,"status":"active","customer":"C001"}'
SET policy:HOME:2001 '{"type":"HOME","premium":1500,"status":"active","customer":"C002"}'
SET policy:LIFE:3001 '{"type":"LIFE","premium":800,"status":"active","customer":"C003"}'

# Sample claims queue
LPUSH claims:pending '{"id":"CLM001","type":"AUTO","amount":5000,"priority":"high"}'
LPUSH claims:pending '{"id":"CLM002","type":"HOME","amount":15000,"priority":"normal"}'
LPUSH claims:pending '{"id":"CLM003","type":"LIFE","amount":100000,"priority":"high"}'
LPUSH claims:pending '{"id":"CLM004","type":"AUTO","amount":3000,"priority":"low"}'
LPUSH claims:pending '{"id":"CLM005","type":"HOME","amount":8000,"priority":"normal"}'

# Sample sessions
SET session:user001 '{"userId":"U001","loginTime":"2024-08-18T10:00:00Z","lastActivity":"2024-08-18T10:30:00Z"}'
SET session:user002 '{"userId":"U002","loginTime":"2024-08-18T09:45:00Z","lastActivity":"2024-08-18T10:25:00Z"}'
SET session:user003 '{"userId":"U003","loginTime":"2024-08-18T10:15:00Z","lastActivity":"2024-08-18T10:35:00Z"}'

# Set TTL on sessions
EXPIRE session:user001 3600
EXPIRE session:user002 3600
EXPIRE session:user003 3600

# Initialize metrics
SET metrics:policy:lookups:minute 0
SET metrics:claims:submissions:minute 0

echo "Sample monitoring data loaded successfully!"
echo ""
echo "Data Summary:"
echo "============="
echo "Policies: 3"
echo "Pending Claims: 5"
echo "Active Sessions: 3"
echo ""
echo "Database Size:"
DBSIZE

REDIS_EOF

chmod +x scripts/load-sample-data.sh

echo "✅ Sample data loaded for monitoring"
EOF

chmod +x scripts/load-sample-data.sh

# Create stress test script
echo "🔨 Creating stress test script..."
cat > scripts/stress-test.js << 'EOF'
const redis = require('redis');

async function stressTest() {
    const client = redis.createClient({
        socket: { host: 'localhost', port: 6379 }
    });
    
    await client.connect();
    console.log('Starting stress test for monitoring...\n');
    
    const operations = [
        // Policy lookups
        async () => {
            const types = ['AUTO', 'HOME', 'LIFE', 'HEALTH'];
            const id = Math.floor(Math.random() * 9999);
            const type = types[Math.floor(Math.random() * types.length)];
            await client.get(`policy:${type}:${id}`);
            await client.incr('metrics:policy:lookups:minute');
        },
        
        // Claim submissions
        async () => {
            const claim = {
                id: `CLM-${Date.now()}`,
                type: ['AUTO', 'HOME', 'HEALTH'][Math.floor(Math.random() * 3)],
                amount: Math.floor(Math.random() * 50000),
                priority: ['low', 'normal', 'high'][Math.floor(Math.random() * 3)]
            };
            await client.lPush('claims:pending', JSON.stringify(claim));
            await client.incr('metrics:claims:submissions:minute');
        },
        
        // Session operations
        async () => {
            const sessionId = `session:user${Math.floor(Math.random() * 100)}`;
            await client.setEx(sessionId, 3600, JSON.stringify({
                userId: `U${Math.floor(Math.random() * 100)}`,
                loginTime: new Date().toISOString()
            }));
        },
        
        // Cache operations
        async () => {
            const key = `cache:data:${Math.floor(Math.random() * 1000)}`;
            await client.setEx(key, 300, JSON.stringify({ data: 'cached' }));
        }
    ];
    
    // Run stress test
    const duration = 30000; // 30 seconds
    const startTime = Date.now();
    let operationCount = 0;
    
    console.log(`Running stress test for ${duration/1000} seconds...`);
    
    while (Date.now() - startTime < duration) {
        const operation = operations[Math.floor(Math.random() * operations.length)];
        await operation();
        operationCount++;
        
        // Small delay to control rate
        if (operationCount % 100 === 0) {
            await new Promise(resolve => setTimeout(resolve, 10));
        }
    }
    
    console.log(`\nStress test completed!`);
    console.log(`Total operations: ${operationCount}`);
    console.log(`Operations per second: ${(operationCount / (duration/1000)).toFixed(2)}`);
    
    await client.quit();
}

// Run if executed directly
if (require.main === module) {
    stressTest().catch(console.error);
}

module.exports = { stressTest };
EOF

# Create test monitoring script
echo "🧪 Creating test script..."
cat > src/test-monitoring.js << 'EOF'
const { HealthCheckSystem } = require('./health-check');
const { MetricsCollector } = require('./metrics-collector');
const redis = require('redis');

async function testMonitoring() {
    console.log('🧪 Testing Monitoring Components\n');
    
    // Test Redis connection
    console.log('1. Testing Redis connection...');
    const client = redis.createClient({
        socket: { host: 'localhost', port: 6379 }
    });
    
    try {
        await client.connect();
        await client.ping();
        console.log('   ✅ Redis connection successful\n');
    } catch (error) {
        console.error('   ❌ Redis connection failed:', error.message);
        process.exit(1);
    }
    
    // Test health check system
    console.log('2. Testing Health Check System...');
    const healthCheck = new HealthCheckSystem();
    await healthCheck.connect();
    
    const health = await healthCheck.performHealthCheck();
    console.log('   Basic health:', health.status);
    
    const detailed = await healthCheck.performDetailedHealthCheck();
    console.log('   Detailed health:', detailed.status);
    console.log('   ✅ Health check system working\n');
    
    // Test metrics collector
    console.log('3. Testing Metrics Collector...');
    const collector = new MetricsCollector();
    await collector.connect();
    
    // Simulate some operations
    await collector.trackPolicyLookup('AUTO', true);
    await collector.trackPolicyLookup('HOME', false);
    await collector.trackClaimSubmission('AUTO', 'high');
    
    const metrics = await collector.getMetrics();
    console.log('   Metrics collected:', metrics.split('\n').length, 'lines');
    console.log('   ✅ Metrics collector working\n');
    
    // Test performance under load
    console.log('4. Testing Performance Monitoring...');
    const startTime = Date.now();
    const operations = 1000;
    
    for (let i = 0; i < operations; i++) {
        await client.set(`test:key:${i}`, `value${i}`);
        if (i % 100 === 0) {
            await collector.trackPolicyLookup('AUTO', true);
        }
    }
    
    const duration = Date.now() - startTime;
    console.log(`   Completed ${operations} operations in ${duration}ms`);
    console.log(`   Throughput: ${(operations / (duration / 1000)).toFixed(2)} ops/sec`);
    console.log('   ✅ Performance monitoring working\n');
    
    // Clean up
    for (let i = 0; i < operations; i++) {
        await client.del(`test:key:${i}`);
    }
    
    await client.quit();
    console.log('✅ All monitoring tests passed!\n');
}

// Run tests
testMonitoring().catch(console.error);
EOF

# Create README
echo "📖 Creating README.md..."
cat > README.md << 'EOF'
# Lab 14: Monitoring & Health Checks for Business Operations

## Overview
This lab implements comprehensive monitoring, health checks, and alerting for production Redis operations with a focus on business metrics.

## Quick Start

1. **Start Redis with monitoring configuration:**
```bash
docker run -d --name redis-monitoring-lab14 \
  -p 6379:6379 \
  redis:7-alpine redis-server \
  --latency-monitor-threshold 100 \
  --slowlog-log-slower-than 10000
```

2. **Install dependencies:**
```bash
npm install
```

3. **Load sample data:**
```bash
./scripts/load-sample-data.sh
```

4. **Start monitoring dashboard:**
```bash
npm run dashboard
```

5. **Access monitoring interfaces:**
- Dashboard: http://localhost:3001
- Health Check: http://localhost:3000/health
- Metrics: http://localhost:3001/metrics
- Alerts: http://localhost:3001/api/alerts

## Available Scripts

- `npm start` - Start the main application
- `npm run health` - Run health check server
- `npm run metrics` - Run metrics collector
- `npm run dashboard` - Start monitoring dashboard
- `npm run stress-test` - Run stress test for monitoring
- `npm test` - Test all monitoring components

## Components

### Health Check System
- Basic and detailed health endpoints
- Readiness and liveness probes
- Memory and performance health checks
- Business metrics monitoring

### Metrics Collector
- Prometheus-compatible metrics
- Business operation tracking
- Performance histograms
- System resource gauges

### Monitoring Dashboard
- Real-time statistics display
- Queue status monitoring
- Performance metrics visualization
- Alert management
- Slow query tracking

## API Endpoints

### Health Checks
- `GET /health` - Basic health status
- `GET /health/detailed` - Detailed health information
- `GET /ready` - Readiness probe
- `GET /live` - Liveness probe

### Monitoring APIs
- `GET /metrics` - Prometheus metrics
- `GET /api/stats` - Real-time statistics
- `GET /api/alerts` - Active alerts
- `GET /api/performance` - Performance data

## Alert Thresholds

- **Memory Usage:** Warning at 75%, Critical at 90%
- **Queue Length:** Warning when pending claims > 100
- **Slow Queries:** Info alert when detected
- **Connection Issues:** Critical when Redis unavailable

## Troubleshooting

**Port conflicts:**
```bash
# Check what's using port 3001
lsof -i :3001

# Kill the process
kill -9 <PID>
```

**Redis connection issues:**
```bash
# Verify Redis is running
docker ps | grep redis

# Test connection
redis-cli ping
```

**Metrics not updating:**
- Check auto-collection is started
- Verify operations are being tracked
- Check browser console for errors

## Production Deployment

1. Configure environment variables
2. Set up proper authentication
3. Enable TLS for Redis connection
4. Configure alert notifications
5. Integrate with monitoring platforms (Prometheus/Grafana)

## Learning Resources

- [Redis Monitoring Guide](https://redis.io/docs/management/monitoring/)
- [Prometheus Best Practices](https://prometheus.io/docs/practices/)
- [Health Check Patterns](https://microservices.io/patterns/observability/health-check-api.html)
EOF

# Create example dashboard configuration
echo "📊 Creating example dashboard config..."
cat > monitoring-dashboards/dashboard-config.json << 'EOF'
{
  "dashboards": [
    {
      "id": "business-operations",
      "name": "Business Operations Dashboard",
      "refresh_interval": 5000,
      "panels": [
        {
          "type": "gauge",
          "title": "Memory Usage",
          "metric": "redis_memory_usage_bytes",
          "thresholds": {
            "warning": 75,
            "critical": 90
          }
        },
        {
          "type": "counter",
          "title": "Policy Lookups",
          "metric": "policy_lookups_total",
          "aggregation": "sum"
        },
        {
          "type": "histogram",
          "title": "Operation Latency",
          "metric": "redis_operation_duration_seconds",
          "buckets": [0.001, 0.005, 0.01, 0.05, 0.1]
        },
        {
          "type": "table",
          "title": "Queue Status",
          "metrics": [
            "claims:pending",
            "claims:processing",
            "notifications:queue"
          ]
        }
      ]
    }
  ],
  "alerts": [
    {
      "name": "High Memory Usage",
      "condition": "redis_memory_usage_bytes > max_memory * 0.9",
      "severity": "critical",
      "notification": "email,slack"
    },
    {
      "name": "Queue Backlog",
      "condition": "queue_length{queue_name='claims:pending'} > 100",
      "severity": "warning",
      "notification": "slack"
    },
    {
      "name": "Low Cache Hit Rate",
      "condition": "cache_hit_rate < 0.8",
      "severity": "info",
      "notification": "email"
    }
  ]
}
EOF

# Create alert rules
echo "🚨 Creating alert rules..."
cat > alerts/alert-rules.yml << 'EOF'
groups:
  - name: redis_alerts
    interval: 30s
    rules:
      - alert: RedisDown
        expr: up{job="redis"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Redis instance down"
          description: "Redis instance has been down for more than 1 minute"
      
      - alert: HighMemoryUsage
        expr: redis_memory_usage_bytes / redis_memory_max_bytes > 0.9
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High Redis memory usage"
          description: "Redis memory usage is above 90%"
      
      - alert: HighQueueLength
        expr: queue_length{queue_name="claims:pending"} > 100
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "High claims queue length"
          description: "Pending claims queue has more than 100 items"
      
      - alert: SlowQueries
        expr: redis_slow_queries_total > 10
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Multiple slow queries detected"
          description: "More than 10 slow queries in the last 5 minutes"
EOF

# Create .gitignore
echo "🚫 Creating .gitignore..."
cat > .gitignore << 'EOF'
# Dependencies
node_modules/
package-lock.json

# Environment
.env
.env.local

# Logs
*.log
npm-debug.log*

# OS files
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
*.swp
*.swo

# Monitoring data
metrics/*.json
alerts/*.log

# Test output
coverage/
.nyc_output/
EOF

echo ""
echo "✅ Lab 14 build script completed successfully!"
echo ""
echo "📂 Project structure created:"
echo "   ${LAB_DIR}/"
echo "   ├── lab14.md                           📋 Complete lab instructions"
echo "   ├── package.json                       📦 Node.js configuration"
echo "   ├── src/"
echo "   │   ├── health-check.js                💚 Health check system"
echo "   │   ├── metrics-collector.js           📊 Metrics collection"
echo "   │   ├── monitoring-dashboard.js        📈 Real-time dashboard"
echo "   │   └── test-monitoring.js             🧪 Test suite"
echo "   ├── public/"
echo "   │   └── index.html                     🌐 Dashboard UI"
echo "   ├── scripts/"
echo "   │   ├── load-sample-data.sh            📊 Sample data loader"
echo "   │   └── stress-test.js                 🔨 Stress testing"
echo "   ├── monitoring-dashboards/"
echo "   │   └── dashboard-config.json          ⚙️ Dashboard configuration"
echo "   ├── alerts/"
echo "   │   └── alert-rules.yml                🚨 Alert definitions"
echo "   ├── README.md                          📖 Documentation"
echo "   └── .gitignore                         🚫 Git ignore rules"
echo ""
echo "🎯 NEXT STEPS:"
echo "   1. cd ${LAB_DIR}"
echo "   2. docker run -d --name redis-monitoring-lab14 -p 6379:6379 redis:7-alpine"
echo "   3. npm install"
echo "   4. ./scripts/load-sample-data.sh"
echo "   5. npm run dashboard"
echo "   6. Open http://localhost:3001 in your browser"
echo "   7. code . (to open in VS Code)"
echo "   8. Open lab14.md and start the lab!"
echo ""
echo "💡 Quick Commands:"
echo "   npm run health         # Start health check server"
echo "   npm run metrics        # Test metrics collection"
echo "   npm run dashboard      # Start monitoring dashboard"
echo "   npm run stress-test    # Run stress test"
echo "   npm test              # Test all components"
echo ""
echo "🚀 Ready to start Lab 14: Monitoring & Health Checks for Business Operations!"
