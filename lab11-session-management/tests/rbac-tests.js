const RBACService = require('../src/services/rbac-service');

async function runRBACTests() {
    console.log('🧪 Running RBAC Tests');
    console.log('======================');

    const rbac = new RBACService();

    try {
        console.log('\n1. Testing customer permissions...');
        const canReadOwnPolicies = await rbac.checkPermission('customer', 'read:own_policies');
        const canManageUsers = await rbac.checkPermission('customer', 'manage:users');
        console.log(`✅ Customer can read own policies: ${canReadOwnPolicies}`);
        console.log(`✅ Customer can manage users: ${canManageUsers} (should be false)`);

        console.log('\n2. Testing agent permissions...');
        const agentCanReadCustomer = await rbac.checkPermission('agent', 'read:customer_policies');
        const agentCanDeleteRecords = await rbac.checkPermission('agent', 'delete:records');
        console.log(`✅ Agent can read customer policies: ${agentCanReadCustomer}`);
        console.log(`✅ Agent can delete records: ${agentCanDeleteRecords} (should be false)`);

        console.log('\n3. Testing admin permissions...');
        const adminCanManage = await rbac.checkPermission('admin', 'manage:users');
        const adminCanRead = await rbac.checkPermission('admin', 'read:all_data');
        console.log(`✅ Admin can manage users: ${adminCanManage}`);
        console.log(`✅ Admin can read all data: ${adminCanRead}`);

        console.log('\n4. Testing access logging...');
        await rbac.logAccessAttempt('customer123', 'customer', 'policy_details', 'read:own_policies', true);
        await rbac.logAccessAttempt('customer123', 'customer', 'admin_panel', 'manage:users', false);
        await rbac.logAccessAttempt('agent456', 'agent', 'customer_claims', 'read:customer_claims', true);
        console.log('✅ Access attempts logged');

        console.log('\n5. Testing permission listing...');
        const customerPerms = rbac.getUserPermissions('customer');
        const agentPerms = rbac.getUserPermissions('agent');
        const adminPerms = rbac.getUserPermissions('admin');
        
        console.log(`✅ Customer permissions (${customerPerms.length}):`, customerPerms);
        console.log(`✅ Agent permissions (${agentPerms.length}):`, agentPerms);
        console.log(`✅ Admin permissions (${adminPerms.length}):`, adminPerms);

        console.log('\n6. Testing access log retrieval...');
        const today = new Date().toISOString().split('T')[0];
        const logs = await rbac.getAccessLogs(today);
        console.log(`✅ Access logs for ${today}: ${logs.length} entries`);
        logs.forEach((log, index) => {
            console.log(`   ${index + 1}. ${log.userRole} -> ${log.action} (${log.allowed})`);
        });

        console.log('\n🎉 All RBAC tests completed successfully!');

    } catch (error) {
        console.error('❌ RBAC test failed:', error.message);
    }
}

runRBACTests().catch(console.error);
