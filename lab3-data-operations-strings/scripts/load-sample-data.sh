#!/bin/bash

# Data Loading Script for Lab 3
# Loads comprehensive sample data optimized for string operations
# Includes policies, customers, premiums, documents, and financial data

echo "🏢 Loading Sample Data for String Operations..."
echo "🎯 Focus: Policy management, premium calculations, and customer data"
echo ""

# Check Redis connection
redis-cli ping > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "❌ Redis connection failed. Please ensure Redis is running:"
    echo "   docker run -d --name redis-lab3 -p 6379:6379 redis:7-alpine"
    exit 1
fi

echo "✅ Redis connection established"
echo "🔄 Loading comprehensive sample data..."

# Load all sample data using Redis CLI
redis-cli << 'REDIS_EOF'
# === POLICY COUNTERS ===
SET policy:counter:auto 100000
SET policy:counter:home 200000  
SET policy:counter:life 300000

# === COMPREHENSIVE POLICIES ===
SET policy:AUTO-100001 "customer_id:CUST001|premium:1200|status:active|created:2024-08-18T10:30:00Z|vehicle:2022 Honda Accord|vin:1HGBH41JXMN109186"
SET policy:AUTO-100002 "customer_id:CUST002|premium:1350|status:active|created:2024-08-17T14:15:00Z|vehicle:2021 Toyota Camry|vin:4T1BE46K57U123456"

SET policy:HOME-200001 "customer_id:CUST002|premium:800|status:active|created:2024-08-16T09:45:00Z|property_value:350000|address:123 Oak Street, Houston, TX"
SET policy:HOME-200002 "customer_id:CUST004|premium:950|status:active|created:2024-08-15T16:20:00Z|property_value:420000|address:456 Pine Avenue, Dallas, TX"

SET policy:LIFE-300001 "customer_id:CUST003|premium:500|status:active|created:2024-08-14T11:30:00Z|coverage:500000|term:20_years|beneficiary:spouse"
SET policy:LIFE-300002 "customer_id:CUST005|premium:650|status:active|created:2024-08-13T13:45:00Z|coverage:750000|term:30_years|beneficiary:children"

# === POLICY RELATIONSHIPS ===
SET policy:AUTO-100001:customer "CUST001"
SET policy:AUTO-100002:customer "CUST002"
SET policy:HOME-200001:customer "CUST002"
SET policy:HOME-200002:customer "CUST004"
SET policy:LIFE-300001:customer "CUST003"
SET policy:LIFE-300002:customer "CUST005"

# === CUSTOMER PROFILES ===
SET customer:CUST001 "John Smith | Age: 35 | Location: Dallas, TX | Phone: (214) 555-0101 | Email: john.smith@email.com"
SET customer:CUST002 "Sarah Johnson | Age: 42 | Location: Houston, TX | Phone: (713) 555-0102 | Email: sarah.johnson@email.com"
SET customer:CUST003 "Michael Brown | Age: 28 | Location: Austin, TX | Phone: (512) 555-0103 | Email: michael.brown@email.com"
SET customer:CUST004 "Emily Davis | Age: 39 | Location: Dallas, TX | Phone: (214) 555-0104 | Email: emily.davis@email.com"
SET customer:CUST005 "Robert Wilson | Age: 45 | Location: Fort Worth, TX | Phone: (817) 555-0105 | Email: robert.wilson@email.com"
SET customer:CUST006 "Lisa Anderson | Age: 33 | Location: San Antonio, TX | Phone: (210) 555-0106 | Email: lisa.anderson@email.com"

# === PREMIUM AMOUNTS ===
SET premium:AUTO-100001 1200
SET premium:AUTO-100002 1350
SET premium:HOME-200001 800
SET premium:HOME-200002 950
SET premium:LIFE-300001 500
SET premium:LIFE-300002 650

