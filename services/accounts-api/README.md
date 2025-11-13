# Accounts API - GraphQL Subgraph

Apollo Federation subgraph service for managing customer accounts, deployed on AWS EKS.

---

## 📋 Overview

The Accounts API is a GraphQL subgraph that provides account management functionality as part of the WorldKinect federated GraphQL architecture. It exposes account data, billing information, and account-related operations through a GraphQL API.

**Technology Stack:**
- TypeScript
- Apollo Server v5
- Apollo Federation (Subgraph)
- Node.js 20+
- Docker
- Kubernetes (EKS)

---

## 🚀 Quick Start

### Local Development

```bash
# Install dependencies
npm install

# Build TypeScript
npm run build

# Run in development mode (with hot reload)
npm run dev

# Access GraphQL Playground
open http://localhost:4000
```

### Docker

```bash
# Build Docker image
npm run docker:build

# Run container
npm run docker:run

# Test health endpoint
curl http://localhost:4000/.well-known/apollo/server-health
```

---

## 📁 Project Structure

```
services/accounts-api/
├── src/
│   ├── index.ts          # Entry point - Apollo Server setup
│   ├── schema.ts         # GraphQL schema (typeDefs)
│   ├── resolvers.ts      # GraphQL resolvers
│   └── types.ts          # TypeScript type definitions
├── kubernetes/
│   ├── deployment.yaml   # K8s deployment manifest
│   └── serviceaccount.yaml  # IAM role for service account
├── dist/                 # Compiled JavaScript (generated)
├── node_modules/         # Dependencies (generated)
├── Dockerfile            # Container definition
├── .dockerignore         # Docker ignore rules
├── package.json          # Dependencies and scripts
├── tsconfig.json         # TypeScript configuration
└── README.md             # This file
```

---

## 🔧 Available Scripts

```bash
# Development
npm run dev              # Run with hot reload
npm run build            # Compile TypeScript
npm start                # Run compiled code

# Testing
npm test                 # Run tests
npm run test:watch       # Run tests in watch mode
npm run test:coverage    # Generate coverage report

# Code Quality
npm run type-check       # Check TypeScript types
npm run lint             # Run ESLint
npm run lint:fix         # Fix linting issues
npm run format           # Format with Prettier
npm run format:check     # Check formatting

# Docker
npm run docker:build     # Build Docker image
npm run docker:run       # Run Docker container

# Utilities
npm run clean            # Remove dist/ directory
```

---

## 📊 GraphQL Schema

### Types

```graphql
type Account @key(fields: "id") {
  id: ID!
  accountNumber: String!
  companyName: String!
  contactName: String
  contactEmail: String
  contactPhone: String
  status: AccountStatus!
  billingAddress: Address
  shippingAddress: Address
  creditLimit: Float
  currentBalance: Float
  createdAt: String!
  updatedAt: String!
}

type Address {
  street: String
  city: String
  state: String
  postalCode: String
  country: String
}

enum AccountStatus {
  ACTIVE
  INACTIVE
  SUSPENDED
  PENDING
}
```

### Queries

```graphql
# Get single account by ID
query {
  account(id: "1") {
    id
    companyName
    status
  }
}

# Get paginated list of accounts
query {
  accounts(limit: 10, offset: 0) {
    nodes {
      id
      accountNumber
      companyName
    }
    totalCount
    hasNextPage
  }
}

# Search accounts
query {
  searchAccounts(query: "acme") {
    id
    companyName
    contactEmail
  }
}
```

---

## 🔌 Federation

This service is part of an Apollo Federation supergraph. It extends the `Account` entity that can be referenced by other subgraphs.

### Entity Resolution

```typescript
// Other subgraphs can reference Account
type Order @key(fields: "id") {
  id: ID!
  account: Account  # Reference to accounts subgraph
}
```

### Subgraph Configuration

```yaml
# In Apollo Router config
subgraphs:
  - name: accounts
    url: http://accounts-api.default.svc.cluster.local:4000/graphql
```

---

## 🐳 Docker

### Build Image

```bash
docker build -t accounts-api:latest .
```

### Run Container

```bash
docker run -p 4000:4000 \
  -e NODE_ENV=production \
  -e PORT=4000 \
  accounts-api:latest
```

### Multi-stage Build

The Dockerfile uses a multi-stage build for optimization:
1. **Build stage:** Compiles TypeScript
2. **Production stage:** Runs compiled JavaScript (smaller image)

---

## ☸️ Kubernetes Deployment

### Deploy to EKS

```bash
# Apply Kubernetes manifests
kubectl apply -f kubernetes/

# Verify deployment
kubectl get pods -l app=accounts-api
kubectl get svc accounts-api

# View logs
kubectl logs -l app=accounts-api -f
```

