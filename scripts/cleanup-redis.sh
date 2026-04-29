#!/usr/bin/env bash
set -euo pipefail

echo "Removing Redis container..."
docker rm -f redis 2>/dev/null || echo "No 'redis' container to remove."

echo "Removing Redis image..."
docker rmi redis/redis-stack:latest 2>/dev/null || echo "No redis-stack image to remove."

echo "Cleanup complete!"
