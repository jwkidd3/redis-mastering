# Insurance String Operations Examples

## Policy Management Examples

### Auto Policy Creation Workflow
```redis
# Step 1: Generate unique policy number
INCR policy:counter:auto                    # Returns 100001
SET policy:AUTO-100001 "Policy Type: Auto | Customer: CUST001 | Vehicle: 2020 Toyota Camry | Premium: $1,200 | Status: Active"

# Step 2: Set related data
SET premium:AUTO-100001 1200
SET policy:AUTO-100001:status "ACTIVE"
SET policy:AUTO-100001:customer "CUST001"

# Step 3: Update customer policy list
APPEND customer:CUST001:policies "AUTO-100001,"

# Verification
GET policy:AUTO-100001
EXISTS policy:AUTO-100001
STRLEN policy:AUTO-100001
```

### Policy Amendment Process
```redis
# Original policy
SET policy:AUTO-100001 "Type: Auto | Customer: CUST001 | Vehicle: 2020 Toyota Camry | Premium: $1,200"

# Add coverage details
APPEND policy:AUTO-100001 " | Coverage: Full | Deductible: $500"

# Update premium due to risk change
INCRBY premium:AUTO-100001 150              # Increase by $150

# Log the change
APPEND audit:policy:AUTO-100001 "2024-08-18T10:30:00Z - Premium increased $150 due to traffic violation\n"

# Verify changes
GET policy:AUTO-100001
GET premium:AUTO-100001
GET audit:policy:AUTO-100001
```

## Customer Management Examples

### Customer Registration Workflow
```redis
# Step 1: Generate customer ID
INCR customer:counter                       # Returns CUST001 equivalent

# Step 2: Store comprehensive profile
SET customer:CUST001 "Name: John Smith | DOB: 1985-03-15 | Phone: 555-0123 | Email: john.smith@email.com | Address: 456 Oak St, Dallas TX"

# Step 3: Initialize customer metrics
SET customer:CUST001:balance 0
SET customer:CUST001:login_count 0
SET customer:CUST001:policies ""

# Step 4: Set communication preferences
SET communication:CUST001 "Preferred: Email | Frequency: Quarterly | Marketing: Yes"

# Verification
GET customer:CUST001
MGET customer:CUST001:balance customer:CUST001:login_count
```

### Customer Profile Updates
```redis
# Update contact information
GETRANGE customer:CUST001 0 50              # Get current start of profile
SETRANGE customer:CUST001 60 "Phone: 555-9999"  # Update phone section

# Add risk assessment data
APPEND customer:CUST001 " | Credit Score: 750 | Risk Level: Low"

# Track profile changes
APPEND activity:CUST001 "2024-08-18T14:30:00Z - Contact information updated\n"
APPEND activity:CUST001 "2024-08-18T14:31:00Z - Risk assessment completed\n"

# View updated profile
GET customer:CUST001
GET activity:CUST001
```

## Premium and Payment Examples

### Premium Calculation Workflow
```redis
# Base premium setup
SET premium:base:auto 800
SET premium:base:home 600
SET premium:base:life 300

# Customer-specific factors
SET factor:age:CUST001 110                   # 10% increase for age (110%)
SET factor:credit:CUST001 95                 # 5% discount for good credit (95%)
SET factor:location:CUST001 105              # 5% increase for location (105%)

# Calculate final premium (base * factors / 10000)
# For auto: 800 * 110 * 95 * 105 / 10000 = 873
SET premium:calculated:AUTO-100001 873

# Round to nearest dollar and store
SET premium:AUTO-100001 873

# Track calculation
APPEND calculation:AUTO-100001 "Base: 800 | Age: 110% | Credit: 95% | Location: 105% | Final: 873\n"
```

