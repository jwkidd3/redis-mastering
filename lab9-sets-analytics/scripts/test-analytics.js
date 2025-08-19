const AnalyticsDashboard = require('../src/analytics-dashboard');
const client = require('../src/connection');

async function testAnalytics() {
    console.log('🧪 Testing Lab 9 Analytics Functions');
    console.log('='.repeat(50));

    try {
        const dashboard = new AnalyticsDashboard();

        // Generate full dashboard
        await dashboard.generateDashboard();

        // Test real-time update
        console.log('\n🔄 Testing real-time analytics update...');
        await dashboard.updateAnalytics(
            'CUST009',
            'AGENT006',
            7500,
            { age: 35, claimCount: 1, creditScore: 720, violations: 0, policyType: 'premium' }
        );

        // Generate dashboard again to see changes
        console.log('\n📊 Updated dashboard:');
        await dashboard.generateDashboard();

        console.log('\n✅ Analytics testing completed successfully!');

    } catch (error) {
        console.error('❌ Analytics test failed:', error);
    } finally {
        client.quit();
    }
}

testAnalytics();
