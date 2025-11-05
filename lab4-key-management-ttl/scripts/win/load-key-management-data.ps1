# Load comprehensive key management sample data for Lab 4
# PowerShell version for Windows

# Check if environment variables are set
if (-not $env:REDIS_HOST -or -not $env:REDIS_PORT) {
    Write-Host "❌ Please set REDIS_HOST and REDIS_PORT environment variables" -ForegroundColor Red
    Write-Host "Example:"
    Write-Host "`$env:REDIS_HOST = 'your-redis-host.com'"
    Write-Host "`$env:REDIS_PORT = '6379'"
    Write-Host "`$env:REDIS_PASSWORD = ''  # if password required"
    exit 1
}

Write-Host "Loading comprehensive key management sample data to $env:REDIS_HOST:$env:REDIS_PORT..." -ForegroundColor Cyan

# Build redis-cli connection command
$redisCmd = "redis-cli -h $env:REDIS_HOST -p $env:REDIS_PORT"
if ($env:REDIS_PASSWORD) {
    $redisCmd += " -a $env:REDIS_PASSWORD"
}

# Test connection first
Write-Host "Testing connection to $env:REDIS_HOST:$env:REDIS_PORT..." -ForegroundColor Yellow
$pingResult = & cmd /c "$redisCmd ping 2>&1"
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Cannot connect to Redis at $env:REDIS_HOST:$env:REDIS_PORT" -ForegroundColor Red
    Write-Host "Please check your connection parameters and try again."
    exit 1
}

Write-Host "✅ Connected successfully to $env:REDIS_HOST:$env:REDIS_PORT" -ForegroundColor Green

# Redis commands as here-string
$redisCommands = @"
FLUSHDB

# === HIERARCHICAL POLICY KEYS ===
SET policy:auto:100001:details "2020 Toyota Camry - John Smith - `$1,200 premium"
SET policy:auto:100001:customer "CUST001"
SET policy:auto:100001:status "active"
SET policy:auto:100001:premium "1200.00"
SET policy:auto:100001:deductible "500"
SET policy:auto:100001:coverage "full"

SET policy:auto:100002:details "2019 BMW 330i - Sarah Wilson - `$1,850 premium"
SET policy:auto:100002:customer "CUST002"
SET policy:auto:100002:status "active"
SET policy:auto:100002:premium "1850.00"
SET policy:auto:100002:deductible "1000"
SET policy:auto:100002:coverage "full"

# Home policies
SET policy:home:200001:details "123 Main St - `$350,000 coverage - `$850 premium"
SET policy:home:200001:customer "CUST002"
SET policy:home:200001:status "active"
SET policy:home:200001:coverage "350000"
SET policy:home:200001:premium "850.00"
SET policy:home:200001:deductible "2000"

SET policy:home:200002:details "456 Oak Ave - `$275,000 coverage - `$625 premium"
SET policy:home:200002:customer "CUST003"
SET policy:home:200002:status "pending"
SET policy:home:200002:coverage "275000"
SET policy:home:200002:premium "625.00"
SET policy:home:200002:deductible "1500"

# Life policies
SET policy:life:300001:details "`$500,000 Term Life - Alice Johnson - `$45/month"
SET policy:life:300001:customer "CUST003"
SET policy:life:300001:status "pending"
SET policy:life:300001:coverage "500000"
SET policy:life:300001:premium "45.00"
SET policy:life:300001:beneficiary "spouse"

SET policy:life:300002:details "`$250,000 Whole Life - John Smith - `$125/month"
SET policy:life:300002:customer "CUST001"
SET policy:life:300002:status "active"
SET policy:life:300002:coverage "250000"
SET policy:life:300002:premium "125.00"
SET policy:life:300002:beneficiary "children"

# === HIERARCHICAL CUSTOMER KEYS ===
SET customer:CUST001:name "John Smith"
SET customer:CUST001:email "john.smith@example.com"
SET customer:CUST001:phone "555-0101"
SET customer:CUST001:tier "premium"
SET customer:CUST001:address "789 Pine St, Boston, MA 02101"
SET customer:CUST001:join_date "2020-03-15"
SET customer:CUST001:agent "AG001"

SET customer:CUST002:name "Sarah Wilson"
SET customer:CUST002:email "sarah.wilson@example.com"
SET customer:CUST002:phone "555-0102"
SET customer:CUST002:tier "standard"
SET customer:CUST002:address "456 Oak Ave, Portland, OR 97201"
SET customer:CUST002:join_date "2021-07-22"
SET customer:CUST002:agent "AG002"

SET customer:CUST003:name "Alice Johnson"
SET customer:CUST003:email "alice.johnson@example.com"
SET customer:CUST003:phone "555-0103"
SET customer:CUST003:tier "premium"
SET customer:CUST003:address "123 Cedar Rd, Austin, TX 78701"
SET customer:CUST003:join_date "2019-11-08"
SET customer:CUST003:agent "AG001"

