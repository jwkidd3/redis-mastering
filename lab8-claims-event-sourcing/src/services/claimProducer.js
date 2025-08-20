/**
 * Claim Producer Service
 * HTTP API for submitting claims to Redis Streams
 */

const express = require('express');
const cors = require('cors');
const redisClient = require('../utils/redisClient');
const Claim = require('../models/claim');

class ClaimProducerService {
    constructor() {
        this.app = express();
        this.port = process.env.PORT || 3001;
        this.claim = null;
        
        this.setupMiddleware();
        this.setupRoutes();
    }

    setupMiddleware() {
        this.app.use(cors());
        this.app.use(express.json());
        this.app.use(express.urlencoded({ extended: true }));
    }

    setupRoutes() {
        // Health check
        this.app.get('/health', (req, res) => {
            res.json({ 
                status: 'healthy', 
                service: 'claim-producer',
                timestamp: new Date().toISOString(),
                redis_connected: redisClient.isConnected()
            });
        });

        // Submit new claim
        this.app.post('/claims', async (req, res) => {
            try {
                const result = await this.claim.submitClaim(req.body);
                
                if (result.success) {
                    res.status(201).json({
                        message: 'Claim submitted successfully',
                        claim_id: result.claim_id,
                        stream_id: result.stream_id
                    });
                } else {
                    res.status(400).json({
                        error: 'Failed to submit claim',
                        details: result.error
                    });
                }
            } catch (error) {
                console.error('Error submitting claim:', error);
                res.status(500).json({
                    error: 'Internal server error',
                    message: error.message
                });
            }
        });

        // Update claim status
        this.app.put('/claims/:claimId/status', async (req, res) => {
            try {
                const { claimId } = req.params;
                const { status, ...details } = req.body;
                
                const result = await this.claim.updateClaimStatus(claimId, status, details);
                
                if (result.success) {
                    res.json({
                        message: 'Claim status updated',
                        claim_id: claimId,
                        status: status,
                        stream_id: result.stream_id
                    });
                } else {
                    res.status(400).json({
                        error: 'Failed to update claim status',
                        details: result.error
                    });
                }
            } catch (error) {
                console.error('Error updating claim:', error);
                res.status(500).json({
                    error: 'Internal server error',
                    message: error.message
                });
            }
        });

        // Get claim history
        this.app.get('/claims/:claimId/history', async (req, res) => {
            try {
                const { claimId } = req.params;
                const result = await this.claim.getClaimHistory(claimId);
                
                if (result.success) {
                    res.json(result);
                } else {
                    res.status(404).json({
                        error: 'Claim not found or error retrieving history',
                        details: result.error
                    });
                }
            } catch (error) {
                console.error('Error getting claim history:', error);
                res.status(500).json({
                    error: 'Internal server error',
                    message: error.message
                });
            }
        });

        // Process payment
        this.app.post('/claims/:claimId/payment', async (req, res) => {
            try {
                const { claimId } = req.params;
                const { amount, payment_method } = req.body;
                
                const result = await this.claim.processPayment(claimId, amount, payment_method);
                
                if (result.success) {
                    res.json({
                        message: 'Payment processed',
                        claim_id: claimId,
                        amount: result.amount,
                        stream_id: result.stream_id
                    });
                } else {
                    res.status(400).json({
                        error: 'Failed to process payment',
                        details: result.error
                    });
                }
            } catch (error) {
                console.error('Error processing payment:', error);
                res.status(500).json({
                    error: 'Internal server error',
                    message: error.message
                });
            }
        });

        // Approve claim
        this.app.post('/claims/:claimId/approve', async (req, res) => {
            try {
                const { claimId } = req.params;
                const { approved_amount, reviewer } = req.body;
                
                const result = await this.claim.approveClaim(claimId, approved_amount, reviewer);
                
                if (result.success) {
                    res.json({
                        message: 'Claim approved',
                        claim_id: claimId,
                        approved_amount: approved_amount,
                        reviewer: reviewer,
                        stream_id: result.stream_id
                    });
                } else {
                    res.status(400).json({
                        error: 'Failed to approve claim',
                        details: result.error
                    });
                }
            } catch (error) {
                console.error('Error approving claim:', error);
                res.status(500).json({
                    error: 'Internal server error',
                    message: error.message
                });
            }
        });

        // Reject claim
        this.app.post('/claims/:claimId/reject', async (req, res) => {
            try {
                const { claimId } = req.params;
                const { reason } = req.body;
                
                const result = await this.claim.rejectClaim(claimId, reason);
                
                if (result.success) {
                    res.json({
                        message: 'Claim rejected',
                        claim_id: claimId,
                        reason: reason,
                        stream_id: result.stream_id
                    });
                } else {
                    res.status(400).json({
                        error: 'Failed to reject claim',
                        details: result.error
                    });
                }
            } catch (error) {
                console.error('Error rejecting claim:', error);
                res.status(500).json({
                    error: 'Internal server error',
                    message: error.message
                });
            }
        });
    }

    async start() {
        try {
            // Connect to Redis
            await redisClient.connect();
            
            // Initialize claim model
            this.claim = new Claim(redisClient);
            
            // Start HTTP server
            this.server = this.app.listen(this.port, () => {
                console.log(`🚀 Claim Producer Service running on port ${this.port}`);
                console.log(`📡 Health check: http://localhost:${this.port}/health`);
                console.log(`📝 Submit claims: POST http://localhost:${this.port}/claims`);
            });
            
        } catch (error) {
            console.error('Failed to start Claim Producer Service:', error);
            process.exit(1);
        }
    }

    async stop() {
        if (this.server) {
            this.server.close();
        }
        await redisClient.disconnect();
        console.log('👋 Claim Producer Service stopped');
    }
}

// Start service if called directly
if (require.main === module) {
    const service = new ClaimProducerService();
    
    // Graceful shutdown
    process.on('SIGINT', async () => {
        console.log('\n🛑 Shutting down Claim Producer Service...');
        await service.stop();
        process.exit(0);
    });
    
    service.start();
}

module.exports = ClaimProducerService;
