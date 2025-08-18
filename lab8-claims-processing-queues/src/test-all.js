import { ClaimsQueue } from './basic-queue.js';
import { PriorityClaimsProcessor, ClaimWorker } from './priority-queue.js';
import { ReliableClaimsQueue } from './reliable-queue.js';

async function runAllTests() {
    console.log('═══════════════════════════════════════════════════════════════');
    console.log('                    RUNNING ALL QUEUE TESTS                    ');
    console.log('═══════════════════════════════════════════════════════════════');
    
    // Test 1: Basic Queue
    console.log('\n📋 TEST 1: Basic Queue Operations\n');
    const basicQueue = new ClaimsQueue();
    await basicQueue.connect();
    
    await basicQueue.enqueueClaim({ claimId: 'TEST-001', type: 'AUTO', amount: 5000 });
    await basicQueue.enqueueClaim({ claimId: 'TEST-002', type: 'HOME', amount: 15000 });
    
    const stats = await basicQueue.getQueueStats();
    console.log('Queue stats:', stats);
    
    const claim = await basicQueue.dequeueClaim();
    console.log('Dequeued claim:', claim?.claimId);
    
    await basicQueue.disconnect();
    console.log('✅ Basic queue test completed\n');
    
    // Test 2: Priority Queue
    console.log('🎯 TEST 2: Priority Queue Processing\n');
    const priorityProcessor = new PriorityClaimsProcessor();
    await priorityProcessor.connect();
    
    await priorityProcessor.routeClaim({ claimId: 'PRI-001', type: 'AUTO', amount: 5000, priority: 'NORMAL' });
    await priorityProcessor.routeClaim({ claimId: 'PRI-002', type: 'LIFE', amount: 100000, priority: 'URGENT' });
    
    const status = await priorityProcessor.getQueueStatus();
    console.log('Priority queue status:', status);
    
    await priorityProcessor.disconnect();
    console.log('✅ Priority queue test completed\n');
    
    // Test 3: Reliable Queue
    console.log('🔒 TEST 3: Reliable Queue with DLQ\n');
    const reliableQueue = new ReliableClaimsQueue();
    await reliableQueue.connect();
    
    await reliableQueue.submitClaim({ claimId: 'REL-001', type: 'HEALTH', amount: 10000 });
    
    const result = await reliableQueue.processNext('TEST-WORKER');
    console.log('Processing result:', result?.success ? 'Success' : 'Failed');
    
    const health = await reliableQueue.getQueueHealth();
    console.log('Queue health:', health);
    
    await reliableQueue.disconnect();
    console.log('✅ Reliable queue test completed\n');
    
    console.log('═══════════════════════════════════════════════════════════════');
    console.log('                    ALL TESTS COMPLETED                        ');
    console.log('═══════════════════════════════════════════════════════════════');
}

runAllTests().catch(console.error).finally(() => process.exit(0));
