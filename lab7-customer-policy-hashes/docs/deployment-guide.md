# Deployment Guide for Redis Hash Applications

## Production Considerations

### Redis Configuration
```bash
# redis.conf optimizations for hash-heavy workloads

# Memory optimization
maxmemory 2gb
maxmemory-policy allkeys-lru

# Hash-specific optimizations
hash-max-ziplist-entries 512
hash-max-ziplist-value 64

# Persistence settings
save 900 1
save 300 10
save 60 10000

# Performance tuning
tcp-keepalive 300
timeout 0
tcp-backlog 511
```

### Application Configuration
```javascript
// production-config.js
module.exports = {
    redis: {
        host: process.env.REDIS_HOST,
        port: process.env.REDIS_PORT || 6379,
        password: process.env.REDIS_PASSWORD,
        retryDelayOnFailover: 100,
        enableReadyCheck: true,
        maxRetriesPerRequest: 3,
        lazyConnect: true,
        keepAlive: 30000,
        family: 4,
        db: process.env.REDIS_DB || 0
    },
    app: {
        environment: process.env.NODE_ENV || 'production',
        logLevel: process.env.LOG_LEVEL || 'info',
        maxConnections: process.env.MAX_CONNECTIONS || 100
    }
};
```

### Connection Pool Management
```javascript
const Redis = require('ioredis');

class RedisConnectionPool {
    constructor(config) {
        this.config = config;
        this.cluster = new Redis.Cluster([
            { host: config.host, port: config.port }
        ], {
            redisOptions: {
                password: config.password,
                family: 4
            },
            enableOfflineQueue: false,
            retryDelayOnFailover: 100,
            maxRetriesPerRequest: 3
        });
    }

    async healthCheck() {
        try {
            await this.cluster.ping();
            return { status: 'healthy', timestamp: new Date().toISOString() };
        } catch (error) {
            return { status: 'unhealthy', error: error.message, timestamp: new Date().toISOString() };
        }
    }
}
```

## Docker Deployment

### Dockerfile
```dockerfile
FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy application code
COPY src/ ./src/
COPY *.js ./

# Create non-root user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001

# Change ownership
RUN chown -R nextjs:nodejs /app
USER nextjs

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node health-check.js

EXPOSE 3000

CMD ["node", "src/app.js"]
```

### Docker Compose
```yaml
version: '3.8'

services:
  redis:
    image: redis:7-alpine
    container_name: redis-server
    restart: unless-stopped
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data
      - ./redis.conf:/usr/local/etc/redis/redis.conf
    command: redis-server /usr/local/etc/redis/redis.conf
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 3s
      retries: 3

  app:
    build: .
    container_name: customer-policy-app
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - REDIS_HOST=redis
      - REDIS_PORT=6379
      - LOG_LEVEL=info
    depends_on:
      redis:
        condition: service_healthy
    volumes:
      - ./logs:/app/logs

volumes:
  redis-data:
```

## Monitoring and Logging

### Application Monitoring
```javascript
const winston = require('winston');

// Configure logging
const logger = winston.createLogger({
    level: 'info',
    format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.errors({ stack: true }),
        winston.format.json()
    ),
    defaultMeta: { service: 'customer-policy-system' },
    transports: [
        new winston.transports.File({ filename: 'logs/error.log', level: 'error' }),
        new winston.transports.File({ filename: 'logs/combined.log' }),
        new winston.transports.Console({
            format: winston.format.simple()
        })
    ]
});

// Performance monitoring
class PerformanceMonitor {
    static async trackHashOperation(operation, key, duration) {
        logger.info('Hash operation completed', {
            operation,
            key,
            duration,
            timestamp: new Date().toISOString()
        });

        // Send to monitoring service
        if (duration > 1000) {
            logger.warn('Slow hash operation detected', {
                operation,
                key,
                duration
            });
        }
    }
}
```

### Health Check Endpoint
```javascript
// health-check.js
const RedisClient = require('./src/redis-client');

async function healthCheck() {
    const redisClient = new RedisClient();
    
    try {
        await redisClient.connect();
        const client = redisClient.getClient();
        
        // Test basic operations
        await client.ping();
        
        // Test hash operations
        const testKey = 'health:check:' + Date.now();
        await client.hSet(testKey, 'status', 'ok');
        await client.del(testKey);
        
        console.log('Health check passed');
        process.exit(0);
    } catch (error) {
        console.error('Health check failed:', error);
        process.exit(1);
    } finally {
        await redisClient.disconnect();
    }
}

healthCheck();
```

## Security Implementation

### Data Encryption
```javascript
const crypto = require('crypto');

class DataEncryption {
    constructor(secretKey) {
        this.algorithm = 'aes-256-gcm';
        this.secretKey = crypto.scryptSync(secretKey, 'salt', 32);
    }

    encrypt(text) {
        const iv = crypto.randomBytes(16);
        const cipher = crypto.createCipher(this.algorithm, this.secretKey, iv);
        
        let encrypted = cipher.update(text, 'utf8', 'hex');
        encrypted += cipher.final('hex');
        
        const authTag = cipher.getAuthTag();
        
        return {
            encrypted,
            iv: iv.toString('hex'),
            authTag: authTag.toString('hex')
        };
    }

    decrypt(encryptedData) {
        const decipher = crypto.createDecipher(
            this.algorithm, 
            this.secretKey, 
            Buffer.from(encryptedData.iv, 'hex')
        );
        
        decipher.setAuthTag(Buffer.from(encryptedData.authTag, 'hex'));
        
        let decrypted = decipher.update(encryptedData.encrypted, 'hex', 'utf8');
        decrypted += decipher.final('utf8');
        
        return decrypted;
    }
}

// Usage in customer manager
class SecureCustomerManager extends CustomerManager {
    constructor() {
        super();
        this.encryption = new DataEncryption(process.env.ENCRYPTION_KEY);
    }

    async createCustomer(customerId, customerData) {
        // Encrypt sensitive data
        if (customerData.ssn) {
            customerData.ssn = this.encryption.encrypt(customerData.ssn);
        }
        
        return super.createCustomer(customerId, customerData);
    }
}
```

