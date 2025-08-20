#!/usr/bin/env node

/**
 * Consumer Service Tests
 */

const redisClient = require('../src/utils/redisClient');

async function testConsumerSetup() {
    console.log('🧪 Testing Consumer Setup');
    console.log('='.repeat(40));
    
    try {
        await redisClient.connect();
        const client = redisClient.getClient();
        
        console.log('\n📊 Test 1: Stream Exists');
        try {
            const streamInfo = await client.xInfoStream('claims:events');
            console.log('✅ PASS', `Stream exists with ${streamInfo.length} events`);
        } catch (error) {
            if (error.message.includes('no such key')) {
                console.log('⚠️ INFO', 'Stream not yet created (normal for new setup)');
            } else {
                console.log('❌ FAIL', `Stream check failed: ${error.message}`);
            }
        }
        
        console.log('\n👥 Test 2: Consumer Group');
        try {
            await redisClient.createConsumerGroup('claims:events', 'test-consumer-group', 'error) {
                this.addError('❌', 'Package.json', 'Invalid JSON format');
            }
        } else {
            this.addError('❌', 'Package.json', 'File missing');
        }
    }

    checkEnvironmentFiles() {
        if (fs.existsSync('.env.template')) {
            this.addResult('✅', 'Environment', '.env.template found');
        } else {
            this.addError('❌', 'Environment', '.env.template missing');
        }

        if (fs.existsSync('.env')) {
            this.addResult('✅', 'Environment', '.env found');
        } else {
            this.addWarning('⚠️', 'Environment', '.env not configured yet');
        }
    }

    checkSourceFiles() {
        const requiredFiles = [
            'src/models/claim.js',
            'src/services/claimProducer.js',
            'src/consumers/claimProcessor.js',
            'src/utils/redisClient.js',
            'config/redis.js'
        ];

        requiredFiles.forEach(file => {
            if (fs.existsSync(file)) {
                this.addResult('✅', 'Source File', file);
            } else {
                this.addError('❌', 'Source File', `${file} missing`);
            }
        });
    }

    checkTestFiles() {
        const testFiles = [
            'tests/claim.test.js',
            'tests/producer.test.js',
            'tests/consumer.test.js'
        ];

        testFiles.forEach(file => {
            if (fs.existsSync(file)) {
                this.addResult('✅', 'Test File', file);
            } else {
                this.addWarning('⚠️', 'Test File', `${file} missing`);
            }
        });
    }

    checkScripts() {
        const scripts = [
            'scripts/setup-lab.sh',
            'scripts/load-sample-data.js',
            'scripts/verify-completion.js'
        ];

        scripts.forEach(script => {
            if (fs.existsSync(script)) {
                this.addResult('✅', 'Script', script);
                // Check if shell scripts are executable
                if (script.endsWith('.sh')) {
                    try {
                        const stats = fs.statSync(script);
                        if (stats.mode & parseInt('111', 8)) {
                            this.addResult('✅', 'Permissions', `${script} executable`);
                        } else {
                            this.addWarning('⚠️', 'Permissions', `${script} not executable`);
                        }
                    } catch (error) {
                        this.addWarning('⚠️', 'Permissions', `Cannot check ${script} permissions`);
                    }
                }
            } else {
                this.addError('❌', 'Script', `${script} missing`);
            }
        });
    }

    async checkDependencies() {
        if (fs.existsSync('node_modules')) {
            this.addResult('✅', 'Dependencies', 'node_modules found');
            
            // Check specific modules
            const requiredModules = ['redis', 'dotenv', 'uuid'];
            requiredModules.forEach(module => {
                if (fs.existsSync(path.join('node_modules', module))) {
                    this.addResult('✅', 'Module', `${module} installed`);
                } else {
                    this.addError('❌', 'Module', `${module} not installed`);
                }
            });
        } else {
            this.addError('❌', 'Dependencies', 'node_modules missing - run npm install');
        }
    }

    async validateRedisConnection() {
        try {
            // Dynamic import for Redis client
            const { createClient } = require('redis');
            
            // Load environment if available
            if (fs.existsSync('.env')) {
                require('dotenv').config();
            }

            const redisConfig = {
                host: process.env.REDIS_HOST || 'localhost',
                port: process.env.REDIS_PORT || 6379,
                password: process.env.REDIS_PASSWORD || undefined
            };

            const client = createClient({
                socket: {
                    host: redisConfig.host,
                    port: redisConfig.port
                },
                password: redisConfig.password
            });

            await client.connect();
            await client.ping();
            await client.disconnect();
            
            this.addResult('✅', 'Redis Connection', `Connected to ${redisConfig.host}:${redisConfig.port}`);
        } catch (error) {
            this.addError('❌', 'Redis Connection', `Failed: ${error.message}`);
        }
    }

    addResult(icon, category, message) {
        this.results.push({ icon, category, message, type: 'success' });
    }

    addError(icon, category, message) {
        this.errors.push({ icon, category, message, type: 'error' });
        this.results.push({ icon, category, message, type: 'error' });
    }

    addWarning(icon, category, message) {
        this.warnings.push({ icon, category, message, type: 'warning' });
        this.results.push({ icon, category, message, type: 'warning' });
    }

    displayResults() {
        console.log('\n📊 VALIDATION RESULTS');
        console.log('='.repeat(50));
        
        this.results.forEach(result => {
            console.log(`${result.icon} ${result.category}: ${result.message}`);
        });

        console.log('\n📈 SUMMARY');
        console.log('='.repeat(30));
        console.log(`✅ Successful checks: ${this.results.filter(r => r.type === 'success').length}`);
        console.log(`⚠️  Warnings: ${this.warnings.length}`);
        console.log(`❌ Errors: ${this.errors.length}`);

        if (this.errors.length === 0) {
            console.log('\n🎉 VALIDATION PASSED!');
            console.log('Lab 8 environment is ready for use.');
        } else {
            console.log('\n❌ VALIDATION FAILED!');
            console.log('Please fix the errors above before proceeding.');
            console.log('\nCommon fixes:');
            console.log('1. Run: npm install');
            console.log('2. Copy .env.template to .env and configure Redis settings');
            console.log('3. Ensure all required files are present');
            console.log('4. Check Redis connection settings');
        }

        if (this.warnings.length > 0) {
            console.log('\n💡 RECOMMENDATIONS:');
            this.warnings.forEach(warning => {
                console.log(`   ${warning.icon} ${warning.message}`);
            });
        }
    }
}

// Run validation if called directly
if (require.main === module) {
    const validator = new SetupValidator();
    validator.validate().then(success => {
        process.exit(success ? 0 : 1);
    }).catch(error => {
        console.error('Validation failed:', error);
        process.exit(1);
    });
}

module.exports = SetupValidator;
