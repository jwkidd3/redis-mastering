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
            'config/redis.js',
            'src/app.js'
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
            'tests/consumer.test.js',
            'tests/run-all-tests.js'
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
                            this.addWarning('⚠️', 'Permissions', `${script} not executable - run: chmod +x ${script}`);
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
                    this.addError('❌', 'Module', `${module} not installed - run: npm install`);
                }
            });
        } else {
            this.addError('❌', 'Dependencies', 'node_modules missing - run: npm install');
        }
    }

    async validateRedisConnection() {
        try {
            // Load environment if available
            if (fs.existsSync('.env')) {
                require('dotenv').config();
            }

            // Check if Redis module is available
            let redisModule;
            try {
                redisModule = require('redis');
            } catch (error) {
                this.addError('❌', 'Redis Module', 'Redis package not installed - run: npm install');
                return;
            }

            const redisConfig = {
                host: process.env.REDIS_HOST || 'localhost',
                port: parseInt(process.env.REDIS_PORT) || 6379,
                password: process.env.REDIS_PASSWORD || undefined
            };

            const client = redisModule.createClient({
                socket: {
                    host: redisConfig.host,
                    port: redisConfig.port,
                    connectTimeout: 5000
                },
                password: redisConfig.password
            });

            // Set up error handler to prevent unhandled errors
            client.on('error', (err) => {
                // Error will be handled by the catch block
            });

            await client.connect();
            const pong = await client.ping();
            await client.disconnect();
            
            if (pong === 'PONG') {
                this.addResult('✅', 'Redis Connection', `Connected to ${redisConfig.host}:${redisConfig.port}`);
            } else {
                this.addError('❌', 'Redis Connection', 'Unexpected ping response');
            }
        } catch (error) {
            if (error.message.includes('ECONNREFUSED')) {
                this.addError('❌', 'Redis Connection', `Connection refused - check if Redis is running and .env configuration`);
            } else if (error.message.includes('ETIMEDOUT')) {
                this.addError('❌', 'Redis Connection', 'Connection timeout - check Redis host and port in .env');
            } else if (error.message.includes('ENOTFOUND')) {
                this.addError('❌', 'Redis Connection', 'Redis host not found - check REDIS_HOST in .env');
            } else {
                this.addError('❌', 'Redis Connection', `Failed: ${error.message}`);
            }
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
            console.log('\n🚀 Next steps:');
            console.log('1. Follow lab8.md instructions');
            console.log('2. Start with: npm run producer');
            console.log('3. Process claims: npm run consumer');
            console.log('4. View analytics: npm run analytics');
        } else {
            console.log('\n❌ VALIDATION FAILED!');
            console.log('Please fix the errors above before proceeding.');
            console.log('\n🔧 Common fixes:');
            console.log('1. Install dependencies: npm install');
            console.log('2. Configure environment: cp .env.template .env && nano .env');
            console.log('3. Make scripts executable: chmod +x scripts/*.sh');
            console.log('4. Check Redis connection in .env file');
            console.log('5. Ensure Redis server is running and accessible');
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
        console.error('❌ Validation script error:', error.message);
        console.log('\n🔧 Troubleshooting:');
        console.log('1. Ensure you are in the lab8-claims-event-sourcing directory');
        console.log('2. Run: npm install');
        console.log('3. Check that all files were created properly');
        process.exit(1);
    });
}

module.exports = SetupValidator;
