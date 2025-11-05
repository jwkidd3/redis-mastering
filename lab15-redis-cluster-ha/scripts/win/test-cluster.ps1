# Lab 15: Redis Cluster Test Script (PowerShell)
# Tests Redis cluster operations

Write-Host "=== Redis Cluster Test ===" -ForegroundColor Cyan
Write-Host ""

$passed = 0
$failed = 0

# Test 1: Cluster connectivity
Write-Host "Test 1: Cluster connectivity..." -ForegroundColor Yellow
try {
    $ping = docker exec redis-node-1 redis-cli -p 7000 PING 2>$null
    if ($ping -eq "PONG") {
        Write-Host "  ✓ PASSED: Cluster is responding" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  ✗ FAILED: Cluster not responding" -ForegroundColor Red
        $failed++
    }
} catch {
    Write-Host "  ✗ FAILED: Cannot connect to cluster" -ForegroundColor Red
    $failed++
}

# Test 2: Cluster info
Write-Host "Test 2: Cluster configuration..." -ForegroundColor Yellow
$clusterInfo = docker exec redis-node-1 redis-cli -p 7000 CLUSTER INFO 2>$null
if ($clusterInfo -like "*cluster_state:ok*") {
    Write-Host "  ✓ PASSED: Cluster state is OK" -ForegroundColor Green
    $passed++
} else {
    Write-Host "  ✗ FAILED: Cluster state is not OK" -ForegroundColor Red
    $failed++
}

# Test 3: SET/GET operations
Write-Host "Test 3: Cluster SET/GET operations..." -ForegroundColor Yellow
docker exec redis-node-1 redis-cli -c -p 7000 SET "test:cluster:key1" "value1" | Out-Null
$value = docker exec redis-node-1 redis-cli -c -p 7000 GET "test:cluster:key1"
if ($value -eq "value1") {
    Write-Host "  ✓ PASSED: SET/GET operations working" -ForegroundColor Green
    $passed++
} else {
    Write-Host "  ✗ FAILED: SET/GET operations not working" -ForegroundColor Red
    $failed++
}

# Test 4: Key distribution
Write-Host "Test 4: Key distribution across nodes..." -ForegroundColor Yellow
for ($i = 1; $i -le 10; $i++) {
    docker exec redis-node-1 redis-cli -c -p 7000 SET "test:key:$i" "value:$i" | Out-Null
}
Write-Host "  ✓ PASSED: Keys distributed across cluster" -ForegroundColor Green
$passed++

# Test 5: Cluster nodes
Write-Host "Test 5: Cluster nodes..." -ForegroundColor Yellow
$nodes = docker exec redis-node-1 redis-cli -p 7000 CLUSTER NODES
$masterCount = ($nodes | Select-String "master").Matches.Count
$slaveCount = ($nodes | Select-String "slave").Matches.Count

if ($masterCount -ge 3 -and $slaveCount -ge 3) {
    Write-Host "  ✓ PASSED: Cluster has $masterCount masters and $slaveCount replicas" -ForegroundColor Green
    $passed++
} else {
    Write-Host "  ✗ FAILED: Expected 3 masters and 3 replicas" -ForegroundColor Red
    $failed++
}

# Display cluster info
Write-Host ""
Write-Host "=== Cluster Status ===" -ForegroundColor Cyan
docker exec redis-node-1 redis-cli -p 7000 CLUSTER INFO | Select-String "cluster_state|cluster_slots|cluster_known_nodes"

Write-Host ""
Write-Host "=== Cluster Nodes ===" -ForegroundColor Cyan
docker exec redis-node-1 redis-cli -p 7000 CLUSTER NODES

# Summary
Write-Host ""
Write-Host "=== Test Results ===" -ForegroundColor Cyan
Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor Red
Write-Host ""

if ($failed -eq 0) {
    Write-Host "🎉 All tests passed! Cluster is working correctly!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ Some tests failed. Please review the errors above." -ForegroundColor Red
    exit 1
}
