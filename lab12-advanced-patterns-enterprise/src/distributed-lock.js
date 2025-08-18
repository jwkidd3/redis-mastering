const { createClient } = require('redis');
const crypto = require('crypto');

class RedisLock {
    constructor(client) {
        this.client = client;
        this.locks = new Map();
    }

    async acquireLock(resource, ttl = 5000) {
        const token = crypto.randomBytes(16).toString('hex');
        const lockKey = `lock:${resource}`;
        
        try {
            // Try to acquire lock with NX (only if not exists)
            const acquired = await this.client.set(
                lockKey,
                token,
                {
                    NX: true,
                    PX: ttl
                }
            );
            
            if (acquired) {
                this.locks.set(resource, { token, timer: null });
                console.log(`Lock acquired: ${resource} with token ${token.substring(0, 8)}...`);
                return token;
            }
            
            console.log(`Failed to acquire lock: ${resource}`);
            return null;
        } catch (error) {
            console.error('Error acquiring lock:', error);
            return null;
        }
    }

    async releaseLock(resource, token) {
        const lockKey = `lock:${resource}`;
        
        // Lua script for atomic check and delete
        const script = `
            if redis.call("get", KEYS[1]) == ARGV[1] then
                return redis.call("del", KEYS[1])
            else
                return 0
            end
        `;
        
        try {
            const released = await this.client.eval(script, {
                keys: [lockKey],
                arguments: [token]
            });
            
            if (released === 1) {
                this.locks.delete(resource);
                console.log(`Lock released: ${resource}`);
                return true;
            }
            
            console.log(`Failed to release lock: ${resource} (wrong token)`);
            return false;
        } catch (error) {
            console.error('Error releasing lock:', error);
            return false;
        }
    }

    async extendLock(resource, token, ttl = 5000) {
        const lockKey = `lock:${resource}`;
        
        // Lua script for atomic check and extend
        const script = `
            if redis.call("get", KEYS[1]) == ARGV[1] then
                return redis.call("pexpire", KEYS[1], ARGV[2])
            else
                return 0
            end
        `;
        
        const extended = await this.client.eval(script, {
            keys: [lockKey],
            arguments: [token, ttl.toString()]
        });
        
        if (extended === 1) {
            console.log(`Lock extended: ${resource}`);
            return true;
        }
        
        return false;
    }

    async withLock(resource, operation, options = {}) {
        const { ttl = 5000, retries = 3, retryDelay = 100 } = options;
        
        for (let i = 0; i < retries; i++) {
            const token = await this.acquireLock(resource, ttl);
            
            if (token) {
                try {
                    const result = await operation();
                    return result;
                } finally {
                    await this.releaseLock(resource, token);
                }
            }
            
            if (i < retries - 1) {
                console.log(`Retrying lock acquisition... (${i + 1}/${retries})`);
                await new Promise(r => setTimeout(r, retryDelay * (i + 1)));
            }
        }
        
        throw new Error(`Failed to acquire lock for ${resource} after ${retries} attempts`);
    }
}

module.exports = RedisLock;
