# Advanced Analytics Examples

## 1. Cohort Analysis

```javascript
// Group customers by signup month
async function cohortAnalysis() {
    const cohorts = {};
    const customers = await client.keys('customer:*:signup_date');
    
    for (const key of customers) {
        const signupDate = await client.get(key);
        const month = new Date(signupDate).toISOString().slice(0, 7);
        const customerId = key.split(':')[1];
        
        await client.sAdd(`cohort:${month}`, customerId);
    }
    
    // Analyze retention
    for (const cohort in cohorts) {
        const members = await client.sMembers(`cohort:${cohort}`);
        const active = await client.sInter(`cohort:${cohort}`, 'customers:active');
        console.log(`${cohort}: ${active.length}/${members.length} retained`);
    }
}
```

## 2. Product Affinity Analysis

```javascript
// Find products frequently bought together
async function productAffinity() {
    const products = await client.keys('product:*');
    const affinities = [];
    
    for (let i = 0; i < products.length; i++) {
        for (let j = i + 1; j < products.length; j++) {
            const product1 = products[i].split(':')[1];
            const product2 = products[j].split(':')[1];
            
            const customers1 = await client.sMembers(`customers:bought:${product1}`);
            const customers2 = await client.sMembers(`customers:bought:${product2}`);
            const both = await client.sInter(
                `customers:bought:${product1}`,
                `customers:bought:${product2}`
            );
            
            const affinity = both.length / Math.min(customers1.length, customers2.length);
            affinities.push({ product1, product2, affinity });
        }
    }
    
    return affinities.sort((a, b) => b.affinity - a.affinity);
}
```

## 3. Real-Time Trending

```javascript
// Track trending topics/products
async function updateTrending(item, score) {
    const now = Date.now();
    const hourBucket = Math.floor(now / 3600000); // Hour buckets
    
    // Add to current hour's trending
    await client.zIncrBy(`trending:${hourBucket}`, score, item);
    
    // Expire old buckets
    await client.expire(`trending:${hourBucket}`, 7200); // 2 hours
    
    // Calculate overall trending
    const currentBucket = `trending:${hourBucket}`;
    const prevBucket = `trending:${hourBucket - 1}`;
    
    // Weighted merge of current and previous hour
    await client.zUnionStore('trending:overall', 2,
        currentBucket, prevBucket,
        { weights: [2, 1] }
    );
    
    // Get top trending
    return await client.zRevRange('trending:overall', 0, 9, { withScores: true });
}
```

## 4. Geographic Analytics

```javascript
// Analyze customers by region
async function geographicAnalysis() {
    const regions = ['north', 'south', 'east', 'west'];
    const analysis = {};
    
    for (const region of regions) {
        const customers = await client.sMembers(`customers:region:${region}`);
        const highValue = await client.sInter(
            `customers:region:${region}`,
            'customers:high_value'
        );
        
        // Calculate metrics
        const totalRevenue = 0;
        for (const customerId of customers) {
            const revenue = await client.get(`customer:${customerId}:total_revenue`);
            totalRevenue += parseFloat(revenue || 0);
        }
        
        analysis[region] = {
            totalCustomers: customers.length,
            highValueCustomers: highValue.length,
            totalRevenue,
            avgRevenue: totalRevenue / customers.length
        };
    }
    
    return analysis;
}
```

## 5. Predictive Scoring

```javascript
// Calculate predictive scores
async function calculatePredictiveScore(customerId) {
    const weights = {
        recency: 0.3,
        frequency: 0.3,
        monetary: 0.4
    };
    
    // Recency score (days since last purchase)
    const lastPurchase = await client.get(`customer:${customerId}:last_purchase`);
    const daysSince = (Date.now() - new Date(lastPurchase)) / 86400000;
    const recencyScore = Math.max(0, 100 - daysSince);
    
    // Frequency score (purchases per month)
    const purchaseCount = await client.get(`customer:${customerId}:purchase_count`);
    const accountAge = await client.get(`customer:${customerId}:account_age_days`);
    const frequencyScore = (purchaseCount / (accountAge / 30)) * 10;
    
    // Monetary score (total spend)
    const totalSpend = await client.get(`customer:${customerId}:total_spend`);
    const monetaryScore = Math.min(100, totalSpend / 100);
    
    // Calculate weighted score
    const predictiveScore = 
        (recencyScore * weights.recency) +
        (frequencyScore * weights.frequency) +
        (monetaryScore * weights.monetary);
    
    // Store in sorted set
    await client.zAdd('customers:predictive_scores', {
        score: predictiveScore,
        value: customerId
    });
    
    return predictiveScore;
}
```
