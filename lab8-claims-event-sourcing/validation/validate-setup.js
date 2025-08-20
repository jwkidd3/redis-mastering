#!/usr/bin/env node

/**
 * Lab 8 Setup Validation Script
 * Validates all requirements for Claims Event Sourcing lab
 */

const fs = require('fs');
const path = require('path');

class SetupValidator {
    constructor() {
        this.errors = [];
        this.warnings = [];
        this.results = [];
    }

    async validate() {
        console.log('🔍 Lab 8 Setup Validation');
        console.log('='.repeat(50));
        
        this.checkNodeJs();
        this.checkProjectStructure();
        this.checkPackageJson();
        this.checkEnvironmentFiles();
        this.checkSourceFiles();
        this.checkTestFiles();
        this.checkScripts();
        
        await this.checkDependencies();
        await this.validateRedisConnection();
        
        this.displayResults();
        
        return this.errors.length === 0;
    }

    checkNodeJs() {
        const nodeVersion = process.version;
        const majorVersion = parseInt(nodeVersion.slice(1).split('.')[0]);
        
        if (majorVersion >= 16) {
            this.addResult('✅', 'Node.js', `Version ${nodeVersion} (compatible)`);
        } else {
            this.addError('❌', 'Node.js', `Version ${nodeVersion} (requires 16+)`);
        }
    }

    checkProjectStructure() {
        const requiredDirs = [
            'src/models',
            'src/services', 
            'src/consumers',
            'src/utils',
            'config',
            'scripts',
            'tests',
            'validation'
        ];

        requiredDirs.forEach(dir => {
            if (fs.existsSync(dir)) {
                this.addResult('✅', 'Directory', dir);
            } else {
                this.addError('❌', 'Directory', `${dir} missing`);
            }
        });
    }

    checkPackageJson() {
        if (fs.existsSync('package.json')) {
            try {
                const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
                this.addResult('✅', 'Package.json', 'Found and valid');
                
                // Check dependencies
                const requiredDeps = ['redis', 'dotenv', 'uuid'];
                requiredDeps.forEach(dep => {
                    if (pkg.dependencies && pkg.dependencies[dep]) {
                        this.addResult('✅', 'Dependency', `${dep} declared`);
                    } else {
                        this.addError('❌', 'Dependency', `${dep} missing from package.json`);
                    }
                });
            } catch (error) {
            this.addTest('Redis Connection', 'ERROR', error.message);
        }
    }

    async testStreamOperations() {
        console.log('\n📊 Test: Stream Operations');
        console.log('-'.repeat(30));
        
        try {
            const claim = new Claim(redisClient);
            
            // Test claim submission
            const testClaim = {
                customer_id: 'TEST-CUST-001',
                policy_number: 'TEST-POL-001',
                amount: 1000,
                description: 'Test claim for verification'
            };
            
            const result = await claim.submitClaim(testClaim);
            
            if (result.success) {
                this.addTest('Claim Submission', 'PASS', `Claim created: ${result.claim_id}`);
                this.score++;
                
                // Test claim history retrieval
                const history = await claim.getClaimHistory(result.claim_id);
                if (history.success && history.events.length > 0) {
                    this.addTest('Claim History', 'PASS', `Retrieved ${history.events.length} events`);
                    this.score++;
                } else {
                    this.addTest('Claim History', 'FAIL', 'Could not retrieve claim history');
                }
            } else {
                this.addTest('Claim Submission', 'FAIL', result.error);
            }
        } catch (error) {
            this.addTest('Stream Operations', 'ERROR', error.message);
        }
    }

    async testClaimLifecycle() {
        console.log('\n🔄 Test: Claim Lifecycle');
        console.log('-'.repeat(30));
        
        try {
            const claim = new Claim(redisClient);
            const client = redisClient.getClient();
            
            // Submit test claim
            const testClaim = {
                customer_id: 'LIFECYCLE-TEST',
                policy_number: 'POL-LIFECYCLE',
                amount: 2500,
                description: 'Lifecycle test claim'
            };
            
            const submitResult = await claim.submitClaim(testClaim);
            if (!submitResult.success) {
                this.addTest('Claim Lifecycle', 'FAIL', 'Could not submit test claim');
                return;
            }
            
            const claimId = submitResult.claim_id;
            
            // Test status update
            const updateResult = await claim.updateClaimStatus(claimId, 'under_review', {
                reviewer: 'test_agent'
            });
            
            if (updateResult.success) {
                this.addTest('Status Update', 'PASS', 'Status updated successfully');
                this.score++;
            } else {
                this.addTest('Status Update', 'FAIL', updateResult.error);
            }
            
            // Test approval
            const approveResult = await claim.approveClaim(claimId, 2500, 'test_reviewer');
            if (approveResult.success) {
                this.addTest('Claim Approval', 'PASS', 'Claim approved successfully');
                this.score++;
            } else {
                this.addTest('Claim Approval', 'FAIL', approveResult.error);
            }
            
            // Test payment
            const paymentResult = await claim.processPayment(claimId, 2500);
            if (paymentResult.success) {
                this.addTest('Payment Processing', 'PASS', 'Payment processed successfully');
                this.score++;
            } else {
                this.addTest('Payment Processing', 'FAIL', paymentResult.error);
            }
            
        } catch (error) {
            this.addTest('Claim Lifecycle', 'ERROR', error.message);
        }
    }

    async testConsumerGroups() {
        console.log('\n👥 Test: Consumer Groups');
        console.log('-'.repeat(30));
        
        try {
            const client = redisClient.getClient();
            const streamName = 'claims:events';
            const testGroupName = 'test-group-verification';
            
            // Create test consumer group
            await redisClient.createConsumerGroup(streamName, testGroupName, 'error) {
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
