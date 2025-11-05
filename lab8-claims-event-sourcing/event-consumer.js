// event-consumer.js - Event consumer for claims using Redis Streams
const redis = require('redis');

class EventConsumer {
    constructor(consumerGroup = 'claims-processors', consumerId = 'consumer-1') {
        this.client = null;
        this.streamKey = 'claims:events';
        this.consumerGroup = consumerGroup;
        this.consumerId = consumerId;
    }

    async connect() {
        this.client = redis.createClient();
        await this.client.connect();

        // Create consumer group if it doesn't exist
        try {
            await this.client.xGroupCreate(this.streamKey, this.consumerGroup, '0', {
                MKSTREAM: true
            });
            console.log(`✓ Consumer group created: ${this.consumerGroup}`);
        } catch (error) {
            if (error.message.includes('BUSYGROUP')) {
                console.log(`✓ Consumer group exists: ${this.consumerGroup}`);
            } else {
                throw error;
            }
        }
    }

    async disconnect() {
        if (this.client) {
            await this.client.quit();
        }
    }

    // Read events from the stream
    async readEvents(count = 10) {
        const messages = await this.client.xReadGroup(
            this.consumerGroup,
            this.consumerId,
            [{ key: this.streamKey, id: '>' }],
            { COUNT: count, BLOCK: 5000 }
        );

        if (!messages || messages.length === 0) {
            return [];
        }

        return messages[0].messages.map(msg => ({
            id: msg.id,
            ...msg.message
        }));
    }

    // Process an event
    async processEvent(eventId, processor) {
        try {
            await processor();
            // Acknowledge the message
            await this.client.xAck(this.streamKey, this.consumerGroup, eventId);
            console.log(`✓ Event processed: ${eventId}`);
        } catch (error) {
            console.error(`✗ Failed to process event ${eventId}:`, error.message);
        }
    }

    // Start consuming events
    async startConsuming(eventHandler) {
        console.log(`✓ Consumer started: ${this.consumerId}`);

        while (true) {
            const events = await this.readEvents();

            for (const event of events) {
                await this.processEvent(event.id, () => eventHandler(event));
            }
        }
    }
}

module.exports = EventConsumer;
