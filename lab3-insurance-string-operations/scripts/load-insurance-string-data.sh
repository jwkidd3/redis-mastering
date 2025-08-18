#!/bin/bash

# Insurance String Operations Sample Data Loader
# Comprehensive data for string manipulation exercises

echo "🏢 Loading Insurance String Operations Sample Data..."

redis-cli << 'REDIS_EOF'
# Clear existing data
FLUSHALL

# === POLICY COUNTER INITIALIZATION ===
SET policy:counter:auto 100000
SET policy:counter:home 200000
SET policy:counter:life 300000

# === SAMPLE POLICIES WITH DETAILED STRING DATA ===
SET policy:AUTO-100001 "Policy Type: Auto | Customer: CUST001 | Vehicle: 2020 Toyota Camry LE | VIN: 1234567890ABCDEFG | Premium: $1,200 | Deductible: $500 | Coverage: Full | Status: Active | Issue Date: 2024-08-18 | Agent: AG001"

SET policy:AUTO-100002 "Policy Type: Auto | Customer: CUST004 | Vehicle: 2019 Honda Civic LX | VIN: ABCDEFG1234567890 | Premium: $950 | Deductible: $250 | Coverage: Full | Status: Active | Issue Date: 2024-08-15 | Agent: AG002"

SET policy:HOME-200001 "Policy Type: Home | Customer: CUST002 | Property: 123 Main St, Dallas TX 75201 | Square Feet: 2,200 | Premium: $800 | Deductible: $1,000 | Coverage: Full Replacement | Status: Active | Issue Date: 2024-08-10 | Agent: AG001"

SET policy:HOME-200002 "Policy Type: Home | Customer: CUST005 | Property: 456 Oak Ave, Dallas TX 75202 | Square Feet: 1,800 | Premium: $650 | Deductible: $500 | Coverage: Actual Cash Value | Status: Active | Issue Date: 2024-08-12 | Agent: AG003"

SET policy:LIFE-300001 "Policy Type: Life | Customer: CUST003 | Coverage: $500,000 Term 20Y | Premium: $420/year | Beneficiaries: 2 | Medical Exam: Required | Status: Active | Issue Date: 2024-08-05 | Agent: AG002"

SET policy:LIFE-300002 "Policy Type: Life | Customer: CUST006 | Coverage: $250,000 Term 10Y | Premium: $180/year | Beneficiaries: 1 | Medical Exam: Not Required | Status: Pending | Issue Date: 2024-08-16 | Agent: AG001"

# === CUSTOMER DETAILED PROFILES ===
SET customer:CUST001 "Name: John Smith | DOB: 1985-03-15 | SSN: ***-**-1234 | Phone: 555-0123 | Email: john.smith@email.com | Address: 456 Oak St, Dallas TX 75201 | Credit Score: 750 | Customer Since: 2018-05-20"

SET customer:CUST002 "Name: Jane Doe | DOB: 1990-07-22 | SSN: ***-**-5678 | Phone: 555-0456 | Email: jane.doe@email.com | Address: 789 Pine Ave, Dallas TX 75202 | Credit Score: 820 | Customer Since: 2020-03-15"

SET customer:CUST003 "Name: Bob Johnson | DOB: 1978-11-08 | SSN: ***-**-9012 | Phone: 555-0789 | Email: bob.johnson@email.com | Address: 321 Elm St, Dallas TX 75203 | Credit Score: 680 | Customer Since: 2019-09-10"

SET customer:CUST004 "Name: Alice Brown | DOB: 1995-09-12 | SSN: ***-**-3456 | Phone: 555-0321 | Email: alice.brown@email.com | Address: 654 Maple Dr, Dallas TX 75204 | Credit Score: 720 | Customer Since: 2021-01-08"

SET customer:CUST005 "Name: Charlie Wilson | DOB: 1982-12-03 | SSN: ***-**-7890 | Phone: 555-0654 | Email: charlie.wilson@email.com | Address: 987 Cedar Ln, Dallas TX 75205 | Credit Score: 790 | Customer Since: 2017-11-22"

SET customer:CUST006 "Name: Diana Rodriguez | DOB: 1988-04-18 | SSN: ***-**-2468 | Phone: 555-0987 | Email: diana.rodriguez@email.com | Address: 147 Birch Way, Dallas TX 75206 | Credit Score: 710 | Customer Since: 2022-06-14"

# === PREMIUM DATA ===
SET premium:AUTO-100001 1200
SET premium:AUTO-100002 950
SET premium:HOME-200001 800
SET premium:HOME-200002 650
SET premium:LIFE-300001 420
SET premium:LIFE-300002 180

# === CUSTOMER BALANCE TRACKING ===
SET customer:CUST001:balance 0
SET customer:CUST002:balance 0
SET customer:CUST003:balance 0
SET customer:CUST004:balance 0
SET customer:CUST005:balance 0
SET customer:CUST006:balance 0

# === POLICY STATUS TRACKING ===
SET policy:AUTO-100001:status "ACTIVE"
SET policy:AUTO-100002:status "ACTIVE"
SET policy:HOME-200001:status "ACTIVE"
SET policy:HOME-200002:status "ACTIVE"
SET policy:LIFE-300001:status "ACTIVE"
SET policy:LIFE-300002:status "PENDING_MEDICAL_REVIEW"

# === DOCUMENT FRAGMENTS ===
SET doc:AUTO-100001:coverage "Bodily Injury Liability: $100,000/$300,000 | Property Damage Liability: $50,000 | Comprehensive: $500 deductible | Collision: $500 deductible | Uninsured Motorist: $100,000/$300,000"

SET doc:AUTO-100001:exclusions "Racing or speed contests | Using vehicle for commercial purposes | Intentional damage | War or military action | Nuclear hazard | Vehicle modifications not reported"

SET doc:HOME-200001:coverage "Dwelling: $300,000 | Personal Property: $225,000 | Liability: $300,000 | Medical Payments: $5,000 | Loss of Use: $60,000 | Deductible: $1,000"

SET doc:LIFE-300001:coverage "Death Benefit: $500,000 | Term: 20 years | Level Premium | Convertible to permanent insurance | Accelerated Death Benefit Rider included"

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

echo "✅ Insurance string operations sample data loaded successfully!"
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
echo ""
echo "📋 Key Exercise Areas:"
echo "   • Policy number generation and management"
echo "   • Premium calculations with atomic operations"
echo "   • Customer profile manipulation and updates"
echo "   • Document assembly through string concatenation"
echo "   • Batch operations for customer data"
echo "   • Financial transaction processing"
