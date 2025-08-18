const { createClient } = require('redis');

class ReliableQueue {
    constructor(client, queueName) {
        this.client = client;
        this.streamKey = `queue:${queueName}`;
        this.consumerGroup = `${queueName}-group`;
        this.consumerId = `consumer-${process.pid}-${Date.now()}`;
        this.running = false;
    }

    async initialize() {
        try {
            await this.client.xGroupCreate(
                this.streamKey,
                this.consumerGroup,
                '$',
                { MKSTREAM: true }
            );
            console.log(`Created consumer group: ${this.consumerGroup}`);
        } catch (error) {
            if (error.message.includes('BUSYGROUP')) {
                console.log(`Consumer group already exists: ${this.consumerGroup}`);
            } else {
                throw error;
            }
        }
    }

    async publish(message) {
        const messageId = await this.client.xAdd(
            this.streamKey,
            '*',
            {
                data: JSON.stringify(message),
                timestamp: Date.now().toString()
            }
        );
        
        console.log(`Published message: ${messageId}`);
        return messageId;
    }

    async consume(handler, options = {}) {
        const { count = 10, block = 1000 } = options;
        this.running = true;
        
        console.log(`Consumer ${this.consumerId} started`);
        
        while (this.running) {
            try {
                // Read pending messages first (messages that were read but not acknowledged)
                const pending = await this.client.xReadGroup(
                    this.consumerGroup,
                    this.consumerId,
                    [{ key: this.streamKey, id: '0' }],
                    { COUNT: count, BLOCK: 0 }
                );
                
                if (pending && pending.length > 0 && pending[0].messages.length > 0) {
                    console.log(`Processing ${pending[0].messages.length} pending messages`);
                    await this.processMessages(pending[0].messages, handler);
                }
                
                // Read new messages
                const messages = await this.client.xReadGroup(
                    this.consumerGroup,
                    this.consumerId,
                    [{ key: this.streamKey, id: '>' }],
                    { COUNT: count, BLOCK: block }
                );
                
                if (messages && messages.length > 0 && messages[0].messages.length > 0) {
                    console.log(`Processing ${messages[0].messages.length} new messages`);
                    await this.processMessages(messages[0].messages, handler);
                }
            } catch (error) {
                if (error.message.includes('NOGROUP')) {
                    await this.initialize();
                } else {
                    console.error('Consumer error:', error);
                    await new Promise(r => setTimeout(r, 1000));
                }
            }
        }
        
        console.log(`Consumer ${this.consumerId} stopped`);
    }

    async processMessages(messages, handler) {
        for (const message of messages) {
            try {
                const data = JSON.parse(message.message.data);
                
                // Process message
                await handler(data, message.id);
                
                // Acknowledge message
                await this.client.xAck(
                    this.streamKey,
                    this.consumerGroup,
                    message.id
                );
                
                console.log(`Processed and acknowledged: ${message.id}`);
            } catch (error) {
                console.error(`Failed to process ${message.id}:`, error);
                // Message will be redelivered to another consumer
            }
        }
    }

    stop() {
        this.running = false;
    }

    async getInfo() {
        const info = await this.client.xInfoGroups(this.streamKey);
        const streamInfo = await this.client.xInfoStream(this.streamKey);
        
        return {
            stream: streamInfo,
            groups: info,
            consumerId: this.consumerId
        };
    }
}

class PriorityQueue {
    constructor(client, queueName) {
        this.client = client;
        this.queueKey = `priority:${queueName}`;
        this.processingKey = `${this.queueKey}:processing`;
    }

    async enqueue(item, priority = 0) {
        const payload = JSON.stringify({
            ...item,
            enqueuedAt: Date.now()
        });
        
        await this.client.zAdd(this.queueKey, {
            score: -priority, // Negative for high priority first
            value: payload
        });
        
        console.log(`Enqueued item with priority ${priority}`);
    }

    async dequeue() {
        // Lua script for atomic dequeue
        const script = `
            local item = redis.call('zrange', KEYS[1], 0, 0)[1]
            if item then
                redis.call('zrem', KEYS[1], item)
                redis.call('zadd', KEYS[2], ARGV[1], item)
                return item
            end
            return nil
        `;
        
        const item = await this.client.eval(script, {
            keys: [this.queueKey, this.processingKey],
            arguments: [Date.now().toString()]
        });
        
        if (item) {
            console.log('Dequeued item');
            return JSON.parse(item);
        }
        
        return null;
    }

    async complete(item) {
        const payload = JSON.stringify(item);
        const removed = await this.client.zRem(this.processingKey, payload);
        
        if (removed) {
            console.log('Item marked as completed');
        }
        
        return removed > 0;
    }

    async requeueStale(maxAge = 60000) {
        const staleTime = Date.now() - maxAge;
        const staleItems = await this.client.zRangeByScore(
            this.processingKey,
            '-inf',
            staleTime
        );
        
        console.log(`Found ${staleItems.length} stale items`);
        
        for (const item of staleItems) {
            const parsed = JSON.parse(item);
            await this.enqueue(parsed, -1); // Lower priority for retry
            await this.client.zRem(this.processingKey, item);
        }
        
        return staleItems.length;
    }

    async getStats() {
        const queueSize = await this.client.zCard(this.queueKey);
        const processingSize = await this.client.zCard(this.processingKey);
        
        return {
            pending: queueSize,
            processing: processingSize,
            total: queueSize + processingSize
        };
    }
}

module.exports = { ReliableQueue, PriorityQueue };