SET customer:CUST004:name "Robert Chen"
SET customer:CUST004:email "robert.chen@example.com"
SET customer:CUST004:phone "555-0104"
SET customer:CUST004:tier "standard"
SET customer:CUST004:address "321 Maple Dr, Denver, CO 80202"
SET customer:CUST004:join_date "2022-01-10"
SET customer:CUST004:agent "AG003"

SET customer:CUST005:name "Maria Garcia"
SET customer:CUST005:email "maria.garcia@example.com"
SET customer:CUST005:phone "555-0105"
SET customer:CUST005:tier "premium"
SET customer:CUST005:address "654 Elm St, Miami, FL 33101"
SET customer:CUST005:join_date "2020-09-14"
SET customer:CUST005:agent "AG002"

SET customer:CUST006:name "David Miller"
SET customer:CUST006:email "david.miller@example.com"
SET customer:CUST006:phone "555-0106"
SET customer:CUST006:tier "standard"
SET customer:CUST006:address "987 Birch Ln, Seattle, WA 98101"
SET customer:CUST006:join_date "2023-02-28"
SET customer:CUST006:agent "AG003"

# === HIERARCHICAL CLAIMS KEYS ===
SET claim:CL001:policy "policy:auto:100001"
SET claim:CL001:customer "CUST001"
SET claim:CL001:amount "2500.00"
SET claim:CL001:status "processing"
SET claim:CL001:date "2024-01-15"
SET claim:CL001:adjuster "ADJ001"
SET claim:CL001:description "Rear-end collision at intersection"

SET claim:CL002:policy "policy:home:200001"
SET claim:CL002:customer "CUST002"
SET claim:CL002:amount "8500.00"
SET claim:CL002:status "approved"
SET claim:CL002:date "2024-01-10"
SET claim:CL002:adjuster "ADJ002"
SET claim:CL002:description "Storm damage to roof and siding"

# === HIERARCHICAL AGENT KEYS ===
SET agent:AG001:name "Mike Thompson"
SET agent:AG001:territory "Northeast"
SET agent:AG001:specialty "auto"
SET agent:AG001:phone "555-0201"
SET agent:AG001:email "mike.thompson@company.com"
SET agent:AG001:hire_date "2018-06-01"
SET agent:AG001:customers_count "2"

SET agent:AG002:name "Lisa Chen"
SET agent:AG002:territory "West Coast"
SET agent:AG002:specialty "home"
SET agent:AG002:phone "555-0202"
SET agent:AG002:email "lisa.chen@company.com"
SET agent:AG002:hire_date "2019-03-15"
SET agent:AG002:customers_count "2"

SET agent:AG003:name "Carlos Rodriguez"
SET agent:AG003:territory "Southwest"
SET agent:AG003:specialty "life"
SET agent:AG003:phone "555-0203"
SET agent:AG003:email "carlos.rodriguez@company.com"
SET agent:AG003:hire_date "2020-01-20"
SET agent:AG003:customers_count "2"

# === QUOTE KEYS WITH BUSINESS-APPROPRIATE TTL ===
SETEX quote:auto:Q001 300 "2020 Honda Civic - 25-year-old driver - `$145/month"
SETEX quote:auto:Q002 300 "2019 BMW 330i - 35-year-old driver - `$195/month"
SETEX quote:auto:Q003 300 "2021 Ford F-150 - 45-year-old driver - `$165/month"
SETEX quote:auto:Q004 300 "2018 Tesla Model 3 - 30-year-old driver - `$175/month"

SETEX quote:home:H001 600 "Single family home - `$350,000 coverage - `$850/year"
SETEX quote:home:H002 600 "Condominium - `$200,000 coverage - `$450/year"
SETEX quote:home:H003 600 "Townhouse - `$275,000 coverage - `$625/year"
SETEX quote:home:H004 600 "Manufactured home - `$150,000 coverage - `$375/year"

SETEX quote:life:L001 1800 "`$250,000 Term Life - 30-year-old - `$25/month"
SETEX quote:life:L002 1800 "`$500,000 Term Life - 40-year-old - `$55/month"
SETEX quote:life:L003 1800 "`$100,000 Whole Life - 25-year-old - `$85/month"
SETEX quote:life:L004 1800 "`$750,000 Term Life - 35-year-old - `$75/month"

# === SESSION MANAGEMENT WITH TTL ===
SETEX session:customer:CUST001:portal 1800 "authenticated_2024-01-15_10:30_token_abc123"
SETEX session:customer:CUST002:portal 1800 "authenticated_2024-01-15_10:45_token_def456"
SETEX session:customer:CUST003:portal 1800 "authenticated_2024-01-15_11:00_token_ghi789"

SETEX session:customer:CUST001:mobile 7200 "mobile_token_abc123_ios"
SETEX session:customer:CUST002:mobile 7200 "mobile_token_def456_android"
SETEX session:customer:CUST004:mobile 7200 "mobile_token_jkl012_ios"

