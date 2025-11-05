# Lab 6 Completion Verification
# PowerShell version for Windows

Write-Host "🎯 Lab 6 Completion Verification" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

$score = 0
$total = 10

Write-Host "Testing lab completion requirements..." -ForegroundColor Yellow
Write-Host ""

# Test 1: Connection test passes
Write-Host "Test 1: Redis Connection"
$result = node tests/connection-test.js 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Redis connection successful" -ForegroundColor Green
    $score++
} else {
    Write-Host "❌ Redis connection failed" -ForegroundColor Red
}

# Test 2: Main application runs
Write-Host ""
Write-Host "Test 2: Main Application"
$job = Start-Job -ScriptBlock { node src/app.js }
Start-Sleep -Seconds 10
Stop-Job $job -ErrorAction SilentlyContinue
$jobState = $job.State
Remove-Job $job
if ($jobState -eq "Running" -or $jobState -eq "Completed") {
    Write-Host "✅ Main application runs without errors" -ForegroundColor Green
    $score++
} else {
    Write-Host "❌ Main application has errors" -ForegroundColor Red
}

# Test 3: Customer model functionality
Write-Host ""
Write-Host "Test 3: Customer Model"
$testScript = @"
const RedisClient = require('./src/clients/redisClient');
const Customer = require('./src/models/customer');

async function test() {
    const redisClient = new RedisClient();
    await redisClient.connect();
    const customer = new Customer(redisClient);

    await customer.create('TEST001', {
        name: 'Test Customer',
        email: 'test@test.com'
    });

    const retrieved = await customer.get('TEST001');
    await customer.delete('TEST001');
    await redisClient.disconnect();

    if (retrieved && retrieved.name === 'Test Customer') {
        console.log('SUCCESS');
    } else {
        throw new Error('Customer operations failed');
    }
}

test().catch(() => process.exit(1));
"@
$testScript | Out-File -FilePath "temp_customer_test.js" -Encoding utf8
$result = node temp_customer_test.js 2>&1
Remove-Item "temp_customer_test.js" -ErrorAction SilentlyContinue
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Customer model operations work" -ForegroundColor Green
    $score++
} else {
    Write-Host "❌ Customer model operations failed" -ForegroundColor Red
}

# Test 4: Policy model functionality
Write-Host ""
Write-Host "Test 4: Policy Model"
$testScript = @"
const RedisClient = require('./src/clients/redisClient');
const Policy = require('./src/models/policy');

async function test() {
    const redisClient = new RedisClient();
    await redisClient.connect();
    const policy = new Policy(redisClient);

    await policy.create('TEST_POL001', {
        customerId: 'TEST001',
        type: 'auto',
        premium: 1000
    });

    const retrieved = await policy.get('TEST_POL001');

    // Cleanup
    const client = redisClient.getClient();
    await client.del('policy:TEST_POL001');
    await client.sRem('policies:index', 'TEST_POL001');
    await redisClient.disconnect();

    if (retrieved && retrieved.type === 'auto') {
        console.log('SUCCESS');
    } else {
        throw new Error('Policy operations failed');
    }
}

test().catch(() => process.exit(1));
"@
$testScript | Out-File -FilePath "temp_policy_test.js" -Encoding utf8
$result = node temp_policy_test.js 2>&1
Remove-Item "temp_policy_test.js" -ErrorAction SilentlyContinue
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Policy model operations work" -ForegroundColor Green
    $score++
} else {
    Write-Host "❌ Policy model operations failed" -ForegroundColor Red
}

# Test 5: Environment configuration
Write-Host ""
Write-Host "Test 5: Environment Configuration"
if ((Test-Path ".env") -and (Get-Content ".env" | Select-String "REDIS_HOST=") -and (Get-Content ".env" | Select-String "REDIS_PORT=")) {
    Write-Host "✅ Environment properly configured" -ForegroundColor Green
    $score++
} else {
    Write-Host "❌ Environment configuration incomplete" -ForegroundColor Red
}

# Test 6: Error handling
Write-Host ""
Write-Host "Test 6: Error Handling"
$testScript = @"
const RedisClient = require('./src/clients/redisClient');

async function test() {
    const redisClient = new RedisClient();
    await redisClient.connect();

    try {
        // Try to get non-existent customer
        const client = redisClient.getClient();
        const result = await client.get('customer:NONEXISTENT');

        if (result === null) {
            console.log('SUCCESS');
        }
    } catch (error) {
        throw error;
    } finally {
        await redisClient.disconnect();
    }
}

