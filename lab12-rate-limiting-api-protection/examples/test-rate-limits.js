// examples/test-rate-limits.js
const axios = require('axios');

const API_BASE = 'http://localhost:3000/api';
const TEST_CUSTOMER = 'CUST_TEST_001';
const TEST_API_KEY = 'test_api_key_12345';

class RateLimitTester {
    constructor() {
        this.results = {
            passed: 0,
            failed: 0,
            rateLimited: 0
        };
    }

    async testCustomerRateLimit() {
        console.log('\n🧪 Testing Customer Rate Limiting...');
        console.log('=====================================');
        
        const requests = [];
        const limit = 10; // Assuming 10 requests per minute for testing
        
        // Make requests up to the limit
        for (let i = 1; i <= limit + 5; i++) {
            requests.push(this.makeQuoteRequest(i));
        }
        
        const results = await Promise.allSettled(requests);
        
        let successCount = 0;
        let rateLimitedCount = 0;
        
        results.forEach((result, index) => {
            if (result.status === 'fulfilled') {
                if (result.value.status === 200) {
                    successCount++;
                    console.log(`✅ Request ${index + 1}: Success`);
                } else if (result.value.status === 429) {
                    rateLimitedCount++;
                    console.log(`🚫 Request ${index + 1}: Rate limited`);
                }
            } else {
                console.log(`❌ Request ${index + 1}: Failed - ${result.reason.message}`);
            }
        });
        
        console.log(`\n📊 Results: ${successCount} successful, ${rateLimitedCount} rate limited`);
        this.results.passed += successCount;
        this.results.rateLimited += rateLimitedCount;
    }

    async makeQuoteRequest(requestNumber) {
        try {
            const response = await axios.post(`${API_BASE}/quotes/auto`, {
                customerId: TEST_CUSTOMER,
                vehicleInfo: {
                    year: 2020,
                    make: 'Toyota',
                    model: 'Camry'
                },
                coverage: 'full'
            }, {
                headers: {
                    'X-Customer-ID': TEST_CUSTOMER,
                    'X-Customer-Tier': 'standard'
                },
                timeout: 5000
            });
            
            return { status: response.status, data: response.data };
            
        } catch (error) {
            if (error.response) {
                return { status: error.response.status, data: error.response.data };
            }
            throw error;
        }
    }

    async testEndpointSpecificLimits() {
        console.log('\n🧪 Testing Endpoint-Specific Rate Limiting...');
        console.log('==============================================');
        
        const endpoints = [
            { path: '/quotes/auto', limit: 10 },
            { path: '/quotes/home', limit: 8 },
            { path: '/quotes/life', limit: 3 }
        ];
        
        for (const endpoint of endpoints) {
            console.log(`\n🎯 Testing ${endpoint.path} (limit: ${endpoint.limit})`);
            
            const requests = [];
            for (let i = 1; i <= endpoint.limit + 2; i++) {
                requests.push(this.makeEndpointRequest(endpoint.path, i));
            }
            
            const results = await Promise.allSettled(requests);
            
            let successCount = 0;
            let rateLimitedCount = 0;
            
            results.forEach((result, index) => {
                if (result.status === 'fulfilled') {
                    if (result.value.status === 200) {
                        successCount++;
                    } else if (result.value.status === 429) {
                        rateLimitedCount++;
                    }
                }
            });
            
            console.log(`   📊 ${successCount} successful, ${rateLimitedCount} rate limited`);
            
            // Wait between endpoint tests
            await new Promise(resolve => setTimeout(resolve, 1000));
        }
    }

    async makeEndpointRequest(endpoint, requestNumber) {
        try {
            const payload = this.getPayloadForEndpoint(endpoint);
            
            const response = await axios.post(`${API_BASE}${endpoint}`, payload, {
                headers: {
                    'X-Customer-ID': `${TEST_CUSTOMER}_${requestNumber}`,
                    'X-Customer-Tier': 'standard'
                },
                timeout: 5000
            });
            
            return { status: response.status, data: response.data };
            
        } catch (error) {
            if (error.response) {
                return { status: error.response.status, data: error.response.data };
            }
            throw error;
        }
    }

    getPayloadForEndpoint(endpoint) {
        const payloads = {
            '/quotes/auto': {
                customerId: TEST_CUSTOMER,
                vehicleInfo: { year: 2020, make: 'Honda', model: 'Civic' },
                coverage: 'basic'
            },
            '/quotes/home': {
                customerId: TEST_CUSTOMER,
                propertyInfo: { type: 'single_family', sqft: 2000, year: 1995 },
                coverage: 'standard'
            },
            '/quotes/life': {
                customerId: TEST_CUSTOMER,
                personalInfo: { age: 35, health: 'good', smoker: false },
                coverage: '250000'
            }
        };
        
        return payloads[endpoint] || {};
    }

    async runAllTests() {
        console.log('🚀 Starting Rate Limit Testing Suite');
        console.log('=====================================');
        
        try {
            await this.testCustomerRateLimit();
            await new Promise(resolve => setTimeout(resolve, 2000));
            
            await this.testEndpointSpecificLimits();
            
            console.log('\n🏁 Test Summary');
            console.log('===============');
            console.log(`✅ Passed: ${this.results.passed}`);
            console.log(`❌ Failed: ${this.results.failed}`);
            console.log(`🚫 Rate Limited: ${this.results.rateLimited}`);
            
        } catch (error) {
            console.error('❌ Test suite failed:', error.message);
        }
    }
}

// Run tests if this file is executed directly
if (require.main === module) {
    const tester = new RateLimitTester();
    tester.runAllTests()
        .then(() => process.exit(0))
        .catch(err => {
            console.error('Error:', err);
            process.exit(1);
        });
}

module.exports = RateLimitTester;
