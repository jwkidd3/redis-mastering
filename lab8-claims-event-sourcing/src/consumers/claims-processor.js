const redisClient = require('../utils/redis-client');

class ClaimsProcessor {
    constructor() {
        this.client = null;
        this.streamName = 'claims:events';
        this.groupName = 'processors';
        this.consumerName = `processor-${Date.now()}`;
        this.running = false;
    }

    async init() {
        this.client = await redisClient.connect();
        
        // Create consumer group if it doesn't exist
        try {
            await this.client.xGroupCreate(this.streamName, this.groupName, '0', {
                MKSTREAM: true
            });
            console.log(`✅ Created consumer group: ${this.groupName}`);
        } catch (error) {
            if (error.message.includes('BUSYGROUP')) {
                console.log(`✅ Consumer group ${this.groupName} already exists`);
            } else {
                throw error;
            }
        }
        
        console.log(`⚙️ Claims Processor initialized: ${this.consumerName}`);
    }

    async start() {
        this.running = true;
        console.log('🚀 Starting claims processor...');
        
        while (this.running) {
            try {
                // Read messages from the stream
                const messages = await this.client.xReadGroup(
                    this.groupName,
                    this.consumerName,
                    [
                        {
                            key: this.streamName,
                            id: '>'
                        }
                    ],
                    {
                        COUNT: 5,
                        BLOCK: 1000
                    }
                );

                if (messages && messages.length > 0) {
                    for (const stream of messages) {
                        for (const message of stream.messages) {
                            await this.processMessage(message);
                        }
                    }
                }
            } catch (error) {
                console.error('❌ Error reading from stream:', error.message);
                await new Promise(resolve => setTimeout(resolve, 1000));
            }
        }
    }

    async processMessage(message) {
        try {
            const { id, message: fields } = message;
            const eventType = fields.eventType;
            const claimId = fields.claimId;
            const data = JSON.parse(fields.data);

            console.log(`📝 Processing ${eventType} for claim ${claimId}`);

            switch (eventType) {
                case 'claim.submitted':
                    await this.handleClaimSubmitted(claimId, data);
                    break;
                case 'claim.assigned':
                    await this.handleClaimAssigned(claimId, data);
                    break;
                case 'claim.approved':
                    await this.handleClaimApproved(claimId, data);
                    break;
                case 'claim.rejected':
                    await this.handleClaimRejected(claimId, data);
                    break;
                default:
                    console.log(`ℹ️ Unhandled event type: ${eventType}`);
            }

            // Acknowledge message processing
            await this.client.xAck(this.streamName, this.groupName, id);
            console.log(`✅ Acknowledged message ${id}`);

        } catch (error) {
            console.error('❌ Error processing message:', error.message);
            // In production, you might want to send to a dead letter queue
        }
    }

    async handleClaimSubmitted(claimId, data) {
        // Auto-assign based on claim type and workload
        const adjusters = await this.getAvailableAdjusters(data.type);
        const assignedAdjuster = this.selectOptimalAdjuster(adjusters);

        if (assignedAdjuster) {
            // Update claim assignment
            await this.client.hSet(`claim:${claimId}`, {
                assignedTo: assignedAdjuster.id,
                status: 'assigned',
                assignedAt: new Date().toISOString()
            });

            // Add assignment to adjuster workload
            await this.client.lPush(`adjuster:${assignedAdjuster.id}:workload`, claimId);
            
            console.log(`📋 Auto-assigned claim ${claimId} to ${assignedAdjuster.name}`);
        }

        // Add to processing metrics
        await this.updateProcessingMetrics('submitted', data);
    }

    async handleClaimAssigned(claimId, data) {
        // Update processing queue
        await this.client.lPush('queue:assigned:claims', claimId);
        
        // Set processing SLA
        const slaHours = this.calculateSLA(data.type, data.priority);
        const slaTime = new Date(Date.now() + slaHours * 60 * 60 * 1000).toISOString();
        
        await this.client.hSet(`claim:${claimId}`, {
            slaDeadline: slaTime,
            processingStarted: new Date().toISOString()
        });

        console.log(`⏰ Set SLA for claim ${claimId}: ${slaHours} hours`);
    }

