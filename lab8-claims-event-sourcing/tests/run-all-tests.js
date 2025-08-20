const chalk = require('chalk');
const RedisClient = require('../src/utils/redis-client');

class TestSuite {
    constructor() {
        this.results = [];
        this.redisClient = new RedisClient();
    }

    async runTest(testName, testFunction) {
        console.log(chalk.blue(`\n🧪 Running: ${testName}`));
        console.log(''.padEnd(50, '-'));
        
        try {
            await testFunction();
            console.log(chalk.green(`✅ ${testName} PASSED`));
            this.results.push({ test: testName, status: 'PASSED' });
        } catch (error) {
            console.log(chalk.red(`❌ ${testName} FAILED: ${error.message}`));
            this.results.push({ test: testName, status: 'FAILED', error: error.message });
        }
    }

    async testBasicConnection() {
        const client = await this.redisClient.connect();
        await client.ping();
        console.log(chalk.green('Connection established successfully'));
    }

    async testStreamOperations() {
        const client = this.redisClient.getClient();
        
        // Test XADD
        const eventId = await client.xAdd('test:events', '*', { 
            type: 'test.event',
            data: JSON.stringify({ test: true })
        });
        
        if (!eventId) throw new Error('XADD failed');
        console.log(chalk.green('XADD operation successful'));
        
        // Test XREAD
        const events = await client.xRead([{ key: 'test:events', id: '0' }]);
        if (!events || events.length === 0) throw new Error('XREAD failed');
        console.log(chalk.green('XREAD operation successful'));
        
        // Test XLEN
        const length = await client.xLen('test:events');
        if (length === 0) throw new Error('XLEN failed');
        console.log(chalk.green('XLEN operation successful'));
        
        // Cleanup
        await client.del('test:events');
    }

    async testConsumerGroups() {
        const client = this.redisClient.getClient();
        
        // Create test stream
        await client.xAdd('test:consumer:stream', '*', { data: 'test' });
        
        // Create consumer group
        try {
            await client.xGroupCreate('test:consumer:stream', 'test-group', '0', { MKSTREAM: true });
        } catch (error) {
            if (!error.message.includes('BUSYGROUP')) {
                throw error;
            }
        }
        
        // Test XREADGROUP
        const messages = await client.xReadGroup('test-group', 'test-consumer', [
            { key: 'test:consumer:stream', id: '>' }
        ], { COUNT: 1 });
        
        console.log(chalk.green('Consumer group operations successful'));
        
        // Cleanup
        await client.xGroupDestroy('test:consumer:stream', 'test-group');
        await client.del('test:consumer:stream');
    }

    async testEventSourcing() {
        const ClaimsProducer = require('../src/services/claims-producer');
        
        // Test if producer can be instantiated
        const producer = new ClaimsProducer();
        if (!producer) throw new Error('ClaimsProducer instantiation failed');
        
        console.log(chalk.green('Event sourcing components available'));
    }

    async testAnalytics() {
        const client = this.redisClient.getClient();
        
        // Test sorted set operations for analytics
        await client.zAdd('test:analytics', [{ score: 100, value: 'metric1' }]);
        const rank = await client.zRank('test:analytics', 'metric1');
        
        if (rank !== 0) throw new Error('Analytics operations failed');
        console.log(chalk.green('Analytics operations successful'));
        
        // Cleanup
        await client.del('test:analytics');
    }

    async displayResults() {
        console.log(chalk.blue('\n📊 TEST RESULTS SUMMARY'));
        console.log(''.padEnd(50, '='));
        
        let passed = 0;
        let failed = 0;
        
        this.results.forEach(result => {
            if (result.status === 'PASSED') {
                console.log(chalk.green(`✅ ${result.test}`));
                passed++;
            } else {
                console.log(chalk.red(`❌ ${result.test}: ${result.error}`));
                failed++;
            }
        });
        
        console.log(''.padEnd(50, '='));
        console.log(chalk.blue(`Total Tests: ${this.results.length}`));
        console.log(chalk.green(`Passed: ${passed}`));
        console.log(chalk.red(`Failed: ${failed}`));
        
        const percentage = Math.round((passed / this.results.length) * 100);
        
        if (failed === 0) {
            console.log(chalk.green('\n🎉 ALL TESTS PASSED! Lab 8 is ready to go!'));
        } else {
            console.log(chalk.red(`\n❌ ${failed} test(s) failed. Please fix issues before proceeding.`));
            process.exit(1);
        }
    }

    async run() {
        console.log(chalk.magenta('🚀 Lab 8 - Comprehensive Test Suite'));
        console.log(chalk.magenta('===================================='));
        
        await this.runTest('Basic Connection', () => this.testBasicConnection());
        await this.runTest('Stream Operations', () => this.testStreamOperations());
        await this.runTest('Consumer Groups', () => this.testConsumerGroups());
        await this.runTest('Event Sourcing Components', () => this.testEventSourcing());
        await this.runTest('Analytics Operations', () => this.testAnalytics());
        
        await this.displayResults();
        await this.redisClient.disconnect();
    }
}

if (require.main === module) {
    const suite = new TestSuite();
    suite.run().catch(console.error);
}

module.exports = TestSuite;
