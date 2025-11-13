const { getRedisClient } = require('../../config/redis-config');

class RBACService {
    constructor() {
        this.rolePermissions = {
            'customer': [
                'read:own_policies',
                'read:own_claims',
                'create:claims',
                'update:own_profile'
            ],
            'agent': [
                'read:customer_policies',
                'read:customer_claims',
                'create:policies',
                'update:customer_profiles',
                'process:claims'
            ],
            'admin': [
                'read:all_data',
                'write:all_data',
                'delete:records',
                'manage:users',
                'view:reports'
            ]
        };
    }

    async checkPermission(userRole, requiredPermission) {
        const permissions = this.rolePermissions[userRole] || [];
        return permissions.includes(requiredPermission);
    }

    async logAccessAttempt(userId, userRole, resource, action, allowed) {
        const client = await getRedisClient();
        const logKey = `access_log:${new Date().toISOString().split('T')[0]}`;
        
        const logEntry = {
            timestamp: new Date().toISOString(),
            userId,
            userRole,
            resource,
            action,
            allowed: allowed ? 'granted' : 'denied'
        };

        await client.lPush(logKey, JSON.stringify(logEntry));
        await client.expire(logKey, 86400); // 24 hours

        console.log(`📝 Access ${allowed ? 'granted' : 'denied'}: ${userRole} -> ${action} on ${resource}`);
    }

    getUserPermissions(userRole) {
        return this.rolePermissions[userRole] || [];
    }

    async getAccessLogs(date) {
        const client = await getRedisClient();
        const logKey = `access_log:${date}`;

        const logs = await client.lRange(logKey, 0, -1);
        return logs.map(log => JSON.parse(log));
    }

    async disconnect() {
        const client = await getRedisClient();
        await client.quit();
        console.log('🔌 Redis connection closed');
    }
}

module.exports = RBACService;
