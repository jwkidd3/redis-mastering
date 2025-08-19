# Lab 11: Customer Portal Session Management & Security

## Quick Start

1. **Setup Environment:**
   ```bash
   ./setup-lab.sh
   ```

2. **Configure Redis Connection:**
   ```bash
   # Update .env file with instructor-provided details
   cp config/.env.example .env
   # Edit .env with your Redis host information
   ```

3. **Test Installation:**
   ```bash
   ./test-lab.sh
   ```

4. **Follow Lab Instructions:**
   ```bash
   # Open lab11.md and follow the step-by-step guide
   ```

## What You'll Learn

- JWT-based session management with Redis
- Role-based access control implementation
- Security monitoring and threat detection
- Session lifecycle management
- Customer portal security patterns

## Key Components

- `src/sessionManager.js` - Core session management
- `src/accessControl.js` - Role-based access control
- `src/securityMonitor.js` - Security monitoring
- `examples/` - Test scripts and demonstrations

## Duration

45 minutes of hands-on exercises covering session security fundamentals.

## Prerequisites

- Node.js and npm installed
- Redis CLI tools
- Redis Insight (recommended)
- Access to Redis server (provided by instructor)
