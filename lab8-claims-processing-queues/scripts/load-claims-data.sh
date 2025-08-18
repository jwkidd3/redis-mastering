#!/bin/bash

echo "Loading sample claims data..."

# Clear existing queues
redis-cli DEL claims:queue:pending claims:queue:urgent claims:queue:high claims:queue:normal claims:queue:low
redis-cli DEL claims:processing claims:completed claims:queue:reliable:pending claims:queue:reliable:processing claims:queue:reliable:dlq

# Create sample claims
redis-cli LPUSH claims:queue:pending '{
  "claimId": "CLM-2024-001",
  "type": "AUTO",
  "amount": 5000,
  "customerName": "John Smith",
  "incidentDate": "2024-01-15",
  "priority": "NORMAL"
}'

redis-cli LPUSH claims:queue:pending '{
  "claimId": "CLM-2024-002",
  "type": "HOME",
  "amount": 25000,
  "customerName": "Sarah Johnson",
  "incidentDate": "2024-01-14",
  "priority": "HIGH"
}'

redis-cli LPUSH claims:queue:pending '{
  "claimId": "CLM-2024-003",
  "type": "LIFE",
  "amount": 100000,
  "customerName": "Robert Davis",
  "incidentDate": "2024-01-13",
  "priority": "URGENT"
}'

redis-cli LPUSH claims:queue:pending '{
  "claimId": "CLM-2024-004",
  "type": "HEALTH",
  "amount": 8500,
  "customerName": "Maria Garcia",
  "incidentDate": "2024-01-16",
  "priority": "HIGH"
}'

redis-cli LPUSH claims:queue:pending '{
  "claimId": "CLM-2024-005",
  "type": "AUTO",
  "amount": 2500,
  "customerName": "James Wilson",
  "incidentDate": "2024-01-17",
  "priority": "LOW"
}'

echo "Sample claims loaded successfully!"
echo "Queue status:"
redis-cli LLEN claims:queue:pending
