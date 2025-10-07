@echo off
echo Removing Redis container...
docker rm -f redis

echo Removing Redis image...
docker rmi redis/redis-stack:latest

echo Cleanup complete!
