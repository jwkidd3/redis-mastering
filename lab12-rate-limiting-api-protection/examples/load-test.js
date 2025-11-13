// examples/load-test.js
const axios = require('axios');

class LoadTester {
    constructor() {
        this.apiBase = 'http://localhost:3000/api';
        this.metrics = {
            totalRequests: 0,
            successfulRequests: 0,
            rateLimitedRequests: 0,
            errorRequests: 0,
            averageResponseTime: 0,
            maxResponseTime: 0,
            minResponseTime: Infinity
        };
    }

    async runLoadTest(options = {}) {
        const {
            concurrency = 10,
            duration = 30, // seconds
            endpoint = '/quotes/auto'
        } = options;

        console.log('⚡ Starting Load Test');
        console.log('====================');
        console.log(`Endpoint: ${endpoint}`);
        console.log(`Concurrency: ${concurrency}`);
        console.log(`Duration: ${duration} seconds`);
        console.log('');

        const startTime = Date.now();
        const endTime = startTime + (duration * 1000);
        const workers = [];

        // Start concurrent workers
        for (let i = 0; i < concurrency; i++) {
            workers.push(this.worker(i, endTime, endpoint));
        }

        // Wait for all workers to complete
        await Promise.all(workers);

        // Calculate final metrics
        this.calculateMetrics();
        this.printResults();
    }

    async worker(workerId, endTime, endpoint) {
        const responseTimes = [];

        while (Date.now() < endTime) {
            try {
                const startRequest = Date.now();
                
                const response = await axios.post(`${this.apiBase}${endpoint}`, {
                    customerId: `LOAD_TEST_${workerId}_${Date.now()}`,
                    vehicleInfo: { year: 2020, make: 'Tesla', model: 'Model 3' },
                    coverage: 'full'
                }, {
                    headers: {
                        'X-Customer-ID': `LOAD_TEST_${workerId}`,
                        'X-Customer-Tier': 'standard'
                    },
                    timeout: 10000
                });

                const responseTime = Date.now() - startRequest;
                responseTimes.push(responseTime);

                this.metrics.totalRequests++;
                
                if (response.status === 200) {
                    this.metrics.successfulRequests++;
                } else if (response.status === 429) {
                    this.metrics.rateLimitedRequests++;
                }

            } catch (error) {
                this.metrics.totalRequests++;
                
                if (error.response && error.response.status === 429) {
                    this.metrics.rateLimitedRequests++;
                } else {
                    this.metrics.errorRequests++;
                }
            }

            // Small delay between requests
            await new Promise(resolve => setTimeout(resolve, 100));
        }

        // Update timing metrics
        if (responseTimes.length > 0) {
            const avgTime = responseTimes.reduce((a, b) => a + b, 0) / responseTimes.length;
            const maxTime = Math.max(...responseTimes);
            const minTime = Math.min(...responseTimes);

            this.metrics.averageResponseTime = Math.max(this.metrics.averageResponseTime, avgTime);
            this.metrics.maxResponseTime = Math.max(this.metrics.maxResponseTime, maxTime);
            this.metrics.minResponseTime = Math.min(this.metrics.minResponseTime, minTime);
        }
    }

    calculateMetrics() {
        this.metrics.successRate = (this.metrics.successfulRequests / this.metrics.totalRequests * 100).toFixed(2);
        this.metrics.rateLimitRate = (this.metrics.rateLimitedRequests / this.metrics.totalRequests * 100).toFixed(2);
        this.metrics.errorRate = (this.metrics.errorRequests / this.metrics.totalRequests * 100).toFixed(2);
    }

    printResults() {
        console.log('\n📊 Load Test Results');
        console.log('====================');
        console.log(`Total Requests: ${this.metrics.totalRequests}`);
        console.log(`Successful: ${this.metrics.successfulRequests} (${this.metrics.successRate}%)`);
        console.log(`Rate Limited: ${this.metrics.rateLimitedRequests} (${this.metrics.rateLimitRate}%)`);
        console.log(`Errors: ${this.metrics.errorRequests} (${this.metrics.errorRate}%)`);
        console.log('');
        console.log('Response Times:');
        console.log(`  Average: ${this.metrics.averageResponseTime.toFixed(2)}ms`);
        console.log(`  Maximum: ${this.metrics.maxResponseTime}ms`);
        console.log(`  Minimum: ${this.metrics.minResponseTime}ms`);
        console.log('');
        
        if (this.metrics.rateLimitRate > 0) {
            console.log('✅ Rate limiting is working correctly!');
        } else {
            console.log('⚠️ No rate limiting detected - check configuration');
        }
    }
}

// Run load test if this file is executed directly
if (require.main === module) {
    const loadTester = new LoadTester();
    
    // Parse command line arguments
    const args = process.argv.slice(2);
    const options = {};
    
    for (let i = 0; i < args.length; i += 2) {
        const key = args[i].replace('--', '');
        const value = args[i + 1];
        
        if (key === 'concurrency' || key === 'duration') {
            options[key] = parseInt(value);
        } else {
            options[key] = value;
        }
    }
    
    loadTester.runLoadTest(options)
        .then(() => process.exit(0))
        .catch(err => {
            console.error('Error:', err);
            process.exit(1);
        });
}

module.exports = LoadTester;
