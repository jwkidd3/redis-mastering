#!/bin/bash
#
# Lab 3: Sample Data Population Script
# Loads sample insurance data into Redis for testing string operations
#

echo "Loading sample insurance data into Redis..."

# Customer data
redis-cli SET "customer:CUST-001:name" "John Doe"
redis-cli SET "customer:CUST-001:email" "john.doe@email.com"
redis-cli SET "customer:CUST-001:phone" "555-0101"

# Policy data
redis-cli SET "policy:POL-001:number" "POL-001"
redis-cli SET "policy:POL-001:type" "auto"
redis-cli SET "policy:POL-001:premium" "1200"

# Claim counters
redis-cli SET "claims:counter" "0"
redis-cli SET "claims:pending:counter" "0"

echo "Sample data loaded successfully!"
echo "Test with: redis-cli GET customer:CUST-001:name"
