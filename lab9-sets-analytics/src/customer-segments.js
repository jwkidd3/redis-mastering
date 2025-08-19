const client = require('./connection');

class CustomerSegments {
    constructor() {
        this.segments = {
            premium: 'customers:premium',
            standard: 'customers:standard',
            new: 'customers:new',
            highrisk: 'customers:high_risk',
            lowrisk: 'customers:low_risk',
            active: 'customers:active',
            inactive: 'customers:inactive'
        };
    }

    async addToSegment(customerId, segmentName) {
        if (!this.segments[segmentName]) {
            throw new Error(`Invalid segment: ${segmentName}`);
        }
        
        const result = await client.sadd(this.segments[segmentName], customerId);
        console.log(`Customer ${customerId} added to ${segmentName}: ${result ? 'new' : 'existing'}`);
        return result;
    }

    async removeFromSegment(customerId, segmentName) {
        if (!this.segments[segmentName]) {
            throw new Error(`Invalid segment: ${segmentName}`);
        }
        
        const result = await client.srem(this.segments[segmentName], customerId);
        console.log(`Customer ${customerId} removed from ${segmentName}: ${result ? 'success' : 'not found'}`);
        return result;
    }

    async isInSegment(customerId, segmentName) {
        if (!this.segments[segmentName]) {
            throw new Error(`Invalid segment: ${segmentName}`);
        }
        
        const result = await client.sismember(this.segments[segmentName], customerId);
        return result === 1;
    }

    async getSegmentMembers(segmentName) {
        if (!this.segments[segmentName]) {
            throw new Error(`Invalid segment: ${segmentName}`);
        }
        
        const members = await client.smembers(this.segments[segmentName]);
        console.log(`${segmentName} segment has ${members.length} customers:`, members);
        return members;
    }

    async getSegmentSize(segmentName) {
        if (!this.segments[segmentName]) {
            throw new Error(`Invalid segment: ${segmentName}`);
        }
        
        const size = await client.scard(this.segments[segmentName]);
        console.log(`${segmentName} segment size: ${size}`);
        return size;
    }

    async getCustomerSegments(customerId) {
        const customerSegments = [];
        
        for (const [segmentName, segmentKey] of Object.entries(this.segments)) {
            const isMember = await client.sismember(segmentKey, customerId);
            if (isMember) {
                customerSegments.push(segmentName);
            }
        }
        
        console.log(`Customer ${customerId} segments:`, customerSegments);
        return customerSegments;
    }
}

module.exports = CustomerSegments;
