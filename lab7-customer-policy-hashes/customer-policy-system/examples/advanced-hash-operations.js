const RedisClient = require('../src/redis-client');

async function advancedHashOperations() {
    const redisClient = new RedisClient();
    
    try {
        await redisClient.connect();
        const client = redisClient.getClient();
        
        console.log('🚀 Advanced Hash Operations\n');

        // Bulk hash operations
        console.log('📦 Bulk hash operations...');
        
        // HMSET equivalent with multiple fields
        await client.hSet('customer:bulk', {
            'name': 'Jane Doe',
            'age': '28',
            'city': 'Seattle',
            'premium': '200'
        });

        // Get multiple fields at once
        const fields = await client.hmGet('customer:bulk', ['name', 'age', 'city']);
        console.log('Multiple fields:', fields);

        // Increment numeric field
        console.log('\n🔢 Numeric operations...');
        await client.hIncrBy('customer:bulk', 'age', 1);
        await client.hIncrByFloat('customer:bulk', 'premium', 15.50);
        
        const newAge = await client.hGet('customer:bulk', 'age');
        const newPremium = await client.hGet('customer:bulk', 'premium');
        console.log(`Updated age: ${newAge}, Updated premium: ${newPremium}`);

        // Check field existence
        console.log('\n❓ Field existence checks...');
        const emailExists = await client.hExists('customer:bulk', 'email');
        const nameExists = await client.hExists('customer:bulk', 'name');
        console.log(`Email exists: ${emailExists}, Name exists: ${nameExists}`);

        // Get all field names
        console.log('\n🔑 Getting field names...');
        const fieldNames = await client.hKeys('customer:bulk');
        console.log('Field names:', fieldNames);

        // Get all values
        console.log('\n📝 Getting all values...');
        const values = await client.hVals('customer:bulk');
        console.log('Values:', values);

        // Hash length
        const hashLength = await client.hLen('customer:bulk');
        console.log(`\n📏 Hash has ${hashLength} fields`);

        // Delete specific field
        console.log('\n🗑️ Deleting field...');
        await client.hDel('customer:bulk', 'age');
        const remainingFields = await client.hKeys('customer:bulk');
        console.log('Remaining fields:', remainingFields);

        console.log('\n✅ Advanced hash operations completed!');

    } catch (error) {
        console.error('❌ Advanced operations failed:', error);
    } finally {
        await redisClient.disconnect();
    }
}

advancedHashOperations();