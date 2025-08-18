// src/test-connection.js
import connectRedis from './connection.js';

(async () => {
    try {
        const client = await connectRedis();
        
        // Test basic operations
        await client.set('test:key', 'Hello Redis from JavaScript!');
        const value = await client.get('test:key');
        console.log('✅ Retrieved value:', value);
        
        // Test JSON operations
        await client.json.set('test:json', '$', {
            name: 'Lab 5',
            type: 'JavaScript Integration',
            timestamp: new Date().toISOString()
        });
        
        const jsonData = await client.json.get('test:json');
        console.log('✅ JSON data:', jsonData);
        
        await client.disconnect();
        console.log('✅ Connection test completed successfully!');
    } catch (error) {
        console.error('❌ Connection test failed:', error);
        process.exit(1);
    }
})();
