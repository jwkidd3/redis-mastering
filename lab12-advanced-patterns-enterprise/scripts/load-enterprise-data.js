const { createClient } = require('redis');

async function loadData() {
    const client = createClient({
        socket: {
            host: 'localhost',
            port: 6379
        }
    });
    
    await client.connect();
    console.log('Loading enterprise sample data...\n');
    
    // Clear existing data
    await client.flushDb();
    
    // Load customer data
    const customers = [
        { id: 'C001', name: 'Acme Corp', tier: 'enterprise', revenue: 5000000 },
        { id: 'C002', name: 'TechStart Inc', tier: 'startup', revenue: 100000 },
        { id: 'C003', name: 'Global Systems', tier: 'enterprise', revenue: 10000000 },
        { id: 'C004', name: 'Local Business', tier: 'small', revenue: 50000 },
        { id: 'C005', name: 'MegaCorp', tier: 'enterprise', revenue: 50000000 }
    ];
    
    for (const customer of customers) {
        await client.hSet(`customer:${customer.id}`, {
            name: customer.name,
            tier: customer.tier,
            revenue: customer.revenue.toString(),
            created: Date.now().toString()
        });
    }
    
    console.log(`✅ Loaded ${customers.length} customers`);
    
    // Load product inventory
    const products = [
        { id: 'P001', name: 'Enterprise License', stock: 100, price: 10000 },
        { id: 'P002', name: 'Pro License', stock: 500, price: 1000 },
        { id: 'P003', name: 'Basic License', stock: 1000, price: 100 },
        { id: 'P004', name: 'Support Package', stock: 50, price: 5000 },
        { id: 'P005', name: 'Training Package', stock: 25, price: 2500 }
    ];
    
    for (const product of products) {
        await client.hSet(`product:${product.id}`, {
            name: product.name,
            stock: product.stock.toString(),
            price: product.price.toString()
        });
        
        // Set inventory levels
        await client.set(`inventory:${product.id}`, product.stock.toString());
    }
    
    console.log(`✅ Loaded ${products.length} products`);
    
    // Create sample transactions
    const transactions = [];
    for (let i = 1; i <= 20; i++) {
        const customerId = customers[Math.floor(Math.random() * customers.length)].id;
        const productId = products[Math.floor(Math.random() * products.length)].id;
        const quantity = Math.floor(Math.random() * 5) + 1;
        
        transactions.push({
            id: `T${String(i).padStart(4, '0')}`,
            customerId,
            productId,
            quantity,
            timestamp: Date.now() - Math.floor(Math.random() * 86400000)
        });
    }
    
    // Store transactions in sorted set by timestamp
    for (const tx of transactions) {
        await client.zAdd('transactions:all', {
            score: tx.timestamp,
            value: JSON.stringify(tx)
        });
    }
    
    console.log(`✅ Loaded ${transactions.length} transactions`);
    
    // Create sample metrics
    const metrics = [
        { name: 'api.requests', value: 15234 },
        { name: 'api.errors', value: 23 },
        { name: 'db.queries', value: 45678 },
        { name: 'cache.hits', value: 89012 },
        { name: 'cache.misses', value: 1234 }
    ];
    
    for (const metric of metrics) {
        await client.set(`metric:${metric.name}`, metric.value.toString());
    }
    
    console.log(`✅ Loaded ${metrics.length} metrics`);
    
    // Create sample user sessions
    const sessions = [];
    for (let i = 1; i <= 10; i++) {
        const sessionId = `sess_${Date.now()}_${i}`;
        sessions.push({
            id: sessionId,
            userId: `U${String(i).padStart(3, '0')}`,
            createdAt: Date.now(),
            lastAccess: Date.now()
        });
    }
    
    for (const session of sessions) {
        await client.setEx(
            `session:${session.id}`,
            3600,
            JSON.stringify(session)
        );
    }
    
    console.log(`✅ Loaded ${sessions.length} sessions\n`);
    
    // Display summary
    const dbSize = await client.dbSize();
    console.log('📊 Database Summary:');
    console.log(`   Total keys: ${dbSize}`);
    console.log(`   Customers: ${customers.length}`);
    console.log(`   Products: ${products.length}`);
    console.log(`   Transactions: ${transactions.length}`);
    console.log(`   Metrics: ${metrics.length}`);
    console.log(`   Sessions: ${sessions.length}\n`);
    
    await client.quit();
    console.log('✨ Enterprise data loaded successfully!');
}

loadData().catch(console.error);
