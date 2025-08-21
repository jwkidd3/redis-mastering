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
        
        this.app.post('/api/alerts/:id/acknowledge', express.json(), (req, res) => {
            const alert = this.alerting.acknowledgeAlert(req.params.id);
            if (alert) {
                res.json(alert);
            } else {
                res.status(404).json({ error: 'Alert not found' });
            }
        });
        
        // Health endpoint for the dashboard itself
        this.app.get('/api/health', (req, res) => {
            res.json({
                status: 'healthy',
                timestamp: new Date().toISOString(),
                service: 'monitoring-dashboard'
            });
        });
    }
    
    start(port = 4000) {
        this.server = this.app.listen(port, () => {
            console.log(`📊 Monitoring Dashboard running on port ${port}`);
            console.log(`🔗 Dashboard URL: http://localhost:${port}`);
            console.log(`📡 Real-time API: http://localhost:${port}/api/metrics/realtime`);
            console.log(`🚨 Alerts API: http://localhost:${port}/api/alerts`);
        });
    }
    
    stop() {
        if (this.server) {
            this.server.close();
        }
    }
}

module.exports = MonitoringDashboard;