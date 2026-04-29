#!/usr/bin/env bash
set -euo pipefail

echo "Stopping Redis container..."
docker stop redis
echo "Redis container stopped!"