### Access Control
```javascript
class AccessControl {
    constructor() {
        this.permissions = new Map();
    }

    async checkPermission(userId, resource, action) {
        const userPermissions = await this.getUserPermissions(userId);
        const permission = `${resource}:${action}`;
        
        return userPermissions.includes(permission) || 
               userPermissions.includes(`${resource}:*`) ||
               userPermissions.includes('*');
    }

    async getUserPermissions(userId) {
        // Implement your permission logic
        // This could be from database, Redis, or external service
        return ['customer:read', 'customer:update', 'policy:read'];
    }
}
```

## Backup and Recovery

### Backup Script
```bash
#!/bin/bash
# backup-redis.sh

BACKUP_DIR="/backups/redis"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="redis_backup_${TIMESTAMP}.rdb"

# Create backup directory
mkdir -p $BACKUP_DIR

# Perform backup
redis-cli --rdb $BACKUP_DIR/$BACKUP_FILE

# Compress backup
gzip $BACKUP_DIR/$BACKUP_FILE

# Upload to cloud storage (example with AWS S3)
aws s3 cp $BACKUP_DIR/${BACKUP_FILE}.gz s3://your-backup-bucket/redis/

# Clean up old backups (keep last 7 days)
find $BACKUP_DIR -name "*.gz" -mtime +7 -delete

echo "Backup completed: ${BACKUP_FILE}.gz"
```

### Recovery Procedure
```bash
#!/bin/bash
# restore-redis.sh

BACKUP_FILE=$1

if [ -z "$BACKUP_FILE" ]; then
    echo "Usage: $0 <backup_file>"
    exit 1
fi

# Stop Redis service
sudo systemctl stop redis

# Backup current data
cp /var/lib/redis/dump.rdb /var/lib/redis/dump.rdb.backup

# Restore from backup
gunzip -c $BACKUP_FILE > /var/lib/redis/dump.rdb

# Set correct permissions
chown redis:redis /var/lib/redis/dump.rdb

# Start Redis service
sudo systemctl start redis

echo "Recovery completed from: $BACKUP_FILE"
```

## Performance Optimization

### Caching Strategy
```javascript
class CachedCustomerManager extends CustomerManager {
    constructor() {
        super();
        this.cache = new Map();
        this.cacheTimeout = 5 * 60 * 1000; // 5 minutes
    }

    async getCustomer(customerId) {
        // Check cache first
        const cached = this.cache.get(customerId);
        if (cached && Date.now() - cached.timestamp < this.cacheTimeout) {
            return cached.data;
        }

        // Fetch from Redis
        const customer = await super.getCustomer(customerId);
        
        // Update cache
        this.cache.set(customerId, {
            data: customer,
            timestamp: Date.now()
        });

        return customer;
    }

    async updateCustomer(customerId, updates) {
        // Update Redis
        await super.updateCustomer(customerId, updates);
        
        // Invalidate cache
        this.cache.delete(customerId);
    }
}
```

### Database Optimization
```javascript
// Connection optimization
const connectionConfig = {
    retryDelayOnFailover: 100,
    enableReadyCheck: true,
    maxRetriesPerRequest: 3,
    lazyConnect: true,
    keepAlive: 30000,
    commandTimeout: 5000,
    connectTimeout: 10000
};

// Use connection pooling for high throughput
class OptimizedRedisClient extends RedisClient {
    constructor() {
        super();
        this.pool = [];
        this.poolSize = 10;
    }

    async getConnection() {
        if (this.pool.length > 0) {
            return this.pool.pop();
        }
        
        const client = redis.createClient(connectionConfig);
        await client.connect();
        return client;
    }

    async releaseConnection(client) {
        if (this.pool.length < this.poolSize) {
            this.pool.push(client);
        } else {
            await client.disconnect();
        }
    }
}
```

## Environment Configuration

### Environment Variables
```bash
# .env.production
NODE_ENV=production
LOG_LEVEL=info

# Redis Configuration
REDIS_HOST=your-redis-host.com
REDIS_PORT=6379
REDIS_PASSWORD=your-secure-password
REDIS_DB=0

# Security
ENCRYPTION_KEY=your-encryption-key
JWT_SECRET=your-jwt-secret

# Application
MAX_CONNECTIONS=100
CACHE_TIMEOUT=300000
BATCH_SIZE=1000

# Monitoring
METRICS_ENDPOINT=https://your-metrics-service.com
LOG_ENDPOINT=https://your-log-service.com
```

### Configuration Management
```javascript
// config/index.js
const config = {
    development: require('./development'),
    production: require('./production'),
    test: require('./test')
};

module.exports = config[process.env.NODE_ENV || 'development'];
```

This deployment guide ensures your Redis hash-based applications are production-ready with proper monitoring, security, and performance optimization.
