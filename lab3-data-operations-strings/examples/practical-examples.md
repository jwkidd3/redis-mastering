# Practical String Operations Examples

This document provides real-world examples of Redis string operations specifically designed for business applications.

## Policy Management Examples

### 1. Auto Policy Creation Workflow

```bash
# Step 1: Generate unique policy number
INCR policy:counter:auto
# Returns: 100001

# Step 2: Create formatted policy number and store policy data
SET policy:AUTO-100001 "customer_id:CUST001|vehicle_vin:1HGBH41JXMN109186|premium:1200|status:pending|created:2024-08-18T10:30:00Z"

# Step 3: Store policy relationships
SET policy:AUTO-100001:customer "CUST001"
SET policy:AUTO-100001:agent "AGT001"
SET policy:AUTO-100001:status "pending"

# Step 4: Initialize premium
SET premium:AUTO-100001 1200

# Step 5: Verify policy creation
EXISTS policy:AUTO-100001
GET policy:AUTO-100001
```

### 2. Home Property Risk Assessment

```bash
# Store property information
SET property:HOME-200001 "address:123 Oak Street, Houston, TX|value:350000|year_built:1995|sq_ft:2400"

# Risk factors assessment
SET risk:HOME-200001:location "flood_zone:X|crime_rate:low|fire_dept_distance:2.3"
SET risk:HOME-200001:property "roof_age:5|foundation:slab|security_system:yes"

# Calculate base premium
SET premium:HOME-200001 800

# Apply risk adjustments
INCRBY premium:HOME-200001 75    # Flood zone adjustment
DECRBY premium:HOME-200001 50    # Security system discount
INCRBY premium:HOME-200001 25    # Age of roof factor

# Final premium
GET premium:HOME-200001          # Returns: 850
```

## Financial Operations Examples

### 3. Premium Payment Processing

```bash
# Initialize customer payment tracking
SET payment:CUST001:balance 0
SET payment:CUST001:last_payment "never"

# Process premium payment
INCRBY payment:CUST001:balance 1200
SET payment:CUST001:last_payment "2024-08-18T14:30:00Z"

# Apply late fee if applicable
INCRBY payment:CUST001:balance 25

# Process partial payment
DECRBY payment:CUST001:balance 500

# Check remaining balance
GET payment:CUST001:balance  # Returns: 725

# Payment history log
APPEND payment:CUST001:history "2024-08-18T14:30:00Z - Payment: $1200|"
APPEND payment:CUST001:history "2024-08-18T14:35:00Z - Late fee: $25|"
APPEND payment:CUST001:history "2024-08-18T16:45:00Z - Partial payment: $500|"

GET payment:CUST001:history
```

### 4. Daily Revenue Tracking

```bash
# Initialize daily counters
SET revenue:daily:2024-08-18 0
SET revenue:auto:2024-08-18 0
SET revenue:home:2024-08-18 0
SET revenue:life:2024-08-18 0

# Process policy payments throughout the day
INCRBY revenue:daily:2024-08-18 1200    # Auto payment
INCRBY revenue:auto:2024-08-18 1200

INCRBY revenue:daily:2024-08-18 850     # Home payment
INCRBY revenue:home:2024-08-18 850

INCRBY revenue:daily:2024-08-18 500     # Life payment
INCRBY revenue:life:2024-08-18 500

# Generate end-of-day report
ECHO "=== Daily Revenue Report for 2024-08-18 ==="
GET revenue:daily:2024-08-18
ECHO "Auto Revenue:"
GET revenue:auto:2024-08-18
ECHO "Home Revenue:"
GET revenue:home:2024-08-18
ECHO "Life Revenue:"
GET revenue:life:2024-08-18

# Calculate monthly totals
INCRBY revenue:monthly:2024-08 2550
```

## Document Generation Examples

### 5. Policy Document Assembly

```bash
# Create document sections
SET doc:AUTO-100001:header "COMPREHENSIVE AUTO POLICY\n"
APPEND doc:AUTO-100001:header "Policy Number: AUTO-100001\n"
APPEND doc:AUTO-100001:header "Effective Date: August 18, 2024\n"
APPEND doc:AUTO-100001:header "Policyholder: John Smith\n"
APPEND doc:AUTO-100001:header "Vehicle: 2022 Honda Accord\n\n"

SET doc:AUTO-100001:coverage "COVERAGE DETAILS:\n"
APPEND doc:AUTO-100001:coverage "• Bodily Injury Liability: $100,000 per person / $300,000 per accident\n"
APPEND doc:AUTO-100001:coverage "• Property Damage Liability: $100,000 per accident\n"
APPEND doc:AUTO-100001:coverage "• Collision Coverage: $500 deductible\n"
APPEND doc:AUTO-100001:coverage "• Comprehensive Coverage: $250 deductible\n"
APPEND doc:AUTO-100001:coverage "• Uninsured Motorist: $100,000 per person / $300,000 per accident\n\n"

SET doc:AUTO-100001:terms "POLICY TERMS:\n"
APPEND doc:AUTO-100001:terms "Policy Period: 6 months (August 18, 2024 - February 18, 2025)\n"
APPEND doc:AUTO-100001:terms "Premium Amount: $1,200\n"
APPEND doc:AUTO-100001:terms "Payment Schedule: Monthly ($200 per month)\n"
APPEND doc:AUTO-100001:terms "Renewal: Automatic unless cancelled\n\n"

# Assemble complete document
GET doc:AUTO-100001:header
GET doc:AUTO-100001:coverage  
GET doc:AUTO-100001:terms

# Check document section sizes
STRLEN doc:AUTO-100001:header
STRLEN doc:AUTO-100001:coverage
STRLEN doc:AUTO-100001:terms
```

These examples demonstrate practical applications of Redis string operations in real business scenarios, providing patterns that can be adapted for production systems.
