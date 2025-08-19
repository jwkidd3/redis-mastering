#!/bin/bash

echo "🚀 Setting up Insurance Microservices Architecture"
echo "=================================================="

# Function to check if port is available
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo "❌ Port $port is already in use"
        return 1
    else
        echo "✅ Port $port is available"
        return 0
    fi
}

# Check required ports
echo "🔍 Checking port availability..."
PORTS=(3000 3001 3002 3003 6379)
for port in "${PORTS[@]}"; do
    if ! check_port $port; then
        echo "Please free up port $port and try again"
        exit 1
    fi
done

# Create package.json files for each service
echo "📦 Creating package.json files..."

# Policy Service
cat > services/policy-service/package.json << 'EOL'
{
  "name": "policy-service",
  "version": "1.0.0",
  "description": "Insurance Policy Management Service",
  "main": "index.js",
  "scripts": {
    "start": "node index.js",
    "dev": "nodemon index.js",
    "test": "jest"
  },
  "dependencies": {
    "redis": "^4.6.0",
    "express": "^4.18.0",
    "cors": "^2.8.5",
    "uuid": "^9.0.0",
    "winston": "^3.8.0"
  },
  "keywords": ["redis", "microservices", "insurance", "policy"],
  "author": "Redis Course",
  "license": "MIT"
}
EOL

# Claims Service
cat > services/claims-service/package.json << 'EOL'
{
  "name": "claims-service",
  "version": "1.0.0",
  "description": "Insurance Claims Processing Service",
  "main": "index.js",
  "scripts": {
    "start": "node index.js",
    "dev": "nodemon index.js",
    "test": "jest"
  },
  "dependencies": {
    "redis": "^4.6.0",
    "express": "^4.18.0",
    "cors": "^2.8.5",
    "uuid": "^9.0.0",
    "winston": "^3.8.0"
  },
  "keywords": ["redis", "microservices", "insurance", "claims"],
  "author": "Redis Course",
  "license": "MIT"
}
EOL

# Customer Service
cat > services/customer-service/package.json << 'EOL'
{
  "name": "customer-service",
  "version": "1.0.0",
  "description": "Insurance Customer Management Service",
  "main": "index.js",
  "scripts": {
    "start": "node index.js",
    "dev": "nodemon index.js",
    "test": "jest"
  },
  "dependencies": {
    "redis": "^4.6.0",
    "express": "^4.18.0",
    "cors": "^2.8.5",
    "uuid": "^9.0.0",
    "winston": "^3.8.0"
  },
  "keywords": ["redis", "microservices", "insurance", "customer"],
  "author": "Redis Course",
  "license": "MIT"
}
EOL

# API Gateway
cat > services/api-gateway/package.json << 'EOL'
{
  "name": "api-gateway",
  "version": "1.0.0",
  "description": "Microservices API Gateway",
  "main": "index.js",
  "scripts": {
    "start": "node index.js",
    "dev": "nodemon index.js",
    "test": "jest"
  },
  "dependencies": {
    "redis": "^4.6.0",
    "express": "^4.18.0",
    "cors": "^2.8.5",
    "http-proxy-middleware": "^2.0.0",
    "winston": "^3.8.0"
  },
  "keywords": ["redis", "microservices", "api-gateway"],
  "author": "Redis Course",
  "license": "MIT"
}
EOL

# Install dependencies for each service
echo "📥 Installing dependencies..."

cd services/policy-service && npm install && cd ../..
cd services/claims-service && npm install && cd ../..
cd services/customer-service && npm install && cd ../..
cd services/api-gateway && npm install && cd ../..

echo ""
echo "✅ Microservices setup complete!"
echo ""
echo "🚀 To start the services:"
echo "1. Terminal 1: cd services/policy-service && npm start"
echo "2. Terminal 2: cd services/claims-service && npm start"
echo "3. Terminal 3: cd services/customer-service && npm start"
echo "4. Terminal 4: cd services/api-gateway && npm start"
echo ""
echo "🌐 Access points:"
echo "• API Gateway: http://localhost:3000"
echo "• Policy Service: http://localhost:3001"
echo "• Claims Service: http://localhost:3002"
echo "• Customer Service: http://localhost:3003"
echo ""
echo "🔧 Health checks:"
echo "curl http://localhost:3000/health"
echo "curl http://localhost:3001/health"
echo "curl http://localhost:3002/health"
echo "curl http://localhost:3003/health"
