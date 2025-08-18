#!/bin/bash

echo "🧹 Clearing Redis database to prevent WRONGTYPE errors..."

# Clear all data
redis-cli FLUSHDB

echo "✅ Redis database cleared successfully!"
echo ""
echo "Database status:"
redis-cli DBSIZE
echo ""
echo "Ready to run tests!"

// ===== TROUBLESHOOTING COMMANDS =====
/*
If you continue to get WRONGTYPE errors, run these commands:

1. Clear all Redis data:
   redis-cli FLUSHDB

2. Check what keys exist:
   redis-cli KEYS "*"

3. Check key types:
   redis-cli TYPE customer:CUST001
   redis-cli TYPE customers:all
   redis-cli TYPE customers:scores

4. If a key has wrong type, delete it:
   redis-cli DEL customer:CUST001
   redis-cli DEL customers:all
   redis-cli DEL customers:scores

5. Then run the test again:
   npm run test-async
*/