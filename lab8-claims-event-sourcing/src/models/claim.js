const { v4: uuidv4 } = require('uuid');

class Claim {
    constructor(data) {
        this.id = data.id || `CLM-${uuidv4().slice(0, 8).toUpperCase()}`;
        this.policyId = data.policyId;
        this.customerId = data.customerId;
        this.amount = parseFloat(data.amount);
        this.description = data.description;
        this.type = data.type; // 'auto', 'home', 'life'
        this.status = 'submitted';
        this.priority = data.priority || 'normal'; // 'low', 'normal', 'high', 'urgent'
        this.submittedAt = new Date().toISOString();
        this.assignedTo = null;
        this.documents = [];
        this.estimatedDays = this.calculateEstimatedDays();
    }

    calculateEstimatedDays() {
        const baseDays = {
            'auto': 7,
            'home': 14,
            'life': 30
        };
        
        const priorityMultiplier = {
            'urgent': 0.5,
            'high': 0.7,
            'normal': 1.0,
            'low': 1.5
        };
        
        return Math.ceil(baseDays[this.type] * priorityMultiplier[this.priority]);
    }

    static validate(data) {
        const errors = [];
        
        if (!data.policyId) errors.push('Policy ID is required');
        if (!data.customerId) errors.push('Customer ID is required');
        if (!data.amount || data.amount <= 0) errors.push('Valid claim amount is required');
        if (!data.description) errors.push('Claim description is required');
        if (!['auto', 'home', 'life'].includes(data.type)) {
            errors.push('Claim type must be auto, home, or life');
        }
        
        return {
            isValid: errors.length === 0,
            errors
        };
    }

    createEvent(eventType, additionalData = {}) {
        return {
            eventId: uuidv4(),
            eventType,
            claimId: this.id,
            timestamp: new Date().toISOString(),
            data: {
                ...this.toJSON(),
                ...additionalData
            },
            version: '1.0'
        };
    }

    toJSON() {
        return {
            id: this.id,
            policyId: this.policyId,
            customerId: this.customerId,
            amount: this.amount,
            description: this.description,
            type: this.type,
            status: this.status,
            priority: this.priority,
            submittedAt: this.submittedAt,
            assignedTo: this.assignedTo,
            documents: this.documents,
            estimatedDays: this.estimatedDays
        };
    }
}

module.exports = Claim;
