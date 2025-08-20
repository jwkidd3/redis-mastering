#!/usr/bin/env node

/**
 * Lab 8 Completion Verification
 */

const redisClient = require('../src/utils/redisClient');
const Claim = require('../src/models/claim');

class LabVerifier {
    constructor() {
        this.tests = [];
        this.score = 0;
        this.maxScore = 10;
    }

    async runAllTests() {
        console.log('🎯 Lab 8 Completion Verification');
        console.log('='.repeat(50));
        
        await redisClient.connect();
        
        await this.testEnvironmentSetup();
        await this.testStreamOperations();
        await this.testClaimLifecycle();
        await this.testConsumerGroups();
        await this.testErrorHandling();
        
        await redisClient.disconnect();
        
        this.displayResults();
        return this.score === this.maxScore;
    }

    async testEnvironmentSetup() {
        console.log('\n🔧 Test: Environment Setup');
        console.log('-'.repeat(30));
        
        try {
            // Test Redis connection
            const client = redisClient.getClient();
            const pong = await client.ping();
            
            if (pong === 'PONG') {
                this.addTest('Redis Connection', 'PASS', 'Successfully connected to Redis');
                this.score += 2;
            } else {
                this.addTest('Redis Connection', 'FAIL', 'Redis ping failed');
            }
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
            await redisClient.createConsumerGroup(streamName, testGroupName, ');
            
            // Verify group was created
            const groups = await client.xInfoGroups(streamName);
            const testGroupExists = groups.some(group => group.name === testGroupName);
            
            if (testGroupExists) {
                this.addTest('Consumer Groups', 'PASS', 'Consumer group created successfully');
                this.score++;
                
                // Clean up test group
                try {
                    await client.xGroupDestroy(streamName, testGroupName);
                } catch (e) {
                    // Ignore cleanup errors
                }
            } else {
                this.addTest('Consumer Groups', 'FAIL', 'Consumer group not found');
            }
        } catch (error) {
            this.addTest('Consumer Groups', 'ERROR', error.message);
        }
    }

    async testErrorHandling() {
        console.log('\n⚠️ Test: Error Handling');
        console.log('-'.repeat(30));
        
        try {
            const claim = new Claim(redisClient);
            
            // Test invalid claim data
            const invalidClaim = {
                // Missing required fields
                description: 'Invalid claim test'
            };
            
            const result = await claim.submitClaim(invalidClaim);
            
            if (!result.success && result.error) {
                this.addTest('Error Handling', 'PASS', 'Invalid data properly rejected');
                this.score++;
            } else {
                this.addTest('Error Handling', 'FAIL', 'Invalid data was accepted');
            }
        } catch (error) {
            this.addTest('Error Handling', 'ERROR', error.message);
        }
    }

    addTest(name, status, message) {
        this.tests.push({ name, status, message });
        const icon = status === 'PASS' ? '✅' : status === 'FAIL' ? '❌' : '⚠️';
        console.log(`${icon} ${name}: ${message}`);
    }

    displayResults() {
        console.log('\n🎯 VERIFICATION RESULTS');
        console.log('='.repeat(50));
        
        const passed = this.tests.filter(t => t.status === 'PASS').length;
        const failed = this.tests.filter(t => t.status === 'FAIL').length;
        const errors = this.tests.filter(t => t.status === 'ERROR').length;
        
        console.log(`📊 Score: ${this.score}/${this.maxScore} (${Math.round(this.score/this.maxScore*100)}%)`);
        console.log(`✅ Passed: ${passed}`);
        console.log(`❌ Failed: ${failed}`);
        console.log(`⚠️  Errors: ${errors}`);
        
        if (this.score === this.maxScore) {
            console.log('\n🎉 EXCELLENT! Lab 8 completed successfully!');
            console.log('🌟 You have mastered Redis Streams for event sourcing!');
        } else if (this.score >= 8) {
            console.log('\n✅ GOOD! Lab mostly completed.');
            console.log('🔧 Review failed tests above for improvement areas.');
        } else if (this.score >= 6) {
            console.log('\n⚠️ PASSING: Lab partially completed.');
            console.log('📚 Review the lab instructions and retry failed sections.');
        } else {
            console.log('\n❌ NEEDS WORK: Significant issues detected.');
            console.log('🆘 Review lab instructions and seek help if needed.');
        }
        
        console.log('\n🚀 Next Lab: Lab 9 - Redis Pub/Sub for Real-time Notifications');
        console.log('📖 Continue building your Redis expertise!');
    }
}

// Run verification if called directly
if (require.main === module) {
    const verifier = new LabVerifier();
    verifier.runAllTests().then(success => {
        process.exit(success ? 0 : 1);
    }).catch(error => {
        console.error('Verification failed:', error);
        process.exit(1);
    });
}

module.exports = LabVerifier;
