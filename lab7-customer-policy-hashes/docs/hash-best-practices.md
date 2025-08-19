# Redis Hash Best Practices

## When to Use Hashes

### Perfect Use Cases
- **User profiles** with multiple attributes
- **Product catalogs** with specifications
- **Configuration settings** with key-value pairs
- **Session data** with multiple fields
- **Customer records** with contact information

### Avoid Hashes For
- **Very large objects** (>1000 fields)
- **Binary data** (use strings instead)
- **Complex nested structures** (consider separate keys)
- **Time-series data** (use lists or sorted sets)

## Performance Optimization

### Memory Efficiency
```javascript
// Good: Related fields in one hash
await client.hSet('user:1001', {
    'name': 'John Doe',
    'email': 'john@example.com',
    'age': '30',
    'city': 'Seattle'
});

// Avoid: Separate keys for related data
await client.set('user:1001:name', 'John Doe');
await client.set('user:1001:email', 'john@example.com');
```

### Batch Operations
```javascript
// Efficient: Single operation
await client.hSet('product:123', {
    'name': 'Widget',
    'price': '29.99',
    'category': 'gadgets',
    'stock': '100'
});

// Inefficient: Multiple operations
await client.hSet('product:123', 'name', 'Widget');
await client.hSet('product:123', 'price', '29.99');
await client.hSet('product:123', 'category', 'gadgets');
await client.hSet('product:123', 'stock', '100');
```

## Key Naming Conventions

### Hierarchical Structure
```javascript
// Application data
'app:config:database'
'app:config:cache'
'app:config:logging'

// User data
'user:profile:1001'
'user:preferences:1001'
'user:session:abc123'

// Business entities
'customer:profile:C001'
'policy:details:POL001'
'claim:info:CLM001'
```

### Consistent Patterns
```javascript
// Good: Consistent entity:type:id pattern
'customer:profile:123'
'customer:billing:123'
'customer:preferences:123'

// Avoid: Inconsistent patterns
'customer_123_profile'
'billing-info-123'
'prefs:123'
```

## Data Type Handling

### Numeric Values
```javascript
// Store as strings, convert when needed
await client.hSet('account:123', 'balance', '1250.75');

// Atomic increment operations
await client.hIncrByFloat('account:123', 'balance', 100.25);

// Retrieve and convert
const balance = parseFloat(await client.hGet('account:123', 'balance'));
```

### JSON Data
```javascript
// Complex objects as JSON strings
const preferences = {
    theme: 'dark',
    notifications: {
        email: true,
        sms: false,
        push: true
    },
    language: 'en-US'
};

await client.hSet('user:123', 'preferences', JSON.stringify(preferences));

// Retrieve and parse
const stored = await client.hGet('user:123', 'preferences');
const parsed = JSON.parse(stored);
```

### Date/Time Values
```javascript
// ISO string format for consistency
await client.hSet('event:123', {
    'created': new Date().toISOString(),
    'scheduled': '2024-12-25T10:00:00Z',
    'modified': new Date().toISOString()
});

// Unix timestamp for calculations
await client.hSet('session:abc', {
    'loginTime': Date.now().toString(),
    'lastActivity': Date.now().toString()
});
```

## Error Handling Patterns

### Existence Checks
```javascript
async function getCustomerSafely(customerId) {
    try {
        // Check if hash exists
        const exists = await client.exists(`customer:${customerId}`);
        if (!exists) {
            throw new Error(`Customer ${customerId} not found`);
        }
        
        return await client.hGetAll(`customer:${customerId}`);
    } catch (error) {
        console.error('Error retrieving customer:', error);
        throw error;
    }
}
```

### Field Validation
```javascript
async function updateCustomerField(customerId, field, value) {
    try {
        // Validate field exists
        const fieldExists = await client.hExists(`customer:${customerId}`, field);
        if (!fieldExists) {
            throw new Error(`Field ${field} does not exist`);
        }
        
        await client.hSet(`customer:${customerId}`, field, value);
    } catch (error) {
        console.error('Error updating field:', error);
        throw error;
    }
}
```

## Security Considerations

