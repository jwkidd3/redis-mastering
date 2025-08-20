#!/usr/bin/env node

/**
 * Producer Service Tests
 */

const http = require('http');

function makeRequest(options, data = null) {
    return new Promise((resolve, reject) => {
        const req = http.request(options, (res) => {
            let body = '';
            res.on('data', chunk => body += chunk);
            res.on('end', () => {
                try {
                    const response = JSON.parse(body);
                    resolve({ status: res.statusCode, data: response });
                } catch (e) {
                    resolve({ status: res.statusCode, data: body });
                }
            });
        });
        
        req.on('error', reject);
        
        if (data) {
            req.write(JSON.stringify(data));
        }
        req.end();
    });
}

async function testProducerAPI() {
    console.log('🧪 Testing Claim Producer API');
    console.log('='.repeat(40));
    
    const baseOptions = {
        hostname: 'localhost',
        port: 3001,
        headers: {
            'Content-Type': 'application/json'
        }
    };
    
    try {
        console.log('\n🔍 Test 1: Health Check');
        const healthResult = await makeRequest({
            ...baseOptions,
            path: '/health',
            method: 'GET'
        });
        
        console.log(healthResult.status === 200 ? '✅ PASS' : '❌ FAIL',
                   `Health check: ${healthResult.status}`);
        
        console.log('\n📝 Test 2: Submit Claim');
        const testClaim = {
            customer_id: 'API-TEST-001',
            policy_number: 'POL-API-001',
            amount: 2000,
            description: 'API test claim'
        };
        
        const submitResult = await makeRequest({
            ...baseOptions,
            path: '/claims',
            method: 'POST'
        }, testClaim);
        
        console.log(submitResult.status === 201 ? '✅ PASS' : '❌ FAIL',
                   `Claim submission: ${submitResult.status}`);
        
        if (submitResult.status === 201) {
            const claimId = submitResult.data.claim_id;
            
            console.log('\n📋 Test 3: Update Status');
            const statusUpdate = { status: 'under_review' };
            const statusResult = await makeRequest({
                ...baseOptions,
                path: `/claims/${claimId}/status`,
                method: 'PUT'
            }, statusUpdate);
            
            console.log(statusResult.status === 200 ? '✅ PASS' : '❌ FAIL',
                       `Status update: ${statusResult.status}`);
            
            console.log('\n📚 Test 4: Get History');
            const historyResult = await makeRequest({
                ...baseOptions,
                path: `/claims/${claimId}/history`,
                method: 'GET'
            });
            
            console.log(historyResult.status === 200 ? '✅ PASS' : '❌ FAIL',
                       `History retrieval: ${historyResult.status}`);
        }
        
        console.log('\n❌ Test 5: Invalid Claim');
        const invalidClaim = { description: 'Missing fields' };
        const invalidResult = await makeRequest({
            ...baseOptions,
            path: '/claims',
            method: 'POST'
        }, invalidClaim);
        
        console.log(invalidResult.status === 400 ? '✅ PASS' : '❌ FAIL',
                   `Invalid claim rejection: ${invalidResult.status}`);
        
        console.log('\n🎉 Producer API tests completed!');
        
    } catch (error) {
        console.error('❌ Producer not running or test failed:', error.message);
        console.log('💡 Start the producer with: npm run producer');
    }
}

if (require.main === module) {
    testProducerAPI();
}

module.exports = { testProducerAPI };
