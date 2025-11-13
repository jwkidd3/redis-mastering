@echo off
REM Lab 15: Redis Cluster Setup Script (Batch)
REM Sets up a 6-node Redis cluster (3 masters + 3 replicas)

echo === Redis Cluster Setup ===
echo.

REM Check if docker-compose is available
where docker-compose >nul 2>&1
if %errorlevel% neq 0 (
    echo X docker-compose not found. Please install Docker Desktop.
    exit /b 1
)

REM Check if cluster is already running
docker-compose ps 2>nul | findstr "redis" >nul 2>&1
if %errorlevel% neq 0 (
    echo Starting Redis cluster with docker-compose...
    docker-compose up -d
    timeout /t 5 /nobreak >nul
) else (
    echo Redis cluster containers are already running
)

echo Waiting for Redis nodes to be ready...
timeout /t 10 /nobreak >nul

REM Create the cluster
echo Creating Redis cluster...
echo.

echo Run this command to create the cluster:
echo redis-cli --cluster create ^
  127.0.0.1:7000 ^
  127.0.0.1:7001 ^
  127.0.0.1:7002 ^
  127.0.0.1:7003 ^
  127.0.0.1:7004 ^
  127.0.0.1:7005 ^
  --cluster-replicas 1
echo.
echo Or execute directly (will prompt for confirmation):

REM Try to create cluster
docker exec redis-node-1 redis-cli --cluster create redis-node-1:7000 redis-node-2:7001 redis-node-3:7002 redis-node-4:7003 redis-node-5:7004 redis-node-6:7005 --cluster-replicas 1 --cluster-yes

echo.
echo === Cluster Setup Complete ===
echo.

REM Show cluster status
echo Cluster nodes:
docker exec redis-node-1 redis-cli -p 7000 CLUSTER NODES

echo.
echo Cluster info:
docker exec redis-node-1 redis-cli -p 7000 CLUSTER INFO

echo.
echo To connect to the cluster:
echo   redis-cli -c -p 7000
echo.
echo Or via Docker:
echo   docker exec -it redis-node-1 redis-cli -c -p 7000
echo.
