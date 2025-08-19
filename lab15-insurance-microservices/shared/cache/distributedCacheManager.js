const redis = require('redis');
const EventEmitter = require('events');

class DistributedCacheManager extends EventEmitter {
    constructor(options = {}) {
        super();
        
        this.options = {
            host: options.host || 'localhost',
            port: options.port || 6379,
            password: options.password || '',
            serviceName: options.serviceName || 'unknown-service',
            keyPrefix: options.keyPrefix || '',
            defaultTTL: options.defaultTTL || 3600,
            maxRetries: options.maxRetries || 3,
            retryDelay: options.retryDelay || 1000
        };

        this.redis = null;
        this.subscriber = null;
        this.publisher = null;
        this.isConnected = false;
        
        this.setupClients();
    }

    setupClients() {
        const clientConfig = {
            socket: {
                host: this.options.host,
                port: this.options.port
            },
            password: this.options.password || undefined,
            retry_strategy: (options) => {
                if (options.error && options.error.code === 'ECONNREFUSED') {
                    console.error(`Redis connection refused for ${this.options.serviceName}`);
                    return new Error('Redis server connection refused');
                }
                if (options.total_retry_time > 1000 * 60 * 60) {
                    console.error(`Redis retry time exhausted for ${this.options.serviceName}`);
                    return new Error('Retry time exhausted');
                }
                return Math.min(options.attempt * 100, 3000);
            }
        };

        this.redis = redis.createClient(clientConfig);
        this.subscriber = redis.createClient(clientConfig);
        this.publisher = redis.createClient(clientConfig);

        this.setupEventHandlers();
    }

    setupEventHandlers() {
        [this.redis, this.subscriber, this.publisher].forEach(client => {
            client.on('error', (err) => {
                console.error(`Redis error in ${this.options.serviceName}:`, err);
                this.emit('error', err);
            });

            client.on('connect', () => {
                console.log(`🔗 ${this.options.serviceName} Redis client connected`);
            });

            client.on('ready', () => {
                console.log(`✅ ${this.options.serviceName} Redis client ready`);
            });
        });

        this.redis.on('ready', () => {
            this.isConnected = true;
            this.emit('ready');
        });
    }

    async connect() {
        try {
            await Promise.all([
                this.redis.connect(),
                this.subscriber.connect(),
                this.publisher.connect()
            ]);

            // Register this service
            await this.registerService();
            
            // Subscribe to cache events
            this.subscribeToEvents();
            
            console.log(`✅ ${this.options.serviceName} connected to Redis cluster`);
            return true;
        } catch (error) {
            console.error(`Failed to connect ${this.options.serviceName} to Redis:`, error);
            throw error;
        }
    }

    async disconnect() {
        try {
            await this.unregisterService();
            
            await Promise.all([
                this.redis.quit(),
                this.subscriber.quit(),
                this.publisher.quit()
            ]);
            
            this.isConnected = false;
            console.log(`🔌 ${this.options.serviceName} disconnected from Redis`);
        } catch (error) {
            console.error(`Error disconnecting ${this.options.serviceName}:`, error);
        }
    }

    getKey(key) {
        return this.options.keyPrefix ? `${this.options.keyPrefix}:${key}` : key;
    }

    // Cache Operations
    async set(key, value, options = {}) {
        const fullKey = this.getKey(key);
        const ttl = options.ttl || this.options.defaultTTL;
        const data = typeof value === 'object' ? JSON.stringify(value) : value;
        
        try {
            await this.redis.setEx(fullKey, ttl, data);
            
            // Notify other services of cache update
            await this.publishEvent('cache:update', {
                service: this.options.serviceName,
                key: fullKey,
                operation: 'SET',
                ttl,
                timestamp: Date.now()
            });
            
            return true;
        } catch (error) {
            console.error(`Cache set error in ${this.options.serviceName}:`, error);
            throw error;
        }
    }

    async get(key) {
        const fullKey = this.getKey(key);
        
        try {
            const data = await this.redis.get(fullKey);
            if (!data) return null;
            
            try {
                return JSON.parse(data);
            } catch (e) {
                return data;
            }
        } catch (error) {
            console.error(`Cache get error in ${this.options.serviceName}:`, error);
            return null;
        }
    }

    async mget(keys) {
        const fullKeys = keys.map(key => this.getKey(key));
        
        try {
            const values = await this.redis.mGet(fullKeys);
            return values.map(value => {
                if (!value) return null;
                try {
                    return JSON.parse(value);
                } catch (e) {
                    return value;
                }
            });
        } catch (error) {
            console.error(`Cache mget error in ${this.options.serviceName}:`, error);
            return keys.map(() => null);
        }
    }

    async del(key, notifyServices = true) {
        const fullKey = this.getKey(key);
        
        try {
            const result = await this.redis.del(fullKey);
            
            if (notifyServices && result > 0) {
                await this.publishEvent('cache:invalidate', {
                    service: this.options.serviceName,
                    key: fullKey,
                    operation: 'DELETE',
                    timestamp: Date.now()
                });
            }
            
            console.log(`🗑️  Cache invalidated: ${fullKey} by ${this.options.serviceName}`);
            return result;
        } catch (error) {
            console.error(`Cache delete error in ${this.options.serviceName}:`, error);
            return 0;
        }
    }

    async invalidatePattern(pattern) {
        const fullPattern = this.getKey(pattern);
        
        try {
            const keys = await this.redis.keys(fullPattern);
            if (keys.length > 0) {
                await this.redis.del(...keys);
                
                await this.publishEvent('cache:invalidate:pattern', {
                    service: this.options.serviceName,
                    pattern: fullPattern,
                    keys,
                    count: keys.length,
                    timestamp: Date.now()
                });
                
                console.log(`🗑️  Pattern invalidated: ${fullPattern} (${keys.length} keys) by ${this.options.serviceName}`);
            }
            
            return keys.length;
        } catch (error) {
            console.error(`Pattern invalidation error in ${this.options.serviceName}:`, error);
            return 0;
        }
    }

