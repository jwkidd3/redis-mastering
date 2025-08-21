const cron = require('node-cron');
const winston = require('winston');
const path = require('path');

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
                new winston.transports.File({ filename: path.join(__dirname, '../logs/alerts.log') }),
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
        this.logger.log(severity.toLowerCase() === 'critical' ? 'error' : 
                       severity.toLowerCase() === 'warning' ? 'warn' : 'info', 
                       `ALERT: ${message}`, alert);
        
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