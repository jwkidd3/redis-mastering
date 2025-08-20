#!/usr/bin/env node

/**
 * Lab 8 Health Check Script
 * Quick runtime validation for running services
 */

async function runHealthCheck() {
    console.log('🏥 Lab 8 Health Check');
    console.log('='.repeat(30));
    
    let allHealthy = true;
    
    try {
        // Check if required modules can be loaded
        require('dotenv').config();
        
        // Check Redis module
        const redis = require('redis');
        console.log('✅ Redis module: Available');
        
        // Test Redis connection
        const client = redis.createClient({
            socket: {
                host: process.env.REDIS_HOST || 'localhost',
                port: parseInt(process.env.REDIS_PORT) || 6379,
                connectTimeout: 5000
            },
            password: process.env.REDIS_PASSWORD
        });

        await client.connect();
        const pong = await client.ping();
        await client.disconnect();
        
        if (pong === 'PONG') {
            console.log('✅ Redis connection: Healthy');
        } else {
            console.log('❌ Redis connection: Unhealthy');
            allHealthy = false;
        }
        
        // Check for streams (if they exist)
        try {
            const streamClient = redis.createClient({
                socket: {
                    host: process.env.REDIS_HOST || 'localhost',
                    port: parseInt(process.env.REDIS_PORT) || 6379
                },
                password: process.env.REDIS_PASSWORD
            });
            
            await streamClient.connect();
            
            try {
                const info = await streamClient.xInfoStream('claims:events');
                console.log(`✅ Claims stream: ${info.length} events`);
            } catch (e) {
                if (e.message.includes('no such key')) {
                    console.log('ℹ️  Claims stream: Not yet created (normal for new setup)');
                } else {
                    throw e;
                }
            }
            
            await streamClient.disconnect();
            
        } catch (error) {
            console.log('⚠️  Stream check failed:', error.message);
        }
        
    } catch (error) {
        console.log('❌ Health check failed:', error.message);
        allHealthy = false;
    }
    
    console.log('\n📊 Overall Health:', allHealthy ? '✅ HEALTHY' : '❌ ISSUES DETECTED');
    
    return allHealthy;
}

// Run health check if called directly
if (require.main === module) {
    runHealthCheck().then(healthy => {
        process.exit(healthy ? 0 : 1);
    }).catch(error => {
        console.error('Health check error:', error);
        process.exit(1);
    });
}

module.exports = { runHealthCheck };
