# Lab 6 Setup Guide

## Quick Setup (Recommended)

```bash
# 1. Run setup script
./scripts/setup-lab.sh

# 2. Initialize project
./scripts/quick-start.sh

# 3. Update environment
nano .env  # Edit with Redis server details

# 4. Validate setup
./scripts/validate-setup.sh

# 5. Start lab
open lab6.md  # Follow lab instructions
```

## Manual Setup

### Prerequisites
- Node.js 16+ installed
- npm package manager
- Redis server details from instructor

### Steps
1. **Initialize Node.js project:**
   ```bash
   cp package.json.template package.json
   npm install
   ```

2. **Configure environment:**
   ```bash
   cp .env.template .env
   # Edit .env with actual Redis server details
   ```

3. **Test connection:**
   ```bash
   npm run test
   ```

4. **Start development:**
   ```bash
   npm run dev
   ```

## Docker Setup (Alternative)

```bash
# Build and run with Docker
docker-compose up -d

# Access container
docker exec -it lab6-javascript-redis bash

# Run lab commands inside container
npm test
npm start
```

## VS Code Integration

1. **Open project in VS Code:**
   ```bash
   code .
   ```

2. **Install recommended extensions** (VS Code will prompt)

3. **Use debugging configurations:**
   - F5: Run main application
   - Ctrl+Shift+P: Run tasks (test, examples, etc.)

## Troubleshooting

### Quick Fixes
```bash
# Reset everything
./scripts/reset-lab.sh

# Validate setup
./scripts/validate-setup.sh

# Check completion
./scripts/verify-completion.sh
```

### Common Issues
- **Connection refused:** Check .env file
- **Module not found:** Run `npm install`
- **Permission denied:** Run `chmod +x scripts/*.sh`

## Lab Progress

- [ ] Environment setup complete
- [ ] Redis connection successful
- [ ] Customer model working
- [ ] Policy model working
- [ ] Examples run successfully
- [ ] Performance tests complete
- [ ] Redis Insight integration
- [ ] Lab verification passed

## Getting Help

1. **Check troubleshooting guide:** `docs/troubleshooting.md`
2. **Validate your setup:** `./scripts/validate-setup.sh`
3. **Review patterns:** `docs/javascript-patterns.md`
4. **Contact instructor** with diagnostic info from validation script

## Next Lab Preview

**Lab 7: Advanced Data Structures** - Redis Hashes for complex customer profiles and nested policy management with field-level operations.
