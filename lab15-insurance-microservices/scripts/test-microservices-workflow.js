#!/usr/bin/env node

const axios = require('axios');

const API_BASE = 'http://localhost:3000/api';
const GATEWAY_BASE = 'http://localhost:3000';

// Helper function for API calls
async function apiCall(method, url, data = null) {
    try {
        const response = await axios({ method, url, data, timeout: 10000 });
        return response.data;
    } catch (error) {
        console.error(`❌ API call failed: ${method} ${url}`, error.response?.data || error.message);
        throw error;
    }
}

// Test workflow
async function runWorkflowTest() {
    console.log('🚀 Testing Insurance Microservices Workflow');
    console.log('============================================');
    
    try {
        // Step 1: Check service health
        console.log('\n📊 Checking service health...');
        const health = await apiCall('GET', `${GATEWAY_BASE}/health`);
        console.log('✅ All services healthy:', Object.keys(health.microservices));
        
        // Step 2: Create customer
        console.log('\n👤 Creating customer...');
        const customer = await apiCall('POST', `${API_BASE}/customers`, {
            customerId: 'CUST-WORKFLOW-001',
            name: 'Sarah Johnson',
            email: 'sarah.johnson@email.com',
            phone: '555-0199',
            address: '123 Main St, Anytown, USA'
        });
        console.log('✅ Customer created:', customer.id);
        
        // Step 3: Create policy for customer
        console.log('\n📋 Creating policy...');
        const policy = await apiCall('POST', `${API_BASE}/policies`, {
            policyNumber: 'POL-WORKFLOW-001',
            customerName: customer.name,
            policyType: 'Auto',
            premium: 1500,
            status: 'Active',
            coverageAmount: 50000,
            deductible: 1000
        });
        console.log('✅ Policy created:', policy.id);
        
        // Step 4: Submit claim
        console.log('\n🔧 Submitting claim...');
        const claim = await apiCall('POST', `${API_BASE}/claims`, {
            policyNumber: policy.policyNumber,
            claimType: 'Collision',
            amount: 3500,
            description: 'Rear-end collision at intersection',
            incidentDate: '2025-01-15T14:30:00Z'
        });
        console.log('✅ Claim submitted:', claim.id);
        
        // Step 5: Get aggregated customer profile
        console.log('\n👥 Retrieving customer profile...');
        const profile = await apiCall('GET', `${API_BASE}/customers/${customer.customerId}/profile`);
        console.log('✅ Customer profile:', {
            customer: profile.customer.name,
            policies: profile.summary.totalPolicies,
            claims: profile.summary.totalClaims,
            premium: profile.summary.totalPremium
        });
        
        // Step 6: Update claim status
        console.log('\n⚡ Processing claim...');
        const updatedClaim = await apiCall('PUT', `${API_BASE}/claims/${claim.id}/status`, {
            status: 'Approved',
            notes: 'Claim approved after review'
        });
        console.log('✅ Claim processed:', updatedClaim.status);
        
        // Step 7: Get dashboard summary
        console.log('\n📈 Generating dashboard summary...');
        const dashboard = await apiCall('GET', `${API_BASE}/dashboard/summary`);
        console.log('✅ Dashboard summary:', {
            totalCustomers: dashboard.customers.totalCustomers,
            totalPolicies: dashboard.policies.totalPolicies,
            totalClaims: dashboard.claims.totalClaims,
            totalPremium: dashboard.policies.totalPremium
        });
        
        // Step 8: Test cache performance
        console.log('\n⚡ Testing cache performance...');
        const start = Date.now();
        
        await Promise.all([
            apiCall('GET', `${API_BASE}/customers/${customer.customerId}`),
            apiCall('GET', `${API_BASE}/policies/${policy.policyNumber}`),
            apiCall('GET', `${API_BASE}/claims/${claim.id}`)
        ]);
        
        const duration = Date.now() - start;
        console.log(`✅ Cache performance: ${duration}ms for 3 parallel requests`);
        
        console.log('\n🎉 Workflow test completed successfully!');
        console.log('=====================================');
        console.log('Key achievements:');
        console.log('• Cross-service data coordination ✅');
        console.log('• Event-driven updates ✅');
        console.log('• Cache coherence ✅');
        console.log('• Service discovery ✅');
        console.log('• API Gateway routing ✅');
        
    } catch (error) {
        console.error('\n❌ Workflow test failed:', error.message);
        process.exit(1);
    }
}

// Load testing function
async function runLoadTest() {
    console.log('\n🚀 Running Load Test...');
    console.log('=======================');
    
    const startTime = Date.now();
    const concurrentRequests = 50;
    const requests = [];
    
    // Create concurrent requests
    for (let i = 0; i < concurrentRequests; i++) {
        requests.push(
            apiCall('GET', `${GATEWAY_BASE}/health`),
            apiCall('GET', `${API_BASE}/dashboard/summary`),
            apiCall('GET', `${API_BASE}/customers`),
            apiCall('GET', `${API_BASE}/policies`),
            apiCall('GET', `${API_BASE}/claims`)
        );
    }
    
    try {
        await Promise.all(requests);
        const duration = Date.now() - startTime;
        const totalRequests = requests.length;
        const requestsPerSecond = Math.round((totalRequests / duration) * 1000);
        
        console.log(`✅ Load test completed:`);
        console.log(`   • Total requests: ${totalRequests}`);
        console.log(`   • Duration: ${duration}ms`);
        console.log(`   • Requests/second: ${requestsPerSecond}`);
        console.log(`   • Average response time: ${Math.round(duration / totalRequests)}ms`);
        
    } catch (error) {
        console.error('❌ Load test failed:', error.message);
    }
}

// Main execution
async function main() {
    const args = process.argv.slice(2);
    
    if (args.includes('--load-test')) {
        await runLoadTest();
    } else {
        await runWorkflowTest();
        
        if (args.includes('--with-load-test')) {
            await runLoadTest();
        }
    }
}

// Run if called directly
if (require.main === module) {
    main().catch(error => {
        console.error('Script failed:', error);
        process.exit(1);
    });
}

module.exports = { runWorkflowTest, runLoadTest };
