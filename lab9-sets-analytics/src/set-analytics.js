const client = require('./connection');

class SetAnalytics {
    async findCustomersInBothSegments(segment1, segment2) {
        const intersection = await client.sinter(`customers:${segment1}`, `customers:${segment2}`);
        console.log(`Customers in both ${segment1} and ${segment2}:`, intersection);
        return intersection;
    }

    async findCustomersInEitherSegment(segment1, segment2) {
        const union = await client.sunion(`customers:${segment1}`, `customers:${segment2}`);
        console.log(`Customers in ${segment1} or ${segment2}:`, union);
        return union;
    }

    async findCustomersInFirstNotSecond(segment1, segment2) {
        const difference = await client.sdiff(`customers:${segment1}`, `customers:${segment2}`);
        console.log(`Customers in ${segment1} but not ${segment2}:`, difference);
        return difference;
    }

    async storeIntersection(segment1, segment2, resultKey) {
        const count = await client.sinterstore(resultKey, `customers:${segment1}`, `customers:${segment2}`);
        console.log(`Stored intersection of ${segment1} and ${segment2} in ${resultKey}: ${count} customers`);
        return count;
    }

    async findHighValueLowRiskCustomers() {
        const resultKey = 'analytics:high_value_low_risk';
        const count = await client.sinterstore(
            resultKey,
            'customers:premium',
            'customers:lowrisk',
            'customers:active'
        );
        
        const customers = await client.smembers(resultKey);
        console.log('High-value low-risk active customers:', customers);
        
        // Set expiration for analytics result
        await client.expire(resultKey, 3600); // 1 hour
        
        return customers;
    }
}

module.exports = SetAnalytics;