test().catch(() => process.exit(1));
"@
$testScript | Out-File -FilePath "temp_error_test.js" -Encoding utf8
$result = node temp_error_test.js 2>&1
Remove-Item "temp_error_test.js" -ErrorAction SilentlyContinue
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Error handling works correctly" -ForegroundColor Green
    $score++
} else {
    Write-Host "❌ Error handling issues" -ForegroundColor Red
}

# Test 7: JSON operations
Write-Host ""
Write-Host "Test 7: JSON Data Operations"
$testScript = @"
const RedisClient = require('./src/clients/redisClient');

async function test() {
    const redisClient = new RedisClient();
    await redisClient.connect();
    const client = redisClient.getClient();

    const testData = { name: 'JSON Test', value: 123 };
    await client.set('test:json', JSON.stringify(testData));

    const retrieved = JSON.parse(await client.get('test:json'));
    await client.del('test:json');
    await redisClient.disconnect();

    if (retrieved.name === 'JSON Test' && retrieved.value === 123) {
        console.log('SUCCESS');
    } else {
        throw new Error('JSON operations failed');
    }
}

test().catch(() => process.exit(1));
"@
$testScript | Out-File -FilePath "temp_json_test.js" -Encoding utf8
$result = node temp_json_test.js 2>&1
Remove-Item "temp_json_test.js" -ErrorAction SilentlyContinue
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ JSON operations work correctly" -ForegroundColor Green
    $score++
} else {
    Write-Host "❌ JSON operations failed" -ForegroundColor Red
}

# Test 8: Examples run
Write-Host ""
Write-Host "Test 8: Example Scripts"
$result = node examples/basic-operations.js 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Example scripts run successfully" -ForegroundColor Green
    $score++
} else {
    Write-Host "❌ Example scripts have errors" -ForegroundColor Red
}

# Test 9: Performance test
Write-Host ""
Write-Host "Test 9: Performance Testing"
$result = node examples/performance-test.js 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Performance tests complete" -ForegroundColor Green
    $score++
} else {
    Write-Host "❌ Performance tests failed" -ForegroundColor Red
}

# Test 10: Project structure
Write-Host ""
Write-Host "Test 10: Project Structure"
$structureScore = 0
if (Test-Path "src/config/redis.js") { $structureScore++ }
if (Test-Path "src/clients/redisClient.js") { $structureScore++ }
if (Test-Path "src/models/customer.js") { $structureScore++ }
if (Test-Path "src/models/policy.js") { $structureScore++ }
if (Test-Path "examples/basic-operations.js") { $structureScore++ }

if ($structureScore -eq 5) {
    Write-Host "✅ Project structure complete" -ForegroundColor Green
    $score++
} else {
    Write-Host "❌ Project structure incomplete ($structureScore/5 files)" -ForegroundColor Red
}

# Results
Write-Host ""
Write-Host "================================="
Write-Host "📊 Lab Completion Score: $score/$total"

$percentage = [int](($score * 100) / $total)

if ($score -eq $total) {
    Write-Host "🎉 EXCELLENT! Lab completed successfully!" -ForegroundColor Green
    Write-Host "🌟 You've mastered JavaScript Redis client development!"
} elseif ($score -ge 8) {
    Write-Host "✅ GOOD! Lab mostly completed ($percentage%)" -ForegroundColor Green
    Write-Host "🔧 Minor issues to address for perfection"
} elseif ($score -ge 6) {
    Write-Host "⚠️  PASSING: Lab partially completed ($percentage%)" -ForegroundColor Yellow
    Write-Host "📚 Review the failed tests and improve"
} else {
    Write-Host "❌ NEEDS WORK: Lab significantly incomplete ($percentage%)" -ForegroundColor Red
    Write-Host "🆘 Seek help and review the lab instructions"
}

Write-Host ""
Write-Host "🎯 Next steps:"
if ($score -ge 8) {
    Write-Host "- Review any failed tests above"
    Write-Host "- Prepare for Lab 7: Advanced Data Structures"
    Write-Host "- Practice with Redis Insight integration"
} else {
    Write-Host "- Fix the failed tests listed above"
    Write-Host "- Review lab6.md instructions"
    Write-Host "- Ask instructor for help if needed"
    Write-Host "- Run this verification again after fixes"
}

Write-Host ""
