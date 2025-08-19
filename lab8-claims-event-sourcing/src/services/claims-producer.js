const redisClient = require('../utils/redis-client');
const Claim = require('../models/claim');

class ClaimsProducer {
    constructor() {
        this.client = null;
        this.streamName = 'claims:events';
    }

    async init() {
        this.client = await redisClient.connect();
        console.log('🏭 Claims Producer initialized');
    }

    async submitClaim(claimData) {
        try {
            // Validate claim data
            const validation = Claim.validate(claimData);
            if (!validation.isValid) {
                throw new Error(`Validation failed: ${validation.errors.join(', ')}`);
            }

            // Create claim instance
            const claim = new Claim(claimData);
            
            // Create submitted event
            const event = claim.createEvent('claim.submitted', {
                submittedBy: claimData.submittedBy || 'customer-portal',
                channel: claimData.channel || 'web'
            });

            // Add event to stream
            const streamId = await this.client.xAdd(
                this.streamName,
                '*', // Auto-generate ID
                {
                    eventType: event.eventType,
                    claimId: event.claimId,
                    eventId: event.eventId,
                    timestamp: event.timestamp,
                    data: JSON.stringify(event.data),
                    version: event.version
                }
            );

            console.log(`✅ Claim submitted: ${claim.id} (Stream ID: ${streamId})`);
            
            // Store claim snapshot
            await this.client.hSet(`claim:${claim.id}`, claim.toJSON());
            
            return {
                success: true,
                claimId: claim.id,
                streamId,
                event
            };

        } catch (error) {
            console.error('❌ Error submitting claim:', error.message);
            return {
                success: false,
                error: error.message
            };
        }
    }

    async updateClaimStatus(claimId, newStatus, additionalData = {}) {
        try {
            // Get current claim data
            const claimData = await this.client.hGetAll(`claim:${claimId}`);
            if (!claimData.id) {
                throw new Error(`Claim ${claimId} not found`);
            }

            // Create status change event
            const event = {
                eventId: require('uuid').v4(),
                eventType: 'claim.status.changed',
                claimId,
                timestamp: new Date().toISOString(),
                data: {
                    previousStatus: claimData.status,
                    newStatus,
                    ...additionalData
                },
                version: '1.0'
            };

            // Add event to stream
            const streamId = await this.client.xAdd(
                this.streamName,
                '*',
                {
                    eventType: event.eventType,
                    claimId: event.claimId,
                    eventId: event.eventId,
                    timestamp: event.timestamp,
                    data: JSON.stringify(event.data),
                    version: event.version
                }
            );

            // Update claim snapshot
            await this.client.hSet(`claim:${claimId}`, {
                status: newStatus,
                lastUpdated: new Date().toISOString()
            });

            console.log(`✅ Claim ${claimId} status updated: ${claimData.status} → ${newStatus}`);
            
            return {
                success: true,
                streamId,
                event
            };

        } catch (error) {
            console.error('❌ Error updating claim status:', error.message);
            return {
                success: false,
                error: error.message
            };
        }
    }

    async assignClaim(claimId, adjusterId, adjusterName) {
        return await this.addClaimEvent(claimId, 'claim.assigned', {
            assignedTo: adjusterId,
            assignedBy: 'system',
            adjusterName
        });
    }

    async addClaimDocument(claimId, documentInfo) {
        return await this.addClaimEvent(claimId, 'claim.document.uploaded', {
            documentId: documentInfo.id,
            documentType: documentInfo.type,
            documentName: documentInfo.name,
            uploadedBy: documentInfo.uploadedBy
        });
    }

    async approveClaim(claimId, approvalData) {
        await this.updateClaimStatus(claimId, 'approved', approvalData);
        return await this.addClaimEvent(claimId, 'claim.approved', {
            approvedAmount: approvalData.approvedAmount,
            approvedBy: approvalData.approvedBy,
            approvalNotes: approvalData.notes
        });
    }

    async rejectClaim(claimId, rejectionData) {
        await this.updateClaimStatus(claimId, 'rejected', rejectionData);
        return await this.addClaimEvent(claimId, 'claim.rejected', {
            rejectionReason: rejectionData.reason,
            rejectedBy: rejectionData.rejectedBy,
            rejectionNotes: rejectionData.notes
        });
    }

    async addClaimEvent(claimId, eventType, eventData) {
        try {
            const event = {
                eventId: require('uuid').v4(),
                eventType,
                claimId,
                timestamp: new Date().toISOString(),
                data: eventData,
                version: '1.0'
            };

            const streamId = await this.client.xAdd(
                this.streamName,
                '*',
                {
                    eventType: event.eventType,
                    claimId: event.claimId,
                    eventId: event.eventId,
                    timestamp: event.timestamp,
                    data: JSON.stringify(event.data),
                    version: event.version
                }
            );

            console.log(`✅ Event added: ${eventType} for claim ${claimId}`);
            
            return {
                success: true,
                streamId,
                event
            };

        } catch (error) {
            console.error(`❌ Error adding event ${eventType}:`, error.message);
            return {
                success: false,
                error: error.message
            };
        }
    }

    async getStreamInfo() {
        try {
            const info = await this.client.xInfo('STREAM', this.streamName);
            return info;
        } catch (error) {
            console.error('❌ Error getting stream info:', error.message);
            return null;
        }
    }

    async shutdown() {
        await redisClient.disconnect();
        console.log('🏭 Claims Producer shut down');
    }
}

// Demo usage if run directly
if (require.main === module) {
    (async () => {
        const producer = new ClaimsProducer();
        await producer.init();

        // Submit a sample claim
        const result = await producer.submitClaim({
            policyId: 'POL-001',
            customerId: 'CUST-001',
            amount: 2500,
            description: 'Rear-end collision on Highway 101',
            type: 'auto',
            priority: 'normal',
            submittedBy: 'customer',
            channel: 'mobile-app'
        });

        console.log('Sample claim submission result:', result);

        // Wait a moment then update status
        setTimeout(async () => {
            await producer.assignClaim(result.claimId, 'ADJ-001', 'Sarah Wilson');
            
            setTimeout(async () => {
                await producer.approveClaim(result.claimId, {
                    approvedAmount: 2500,
                    approvedBy: 'ADJ-001',
                    notes: 'Clear liability, approved for full amount'
                });
                
                // Show stream info
                const streamInfo = await producer.getStreamInfo();
                console.log('Stream info:', streamInfo);
                
                await producer.shutdown();
            }, 2000);
        }, 1000);
    })();
}

module.exports = ClaimsProducer;
