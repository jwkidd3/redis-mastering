# Redis Hash Commands Reference

## Basic Hash Operations

### Setting Values
```bash
# Set single field
HSET key field value

# Set multiple fields
HSET key field1 value1 field2 value2

# Set multiple fields (legacy syntax)
HMSET key field1 value1 field2 value2

# Set field only if it doesn't exist
HSETNX key field value
```

### Getting Values
```bash
# Get single field
HGET key field

# Get all fields and values
HGETALL key

# Get multiple fields
HMGET key field1 field2 field3

# Get all field names
HKEYS key

# Get all values
HVALS key
```

### Field Management
```bash
# Check if field exists
HEXISTS key field

# Delete one or more fields
HDEL key field1 field2

# Get number of fields
HLEN key
```

### Numeric Operations
```bash
# Increment integer field
HINCRBY key field increment

# Increment float field
HINCRBYFLOAT key field increment
```

## JavaScript Examples with redis Package

### Connection Setup
```javascript
const redis = require('redis');
const client = redis.createClient({
    host: 'your-redis-host',
    port: 6379
});

await client.connect();
```

### Basic Operations
```javascript
// Set hash fields
await client.hSet('user:1001', {
    'name': 'John Doe',
    'email': 'john@example.com',
    'age': '30'
});

// Get single field
const name = await client.hGet('user:1001', 'name');

// Get all fields
const user = await client.hGetAll('user:1001');

// Get multiple fields
const fields = await client.hmGet('user:1001', ['name', 'email']);
```

### Advanced Operations
```javascript
// Check field existence
const exists = await client.hExists('user:1001', 'phone');

// Get field count
const fieldCount = await client.hLen('user:1001');

// Get all field names
const fieldNames = await client.hKeys('user:1001');

// Increment numeric field
await client.hIncrBy('user:1001', 'age', 1);

// Delete field
await client.hDel('user:1001', 'temporary_field');
```

### Complex Data Handling
```javascript
// Store JSON data in hash field
const complexData = {
    preferences: { theme: 'dark', notifications: true },
    settings: { language: 'en', timezone: 'UTC' }
};

await client.hSet('user:1001', 'preferences', JSON.stringify(complexData));

// Retrieve and parse JSON data
const storedData = await client.hGet('user:1001', 'preferences');
const parsedData = JSON.parse(storedData);
```

## Best Practices

### Key Naming Conventions
```javascript
// Use consistent patterns
'user:1001'           // User profile
'policy:AUTO001'      // Policy data
'session:abc123'      // Session data
'cart:user:1001'      // Shopping cart
```

### Memory Optimization
```javascript
// Hashes are memory-efficient for small collections
// Use hashes when you have:
// - Related fields that are accessed together
// - Small to medium-sized objects (< 1000 fields)
// - Need to update individual fields frequently
```

### Error Handling
```javascript
try {
    const data = await client.hGetAll('user:1001');
    if (Object.keys(data).length === 0) {
        console.log('Hash not found or empty');
    }
} catch (error) {
    console.error('Redis operation failed:', error);
}
```

### Batch Operations
```javascript
// Use pipeline for multiple operations
const pipeline = client.multi();
pipeline.hSet('user:1001', 'lastLogin', new Date().toISOString());
pipeline.hIncrBy('user:1001', 'loginCount', 1);
pipeline.hSet('user:1001', 'status', 'active');
await pipeline.exec();
```

## Performance Considerations

### When to Use Hashes
- ✅ Storing user profiles, product details, configuration data
- ✅ When you need to update individual fields frequently
- ✅ Memory-efficient storage of structured data
- ✅ When fields are accessed together

### When NOT to Use Hashes
- ❌ Very large objects (> 1000 fields)
- ❌ When you always access all fields together (use strings with JSON)
- ❌ Complex nested structures (consider separate keys)
- ❌ When you need field-level expiration (use separate keys)

### Memory Usage
```javascript
// Check memory usage of hash
await client.memory('usage', 'user:1001');

// Estimate hash overhead
// Each hash field has small overhead (~20-40 bytes)
// Total memory = (key_size + value_size + overhead) * field_count
```

## Common Patterns

### User Profile Management
```javascript
class UserProfile {
    async create(userId, profileData) {
        await client.hSet(`user:${userId}`, profileData);
    }
    
    async update(userId, updates) {
        await client.hSet(`user:${userId}`, updates);
    }
    
    async get(userId) {
        return await client.hGetAll(`user:${userId}`);
    }
}
```

### Configuration Storage
```javascript
class AppConfig {
    async setConfig(section, key, value) {
        await client.hSet(`config:${section}`, key, value);
    }
    
    async getConfig(section) {
        return await client.hGetAll(`config:${section}`);
    }
}
```

### Shopping Cart
```javascript
class ShoppingCart {
    async addItem(userId, productId, quantity) {
        await client.hSet(`cart:${userId}`, productId, quantity);
    }
    
    async removeItem(userId, productId) {
        await client.hDel(`cart:${userId}`, productId);
    }
    
    async getCart(userId) {
        return await client.hGetAll(`cart:${userId}`);
    }
}
```