    async exists(key) {
        const fullKey = this.getKey(key);
        try {
            return await this.redis.exists(fullKey);
        } catch (error) {
            console.error(`Cache exists error in ${this.options.serviceName}:`, error);
            return 0;
        }
    }

    async ttl(key) {
        const fullKey = this.getKey(key);
        try {
            return await this.redis.ttl(fullKey);
        } catch (error) {
            console.error(`TTL check error in ${this.options.serviceName}:`, error);
            return -1;
        }
    }

    // Event System
    async publishEvent(channel, data) {
        try {
            const message = JSON.stringify(data);
            await this.publisher.publish(channel, message);
            this.emit('event:published', { channel, data });
        } catch (error) {
            console.error(`Event publish error in ${this.options.serviceName}:`, error);
        }
    }

    subscribeToEvents() {
        const channels = [
            'cache:update',
            'cache:invalidate',
            'cache:invalidate:pattern',
            `service:${this.options.serviceName}:events`
        ];

        channels.forEach(channel => {
            this.subscriber.subscribe(channel);
        });

        this.subscriber.on('message', (channel, message) => {
            try {
                const event = JSON.parse(message);
                
                if (event.service !== this.options.serviceName) {
                    console.log(`📡 ${this.options.serviceName} received ${channel} from ${event.service}`);
                    this.handleCacheEvent(channel, event);
                    this.emit('event:received', { channel, event });
                }
            } catch (error) {
                console.error(`Event handling error in ${this.options.serviceName}:`, error);
            }
        });
    }

    handleCacheEvent(channel, event) {
        switch (channel) {
            case 'cache:invalidate':
                this.emit('cache:invalidated', event);
                break;
            case 'cache:invalidate:pattern':
                this.emit('cache:pattern:invalidated', event);
                break;
            case 'cache:update':
                this.emit('cache:updated', event);
                break;
            default:
                this.emit('cache:event', { channel, event });
        }
    }

    // Service Registry
    async registerService() {
        const serviceKey = `service:registry:${this.options.serviceName}`;
        const serviceInfo = {
            name: this.options.serviceName,
            registeredAt: new Date().toISOString(),
            lastHeartbeat: new Date().toISOString(),
            status: 'active',
            version: process.env.SERVICE_VERSION || '1.0.0',
            host: process.env.HOSTNAME || 'localhost',
            port: process.env.PORT || 3000
        };

        try {
            await this.redis.setEx(serviceKey, 30, JSON.stringify(serviceInfo));
            
            // Setup heartbeat
            this.heartbeatInterval = setInterval(async () => {
                try {
                    serviceInfo.lastHeartbeat = new Date().toISOString();
                    await this.redis.setEx(serviceKey, 30, JSON.stringify(serviceInfo));
                } catch (error) {
                    console.error(`Heartbeat error for ${this.options.serviceName}:`, error);
                }
            }, 10000); // 10 second heartbeat
            
            console.log(`📋 Service registered: ${this.options.serviceName}`);
        } catch (error) {
            console.error(`Service registration error for ${this.options.serviceName}:`, error);
        }
    }

    async unregisterService() {
        if (this.heartbeatInterval) {
            clearInterval(this.heartbeatInterval);
        }

        const serviceKey = `service:registry:${this.options.serviceName}`;
        try {
            await this.redis.del(serviceKey);
            console.log(`📋 Service unregistered: ${this.options.serviceName}`);
        } catch (error) {
            console.error(`Service unregistration error for ${this.options.serviceName}:`, error);
        }
    }

    async getRegisteredServices() {
        try {
            const keys = await this.redis.keys('service:registry:*');
            const services = [];
            
            for (const key of keys) {
                const data = await this.redis.get(key);
                if (data) {
                    try {
                        services.push(JSON.parse(data));
                    } catch (e) {
                        console.warn(`Invalid service data for ${key}`);
                    }
                }
            }
            
            return services;
        } catch (error) {
            console.error(`Get services error in ${this.options.serviceName}:`, error);
            return [];
        }
    }

    // Health Check
    async healthCheck() {
        try {
            const start = Date.now();
            await this.redis.ping();
            const latency = Date.now() - start;
            
            return {
                status: 'healthy',
                service: this.options.serviceName,
                latency: `${latency}ms`,
                connected: this.isConnected,
                timestamp: new Date().toISOString()
            };
        } catch (error) {
            return {
                status: 'unhealthy',
                service: this.options.serviceName,
                error: error.message,
                connected: false,
                timestamp: new Date().toISOString()
            };
        }
    }

    // Transaction Support
    async transaction(operations) {
        const multi = this.redis.multi();
        
        try {
            for (const op of operations) {
                switch (op.type) {
                    case 'set':
                        multi.setEx(this.getKey(op.key), op.ttl || this.options.defaultTTL, 
                                   typeof op.value === 'object' ? JSON.stringify(op.value) : op.value);
                        break;
                    case 'del':
                        multi.del(this.getKey(op.key));
                        break;
                    case 'incr':
                        multi.incr(this.getKey(op.key));
                        break;
                    case 'decr':
                        multi.decr(this.getKey(op.key));
                        break;
                }
            }
            
            const results = await multi.exec();
            console.log(`✅ Transaction completed: ${operations.length} operations`);
            return results;
        } catch (error) {
            console.error(`Transaction error in ${this.options.serviceName}:`, error);
            throw error;
        }
    }
}

module.exports = DistributedCacheManager;