    async handleClaimApproved(claimId, data) {
        // Move to payment queue
        await this.client.lPush('queue:payment:pending', claimId);
        
        // Update metrics
        await this.updateProcessingMetrics('approved', data);
        
        // Calculate processing time
        const claimData = await this.client.hGetAll(`claim:${claimId}`);
        const processingTime = this.calculateProcessingTime(
            claimData.submittedAt,
            new Date().toISOString()
        );
        
        await this.client.hSet(`claim:${claimId}`, {
            processingTimeHours: processingTime,
            approvedAt: new Date().toISOString()
        });

        console.log(`💰 Claim ${claimId} approved for payment (${processingTime}h processing time)`);
    }

    async handleClaimRejected(claimId, data) {
        // Move to closed claims
        await this.client.lPush('queue:claims:closed', claimId);
        
        // Update metrics
        await this.updateProcessingMetrics('rejected', data);
        
        console.log(`❌ Claim ${claimId} rejected: ${data.rejectionReason}`);
    }

    async getAvailableAdjusters(claimType) {
        // In production, this would query a database
        const adjusters = [
            { id: 'ADJ-001', name: 'Sarah Wilson', specialty: 'auto', workload: 5 },
            { id: 'ADJ-002', name: 'Mike Johnson', specialty: 'home', workload: 3 },
            { id: 'ADJ-003', name: 'Lisa Chen', specialty: 'life', workload: 2 },
            { id: 'ADJ-004', name: 'David Rodriguez', specialty: 'auto', workload: 4 }
        ];

        return adjusters.filter(adj => 
            adj.specialty === claimType || adj.specialty === 'general'
        );
    }

    selectOptimalAdjuster(adjusters) {
        if (adjusters.length === 0) return null;
        
        // Select adjuster with lowest workload
        return adjusters.reduce((min, current) => 
            current.workload < min.workload ? current : min
        );
    }

    calculateSLA(claimType, priority) {
        const baseSLA = {
            'auto': 48,   // 48 hours
            'home': 72,   // 72 hours
            'life': 168   // 168 hours (1 week)
        };

        const priorityMultiplier = {
            'urgent': 0.25,
            'high': 0.5,
            'normal': 1.0,
            'low': 1.5
        };

        return baseSLA[claimType] * priorityMultiplier[priority];
    }

    calculateProcessingTime(startTime, endTime) {
        const start = new Date(startTime);
        const end = new Date(endTime);
        return Math.round((end - start) / (1000 * 60 * 60)); // Hours
    }

    async updateProcessingMetrics(action, data) {
        const today = new Date().toISOString().split('T')[0];
        
        // Daily counters
        await this.client.hIncrBy(`metrics:daily:${today}`, `claims:${action}`, 1);
        await this.client.hIncrBy(`metrics:daily:${today}`, `claims:${data.type}:${action}`, 1);
        
        // Hourly counters
        const hour = new Date().getHours();
        await this.client.hIncrBy(`metrics:hourly:${today}:${hour}`, `claims:${action}`, 1);
    }

    async stop() {
        this.running = false;
        console.log('🛑 Claims processor stopped');
    }

    async shutdown() {
        await this.stop();
        await redisClient.disconnect();
        console.log('⚙️ Claims processor shut down');
    }
}

// Run if executed directly
if (require.main === module) {
    (async () => {
        const processor = new ClaimsProcessor();
        await processor.init();
        
        // Handle graceful shutdown
        process.on('SIGINT', async () => {
            console.log('\n📡 Received SIGINT, shutting down gracefully...');
            await processor.shutdown();
            process.exit(0);
        });
        
        await processor.start();
    })();
}

module.exports = ClaimsProcessor;
