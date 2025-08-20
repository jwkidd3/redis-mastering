const SessionManager = require('../src/models/session');
const RBACService = require('../src/services/rbac-service');

async function basicSessionDemo() {
    console.log('🚀 Basic Session Management Demo');
    console.log('================================');

    const sessionManager = new SessionManager();
    const rbac = new RBACService();

    // Simulate customer login
    console.log('\n👤 Customer Portal Login Simulation');
    const customerSession = await sessionManager.createSession(
        'CUST001',
        'customer',
        {
            ipAddress: '203.0.113.45',
            userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
            customerType: 'premium',
            policyNumber: 'POL-2024-001234'
        }
    );

    // Test customer accessing their data
    console.log('\n🔍 Customer Accessing Policy Information');
    const session = await sessionManager.getSession(customerSession);
    const canAccess = await rbac.checkPermission(session.userRole, 'read:own_policies');
    
    if (canAccess) {
        console.log('✅ Access granted to policy information');
        await rbac.logAccessAttempt(session.userId, session.userRole, 'policy_details', 'read:own_policies', true);
    }

    // Test customer trying to access admin functions
    console.log('\n🚫 Customer Attempting Admin Access');
    const canAccessAdmin = await rbac.checkPermission(session.userRole, 'manage:users');
    console.log(`❌ Admin access: ${canAccessAdmin ? 'GRANTED (ERROR!)' : 'DENIED (correct)'}`);
    await rbac.logAccessAttempt(session.userId, session.userRole, 'admin_panel', 'manage:users', canAccessAdmin);

    // Simulate agent login
    console.log('\n👨‍💼 Agent Portal Login');
    const agentSession = await sessionManager.createSession(
        'AGT001',
        'agent',
        {
            ipAddress: '198.51.100.22',
            userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X)',
            agentCode: 'A-2024-567',
            territory: 'Northwest'
        }
    );

    // Test agent accessing customer data
    console.log('\n🔍 Agent Accessing Customer Claims');
    const agentSessionData = await sessionManager.getSession(agentSession);
    const agentCanAccess = await rbac.checkPermission(agentSessionData.userRole, 'read:customer_claims');
    
    if (agentCanAccess) {
        console.log('✅ Agent can access customer claims');
        await rbac.logAccessAttempt(agentSessionData.userId, agentSessionData.userRole, 'customer_claims', 'read:customer_claims', true);
    }

    console.log('\n📊 Session Summary');
    const customerSessions = await sessionManager.getUserActiveSessions('CUST001');
    const agentSessions = await sessionManager.getUserActiveSessions('AGT001');
    
    console.log(`Customer active sessions: ${customerSessions.length}`);
    console.log(`Agent active sessions: ${agentSessions.length}`);

    console.log('\n🎯 Demo completed successfully!');
}

basicSessionDemo().catch(console.error);
