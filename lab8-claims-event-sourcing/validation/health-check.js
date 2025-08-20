#!/usr/bin/env node

/**
 * Lab 8 Health Check Script
 * Quick runtime validation for running services
 */

const { createClient } = require('redis');

class HealthChecker {
    constructor() {
        this.checks = [];
    }

    async runAllChecks() {
        console.log('🏥 Lab 8 Health Check');
        console.log('='.repeat(30));
        
        await this.checkRedisConnection();
        await this.checkStreams();
        await this.checkConsumerGroups();
        
        this.displayResults();
        
        return this.checks.every(check => check.passed);
    }

    async checkRedisConnection() {
        try {
            require('dotenv').config();
            
            const client = createClient({
                socket: {
                    host: process.env.REDIS_HOST || 'localhost',
                    port: process.env.REDIS_PORT || 6379
                },
                password: process.env.REDIS_PASSWORD
            });

            await client.connect();
            const pong = await client.ping();
            await client.disconnect();
            
            this.addCheck('Redis Connection', true, 'Connected successfully');
        } catch (error) {
            this.addCheck('Redis Connection', false, error.message);
        }
    }

    async checkStreams() {
        try {
            require('dotenv').config();
            
            const client = createClient({
                socket: {
                    host: process.env.REDIS_HOST || 'localhost',
                    port: process.env.REDIS_PORT || 6379
                },
                password: process.env.REDIS_PASSWORD
            });

            await client.connect();
            
            // Check if claims stream exists and has data
            try {
                const info = await client.xInfoStream('claims:events');
                this.addCheck('Claims Stream', true, `${info.length} events in stream`);
            } catch (error) {
                if (error.message.includes('no such key')) {
                    this.addCheck('Claims Stream', true, 'Stream ready (empty)');
                } else {
                    throw error;
                }
            }
            
            await client.disconnect();
        } catch (error) {
            this.addCheck('Claims Stream', false, error.message);
        }
    }

    async checkConsumerGroups() {
        try {
            require('dotenv').config();
            
            const client = createClient({
                socket: {
                    host: process.env.REDIS_HOST || 'localhost',
                    port: process.env.REDIS_PORT || 6379
                },
                password: process.env.REDIS_PASSWORD
            });

            await client.connect();
            
            try {
                const groups = await client.xInfoGroups('claims:events');
                if (groups.length > 0) {
                    this.addCheck('Consumer Groups', true, `${groups.length} groups configured`);
                } else {
                    this.addCheck('Consumer Groups', true, 'No groups yet (normal for new setup)');
                }
            } catch (error) {
                if (error.message.includes('no such key')) {
                    this.addCheck('Consumer Groups', true, 'Ready for consumer group creation');
                } else {
                    throw error;
                }
            }
            
            await client.disconnect();
        } catch (error) {
            this.addCheck('Consumer Groups', false, error.message);
        }
    }

    addCheck(name, passed, message) {
        this.checks.push({ name, passed, message });
    }

    displayResults() {
        console.log('\n📊 HEALTH CHECK RESULTS');
        console.log('='.repeat(40));
        
        this.checks.forEach(check => {
            const icon = check.passed ? '✅' : '❌';
            console.log(`${icon} ${check.name}: ${check.message}`);
        });

        const passedCount = this.checks.filter(c => c.passed).length;
        const totalCount = this.checks.length;
        
        console.log(`\n📈 Overall Health: ${passedCount}/${totalCount} checks passed`);
        
        if (passedCount === totalCount) {
            console.log('🎉 All systems healthy!');
        } else {
            console.log('⚠️  Some issues detected - check the details above');
        }
    }
}

// Run health check if called directly
if (require.main === module) {
    const checker = new HealthChecker();
    checker.runAllChecks().then(success => {
        process.exit(success ? 0 : 1);
    }).catch(error => {
        console.error('Health check failed:', error);
        process.exit(1);
    });
}

module.exports = HealthChecker;