# === POLICY DOCUMENT FRAGMENTS ===
SET doc:AUTO-100001:header "AUTO POLICY\nPolicy Number: AUTO-100001\nEffective Date: 2024-08-18\nPolicyholder: John Smith\nVehicle: 2022 Honda Accord\n"

SET doc:AUTO-100001:coverage "COVERAGE DETAILS:\nLiability: $100,000/$300,000 | Collision: $500 deductible | Uninsured Motorist: $100,000/$300,000"

SET doc:AUTO-100001:exclusions "Racing or speed contests | Using vehicle for commercial purposes | Intentional damage | War or military action | Nuclear hazard | Vehicle modifications not reported"

SET doc:HOME-200001:coverage "Dwelling: $300,000 | Personal Property: $225,000 | Liability: $300,000 | Medical Payments: $5,000 | Loss of Use: $60,000 | Deductible: $1,000"

SET doc:LIFE-300001:coverage "Death Benefit: $500,000 | Term: 20 years | Level Premium | Convertible to permanent coverage | Accelerated Death Benefit Rider included"

# === ACTIVITY LOGS ===
SET activity:CUST001:log "2024-08-18T09:15:00Z - Policy inquiry via phone | 2024-08-18T09:30:00Z - Premium payment processed | 2024-08-18T10:45:00Z - Policy documents emailed"

SET activity:CUST002:log "2024-08-17T14:20:00Z - Online quote request | 2024-08-17T15:45:00Z - Policy purchased online | 2024-08-18T08:30:00Z - Welcome packet mailed"

SET activity:CUST003:log "2024-08-16T11:30:00Z - Beneficiary update request | 2024-08-16T11:45:00Z - Forms completed | 2024-08-17T16:20:00Z - Changes processed"

# === COMMUNICATION PREFERENCES ===
SET communication:CUST001 "Preferred: Email | Frequency: Quarterly | Last Contact: 2024-08-18 | Method: Email | Marketing Opt-in: Yes"

SET communication:CUST002 "Preferred: Phone | Frequency: Annual | Last Contact: 2024-08-17 | Method: Phone | Marketing Opt-in: No"

SET communication:CUST003 "Preferred: Mail | Frequency: Semi-Annual | Last Contact: 2024-08-16 | Method: Mail | Marketing Opt-in: Yes"

# === REVENUE TRACKING ===
SET revenue:daily:2024-08-18 0
SET revenue:monthly:2024-08 0
SET revenue:auto:2024-08-18 0
SET revenue:home:2024-08-18 0
SET revenue:life:2024-08-18 0

# === RISK SCORES ===
SET risk:score:CUST001 750
SET risk:score:CUST002 820
SET risk:score:CUST003 680
SET risk:score:CUST004 720
SET risk:score:CUST005 790
SET risk:score:CUST006 710

# === LOCATION CODES ===
SET location:code:dallas "DAL"
SET location:code:houston "HOU"
SET location:code:austin "AUS"
SET location:code:fort_worth "FTW"
SET location:code:san_antonio "SAT"

REDIS_EOF

echo "✅ Sample data loaded successfully!"
echo ""
echo "📊 Data Summary:"
redis-cli << 'REDIS_EOF'
ECHO "=== POLICY COUNTERS ==="
MGET policy:counter:auto policy:counter:home policy:counter:life
ECHO ""
ECHO "=== POLICIES ==="
KEYS policy:*-*
ECHO ""
ECHO "=== CUSTOMERS ==="
KEYS customer:CUST*
ECHO ""
ECHO "=== PREMIUMS ==="
KEYS premium:*
ECHO ""
ECHO "=== DOCUMENT FRAGMENTS ==="
KEYS doc:*
ECHO ""
ECHO "=== ACTIVITY LOGS ==="
KEYS activity:*
ECHO ""
ECHO "Database Size:"
DBSIZE
REDIS_EOF

echo ""
echo "🎯 Ready for Lab 3 string operations exercises!"
