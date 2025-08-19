// Complete Claims Processing System Solution
// This file contains the integrated solution for Lab 8

const redis = require('redis');
const { v4: uuidv4 } = require('uuid');

class CompleteClaimsSystem {
    constructor(redisConfig = {}) {
        this.client = redis.createClient({
            host: redisConfig.host || 'redis-server.training.com',
            port: redisConfig.port || 6379,
            ...redisConfig
        });

        // Queue definitions
        this.queues = {
            urgent: 'claims:queue:urgent',
            standard: 'claims:queue:standard',
            processing: 'claims:queue:processing',
            completed: 'claims:queue:completed',
            failed: 'claims:queue:failed'
        };

        this.claimsHash = 'claims:data';
        this.isProcessing = false;
    }

    async connect() {
        await this.client.connect();
        console.log('✅ Connected to Redis');
    }

    async disconnect() {
        await this.client.quit();
    }

    // Submit a new claim
    async submitClaim(claimData) {
        const claim = {
            id: uuidv4(),
            ...claimData,
            submittedAt: new Date().toISOString(),
            status: 'submitted'
        };

        // Store claim data
        await this.client.hSet(this.claimsHash, claim.id, JSON.stringify(claim));

        // Add to appropriate queue
        const queueName = claim.priority === 'urgent' ? this.queues.urgent : this.queues.standard;
        await this.client.lPush(queueName, claim.id);

        console.log(`📝 Claim ${claim.id} submitted to ${queueName}`);
        return claim.id;
    }

    // Process claims continuously
    async startProcessing(processorId = 'PROCESSOR-001') {
        this.isProcessing = true;
        console.log(`🚀 Started processing with ${processorId}`);

        while (this.isProcessing) {
            try {
                // Use blocking pop to wait for claims
                const result = await this.client.brPop([this.queues.urgent, this.queues.standard], 10);
                
                if (result) {
                    const claimId = result.element;
                    await this.processClaim(claimId, processorId);
                }
            } catch (error) {
                console.error('Processing error:', error);
                await new Promise(resolve => setTimeout(resolve, 5000));
            }
        }
    }

    async processClaim(claimId, processorId) {
        try {
            // Move to processing queue
            await this.client.lPush(this.queues.processing, claimId);
            
            // Get and update claim
            const claimJson = await this.client.hGet(this.claimsHash, claimId);
            const claim = JSON.parse(claimJson);
            claim.status = 'processing';
            claim.assignedTo = processorId;
            
            await this.client.hSet(this.claimsHash, claimId, JSON.stringify(claim));
            
            console.log(`🔄 Processing ${claim.claimType} claim for ${claim.customerName} ($${claim.amount})`);
            
            // Simulate processing (urgent claims process faster)
            const processingTime = claim.priority === 'urgent' ? 1000 : 3000;
            await new Promise(resolve => setTimeout(resolve, processingTime));
            
            // Simulate success/failure (90% success rate)
            const success = Math.random() > 0.1;
            
            if (success) {
                await this.completeClaim(claimId);
            } else {
                await this.failClaim(claimId);
            }
            
        } catch (error) {
            console.error(`Error processing claim ${claimId}:`, error);
            await this.failClaim(claimId);
        }
    }

    async completeClaim(claimId) {
        // Remove from processing, add to completed
        await this.client.lRem(this.queues.processing, 1, claimId);
        await this.client.lPush(this.queues.completed, claimId);
        
        // Update status
        const claimJson = await this.client.hGet(this.claimsHash, claimId);
        const claim = JSON.parse(claimJson);
        claim.status = 'completed';
        claim.completedAt = new Date().toISOString();
        
        await this.client.hSet(this.claimsHash, claimId, JSON.stringify(claim));
        console.log(`✅ Claim ${claimId} completed`);
    }

    async failClaim(claimId) {
        // Remove from processing, add to failed
        await this.client.lRem(this.queues.processing, 1, claimId);
        await this.client.lPush(this.queues.failed, claimId);
        
        // Update status
        const claimJson = await this.client.hGet(this.claimsHash, claimId);
        const claim = JSON.parse(claimJson);
        claim.status = 'failed';
        claim.failedAt = new Date().toISOString();
        
        await this.client.hSet(this.claimsHash, claimId, JSON.stringify(claim));
        console.log(`❌ Claim ${claimId} failed`);
    }

    // Get queue statistics
    async getStats() {
        const stats = {};
        for (const [name, queue] of Object.entries(this.queues)) {
            stats[name] = await this.client.lLen(queue);
        }
        return stats;
    }

    stopProcessing() {
        this.isProcessing = false;
        console.log('🛑 Processing stopped');
    }
}

module.exports = CompleteClaimsSystem;

// Example usage:
if (require.main === module) {
    async function demo() {
        const system = new CompleteClaimsSystem();
        await system.connect();

        // Submit test claims
        await system.submitClaim({
            policyNumber: 'POL-001',
            customerName: 'John Doe',
            claimType: 'auto',
            priority: 'urgent',
            amount: 5000,
            description: 'Collision damage'
        });

        await system.submitClaim({
            policyNumber: 'POL-002',
            customerName: 'Jane Smith',
            claimType: 'home',
            priority: 'standard',
            amount: 3000,
            description: 'Water damage'
        });

        // Start processing
        setTimeout(() => system.stopProcessing(), 15000);
        await system.startProcessing();
        
        // Show final stats
        const stats = await system.getStats();
        console.log('📊 Final stats:', stats);
        
        await system.disconnect();
    }

    demo().catch(console.error);
}
