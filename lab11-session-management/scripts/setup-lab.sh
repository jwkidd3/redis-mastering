#!/usr/bin/env bash
set -euo pipefail

LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$LAB_DIR"

echo "═══════════════════════════════════════════════════════════"
echo "  Lab 11: Session Management — Setup"
echo "═══════════════════════════════════════════════════════════"

# 1. Verify Redis
REDIS_HOST="${REDIS_HOST:-localhost}"
REDIS_PORT="${REDIS_PORT:-6379}"
echo
echo "→ Checking Redis at ${REDIS_HOST}:${REDIS_PORT}..."
if command -v redis-cli >/dev/null 2>&1; then
    if redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" PING >/dev/null 2>&1; then
        echo "  ✓ Redis is responding (PONG)"
    else
        echo "  ✗ Redis is not responding."
        echo "    Start it with: bash ../scripts/start-redis.sh"
        exit 1
    fi
else
    echo "  ⚠ redis-cli not installed. Skipping ping check."
    echo "    Install with: bash ../scripts/install-redis-cli.sh"
fi

# 2. Install dependencies
echo
echo "→ Installing npm dependencies..."
npm install --silent
echo "  ✓ Dependencies installed"

# 3. Create config/.env if missing
echo
if [ -f config/.env ]; then
    echo "→ config/.env already exists — leaving it untouched."
else
    echo "→ Creating config/.env from config/.env.example..."
    cp config/.env.example config/.env
    # Default the host to localhost for student installs
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' 's/^REDIS_HOST=.*/REDIS_HOST=localhost/' config/.env
    else
        sed -i 's/^REDIS_HOST=.*/REDIS_HOST=localhost/' config/.env
    fi
    echo "  ✓ config/.env created (REDIS_HOST=localhost)"
fi

echo
echo "═══════════════════════════════════════════════════════════"
echo "  Setup complete."
echo "═══════════════════════════════════════════════════════════"
echo
echo "Next steps:"
echo "  npm test              # Run session tests"
echo "  npm run test-rbac     # Run RBAC tests"
echo "  npm run test-security # Run security tests"
echo "  node examples/basic-session-demo.js"
echo
