import connectRedis from './connection.js';

class EventManager {
    constructor() {
        this.publisher = null;
        this.subscriber = null;
    }
    
    async initialize() {
        this.publisher = await connectRedis();
        this.subscriber = await connectRedis();
        console.log('📡 Event manager initialized');
    }
    
    async subscribeToEvents(channel, callback) {
        await this.subscriber.subscribe(channel, (message) => {
            try {
                const data = JSON.parse(message);
                callback(data);
            } catch (error) {
                console.error('Error parsing message:', error);
                callback({ raw: message });
            }
        });
        console.log(`🎧 Subscribed to channel: ${channel}`);
    }
    
    async publishEvent(channel, data) {
        const message = JSON.stringify({
            ...data,
            timestamp: Date.now(),
            id: Math.random().toString(36).substring(7)
        });
        
        const result = await this.publisher.publish(channel, message);
        console.log(`📢 Published to ${channel}, subscribers: ${result}`);
        return result;
    }
    
    async cleanup() {
        if (this.subscriber) {
            await this.subscriber.disconnect();
        }
        if (this.publisher) {
            await this.publisher.disconnect();
        }
    }
}

export default EventManager;