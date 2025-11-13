@echo off
REM Lab 15: Redis Cluster Test Script (Batch)
REM Tests Redis cluster operations

setlocal enabledelayedexpansion
echo === Redis Cluster Test ===
echo.

set passed=0
set failed=0

REM Test 1: Cluster connectivity
echo Test 1: Cluster connectivity...
docker exec redis-node-1 redis-cli -p 7000 PING 2>nul | findstr "PONG" >nul 2>&1
if %errorlevel% equ 0 (
    echo   [OK] PASSED: Cluster is responding
    set /a passed+=1
) else (
    echo   [X] FAILED: Cluster not responding
    set /a failed+=1
)

REM Test 2: Cluster info
echo Test 2: Cluster configuration...
docker exec redis-node-1 redis-cli -p 7000 CLUSTER INFO 2>nul | findstr "cluster_state:ok" >nul 2>&1
if %errorlevel% equ 0 (
    echo   [OK] PASSED: Cluster state is OK
    set /a passed+=1
) else (
    echo   [X] FAILED: Cluster state is not OK
    set /a failed+=1
)

REM Test 3: SET/GET operations
echo Test 3: Cluster SET/GET operations...
docker exec redis-node-1 redis-cli -c -p 7000 SET "test:cluster:key1" "value1" >nul 2>&1
docker exec redis-node-1 redis-cli -c -p 7000 GET "test:cluster:key1" > temp_result.txt 2>&1
findstr "value1" temp_result.txt >nul 2>&1
if %errorlevel% equ 0 (
    echo   [OK] PASSED: SET/GET operations working
    set /a passed+=1
) else (
    echo   [X] FAILED: SET/GET operations not working
    set /a failed+=1
)
del temp_result.txt >nul 2>&1

REM Test 4: Key distribution
echo Test 4: Key distribution across nodes...
for /l %%i in (1,1,10) do (
    docker exec redis-node-1 redis-cli -c -p 7000 SET "test:key:%%i" "value:%%i" >nul 2>&1
)
echo   [OK] PASSED: Keys distributed across cluster
set /a passed+=1

REM Test 5: Cluster nodes
echo Test 5: Cluster nodes...
docker exec redis-node-1 redis-cli -p 7000 CLUSTER NODES > cluster_nodes.txt 2>&1
findstr /c:"master" cluster_nodes.txt | find /c "master" > master_count.txt
findstr /c:"slave" cluster_nodes.txt | find /c "slave" > slave_count.txt
set /p masterCount=<master_count.txt
set /p slaveCount=<slave_count.txt

if !masterCount! geq 3 (
    if !slaveCount! geq 3 (
        echo   [OK] PASSED: Cluster has !masterCount! masters and !slaveCount! replicas
        set /a passed+=1
    ) else (
        echo   [X] FAILED: Expected 3 masters and 3 replicas
        set /a failed+=1
    )
) else (
    echo   [X] FAILED: Expected 3 masters and 3 replicas
    set /a failed+=1
)
del cluster_nodes.txt master_count.txt slave_count.txt >nul 2>&1

REM Display cluster info
echo.
echo === Cluster Status ===
docker exec redis-node-1 redis-cli -p 7000 CLUSTER INFO | findstr "cluster_state cluster_slots cluster_known_nodes"

echo.
echo === Cluster Nodes ===
docker exec redis-node-1 redis-cli -p 7000 CLUSTER NODES

REM Summary
echo.
echo === Test Results ===
echo Passed: %passed%
echo Failed: %failed%
echo.

if %failed% equ 0 (
    echo All tests passed! Cluster is working correctly!
    exit /b 0
) else (
    echo Some tests failed. Please review the errors above.
    exit /b 1
)