### Horizontal Pod Autoscaling

The deployment includes HPA configuration:
- Min replicas: 2
- Max replicas: 10
- Target CPU: 70%
- Target Memory: 80%

```bash
# Check HPA status
kubectl get hpa accounts-api-hpa
```

---

## 🧪 Testing

### Unit Tests

```bash
npm test
```

### Integration Tests

```bash
# Start the service
npm run dev

# Test GraphQL queries
curl -X POST http://localhost:4000/graphql \
  -H "Content-Type: application/json" \
  -d '{"query":"{ accounts { nodes { id } } }"}'
```

### Health Checks

```bash
# Health endpoint
curl http://localhost:4000/.well-known/apollo/server-health

# Should return: {"status":"pass"}
```

---

## 🔐 Environment Variables

```bash
# Server Configuration
NODE_ENV=production          # Environment (development/production)
PORT=4000                    # Server port

# Apollo Configuration
APOLLO_GRAPH_REF=           # Apollo Studio graph reference
APOLLO_KEY=                 # Apollo Studio API key

# Logging
LOG_LEVEL=info              # Log level (debug/info/warn/error)

# Database (when integrated)
DATABASE_URL=               # Database connection string
DB_POOL_MIN=2              # Connection pool min
DB_POOL_MAX=10             # Connection pool max

# AWS (if needed)
AWS_REGION=us-east-1       # AWS region
```

---

## 🔍 Monitoring

### Metrics

The service exposes Apollo Server metrics:
- Request rate
- Error rate
- Response time
- Resolver performance

### Logs

Structured JSON logging for easy parsing:

```typescript
console.log(JSON.stringify({
  level: 'info',
  message: 'Account fetched',
  accountId: '123',
  timestamp: new Date().toISOString()
}));
```

### Health Checks

Kubernetes uses these probes:
- **Liveness:** `/.well-known/apollo/server-health`
- **Readiness:** `/.well-known/apollo/server-health`

---

## 🚢 CI/CD

### Automated Deployment

Deployments are automated via:
- **GitHub Actions:** On push to main/staging/prod branches
- **Jenkins:** Manual or scheduled deployments
- **Scripts:** `../../scripts/ci-cd-pipeline.sh`

### Manual Deployment

```bash
# From project root
cd ~/worldkinect

# Build and push to ECR
./scripts/build-and-push.sh

# Deploy to EKS
./scripts/deploy-to-eks.sh

# Or run complete pipeline
./scripts/ci-cd-pipeline.sh
```

---

## 🐛 Troubleshooting

### Port Already in Use

```bash
# Find and kill process using port 4000
lsof -ti:4000 | xargs kill -9

# Or use a different port
PORT=4001 npm run dev
```

### TypeScript Errors

```bash
# Clean and rebuild
npm run clean
npm run build

# Check types
npm run type-check
```

### Docker Build Issues

```bash
# Build without cache
docker build --no-cache -t accounts-api:latest .

# Check logs
docker logs <container-id>
```

### Pod Issues in Kubernetes

```bash
# Describe pod
kubectl describe pod <pod-name>

# View logs
kubectl logs <pod-name>

# Get previous logs (if crashed)
kubectl logs <pod-name> --previous

# Execute into pod
kubectl exec -it <pod-name> -- /bin/sh
```

---

## 📚 Documentation

For more detailed information, see:

- **[IAM Setup Guide](../../docs/guides/01-iam-setup.md)** - AWS permissions
- **[Local Development Guide](../../docs/guides/04-local-development.md)** - Development workflow
- **[EKS Migration Guide](../../docs/guides/03-eks-migration.md)** - Migration from Lambda
- **[CI/CD Automation](../../docs/guides/05-cicd-automation.md)** - Deployment pipelines

---

## 🔗 Related Services

This subgraph is part of the WorldKinect federated graph:

- **Apollo Router** - Federation gateway
- **Orders Subgraph** - Order management
- **Products Subgraph** - Product catalog
- **Accounts Subgraph** - This service

---

## 🎯 Next Steps

1. **Add database integration** - Connect to RDS/DynamoDB
2. **Implement authentication** - Add JWT validation
3. **Add caching** - Response caching with Redis
4. **Enhance monitoring** - Add Prometheus metrics
5. **Add more tests** - Increase coverage
6. **Implement DataLoader** - Optimize N+1 queries

---

## 📞 Support

- **Documentation:** [../../docs/](../../docs/)
- **Issues:** GitHub Issues
- **Main README:** [../../README.md](../../README.md)

---

**Last Updated:** 2025-01-13
