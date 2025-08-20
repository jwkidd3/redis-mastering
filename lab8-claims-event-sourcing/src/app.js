/**
 * Lab 8 Main Application
 * Demonstrates Redis Streams for claims event sourcing
 */

const redisClient = require('./utils/redisClient');

async function main() {
    console.log('🚀 Starting Lab 8: Claims Event Sourcing');
    console.log('==========================================');
    
    try {
        // Connect to Redis
        await redisClient.connect();
        console.log('✅ Connected to Redis');
        
        // Initialize streams
        await redisClient.createStream('claims:events');
        await redisClient.createConsumerGroup('claims:events', 'claims-processors');
        
        console.log('✅ Streams and consumer groups ready');
        console.log('');
        console.log('🎯 Lab 8 is ready! Choose your next step:');
        console.log('');
        console.log('📝 Submit claims:     npm run producer');
        console.log('⚙️  Process claims:    npm run consumer');
        console.log('📊 View analytics:    npm run analytics');
        console.log('🧪 Run tests:        npm run test:all');
        console.log('✅ Verify setup:     npm run validate');
        console.log('');
        console.log('📖 Follow lab8.md for detailed instructions');
        
    } catch (error) {
        console.error('❌ Failed to start application:', error);
        process.exit(1);
    } finally {
        await redisClient.disconnect();
    }
}

if (require.main === module) {
    main();
}

module.exports = { main };
