const HealthCheckService = require('./health-check-service');
const ProductionAlertingSystem = require('./alerting-system');
const MonitoringDashboard = require('./monitoring-dashboard');

async function startProductionMonitoring() {
    console.log('🚀 Starting Production Redis Monitoring System...');
    console.log('');
    
    try {
        // Initialize health check service
        const healthService = new HealthCheckService();
        
        // Initialize alerting system
        const alerting = new ProductionAlertingSystem(healthService);
        
        // Start health check service
        await healthService.start(3000);
        
        // Start monitoring dashboard
        const dashboard = new MonitoringDashboard(healthService, alerting);
        dashboard.start(4000);
        
        console.log('');
        console.log('✅ Production monitoring system started successfully');
        console.log('');
        console.log('📊 Services running:');
        console.log('   • Health Check API: http://localhost:3000/health');
        console.log('   • Business Metrics: http://localhost:3000/health/business');
        console.log('   • Performance Metrics: http://localhost:3000/health/performance');
        console.log('   • Monitoring Dashboard: http://localhost:4000');
        console.log('   • Real-time Metrics: http://localhost:4000/api/metrics/realtime');
        console.log('   • Alerts API: http://localhost:4000/api/alerts');
        console.log('');
        console.log('💡 Tip: Open http://localhost:4000 in your browser to see the dashboard');
        console.log('');
        
        // Graceful shutdown
        process.on('SIGINT', async () => {
            console.log('\n🛑 Shutting down monitoring system...');
            await healthService.stop();
            dashboard.stop();
            process.exit(0);
        });
        
        process.on('SIGTERM', async () => {
            console.log('\n🛑 Shutting down monitoring system...');
            await healthService.stop();
            dashboard.stop();
            process.exit(0);
        });
        
    } catch (error) {
        console.error('❌ Failed to start monitoring system:', error.message);
        process.exit(1);
    }
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