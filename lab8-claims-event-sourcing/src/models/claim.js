/**
 * Claim Model for Event Sourcing
 */

const { v4: uuidv4 } = require('uuid');

class Claim {
    constructor(redisClient) {
        this.redis = redisClient;
        this.streamName = 'claims:events';
    }

    async submitClaim(claimData) {
        const claimId = `CLM-${uuidv4().substring(0, 8).toUpperCase()}`;
        
        // Validate required fields
        const required = ['customer_id', 'policy_number', 'amount', 'description'];
        const missing = required.filter(field => !claimData[field]);
        
        if (missing.length > 0) {
            return {
                success: false,
                error: `Missing required fields: ${missing.join(', ')}`
            };
        }

        try {
            const client = this.redis.getClient();
            
            const eventData = {
                type: 'claim_submitted',
                claim_id: claimId,
                customer_id: claimData.customer_id,
                policy_number: claimData.policy_number,
                amount: claimData.amount.toString(),
                description: claimData.description,
                incident_date: claimData.incident_date || new Date().toISOString(),
                submitted_at: new Date().toISOString(),
                status: 'pending'
            };

            const streamId = await client.xAdd(this.streamName, '*', eventData);
            
            console.log(`✅ Claim ${claimId} submitted with stream ID: ${streamId}`);
            
            return {
                success: true,
                claim_id: claimId,
                stream_id: streamId
            };
        } catch (error) {
            console.error('Failed to submit claim:', error);
            return {
                success: false,
                error: error.message
            };
        }
    }

    async updateClaimStatus(claimId, status, details = {}) {
        try {
            const client = this.redis.getClient();
            
            const eventData = {
                type: 'claim_status_updated',
                claim_id: claimId,
                status: status,
                updated_at: new Date().toISOString(),
                ...details
            };

            const streamId = await client.xAdd(this.streamName, '*', eventData);
            
            console.log(`✅ Claim ${claimId} status updated to ${status}`);
            
            return {
                success: true,
                stream_id: streamId
            };
        } catch (error) {
            console.error('Failed to update claim status:', error);
            return {
                success: false,
                error: error.message
            };
        }
    }

    async getClaimHistory(claimId) {
        try {
            const client = this.redis.getClient();
            
            // Read all events from the stream
            const events = await client.xRange(this.streamName, '-', '+');
            
            // Filter events for this specific claim
            const claimEvents = events
                .filter(event => event.message.claim_id === claimId)
                .map(event => ({
                    id: event.id,
                    timestamp: event.id.split('-')[0],
                    ...event.message
                }));

            return {
                success: true,
                claim_id: claimId,
                events: claimEvents
            };
        } catch (error) {
            console.error('Failed to get claim history:', error);
            return {
                success: false,
                error: error.message
            };
        }
    }

    async processPayment(claimId, amount, paymentMethod = 'bank_transfer') {
        try {
            const client = this.redis.getClient();
            
            const eventData = {
                type: 'claim_paid',
                claim_id: claimId,
                amount: amount.toString(),
                payment_method: paymentMethod,
                paid_at: new Date().toISOString(),
                status: 'paid'
            };

            const streamId = await client.xAdd(this.streamName, '*', eventData);
            
            console.log(`💰 Claim ${claimId} payment processed: $${amount}`);
            
            return {
                success: true,
                stream_id: streamId,
                amount: amount
            };
        } catch (error) {
            console.error('Failed to process payment:', error);
            return {
                success: false,
                error: error.message
            };
        }
    }

    async rejectClaim(claimId, reason) {
        return await this.updateClaimStatus(claimId, 'rejected', {
            rejection_reason: reason,
            rejected_at: new Date().toISOString()
        });
    }

    async approveClaim(claimId, approvedAmount, reviewer) {
        return await this.updateClaimStatus(claimId, 'approved', {
            approved_amount: approvedAmount.toString(),
            reviewer: reviewer,
            approved_at: new Date().toISOString()
        });
    }
}

module.exports = Claim;
