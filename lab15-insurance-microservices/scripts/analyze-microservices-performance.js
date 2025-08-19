#!/usr/bin/env node

const axios = require('axios');
const redis = require('redis');

const API_BASE = 'http://localhost:3000/api';
const REDIS_HOST = process.env.REDIS_HOST || 'localhost';
const REDIS_PORT = process.env.REDIS_PORT || 6379;

// Helper function for API calls
async function apiCall(method, url, data = null) {
    try {
        const start = Date.now();
        const response = await axios({ method, url, data, timeout: 10000 });
        const duration = Date.now() - start;
        return { data: response.data, duration };
    } catch (error) {
        console.error(`❌ API call failed: ${method} ${url}`, error.response?.data || error.message);
        throw error;
    }
}

// Redis analysis
async function analyzeRedisPerformance() {
    console.log('🔍 Analyzing Redis Performance');
    console.log('==============================');
    
    const client = redis.createClient({
        socket: { host: REDIS_HOST, port: REDIS_PORT }
    });
    
    try {
        await client.connect();
        
        // Get Redis info
        const info = await client.info();
        const memory = await client.info('memory');
        const stats = await client.info('stats');
        
        console.log('📊 Redis Metrics:');
        
        // Parse memory info
        const memoryLines = memory.split('\r\n');
        const usedMemory = memoryLines.find(line => line.startsWith('used_memory_human:'))?.split(':')[1];
        const maxMemory = memoryLines.find(line => line.startsWith('maxmemory_human:'))?.split(':')[1];
        
        console.log(`   • Used Memory: ${usedMemory || 'N/A'}`);
        console.log(`   • Max Memory: ${maxMemory || 'N/A'}`);
        
        // Parse stats
        const statsLines = stats.split('\r\n');
        const totalConnections = statsLines.find(line => line.startsWith('total_connections_received:'))?.split(':')[1];
        const totalCommands = statsLines.find(line => line.startsWith('total_commands_processed:'))?.split(':')[1];
        
        console.log(`   • Total Connections: ${totalConnections || 'N/A'}`);
        console.log(`   • Total Commands: ${totalCommands || 'N/A'}`);
        
        // Check key distribution
        const keyspaces = ['policy:*', 'claims:*', 'customer:*', 'service:*'];
        console.log('\n🔑 Key Distribution:');
        
        for (const pattern of keyspaces) {
            const keys = await client.keys(pattern);
            console.log(`   • ${pattern}: ${keys.length} keys`);
        }
        
        // Test latency
        console.log('\n⚡ Latency Test:');
        const latencyTests = [];
        
        for (let i = 0; i < 10; i++) {
            const start = Date.now();
            await client.ping();
            const latency = Date.now() - start;
            latencyTests.push(latency);
        }
        
        const avgLatency = latencyTests.reduce((sum, lat) => sum + lat, 0) / latencyTests.length;
        const maxLatency = Math.max(...latencyTests);
        const minLatency = Math.min(...latencyTests);
        
        console.log(`   • Average: ${avgLatency.toFixed(2)}ms`);
        console.log(`   • Min: ${minLatency}ms`);
        console.log(`   • Max: ${maxLatency}ms`);
        
        await client.quit();
        
    } catch (error) {
        console.error('❌ Redis analysis failed:', error.message);
        try { await client.quit(); } catch {}
    }
}

// API performance analysis
async function analyzeApiPerformance() {
    console.log('\n🌐 Analyzing API Performance');
    console.log('============================');
    
    const endpoints = [
        { method: 'GET', url: `${API_BASE}/customers`, name: 'List Customers' },
        { method: 'GET', url: `${API_BASE}/policies`, name: 'List Policies' },
        { method: 'GET', url: `${API_BASE}/claims`, name: 'List Claims' },
        { method: 'GET', url: `${API_BASE}/dashboard/summary`, name: 'Dashboard Summary' }
    ];
    
    console.log('📊 Endpoint Performance:');
    
    for (const endpoint of endpoints) {
        try {
            const result = await apiCall(endpoint.method, endpoint.url);
            console.log(`   • ${endpoint.name}: ${result.duration}ms`);
        } catch (error) {
            console.log(`   • ${endpoint.name}: FAILED`);
        }
    }
    
    // Test cache effectiveness
    console.log('\n🔄 Cache Effectiveness Test:');
    
    try {
        // First request (should miss cache)
        const { duration: firstCall } = await apiCall('GET', `${API_BASE}/dashboard/summary`);
        
        // Second request (should hit cache)
        const { duration: secondCall } = await apiCall('GET', `${API_BASE}/dashboard/summary`);
        
        const improvement = ((firstCall - secondCall) / firstCall * 100).toFixed(1);
        console.log(`   • First call: ${firstCall}ms`);
        console.log(`   • Cached call: ${secondCall}ms`);
        console.log(`   • Cache improvement: ${improvement}%`);
        
    } catch (error) {
        console.log('   • Cache test: FAILED');
    }
}