### Input Validation
```javascript
function validateEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
}

async function createCustomer(customerData) {
    // Validate inputs before storing
    if (!validateEmail(customerData.email)) {
        throw new Error('Invalid email format');
    }
    
    // Sanitize data
    const sanitized = {
        firstName: customerData.firstName.trim(),
        lastName: customerData.lastName.trim(),
        email: customerData.email.toLowerCase().trim()
    };
    
    await client.hSet(`customer:${customerId}`, sanitized);
}
```

### Access Control
```javascript
// Check permissions before operations
async function updateCustomerData(userId, customerId, updates) {
    // Verify user has permission to update this customer
    const hasPermission = await checkUserPermission(userId, customerId);
    if (!hasPermission) {
        throw new Error('Insufficient permissions');
    }
    
    await client.hSet(`customer:${customerId}`, updates);
}
```

## Monitoring and Debugging

### Memory Usage Tracking
```javascript
async function getHashMemoryUsage(key) {
    try {
        const memory = await client.memory('usage', key);
        const fieldCount = await client.hLen(key);
        
        return {
            totalMemory: memory,
            fieldCount: fieldCount,
            avgFieldSize: memory / fieldCount
        };
    } catch (error) {
        console.log('Memory command not available');
        return null;
    }
}
```

### Performance Monitoring
```javascript
async function timedHashOperation(operation, ...args) {
    const start = Date.now();
    try {
        const result = await operation(...args);
        const duration = Date.now() - start;
        
        console.log(`Hash operation completed in ${duration}ms`);
        return result;
    } catch (error) {
        const duration = Date.now() - start;
        console.error(`Hash operation failed after ${duration}ms:`, error);
        throw error;
    }
}
```

## Advanced Patterns

### Hash Pipelines
```javascript
async function batchCustomerUpdate(customerId, updates) {
    const pipeline = client.multi();
    
    // Queue multiple hash operations
    Object.entries(updates).forEach(([field, value]) => {
        pipeline.hSet(`customer:${customerId}`, field, value);
    });
    
    // Add timestamp
    pipeline.hSet(`customer:${customerId}`, 'lastUpdated', new Date().toISOString());
    
    // Execute all operations atomically
    const results = await pipeline.exec();
    return results;
}
```

### Hash Expiration Management
```javascript
// Note: Hashes don't support field-level expiration
// Use separate keys for fields that need expiration

async function setTemporaryField(key, field, value, ttlSeconds) {
    // Store temporary data in separate key
    const tempKey = `${key}:temp:${field}`;
    await client.setEx(tempKey, ttlSeconds, value);
    
    // Reference in main hash
    await client.hSet(key, `${field}_ref`, tempKey);
}
```

### Indexing Strategies
```javascript
// Create indexes for fast lookups
async function createCustomerIndex(customerId, customerData) {
    // Store main data
    await client.hSet(`customer:${customerId}`, customerData);
    
    // Create indexes
    await client.sAdd(`customers:city:${customerData.city}`, customerId);
    await client.sAdd(`customers:state:${customerData.state}`, customerId);
    await client.sAdd(`customers:status:${customerData.status}`, customerId);
}
```

## Testing Strategies

### Unit Test Examples
```javascript
// Example test for customer creation
describe('CustomerManager', () => {
    test('should create customer with valid data', async () => {
        const customerData = {
            firstName: 'John',
            lastName: 'Doe',
            email: 'john@example.com'
        };
        
        const customerId = await customerManager.createCustomer('C001', customerData);
        expect(customerId).toBe('C001');
        
        const stored = await customerManager.getCustomer('C001');
        expect(stored.firstName).toBe('John');
        expect(stored.email).toBe('john@example.com');
    });
});
```

### Integration Tests
```javascript
async function testCustomerPolicyIntegration() {
    // Create customer
    const customerId = 'TEST001';
    await customerManager.createCustomer(customerId, testCustomerData);
    
    // Create policy for customer
    const policyData = { ...testPolicyData, customerId };
    const policyId = await policyManager.createPolicy(policyData);
    
    // Verify relationship
    const customerPolicies = await policyManager.getCustomerPolicies(customerId);
    expect(customerPolicies).toHaveLength(1);
    expect(customerPolicies[0].policyNumber).toBe(policyId);
    
    // Cleanup
    await customerManager.deleteCustomer(customerId);
    await policyManager.deletePolicy(policyId);
}
```
