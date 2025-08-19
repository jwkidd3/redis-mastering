// src/server.js
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
require('dotenv').config();

const redisClient = require('../config/redis');
const RateLimitMiddleware = require('./middleware/rateLimitMiddleware');

// Import route handlers
const quoteRoutes = require('./routes/quotes');
const policyRoutes = require('./routes/policies');
const adminRoutes = require('./routes/admin');

class InsuranceAPIServer {
    constructor() {
        this.app = express();
        this.port = process.env.PORT || 3000;
        this.rateLimitMiddleware = null;
    }

    async initialize() {
        try {
            // Connect to Redis
            await redisClient.connect();
            
            // Initialize rate limiting middleware
            this.rateLimitMiddleware = new RateLimitMiddleware(redisClient.getClient());
            
            // Setup Express middleware
            this.setupMiddleware();
            
            // Setup routes
            this.setupRoutes();
            
            // Setup error handling
            this.setupErrorHandling();
            
            console.log('✅ Server initialized successfully');
            
        } catch (error) {
            console.error('❌ Server initialization failed:', error.message);
            throw error;
        }
    }

    setupMiddleware() {
        // Security middleware
        this.app.use(helmet());
        this.app.use(cors());
        
        // Logging
        this.app.use(morgan('combined'));
        
        // Body parsing
        this.app.use(express.json({ limit: '10mb' }));
        this.app.use(express.urlencoded({ extended: true }));
        
        // Trust proxy for accurate IP addresses
        this.app.set('trust proxy', 1);
        
        // Global IP rate limiting (DDoS protection)
        this.app.use(this.rateLimitMiddleware.ipRateLimit({
            limit: 1000,
            windowSeconds: 60
        }));
    }

    setupRoutes() {
        // Health check endpoint (no rate limiting)
        this.app.get('/health', (req, res) => {
            res.json({
                status: 'healthy',
                timestamp: new Date().toISOString(),
                redis: redisClient.isConnected ? 'connected' : 'disconnected',
                uptime: process.uptime()
            });
        });

        // API routes with rate limiting
        this.app.use('/api/quotes', quoteRoutes(this.rateLimitMiddleware));
        this.app.use('/api/policies', policyRoutes(this.rateLimitMiddleware));
        this.app.use('/api/admin', adminRoutes(this.rateLimitMiddleware));

        // Rate limit status endpoint
        this.app.get('/api/rate-limit/status', 
            this.rateLimitMiddleware.apiKeyRateLimit(),
            async (req, res) => {
                try {
                    const customerId = req.headers['x-customer-id'] || 'unknown';
                    const apiKey = req.headers['x-api-key'];
                    
                    const customerStatus = await this.rateLimitMiddleware.rateLimitService
                        .getRateLimitStatus(customerId, 'customer');
                    const apiStatus = await this.rateLimitMiddleware.rateLimitService
                        .getRateLimitStatus(apiKey, 'api');

                    res.json({
                        customer: customerStatus,
                        api: apiStatus,
                        timestamp: new Date().toISOString()
                    });
                } catch (error) {
                    res.status(500).json({ error: error.message });
                }
            }
        );

        // 404 handler
        this.app.use('*', (req, res) => {
            res.status(404).json({
                error: 'Endpoint not found',
                path: req.originalUrl,
                method: req.method
            });
        });
    }

    setupErrorHandling() {
        this.app.use((error, req, res, next) => {
            console.error('❌ Unhandled error:', error);
            res.status(500).json({
                error: 'Internal server error',
                message: process.env.NODE_ENV === 'development' ? error.message : 'Something went wrong'
            });
        });
    }

    async start() {
        try {
            await this.initialize();
            
            this.server = this.app.listen(this.port, () => {
                console.log(`🚀 Insurance API Server running on port ${this.port}`);
                console.log(`📊 Health check: http://localhost:${this.port}/health`);
                console.log(`🛡️ Rate limiting active on all API endpoints`);
            });
            
        } catch (error) {
            console.error('❌ Failed to start server:', error.message);
            process.exit(1);
        }
    }

    async stop() {
        if (this.server) {
            this.server.close();
        }
        await redisClient.disconnect();
        console.log('🛑 Server stopped');
    }
}

// Start server if this file is run directly
if (require.main === module) {
    const server = new InsuranceAPIServer();
    
    server.start().catch(error => {
        console.error('💥 Server startup failed:', error);
        process.exit(1);
    });
    
    // Graceful shutdown
    process.on('SIGINT', async () => {
        console.log('🛑 Shutting down gracefully...');
        await server.stop();
        process.exit(0);
    });
    
    process.on('SIGTERM', async () => {
        console.log('🛑 Shutting down gracefully...');
        await server.stop();
        process.exit(0);
    });
}

module.exports = InsuranceAPIServer;