// Service integration analysis
async function analyzeServiceIntegration() {
    console.log('\n🔗 Analyzing Service Integration');
    console.log('===============================');
    
    const services = [
        { name: 'Policy Service', url: 'http://localhost:3001/health' },
        { name: 'Claims Service', url: 'http://localhost:3002/health' },
        { name: 'Customer Service', url: 'http://localhost:3003/health' },
        { name: 'API Gateway', url: 'http://localhost:3000/health' }
    ];
    
    console.log('🏥 Service Health:');
    
    for (const service of services) {
        try {
            const { data, duration } = await apiCall('GET', service.url);
            const status = data.status === 'healthy' ? '✅' : '❌';
            console.log(`   ${status} ${service.name}: ${duration}ms`);
        } catch (error) {
            console.log(`   ❌ ${service.name}: OFFLINE`);
        }
    }
    
    // Test cross-service communication
    console.log('\n🔄 Cross-Service Communication:');
    
    try {
        // Create test data that should trigger cross-service events
        const customer = await apiCall('POST', `${API_BASE}/customers`, {
            customerId: `PERF-TEST-${Date.now()}`,
            name: 'Performance Test User',
            email: 'perf@test.com'
        });
        
        const policy = await apiCall('POST', `${API_BASE}/policies`, {
            policyNumber: `PERF-POL-${Date.now()}`,
            customerName: customer.data.name,
            policyType: 'Test',
            premium: 100
        });
        
        const claim = await apiCall('POST', `${API_BASE}/claims`, {
            policyNumber: policy.data.policyNumber,
            claimType: 'Test',
            amount: 50
        });
        
        console.log('   ✅ Cross-service data creation successful');
        
        // Cleanup
        await apiCall('DELETE', `${API_BASE}/customers/${customer.data.customerId}`);
        console.log('   🗑️  Test data cleaned up');
        
    } catch (error) {
        console.log('   ❌ Cross-service communication failed');
    }
}

// Generate performance report
async function generateReport() {
    console.log('📋 Generating Performance Report');
    console.log('================================');
    
    const report = {
        timestamp: new Date().toISOString(),
        redis: {},
        api: {},
        services: {},
        recommendations: []
    };
    
    // Add recommendations based on analysis
    report.recommendations = [
        "Monitor Redis memory usage and implement appropriate eviction policies",
        "Consider implementing connection pooling for high-traffic scenarios",
        "Set up proper monitoring and alerting for service health checks",
        "Implement circuit breakers for improved fault tolerance",
        "Consider Redis clustering for horizontal scaling",
        "Optimize cache TTL values based on data access patterns"
    ];
    
    console.log('\n📊 Performance Report Summary:');
    console.log(`   • Generated at: ${report.timestamp}`);
    console.log(`   • Services analyzed: 4`);
    console.log(`   • Recommendations: ${report.recommendations.length}`);
    
    console.log('\n💡 Key Recommendations:');
    report.recommendations.forEach((rec, index) => {
        console.log(`   ${index + 1}. ${rec}`);
    });
    
    return report;
}

// Main execution
async function main() {
    console.log('🚀 Microservices Performance Analysis');
    console.log('=====================================');
    
    try {
        await analyzeRedisPerformance();
        await analyzeApiPerformance();
        await analyzeServiceIntegration();
        await generateReport();
        
        console.log('\n✅ Performance analysis completed successfully!');
        
    } catch (error) {
        console.error('\n❌ Performance analysis failed:', error.message);
        process.exit(1);
    }
}

// Run if called directly
if (require.main === module) {
    main().catch(error => {
        console.error('Analysis failed:', error);
        process.exit(1);
    });
}

module.exports = { 
    analyzeRedisPerformance, 
    analyzeApiPerformance, 
    analyzeServiceIntegration,
    generateReport
};
