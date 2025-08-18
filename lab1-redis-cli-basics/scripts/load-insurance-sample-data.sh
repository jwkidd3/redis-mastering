#!/bin/bash

# Insurance Sample Data Loader
# Loads comprehensive insurance data for Redis CLI practice

echo "🏢 Loading Insurance Sample Data into Redis..."

redis-cli << 'REDIS_EOF'
# Clear existing data
FLUSHALL

# === INSURANCE POLICIES ===
SET policy:INS001 "Auto Insurance - Toyota Camry 2020 - Customer: CUST001 - Premium: $1,200/year"
SET policy:INS002 "Home Insurance - 123 Main St - Customer: CUST002 - Premium: $800/year"  
SET policy:INS003 "Life Insurance - Term 20Y 500K - Customer: CUST003 - Premium: $420/year"
SET policy:INS004 "Auto Insurance - Honda Civic 2019 - Customer: CUST001 - Premium: $950/year"
SET policy:INS005 "Renters Insurance - Downtown Apt - Customer: CUST004 - Premium: $200/year"

# === CUSTOMERS ===
SET customer:CUST001 "John Smith - DOB: 1985-03-15 - Phone: 555-0123 - Email: john.smith@email.com"
SET customer:CUST002 "Jane Doe - DOB: 1990-07-22 - Phone: 555-0456 - Email: jane.doe@email.com"
SET customer:CUST003 "Bob Johnson - DOB: 1978-11-08 - Phone: 555-0789 - Email: bob.johnson@email.com"
SET customer:CUST004 "Alice Brown - DOB: 1995-09-12 - Phone: 555-0321 - Email: alice.brown@email.com"

# === CLAIMS ===
SET claim:CLM001 "Auto Accident - Policy: INS001 - Amount: $2,500 - Status: Processing - Date: 2024-08-15"
SET claim:CLM002 "Water Damage - Policy: INS002 - Amount: $8,200 - Status: Approved - Date: 2024-08-10"
SET claim:CLM003 "Theft - Policy: INS005 - Amount: $1,800 - Status: Under Review - Date: 2024-08-12"
SET claim:CLM004 "Hail Damage - Policy: INS001 - Amount: $3,200 - Status: Denied - Date: 2024-08-08"

# === AGENTS ===
SET agent:AG001 "Michael Davis - Policies Sold: 23 - Commission: $15,200 - Region: North"
SET agent:AG002 "Sarah Wilson - Policies Sold: 31 - Commission: $22,400 - Region: South"
SET agent:AG003 "Tom Miller - Policies Sold: 19 - Commission: $12,800 - Region: East"
SET agent:AG004 "Lisa Chen - Policies Sold: 27 - Commission: $18,900 - Region: West"

# === TEMPORARY QUOTES (with TTL) ===
SETEX quote:AUTO:Q001 300 "Honda Pilot 2023 - Estimated Premium: $1,350/year - Valid: 5 minutes"
SETEX quote:HOME:Q001 600 "Suburban Home - Estimated Premium: $1,200/year - Valid: 10 minutes"
SETEX quote:LIFE:Q001 1800 "Term Life 750K - Estimated Premium: $65/month - Valid: 30 minutes"

# === COUNTERS ===
SET daily:policies_created 8
SET daily:claims_submitted 12
SET daily:quotes_generated 45
SET daily:customer_logins 127

# === CUSTOMER METRICS ===
SET customer:CUST001:login_count 15
SET customer:CUST002:login_count 8
SET customer:CUST003:login_count 22
SET customer:CUST004:login_count 3

# === POLICY METRICS ===
SET policy:INS001:claims_count 2
SET policy:INS002:claims_count 1
SET policy:INS003:claims_count 0
SET policy:INS004:claims_count 0
SET policy:INS005:claims_count 1

# === PREMIUM TRACKING ===
SET premium:collected:2024-08-18 25600
SET premium:collected:2024-08-17 31200
SET premium:collected:2024-08-16 28900

REDIS_EOF

echo "✅ Insurance sample data loaded successfully!"
echo ""
echo "📊 Data Summary:"
redis-cli << 'REDIS_EOF'
ECHO "Policies:"
KEYS policy:*
ECHO ""
ECHO "Customers:" 
KEYS customer:*
ECHO ""
ECHO "Claims:"
KEYS claim:*
ECHO ""
ECHO "Agents:"
KEYS agent:*
ECHO ""
ECHO "Active Quotes:"
KEYS quote:*
ECHO ""
ECHO "Database Size:"
DBSIZE
REDIS_EOF

echo ""
echo "🎯 Ready for Lab 1 exercises!"
