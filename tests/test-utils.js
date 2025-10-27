/**
 * Test Utilities for Redis Mastering Course Integration Tests
 */

const { createClient } = require('redis');
const { exec } = require('child_process');
const { promisify } = require('util');
const fs = require('fs').promises;
const path = require('path');

const execAsync = promisify(exec);

class TestUtils {
    constructor() {
        this.redisClient = null;
        this.testResults = [];
    }

    /**
     * Initialize Redis client for testing
     */
    async initRedisClient(options = {}) {
        const config = {
            host: options.host || 'localhost',
            port: options.port || 6379,
            password: options.password || undefined,
            socket: {
                reconnectStrategy: false
            }
        };

        this.redisClient = createClient(config);

        this.redisClient.on('error', (err) => {
            console.error('Redis Client Error:', err);
        });

        await this.redisClient.connect();
        return this.redisClient;
    }

    /**
     * Close Redis connection
     */
    async closeRedisClient() {
        if (this.redisClient && this.redisClient.isOpen) {
            await this.redisClient.quit();
            this.redisClient = null;
        }
    }

    /**
     * Check if Redis is running
     */
    async isRedisRunning(port = 6379) {
        try {
            const client = createClient({
                socket: {
                    host: 'localhost',
                    port,
                    reconnectStrategy: false
                }
            });
            await client.connect();
            await client.ping();
            await client.quit();
            return true;
        } catch (error) {
            return false;
        }
    }

    /**
     * Flush all Redis databases
     */
    async flushAllDatabases() {
        if (!this.redisClient) {
            await this.initRedisClient();
        }
        await this.redisClient.flushAll();
    }

    /**
     * Execute shell script and return output
     */
    async executeScript(scriptPath, cwd) {
        try {
            const { stdout, stderr } = await execAsync(`bash ${scriptPath}`, { cwd });
            return { success: true, stdout, stderr };
        } catch (error) {
            return {
                success: false,
                stdout: error.stdout || '',
                stderr: error.stderr || error.message
            };
        }
    }

    /**
     * Execute Node.js script and return output
     */
    async executeNodeScript(scriptPath, cwd) {
        try {
            const { stdout, stderr } = await execAsync(`node ${scriptPath}`, { cwd, timeout: 30000 });
            return { success: true, stdout, stderr };
        } catch (error) {
            return {
                success: false,
                stdout: error.stdout || '',
                stderr: error.stderr || error.message
            };
        }
    }

    /**
     * Check if file exists
     */
    async fileExists(filePath) {
        try {
            await fs.access(filePath);
            return true;
        } catch {
            return false;
        }
    }

    /**
     * Read file content
     */
    async readFile(filePath) {
        try {
            return await fs.readFile(filePath, 'utf-8');
        } catch (error) {
            throw new Error(`Failed to read file ${filePath}: ${error.message}`);
        }
    }

    /**
     * Log test result
     */
    logTest(labName, testName, passed, message = '') {
        const result = {
            lab: labName,
            test: testName,
            passed,
            message,
            timestamp: new Date().toISOString()
        };
        this.testResults.push(result);

        const status = passed ? '✓' : '✗';
        const color = passed ? '\x1b[32m' : '\x1b[31m';
        const reset = '\x1b[0m';

        console.log(`  ${color}${status}${reset} ${testName}${message ? ': ' + message : ''}`);

        return result;
    }

    /**
     * Log lab header
     */
    logLabHeader(labNumber, labName) {
        console.log(`\n${'='.repeat(80)}`);
        console.log(`Lab ${labNumber}: ${labName}`);
        console.log(`${'='.repeat(80)}`);
    }

    /**
     * Get test summary
     */
    getTestSummary() {
        const total = this.testResults.length;
        const passed = this.testResults.filter(r => r.passed).length;
        const failed = total - passed;
        const percentage = total > 0 ? ((passed / total) * 100).toFixed(2) : 0;

        return {
            total,
            passed,
            failed,
            percentage,
            results: this.testResults
        };
    }

    /**
     * Print test summary
     */
    printTestSummary() {
        const summary = this.getTestSummary();

        console.log(`\n${'='.repeat(80)}`);
        console.log('TEST SUMMARY');
        console.log(`${'='.repeat(80)}`);
        console.log(`Total Tests: ${summary.total}`);
        console.log(`Passed: \x1b[32m${summary.passed}\x1b[0m`);
        console.log(`Failed: \x1b[31m${summary.failed}\x1b[0m`);
        console.log(`Success Rate: ${summary.percentage}%`);

        if (summary.failed > 0) {
            console.log(`\n${'='.repeat(80)}`);
            console.log('FAILED TESTS:');
            console.log(`${'='.repeat(80)}`);
            summary.results
                .filter(r => !r.passed)
                .forEach(r => {
                    console.log(`\x1b[31m✗\x1b[0m ${r.lab} - ${r.test}`);
                    if (r.message) console.log(`  ${r.message}`);
                });
        }

        return summary;
    }

    /**
     * Wait for specified milliseconds
     */
    async wait(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    /**
     * Check Redis key existence
     */
    async keyExists(key) {
        if (!this.redisClient) {
            await this.initRedisClient();
        }
        return await this.redisClient.exists(key) === 1;
    }

    /**
     * Get Redis key value
     */
    async getValue(key) {
        if (!this.redisClient) {
            await this.initRedisClient();
        }
        return await this.redisClient.get(key);
    }

    /**
     * Check if Docker container is running
     */
    async isDockerContainerRunning(containerName) {
        try {
            const { stdout } = await execAsync(`docker ps --filter "name=${containerName}" --format "{{.Names}}"`);
            return stdout.trim() === containerName;
        } catch {
            return false;
        }
    }

    /**
     * Start Docker Compose in directory
     */
    async startDockerCompose(directory) {
        try {
            await execAsync('docker-compose up -d', { cwd: directory });
            await this.wait(5000); // Wait for services to start
            return true;
        } catch (error) {
            console.error(`Failed to start docker-compose: ${error.message}`);
            return false;
        }
    }

    /**
     * Stop Docker Compose in directory
     */
    async stopDockerCompose(directory) {
        try {
            await execAsync('docker-compose down', { cwd: directory });
            return true;
        } catch (error) {
            console.error(`Failed to stop docker-compose: ${error.message}`);
            return false;
        }
    }

    /**
     * Save test results to JSON file
     */
    async saveTestResults(outputPath) {
        const summary = this.getTestSummary();
        await fs.writeFile(
            outputPath,
            JSON.stringify(summary, null, 2),
            'utf-8'
        );
        console.log(`\nTest results saved to: ${outputPath}`);
    }
}

module.exports = TestUtils;