### Payment Processing Workflow
```redis
# Customer makes payment
SET payment:transaction:TXN001 "Customer: CUST001 | Amount: 873 | Policy: AUTO-100001 | Date: 2024-08-18T15:00:00Z"

# Update customer balance
INCRBY customer:CUST001:balance 873

# Apply payment to policy
DECRBY customer:CUST001:balance 873
SET policy:AUTO-100001:paid_status "CURRENT"

# Update payment history
APPEND customer:CUST001:payments "2024-08-18T15:00:00Z|AUTO-100001|873|TXN001\n"

# Daily revenue tracking
INCRBY revenue:daily:2024-08-18 873
INCR payments:count:daily:2024-08-18

# Verification
GET customer:CUST001:balance               # Should be 0
GET revenue:daily:2024-08-18
GET payments:count:daily:2024-08-18
```

## Claims Processing Examples

### Claims Submission Workflow
```redis
# Generate claim number
INCR claims:counter                         # Returns CLM001 equivalent

# Store claim details
SET claim:CLM001 "Type: Auto | Policy: AUTO-100001 | Customer: CUST001 | Amount: $2,500 | Date: 2024-08-18 | Status: Submitted"

# Initialize claim tracking
SET claim:CLM001:status "SUBMITTED"
SET claim:CLM001:amount 2500
SET claim:CLM001:adjuster ""

# Add to processing queue
APPEND claims:processing:queue "CLM001|URGENT|2500|2024-08-18\n"

# Update policy claim history
APPEND policy:AUTO-100001:claims "CLM001|2024-08-18|2500|SUBMITTED\n"

# Customer notification
APPEND customer:CUST001:notifications "Claim CLM001 submitted successfully - We will contact you within 24 hours\n"
```

### Claims Processing Updates
```redis
# Assign adjuster
SET claim:CLM001:adjuster "ADJ001"
SETRANGE claim:CLM001:status 0 "ASSIGNED"

# Update claim with adjuster notes
APPEND claim:CLM001 " | Adjuster: ADJ001 | Notes: Initial review completed"

# Process status updates
APPEND claim:CLM001:timeline "2024-08-18T09:00:00Z - Claim submitted\n"
APPEND claim:CLM001:timeline "2024-08-18T11:30:00Z - Assigned to ADJ001\n"
APPEND claim:CLM001:timeline "2024-08-18T14:15:00Z - Initial review completed\n"

# Update daily metrics
INCR claims:assigned:daily:2024-08-18
INCRBY claims:amount:daily:2024-08-18 2500
```

## Document Assembly Examples

### Policy Document Generation
```redis
# Document templates
SET template:policy:header "INSURANCE POLICY\nPolicy Number: {policy_number}\nEffective Date: {date}\n\n"
SET template:policy:customer "POLICYHOLDER INFORMATION\nName: {customer_name}\nAddress: {customer_address}\n\n"
SET template:auto:coverage "COVERAGE DETAILS\nLiability: $100,000/$300,000\nCollision: $500 deductible\nComprehensive: $500 deductible\n\n"

# Assemble policy document for AUTO-100001
SET document:AUTO-100001 ""
APPEND document:AUTO-100001 "INSURANCE POLICY\nPolicy Number: AUTO-100001\nEffective Date: 2024-08-18\n\n"
APPEND document:AUTO-100001 "POLICYHOLDER INFORMATION\nName: John Smith\nAddress: 456 Oak St, Dallas TX\n\n"
APPEND document:AUTO-100001 "COVERAGE DETAILS\nLiability: $100,000/$300,000\nCollision: $500 deductible\nComprehensive: $500 deductible\n\n"
APPEND document:AUTO-100001 "PREMIUM: $1,200 annually\nDUE DATE: 2024-09-18"

# Check document length and content
STRLEN document:AUTO-100001
GET document:AUTO-100001
```

### Email Template Processing
```redis
# Email templates
SET email:template:welcome "Dear {customer_name},\n\nWelcome to our insurance family! Your policy {policy_number} is now active.\n\nPremium: ${premium}\nNext payment due: {due_date}\n\nThank you for choosing us!\n\nBest regards,\nInsurance Team"

# Customer-specific email generation
SET email:CUST001:welcome ""
APPEND email:CUST001:welcome "Dear John Smith,\n\n"
APPEND email:CUST001:welcome "Welcome to our insurance family! Your policy AUTO-100001 is now active.\n\n"
APPEND email:CUST001:welcome "Premium: $1,200\n"
APPEND email:CUST001:welcome "Next payment due: 2024-09-18\n\n"
APPEND email:CUST001:welcome "Thank you for choosing us!\n\nBest regards,\nInsurance Team"

# Email delivery tracking
SET email:CUST001:welcome:status "QUEUED"
APPEND email:delivery:log "2024-08-18T16:00:00Z|CUST001|welcome|QUEUED\n"
```