SETEX session:agent:AG001:workstation 28800 "agent_session_active_workstation_1"
SETEX session:agent:AG002:workstation 28800 "agent_session_active_workstation_2"
SETEX session:agent:AG003:workstation 28800 "agent_session_active_workstation_3"

SETEX session:agent:AG001:mobile 14400 "field_session_active_tablet_1"
SETEX session:agent:AG002:mobile 14400 "field_session_active_tablet_2"

# === TEMPORAL DATA WITH APPROPRIATE TTL ===
SETEX metrics:daily:2024-01-15:quotes_generated 86400 "47"
SETEX metrics:daily:2024-01-15:policies_sold 86400 "12"
SETEX metrics:daily:2024-01-15:claims_processed 86400 "8"
SETEX metrics:daily:2024-01-15:customer_calls 86400 "23"
SETEX metrics:daily:2024-01-15:agent_logins 86400 "15"

SETEX report:weekly:2024-W03:sales_summary 604800 "policies: 85, premium: `$45,200, conversion: 12.5%"
SETEX report:weekly:2024-W03:claims_summary 604800 "claims: 23, payout: `$67,500, avg_claim: `$2,935"
SETEX report:weekly:2024-W03:agent_performance 604800 "top_agent: AG001, policies: 28, customer_satisfaction: 4.8"

SETEX analytics:monthly:2024-01:conversion_rate 2592000 "12.5%"
SETEX analytics:monthly:2024-01:customer_acquisition 2592000 "156"
SETEX analytics:monthly:2024-01:retention_rate 2592000 "94.2%"
SETEX analytics:monthly:2024-01:avg_premium 2592000 "1245.50"

# === SECURITY FEATURES WITH TTL ===
SETEX security:failed_login:CUST001 900 "attempt_count:3_last_attempt:2024-01-15_10:45"
SETEX security:failed_login:CUST004 900 "attempt_count:1_last_attempt:2024-01-15_11:15"

SETEX security:password_reset:CUST002:token_xyz789 600 "reset_pending_email_sent"
SETEX security:password_reset:CUST005:token_abc456 600 "reset_pending_sms_sent"

SETEX security:lockout:CUST003 1800 "locked_too_many_attempts_contact_support"

SETEX security:2fa:CUST001:code_123456 300 "pending_verification"
SETEX security:2fa:CUST002:code_789012 300 "pending_verification"

# === CACHE PATTERNS WITH STRATEGIC TTL ===
SETEX cache:customer:CUST001:profile 3600 "{\"name\":\"John Smith\",\"tier\":\"premium\",\"policies\":2}"
SETEX cache:customer:CUST002:profile 3600 "{\"name\":\"Sarah Wilson\",\"tier\":\"standard\",\"policies\":2}"

SETEX cache:policy:auto:100001:summary 1800 "{\"customer\":\"John Smith\",\"premium\":1200,\"status\":\"active\"}"
SETEX cache:policy:home:200001:summary 1800 "{\"customer\":\"Sarah Wilson\",\"coverage\":350000,\"premium\":850}"

SETEX cache:agent:AG001:dashboard 900 "{\"customers\":2,\"quotes_pending\":3,\"claims_processing\":1}"
SETEX cache:agent:AG002:dashboard 900 "{\"customers\":2,\"quotes_pending\":2,\"claims_processing\":0}"
"@

# Execute commands via redis-cli
$redisCommands | & cmd /c "$redisCmd" 2>&1 | Out-Null

Write-Host "`n✅ Comprehensive key management sample data loaded successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Data Summary:" -ForegroundColor Cyan
Write-Host "   - Policies: 6 (2 auto, 2 home, 2 life) with complete attributes"
Write-Host "   - Customers: 6 with full profile information"
Write-Host "   - Claims: 2 with processing details"
Write-Host "   - Agents: 3 with territory and specialty information"
Write-Host "   - Quotes: 12 with business-appropriate TTL"
Write-Host "   - Sessions: 8 with role-based TTL"
Write-Host "   - Temporal Data: 12 items with appropriate TTL"
Write-Host "   - Security Features: 7 items with security-focused TTL"
Write-Host "   - Cache Patterns: 6 items with performance-optimized TTL"
Write-Host ""
Write-Host "🔑 Key Patterns Created:" -ForegroundColor Cyan
Write-Host "   - policy:{type}:{number}:{attribute}"
Write-Host "   - customer:{id}:{attribute}"
Write-Host "   - claim:{id}:{attribute}"
Write-Host "   - agent:{id}:{attribute}"
Write-Host "   - quote:{type}:{id} (with TTL)"
Write-Host "   - session:{type}:{id}:{device} (with TTL)"
Write-Host ""
Write-Host "🎯 Ready for Lab 4 key management and TTL strategy exercises!" -ForegroundColor Green
Write-Host ""
Write-Host "✅ Data loading completed successfully to $env:REDIS_HOST:$env:REDIS_PORT" -ForegroundColor Green
Write-Host "Use 'redis-cli -h $env:REDIS_HOST -p $env:REDIS_PORT KEYS `"*`"' to see all loaded keys."
