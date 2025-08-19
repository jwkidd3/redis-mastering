# Lab 6 Docker Environment
# Node.js Redis Client Development Environment

FROM node:18-alpine

# Set working directory
WORKDIR /app

# Create lab user
RUN addgroup -g 1001 -S labuser && \
    adduser -S labuser -G labuser -u 1001

# Install system dependencies
RUN apk add --no-cache \
    bash \
    curl \
    redis \
    git

# Copy package files
COPY package.json.template package.json
RUN npm install

# Copy lab files
COPY . .

# Set permissions
RUN chown -R labuser:labuser /app

# Switch to lab user
USER labuser

# Expose port for potential web interface
EXPOSE 3000

# Default command
CMD ["bash", "-c", "echo 'Lab 6 Environment Ready!' && echo 'Run: npm test (test connection)' && echo 'Run: npm start (main app)' && bash"]
