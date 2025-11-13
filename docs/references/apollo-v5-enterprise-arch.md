# Enterprise GraphQL Server Architecture

## 🏗️ Architecture Overview

This is an **enterprise-grade Apollo GraphQL server** built for high-transaction systems with:

- **Express.js** integration for middleware support
- **Connection pooling** (PostgreSQL + Redis)
- **JWT authentication** & role-based authorization
- **Distributed tracing** with transaction IDs
- **Structured logging** (Winston)
- **Health checks** & metrics
- **Graceful shutdown** handling
- **Database transactions** with rollback support
- **Response caching** (Redis)
- **Security hardening** (Helmet, CORS, rate limiting)

---

## 📁 Project Structure

```
src/
├── index.ts                    # Main server setup with Express
├── types.ts                    # TypeScript interfaces
├── schema.ts                   # GraphQL schema definitions
├── resolvers.ts                # Resolver implementations
├── datasources.ts              # Database & cache connections
├── auth.ts                     # JWT authentication
├── logger.ts                   # Winston logger config
└── monitoring.ts               # Health checks & metrics
```

---

## 🚀 Key Changes from `startStandaloneServer`

### Before (Standalone):
```typescript
import { startStandaloneServer } from '@apollo/server/standalone';

startStandaloneServer(server, {
  listen: { port: 4000 },
});
```

### After (Enterprise with Express):
```typescript
import express from 'express';
import { expressMiddleware } from '@apollo/server/express4';

const app = express();
const httpServer = http.createServer(app);

// Add middleware
app.use(helmet());
app.use(cors());
app.use(compression());
app.get('/health', healthCheck);

// GraphQL endpoint with context
app.use('/graphql', 
  json(),
  expressMiddleware(server, {
    context: async ({ req }) => ({
      user: await authenticateRequest(req),
      dataSources: await createDataSources(),
      transactionId: req.headers['x-transaction-id'],
    })
  })
);

httpServer.listen(PORT);
```

---

## 🔑 Enterprise Features

### 1. **Connection Pooling**
- PostgreSQL connection pool (max 20 connections)
- Redis connection with retry logic
- Automatic connection health monitoring

### 2. **Authentication & Authorization**
```typescript
// JWT-based authentication
const user = await authenticateRequest(req);

// Role-based access control
requireRole(user, 'admin');
requirePermission(user, 'customer:read');
```

### 3. **Database Transactions**
```typescript
// Atomic operations with rollback
await dataSources.db.transaction(async (trx) => {
  await trx.query('INSERT INTO customers ...');
  await trx.query('INSERT INTO audit_log ...');
  // Auto-rollback on error
});
```

### 4. **Response Caching**
```typescript
// Check cache first
const cached = await dataSources.cache.get(`customer:${id}`);
if (cached) return JSON.parse(cached);

// Cache for 5 minutes
await dataSources.cache.set(cacheKey, JSON.stringify(data), 300);
```

### 5. **Distributed Tracing**
```typescript
// Track requests across services
const transactionId = req.headers['x-transaction-id'] || crypto.randomUUID();
logger.child({ transactionId });
```

### 6. **Graceful Shutdown**
```typescript
// On SIGTERM/SIGINT:
// 1. Stop accepting new connections
// 2. Finish in-flight requests
// 3. Close database connections
// 4. Exit cleanly
```

### 7. **Health Checks**
```bash
# Kubernetes/Docker health checks
curl http://localhost:4000/health
curl http://localhost:4000/ready
```

---

## 🛠️ Installation

```bash
# Install dependencies
npm install

# Copy environment variables
cp .env.example .env

# Edit .env with your configuration
nano .env

# Run in development
npm run dev

# Build for production
npm run build

# Run in production
npm start
```

---

## 📊 Monitoring & Observability

### Metrics Endpoint
```bash
curl http://localhost:4000/metrics
```

Returns:
```json
{
  "totalRequests": 1523,
  "totalErrors": 12,
  "errorRate": "0.79%",
  "avgLatency": 45,
  "p95Latency": 120,
  "uptime": 3600
}
```

### Structured Logging
```typescript
// Contextual logging with transaction IDs
logger.info('Customer created', { 
  customerId, 
  userId, 
  transactionId 
});
```

Logs output:
```json
{
  "level": "info",
  "message": "Customer created",
  "customerId": "CUST-1001",
  "userId": "USER-123",
  "transactionId": "abc-123-xyz",
  "timestamp": "2025-11-05T12:00:00.000Z"
}
```

---

## 🔒 Security Features

1. **Helmet.js** - Security headers
2. **CORS** - Whitelist allowed origins
3. **JWT** - Token-based authentication
4. **Input validation** - GraphQL schema validation
5. **Rate limiting** - (Add express-rate-limit)
6. **SQL injection protection** - Parameterized queries
7. **Error masking** - Hide internal errors in production

---

## 🧪 Testing

```bash
# Run tests
npm test

# Type checking
npm run type-check

# Linting
npm run lint
```

---

## 🚢 Production Deployment

### Docker
```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY dist ./dist
CMD ["node", "dist/index.js"]
```

### Kubernetes
```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 4000
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /ready
    port: 4000
  initialDelaySeconds: 5
  periodSeconds: 5
```

---

## 📈 Performance Considerations

1. **Connection Pooling** - Reuse database connections
2. **Redis Caching** - Reduce database load
3. **Compression** - gzip response bodies
4. **Query Batching** - Use DataLoader for N+1 queries
5. **Index Database** - Proper indexes on frequently queried columns
6. **CDN** - Cache static GraphQL schema introspection

---

## 🔄 Migration Path

**Step 1**: Replace `startStandaloneServer` with Express  
**Step 2**: Add database connection pooling  
**Step 3**: Implement JWT authentication  
**Step 4**: Add Redis caching layer  
**Step 5**: Set up monitoring & logging  
**Step 6**: Implement health checks  
**Step 7**: Add graceful shutdown  

---

## 📚 Additional Resources

- [Apollo Server Docs](https://www.apollographql.com/docs/apollo-server/)
- [Express.js Best Practices](https://expressjs.com/en/advanced/best-practice-security.html)
- [PostgreSQL Connection Pooling](https://node-postgres.com/features/pooling)
- [Winston Logging](https://github.com/winstonjs/winston)

---

## 📝 License

MIT