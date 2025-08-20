/**
 * Claim Processor Consumer
 * Processes claim events from Redis Streams
 */

const redisClient = require('../utils/redisClient');
const config = require('../../config/redis');

class ClaimProcessor {
    constructor() {
        this.consumerName = `processor-${Date.now()}`;
        this.groupName = config.streams.consumerGroup;
        this.streamName = config.streams.claimsEvents;
        this.running = false;
    }

    async start() {
        try {
            await redisClient.connect();
            
            // Ensure consumer group exists
            await redisClient.createConsumerGroup(this.streamName, this.groupName, '0');
            
            console.log(`🔄 Starting claim processor: ${this.consumerName}`);
            console.log(`📡 Listening to stream: ${this.streamName}`);
            console.log(`👥 Consumer group: ${this.groupName}`);
            
            this.running = true;
            await this.processLoop();
            
        } catch (error) {
            console.error('Failed to start claim processor:', error);
            throw error;
        }
    }

    async processLoop() {
        const client = redisClient.getClient();
        
        while (this.running) {
            try {
                // Read messages from the stream
                const messages = await client.xReadGroup(
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
                            
                            // Acknowledge the message
                            await client.xAck(this.streamName, this.groupName, message.id);
                        }
                    }
                }
            } catch (error) {
                if (this.running) {
                    console.error('Error in process loop:', error);
                    await new Promise(resolve => setTimeout(resolve, 5000));
                }
            }
        }
    }

    async processMessage(message) {
        const { id, message: data } = message;
        const eventType = data.type;
        
        console.log(`📨 Processing event: ${eventType} (ID: ${id})`);
        
        try {
            switch (eventType) {
                case 'claim_submitted':
                    await this.handleClaimSubmitted(data);
                    break;
                    
                case 'claim_status_updated':
                    await this.handleStatusUpdate(data);
                    break;
                    
                case 'claim_paid':
                    await this.handlePayment(data);
                    break;
                    
                default:
                    console.log(`ℹ️  Unknown event type: ${eventType}`);
            }
            
            console.log(`✅ Successfully processed event ${id}`);
            
        } catch (error) {
            console.error(`❌ Failed to process event ${id}:`, error);
            
            // Send to dead letter queue
            await this.sendToDeadLetter(message, error.message);
        }
    }

    async handleClaimSubmitted(data) {
        const { claim_id, customer_id, amount } = data;
        
        console.log(`🆕 New claim submitted: ${claim_id} for customer ${customer_id} - $${amount}`);
        
        // Simulate processing time
        await new Promise(resolve => setTimeout(resolve, 500));
        
        // Auto-approve small claims (< $1000)
        if (parseFloat(amount) < 1000) {
            console.log(`🚀 Auto-approving small claim: ${claim_id}`);
            
            const client = redisClient.getClient();
            await client.xAdd(this.streamName, '*', {
                type: 'claim_status_updated',
                claim_id: claim_id,
                status: 'auto_approved',
                approved_amount: amount,
                reviewer: 'auto_system',
                approved_at: new Date().toISOString()
            });
        } else {
            console.log(`⏳ Claim ${claim_id} requires manual review (amount: $${amount})`);
        }
    }

    async handleStatusUpdate(data) {
        const { claim_id, status } = data;
        
        console.log(`📋 Claim ${claim_id} status updated to: ${status}`);
        
        // Trigger payment for approved claims
        if (status === 'approved' || status === 'auto_approved') {
            const amount = data.approved_amount || data.amount;
            
            console.log(`💳 Triggering payment for claim ${claim_id}: $${amount}`);
            
            // Simulate payment processing delay
            await new Promise(resolve => setTimeout(resolve, 1000));
            
            const client = redisClient.getClient();
            await client.xAdd(this.streamName, '*', {
                type: 'claim_paid',
                claim_id: claim_id,
                amount: amount,
                payment_method: 'bank_transfer',
                paid_at: new Date().toISOString(),
                status: 'paid'
            });
        }
    }

    async handlePayment(data) {
        const { claim_id, amount, payment_method } = data;
        
        console.log(`💰 Payment processed for claim ${claim_id}: $${amount} via ${payment_method}`);
        
        // Update any external payment systems here
        // Send notifications, update databases, etc.
        
        console.log(`🎉 Claim ${claim_id} processing completed successfully!`);
    }

    async sendToDeadLetter(message, error) {
        try {
            const client = redisClient.getClient();
            const deadLetterStream = config.streams.failedClaims;
            
            await client.xAdd(deadLetterStream, '*', {
                original_id: message.id,
                error_message: error,
                failed_at: new Date().toISOString(),
                ...message.message
            });
            
            console.log(`☠️  Sent message to dead letter queue: ${message.id}`);
        } catch (dlqError) {
            console.error('Failed to send to dead letter queue:', dlqError);
        }
    }

    async stop() {
        console.log('🛑 Stopping claim processor...');
        this.running = false;
        await redisClient.disconnect();
        console.log('👋 Claim processor stopped');
    }

    async getProcessingStats() {
        try {
            const client = redisClient.getClient();
            
            // Get consumer group info
            const consumers = await client.xInfoConsumers(this.streamName, this.groupName);
            const thisConsumer = consumers.find(c => c.name === this.consumerName);
            
            // Get stream stats
            const streamInfo = await client.xInfoStream(this.streamName);
            
            return {
                consumer_name: this.consumerName,
                group_name: this.groupName,
                stream_length: streamInfo.length,
                pending_messages: thisConsumer ? thisConsumer.pending : 0,
                total_consumers: consumers.length
            };
        } catch (error) {
            console.error('Failed to get processing stats:', error);
            return null;
        }
    }
}

// Start processor if called directly
if (require.main === module) {
    const processor = new ClaimProcessor();
    
    // Graceful shutdown
    process.on('SIGINT', async () => {
        console.log('\n🛑 Shutting down claim processor...');
        await processor.stop();
        process.exit(0);
    });
    
    processor.start().catch(error => {
        console.error('Failed to start processor:', error);
        process.exit(1);
    });
}

module.exports = ClaimProcessor;
