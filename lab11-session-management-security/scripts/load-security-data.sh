#!/bin/bash

echo "Loading security sample data..."

# Clear existing data
redis-cli FLUSHDB > /dev/null

# Create sample users
redis-cli HSET user:alice data '{"username":"alice","passwordHash":"$2b$10$sample","roles":["admin"],"status":"active"}' > /dev/null
redis-cli HSET user:bob data '{"username":"bob","passwordHash":"$2b$10$sample","roles":["user"],"status":"active"}' > /dev/null
redis-cli HSET user:charlie data '{"username":"charlie","passwordHash":"$2b$10$sample","roles":["guest"],"status":"active"}' > /dev/null

# Create sample permissions
redis-cli SADD permissions:alice read write delete manage_users view_analytics > /dev/null
redis-cli SADD permissions:bob read write > /dev/null
redis-cli SADD permissions:charlie read > /dev/null

# Create sample security events
for i in {1..5}; do
    redis-cli LPUSH auth:events "auth:log:$(date +%s)$i" > /dev/null
done

echo "✓ Security sample data loaded"
echo ""
echo "Sample Users:"
echo "  - alice (admin)"
echo "  - bob (user)"
echo "  - charlie (guest)"
echo ""
