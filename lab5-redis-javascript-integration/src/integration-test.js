import DataProcessor from './data-operations.js';
import EventManager from './pubsub.js';
import StreamProcessor from './streams.js';

async function runIntegrationTests() {
    console.log('🧪 Running Integration Tests...\n');
    
    // Test 1: Data Operations
    console.log('Test 1: Data Operations');
    const processor = new DataProcessor();
    await processor.initialize();
    
    await processor.processCustomerData([
        { id: 'TEST001', name: 'Test User', email: 'test@example.com' }
    ]);
    
    const customer = await processor.getCustomerDetails('TEST001');
    console.log('✅ Customer created:', customer);
    await processor.cleanup();
    
    // Test 2: Pub/Sub
    console.log('\nTest 2: Pub/Sub Pattern');
    const eventManager = new EventManager();
    await eventManager.initialize();
    
    // Set up subscriber first
    await eventManager.subscribeToEvents('test:events', (data) => {
        console.log('✅ Received event:', data);
    });
    
    // Small delay to ensure subscription is active
    await new Promise(resolve => setTimeout(resolve, 100));
    
    await eventManager.publishEvent('test:events', {
        type: 'TEST_EVENT',
        timestamp: Date.now()
    });
    
    // Wait for message processing
    await new Promise(resolve => setTimeout(resolve, 1000));
    await eventManager.cleanup();
    
    // Test 3: Streams
    console.log('\nTest 3: Stream Processing');
    const streamProcessor = new StreamProcessor();
    await streamProcessor.initialize();
    
    await streamProcessor.addToStream('test:stream', {
        action: 'test_action',
        value: '123'
    });
    
    const messages = await streamProcessor.readStream('test:stream');
    console.log('✅ Stream messages:', messages);
    await streamProcessor.cleanup();
    
    console.log('\n🎉 All integration tests completed successfully!');
}

runIntegrationTests().catch((error) => {
    console.error('❌ Integration test failed:', error);
    process.exit(1);
});
