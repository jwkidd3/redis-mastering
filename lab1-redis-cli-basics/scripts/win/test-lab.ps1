# Lab 1: Test Script (PowerShell)
# Validates that lab exercises were completed correctly

Write-Host "=== Lab 1: Testing Lab Completion ===" -ForegroundColor Cyan
Write-Host ""

$passed = 0
$failed = 0

# Test 1: Redis connection
Write-Host "Test 1: Redis Connection..." -ForegroundColor Yellow
try {
    $ping = redis-cli ping 2>$null
    if ($ping -eq "PONG") {
        Write-Host "  ✓ PASSED: Redis is accessible" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  ✗ FAILED: Redis not responding" -ForegroundColor Red
        $failed++
    }
} catch {
    Write-Host "  ✗ FAILED: Cannot connect to Redis" -ForegroundColor Red
    $failed++
}

# Test 2: Basic SET/GET
Write-Host "Test 2: Basic SET/GET operations..." -ForegroundColor Yellow
redis-cli SET "test:key" "test:value" | Out-Null
$value = redis-cli GET "test:key"
if ($value -eq "test:value") {
    Write-Host "  ✓ PASSED: SET/GET working" -ForegroundColor Green
    $passed++
} else {
    Write-Host "  ✗ FAILED: SET/GET not working correctly" -ForegroundColor Red
    $failed++
}

# Test 3: KEYS pattern matching
Write-Host "Test 3: KEYS pattern matching..." -ForegroundColor Yellow
$keys = redis-cli KEYS "policy:*"
if ($keys) {
    Write-Host "  ✓ PASSED: KEYS command working" -ForegroundColor Green
    $passed++
} else {
    Write-Host "  ✗ FAILED: KEYS command not working" -ForegroundColor Red
    $failed++
}

# Test 4: INCR counter
Write-Host "Test 4: INCR counter operation..." -ForegroundColor Yellow
redis-cli SET "test:counter" "0" | Out-Null
$result = redis-cli INCR "test:counter"
if ($result -eq "1") {
    Write-Host "  ✓ PASSED: INCR working" -ForegroundColor Green
    $passed++
} else {
    Write-Host "  ✗ FAILED: INCR not working correctly" -ForegroundColor Red
    $failed++
}

# Test 5: DEL operation
Write-Host "Test 5: DEL operation..." -ForegroundColor Yellow
redis-cli SET "test:delete" "value" | Out-Null
redis-cli DEL "test:delete" | Out-Null
$result = redis-cli GET "test:delete"
if ([string]::IsNullOrEmpty($result) -or $result -eq "(nil)") {
    Write-Host "  ✓ PASSED: DEL working" -ForegroundColor Green
    $passed++
} else {
    Write-Host "  ✗ FAILED: DEL not working correctly" -ForegroundColor Red
    $failed++
}

# Summary
Write-Host ""
Write-Host "=== Test Results ===" -ForegroundColor Cyan
Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor Red
Write-Host ""

if ($failed -eq 0) {
    Write-Host "🎉 All tests passed! Lab 1 completed successfully!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ Some tests failed. Please review the errors above." -ForegroundColor Red
    exit 1
}