## Reporting and Analytics Examples

### Daily Business Metrics
```redis
# Initialize daily counters
SET metrics:daily:2024-08-18:new_policies 0
SET metrics:daily:2024-08-18:claims_submitted 0
SET metrics:daily:2024-08-18:revenue 0
SET metrics:daily:2024-08-18:payments_received 0

# Update throughout the day
INCR metrics:daily:2024-08-18:new_policies     # New policy created
INCR metrics:daily:2024-08-18:claims_submitted # Claim submitted
INCRBY metrics:daily:2024-08-18:revenue 1200   # Premium collected
INCR metrics:daily:2024-08-18:payments_received # Payment processed

# Category breakdowns
INCRBY metrics:auto:revenue:2024-08-18 1200
INCRBY metrics:home:revenue:2024-08-18 800
INCRBY metrics:life:revenue:2024-08-18 420

# End of day reporting
MGET metrics:daily:2024-08-18:new_policies metrics:daily:2024-08-18:claims_submitted metrics:daily:2024-08-18:revenue
```

### Customer Analytics
```redis
# Customer lifetime value calculation
SET customer:CUST001:total_premiums 0
INCRBY customer:CUST001:total_premiums 1200    # Auto policy
INCRBY customer:CUST001:total_premiums 800     # Home policy

# Customer engagement metrics
INCR customer:CUST001:login_count
SET customer:CUST001:last_login "2024-08-18T16:30:00Z"
APPEND customer:CUST001:engagement "login|2024-08-18T16:30:00Z|portal\n"

# Risk assessment updates
SET customer:CUST001:risk_score 750
SET customer:CUST001:risk_factors "age:39|credit:750|claims:0|violations:0"

# Customer segmentation
APPEND segment:high_value "CUST001|LTV:2000|Risk:750\n"
```

## Advanced String Patterns

### Batch Customer Operations
```redis
# Batch customer status updates
MSET customer:CUST001:status "active" customer:CUST002:status "active" customer:CUST003:status "active"

# Batch premium retrievals
MGET premium:AUTO-100001 premium:HOME-200001 premium:LIFE-300001

# Batch last login updates
MSET customer:CUST001:last_login "2024-08-18" customer:CUST002:last_login "2024-08-18" customer:CUST003:last_login "2024-08-18"
```

### Complex Document Assembly
```redis
# Multi-section document assembly
SET doc:comprehensive:AUTO-100001 ""

# Add header section
APPEND doc:comprehensive:AUTO-100001 "=== COMPREHENSIVE POLICY DOCUMENT ===\n"
APPEND doc:comprehensive:AUTO-100001 "Policy: AUTO-100001 | Customer: John Smith\n\n"

# Add coverage section
APPEND doc:comprehensive:AUTO-100001 "=== COVERAGE DETAILS ===\n"
GET doc:AUTO-100001:coverage                                    # Retrieve coverage text
APPEND doc:comprehensive:AUTO-100001 "\n\n"

# Add exclusions section
APPEND doc:comprehensive:AUTO-100001 "=== EXCLUSIONS ===\n"
GET doc:AUTO-100001:exclusions                                  # Retrieve exclusions text
APPEND doc:comprehensive:AUTO-100001 "\n\n"

# Add terms section
APPEND doc:comprehensive:AUTO-100001 "=== TERMS AND CONDITIONS ===\n"
GET doc:AUTO-100001:terms                                       # Retrieve terms text

# Final document length check
STRLEN doc:comprehensive:AUTO-100001
```

These examples demonstrate practical insurance string operations that maintain data consistency, support business workflows, and enable efficient customer service operations.
