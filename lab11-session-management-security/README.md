# Lab 11: Session Management & Security for Business Systems

**Duration:** 45 minutes  
**Focus:** JavaScript-based session management, authentication, and security patterns  
**Technologies:** Node.js, Redis, JWT, bcrypt

## 📁 Project Structure

```
lab11-session-management-security/
├── lab11.md                    # Complete lab instructions (START HERE)
├── src/
│   ├── session-manager.js      # Core session management system
│   ├── auth-manager.js         # Authentication and authorization
│   └── index.js                # Express server integration
├── tests/
│   └── test-security.js        # Comprehensive security tests
├── scripts/
│   └── load-security-data.sh   # Sample data loader
├── package.json                # Node.js dependencies
├── .env.example                # Environment configuration template
└── README.md                   # This file
```

## 🚀 Quick Start

1. **Install Dependencies:**
   ```bash
   npm install
   ```

2. **Start Redis:**
   ```bash
   docker run -d --name redis-security-lab11 -p 6379:6379 redis:7-alpine
   ```

3. **Load Sample Data:**
   ```bash
   ./scripts/load-security-data.sh
   ```

4. **Run Tests:**
   ```bash
   npm test
   ```

5. **Start Server:**
   ```bash
   npm start
   ```

## 🔒 Security Features

### Session Management
- Secure token generation with crypto
- Session expiration and renewal
- Concurrent session limits
- Session activity tracking
- Automatic cleanup of expired sessions

### Authentication
- Password hashing with bcrypt
- Rate limiting on login attempts
- Account lockout after failed attempts
- JWT token generation and validation
- Password history to prevent reuse

### Authorization
- Role-based access control (RBAC)
- Dynamic permission management
- Permission caching for performance
- Middleware for protected routes

### Security Monitoring
- Authentication event logging
- Security breach detection
- Real-time analytics
- Audit trail maintenance

## 🧪 Testing

Run the comprehensive test suite:

```bash
npm test
```

Tests cover:
- User registration and authentication
- Session creation and management
- Rate limiting and account lockout
- Permission verification
- Password management
- Performance benchmarks

## 🚀 Production Deployment

### Environment Variables

Copy `.env.example` to `.env` and configure:

```bash
cp .env.example .env
```

### Security Checklist

- [ ] Change JWT_SECRET to strong random value
- [ ] Enable Redis AUTH with password
- [ ] Configure TLS/SSL for Redis
- [ ] Set up rate limiting
- [ ] Enable monitoring and alerting
- [ ] Regular security audits
- [ ] Backup authentication data
- [ ] Test disaster recovery

### Docker Deployment

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3000
CMD ["node", "src/index.js"]
```

## 📊 API Endpoints

### Authentication
- `POST /api/login` - User login
- `POST /api/logout` - User logout
- `POST /api/register` - User registration
- `POST /api/refresh` - Refresh session

### Protected Routes
- `GET /api/protected/data` - Protected data access
- `GET /api/protected/profile` - User profile
- `PUT /api/protected/password` - Change password

### Health & Monitoring
- `GET /health` - System health check
- `GET /metrics` - Performance metrics

## 🎯 Learning Objectives Achieved

✅ Secure session storage and management  
✅ Authentication with rate limiting  
✅ Role-based access control (RBAC)  
✅ Password security best practices  
✅ Security event monitoring  
✅ Production-ready patterns  

## 📚 Additional Resources

- [Redis Security](https://redis.io/topics/security)
- [OWASP Session Management](https://owasp.org/www-community/attacks/Session_hijacking_attack)
- [JWT Best Practices](https://tools.ietf.org/html/rfc8725)
- [bcrypt Documentation](https://github.com/kelektiv/node.bcrypt.js)

## 🆘 Troubleshooting

**Redis Connection Issues:**
```bash
redis-cli ping
docker logs redis-security-lab11
```

**Authentication Failures:**
- Check Redis for user data
- Verify password hashing
- Check rate limiting status

**Session Issues:**
- Verify TTL settings
- Check session storage
- Monitor session analytics

---

**Ready to start?** Open `lab11.md` and begin implementing enterprise security! 🔐
