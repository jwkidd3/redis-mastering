// event-producer.js - Event producer for claims using Redis Streams
const redis = require('redis');

class EventProducer {
    constructor() {
        this.client = null;
        this.streamKey = 'claims:events';
    }

    async connect() {
        this.client = redis.createClient();
        await this.client.connect();
    }

    async disconnect() {
        if (this.client) {
            await this.client.quit();
        }
    }

    // Publish an event to the stream
    async publishEvent(eventType, eventData) {
        const messageId = await this.client.xAdd(
            this.streamKey,
            '*', // Auto-generate message ID
            {
                event_type: eventType,
                timestamp: new Date().toISOString(),
                ...eventData
            }
        );
        console.log(`✓ Event published: ${eventType} (ID: ${messageId})`);
        return messageId;
    }

    // Publish claim submission event
    async publishClaimSubmitted(claimData) {
        return await this.publishEvent('claim.submitted', {
            claim_id: claimData.claim_id,
            customer_id: claimData.customer_id,
            policy_id: claimData.policy_id,
            amount: claimData.amount.toString(),
            description: claimData.description
        });
    }

    // Publish claim approval event
    async publishClaimApproved(claimId) {
        return await this.publishEvent('claim.approved', {
            claim_id: claimId
        });
    }

    // Publish claim rejection event
    async publishClaimRejected(claimId, reason) {
        return await this.publishEvent('claim.rejected', {
            claim_id: claimId,
            reason: reason
        });
    }
}

module.exports = EventProducer;
