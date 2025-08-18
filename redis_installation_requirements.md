# Redis Mastering Course - Software Installation Requirements

## Required Software Installation

### 1. Docker Desktop
- **Purpose**: Container platform for Redis instances and lab environments
- **Installation**: Download from [docker.com](https://www.docker.com/products/docker-desktop/)
- **Platform Support**: Windows 10/11 Pro/Enterprise, macOS 10.15+
- **Why needed**: Provides consistent Redis environment across platforms, eliminates local Redis installation complexity

### 2. Node.js (LTS Version)
- **Purpose**: JavaScript runtime for Redis client applications
- **Version**: Latest LTS (currently 18.x or 20.x)
- **Installation**: Download from [nodejs.org](https://nodejs.org/)
- **Includes**: npm (Node Package Manager)
- **Platform Support**: Windows, macOS, Linux

### 3. Visual Studio Code
- **Purpose**: Primary development environment
- **Installation**: Download from [code.visualstudio.com](https://code.visualstudio.com/)
- **Platform Support**: Windows, macOS, Linux

### 4. Redis Insight
- **Purpose**: Redis GUI tool for visualization and CLI access
- **Installation**: Download from [Redis website](https://redis.io/insight/)
- **Platform Support**: Windows, macOS, Linux
- **Features**: Built-in Redis CLI, memory analysis, real-time monitoring

## Required Node.js Packages

Students will install these during the course setup:

```bash
# Core Redis client
npm install redis

# Web framework for API labs
npm install express

# Additional utilities
npm install dotenv          # Environment variables
npm install cors            # Cross-origin requests
npm install body-parser     # Request parsing
npm install helmet          # Security headers
npm install morgan          # HTTP logging
npm install uuid            # Unique ID generation
npm install bcrypt          # Password hashing (for session labs)
npm install jsonwebtoken    # JWT tokens (for session labs)
```

## Recommended VS Code Extensions

For enhanced JavaScript/Redis development:

- **JavaScript (ES6) code snippets**
- **Docker** - Container management
- **Redis** - Redis syntax highlighting
- **Prettier** - Code formatting
- **ESLint** - JavaScript linting
- **Thunder Client** - API testing (alternative to Postman)

## Docker Images Required

These will be pulled during course setup:

```bash
# Official Redis image
docker pull redis:7-alpine

# Node.js base image (for containerized labs)
docker pull node:18-alpine

# Redis with modules (if needed for advanced labs)
docker pull redis/redis-stack:latest
```

## Pre-Course Setup Script

Students can run this setup script before the course:

```bash
#!/bin/bash
# Course setup script

# Create course directory
mkdir redis-mastering-course
cd redis-mastering-course

# Initialize Node.js project
npm init -y

# Install required packages
npm install redis express dotenv cors body-parser helmet morgan uuid bcrypt jsonwebtoken

# Pull Docker images
docker pull redis:7-alpine
docker pull node:18-alpine
docker pull redis/redis-stack:latest

# Create basic project structure
mkdir labs
mkdir presentations
mkdir docker-configs

echo "Setup complete! Ready for Redis Mastering Course."
```

## System Requirements

### Minimum Hardware
- **RAM**: 8GB (16GB recommended)
- **Storage**: 10GB free space
- **CPU**: Dual-core processor
- **Network**: Internet connection for package downloads

### Operating System Support
- **Windows**: Windows 10/11 (Docker Desktop requires Pro/Enterprise for Windows 10)
- **macOS**: macOS 10.15 (Catalina) or later
- **Linux**: Ubuntu 18.04+, CentOS 7+, or equivalent

## Installation Verification

Students should verify their setup with these commands:

```bash
# Check Node.js and npm
node --version
npm --version

# Check Docker
docker --version
docker run hello-world

# Test Redis connection
docker run --rm redis:7-alpine redis-cli --version

# Check VS Code
code --version
```

This installation setup ensures all students have a consistent, cross-platform development environment that supports all course labs and activities using Docker, JavaScript/Node.js, Redis Insight, and Visual Studio Code.