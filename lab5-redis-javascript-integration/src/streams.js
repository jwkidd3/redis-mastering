import connectRedis from './connection.js';

class StreamProcessor {
    constructor() {
        this.client = null;
    }
    
    async initialize() {
        this.client = await connectRedis();
        console.log('🌊 Stream processor initialized');
    }
    
    async addToStream(streamKey, data) {
        const result = await this.client.xAdd(streamKey, '*', data);
        console.log(`➕ Added to stream ${streamKey}: ${result}`);
        return result;
    }
    
    async readStream(streamKey, count = 10) {
        const messages = await this.client.xRange(streamKey, '-', '+', {
            COUNT: count
        });
        
        console.log(`📖 Read ${messages.length} messages from ${streamKey}`);
        return messages.map(msg => ({
            id: msg.id,
            data: msg.message
        }));
    }
    
    async processStreamWithConsumerGroup(streamKey, groupName, consumerName) {
        try {
            // Create consumer group
            await this.client.xGroupCreate(streamKey, groupName, '0', {
                MKSTREAM: true
            });
        } catch (err) {
            if (!err.message.includes('BUSYGROUP')) {
                throw err;
            }
        }
        
        // Read from group
        const messages = await this.client.xReadGroup(
            groupName,
            consumerName,
            [{ key: streamKey, id: '>' }],
            { COUNT: 5, BLOCK: 1000 }
        );
        
        if (messages) {
            for (const stream of messages) {
                for (const message of stream.messages) {
                    console.log(`🔄 Processing message: ${message.id}`);
                    
                    // Acknowledge message
                    await this.client.xAck(streamKey, groupName, message.id);
                }
            }
        }
        
        return messages;
    }
    
    async cleanup() {
        if (this.client) {
            await this.client.disconnect();
        }
    }
}

export default StreamProcessor;