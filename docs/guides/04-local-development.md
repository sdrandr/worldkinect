# Local Development Guide

Complete guide for setting up and running the Accounts API on your Mac for local development.

---

## 🎯 Prerequisites

### Required Software

```bash
# Check Node.js version (need 20+)
node --version

# Check npm version
npm --version

# Check Docker
docker --version

# Check AWS CLI
aws --version

# Check kubectl
kubectl version --client
```

### Install Missing Tools

```bash
# Install Node.js 20 (using nvm)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install 20
nvm use 20

# Install Docker Desktop
# Download from: https://www.docker.com/products/docker-desktop

# Install AWS CLI
brew install awscli

# Install kubectl
brew install kubectl

# Install jq (useful for JSON parsing)
brew install jq
```

---

## ⚙️ Initial Setup

### 1. Clone Repository

```bash
# Clone the repo
git clone https://github.com/<your-org>/worldkinect.git
cd worldkinect
```

### 2. Configure AWS CLI

```bash
# Configure with terraform-admin credentials
aws configure

# Verify
aws sts get-caller-identity
# Should show: terraform-admin
```

### 3. Configure kubectl for EKS

```bash
# Update kubeconfig for dev cluster
aws eks update-kubeconfig \
  --region us-east-1 \
  --name worldkinect-dev

# Verify connection
kubectl get nodes
```

---

## 🚀 Running Locally

### Option 1: Native Node.js (Fastest for Development)

```bash
# Navigate to service
cd services/accounts-api

# Install dependencies
npm install

# Build TypeScript
npm run build

# Run in development mode (with hot reload)
npm run dev

# Or run built version
npm start
```

**Access the service:**
- GraphQL Playground: http://localhost:4000
- Health check: http://localhost:4000/.well-known/apollo/server-health

**Test queries:**
```graphql
# In GraphQL Playground (http://localhost:4000)

# Get all accounts
query {
  accounts {
    nodes {
      id
      accountNumber
      companyName
      status
    }
    totalCount
  }
}

# Get single account
query {
  account(id: "1") {
    id
    accountNumber
    companyName
    billingAddress {
      street
      city
      state
      postalCode
    }
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

### Option 2: Docker (Production-like Environment)

```bash
cd services/accounts-api

# Build Docker image
npm run docker:build
# or: docker build -t accounts-api:latest .

# Run container
npm run docker:run
# or: docker run -p 4000:4000 accounts-api:latest

# View logs
docker logs -f <container-id>

# Stop container
docker stop <container-id>
```

**Test the container:**
```bash
# Health check
curl http://localhost:4000/.well-known/apollo/server-health

# GraphQL query
curl -X POST http://localhost:4000/graphql \
  -H "Content-Type: application/json" \
  -d '{"query":"{ accounts { nodes { id companyName } } }"}'
```

---

### Option 3: Docker Compose (Full Stack)

Create `docker-compose.yml` in project root:

```yaml
version: '3.8'

services:
  accounts-api:
    build:
      context: ./services/accounts-api
      dockerfile: Dockerfile
    ports:
      - "4000:4000"
    environment:
      - NODE_ENV=development
      - PORT=4000
    volumes:
      - ./services/accounts-api/src:/app/src
    command: npm run dev
```

**Run:**
```bash
# Start all services
docker-compose up

# Run in background
docker-compose up -d

# View logs
docker-compose logs -f accounts-api

# Stop
docker-compose down
```

---

## 🧪 Testing

### Run Tests

```bash
cd services/accounts-api

# Run all tests
npm test

# Run tests in watch mode
npm run test:watch

# Run tests with coverage
npm run test:coverage

# View coverage report
open coverage/lcov-report/index.html
```

### Type Checking

```bash
# Check TypeScript types
npm run type-check

# Watch mode for type checking
npm run type-check -- --watch
```

### Linting

```bash
# Run linter
npm run lint

# Fix linting issues automatically
npm run lint:fix

# Format code with Prettier
npm run format

# Check formatting without changing
npm run format:check
```

---

## 🔧 Development Workflow

### Typical Development Cycle

```bash
# 1. Create feature branch
git checkout -b feature/add-mutation

# 2. Start dev server (with hot reload)
npm run dev

# 3. Make changes to src/ files
# Changes auto-reload in dev mode

# 4. Test your changes
npm test

# 5. Type check
npm run type-check

# 6. Lint
npm run lint:fix

# 7. Commit
git add .
git commit -m "feat: add new mutation"

# 8. Push
git push origin feature/add-mutation
```

---

## 🗂️ Project Structure

```
services/accounts-api/
├── src/
│   ├── index.ts           # Entry point (Apollo Server setup)
│   ├── schema.ts          # GraphQL schema (typeDefs)
│   ├── resolvers.ts       # GraphQL resolvers
│   └── types.ts           # TypeScript types
├── dist/                  # Compiled JavaScript (generated)
├── node_modules/          # Dependencies (generated)
├── kubernetes/            # K8s manifests
│   ├── deployment.yaml
│   └── serviceaccount.yaml
├── Dockerfile             # Container definition
├── .dockerignore
├── package.json           # Dependencies and scripts
├── tsconfig.json          # TypeScript config
└── README.md
```

---

## 🎨 VSCode Setup (Recommended)

### Install Extensions

```bash
# Install recommended extensions
code --install-extension dbaeumer.vscode-eslint
code --install-extension esbenp.prettier-vscode
code --install-extension GraphQL.vscode-graphql
code --install-extension ms-azuretools.vscode-docker
```

### Workspace Settings

Create `.vscode/settings.json`:

```json
{
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true
  },
  "typescript.tsdk": "node_modules/typescript/lib",
  "files.exclude": {
    "**/.git": true,
    "**/node_modules": true,
    "**/dist": true
  }
}
```

### Recommended Tasks

Create `.vscode/tasks.json`:

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "npm: dev",
      "type": "npm",
      "script": "dev",
      "problemMatcher": [],
      "presentation": {
        "reveal": "always"
      },
      "group": {
        "kind": "build",
        "isDefault": true
      }
    },
    {
      "label": "npm: test",
      "type": "npm",
      "script": "test",
      "problemMatcher": [],
      "presentation": {
        "reveal": "always"
      }
    }
  ]
}
```

---

## 📝 Environment Variables

### Development

Create `.env.local` (not committed to git):

```bash
NODE_ENV=development
PORT=4000
LOG_LEVEL=debug

# Database (when you add it)
# DATABASE_URL=postgresql://localhost:5432/accounts
# DB_POOL_MIN=2
# DB_POOL_MAX=10

# AWS (optional for local dev)
# AWS_REGION=us-east-1
# AWS_ACCOUNT_ID=123456789012
```

### Loading Environment Variables

Update `src/index.ts`:

```typescript
import dotenv from 'dotenv';

// Load .env.local in development
if (process.env.NODE_ENV !== 'production') {
  dotenv.config({ path: '.env.local' });
}
```

---

## 🐛 Debugging

### VSCode Debugger

Create `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "node",
      "request": "launch",
      "name": "Debug Accounts API",
      "skipFiles": ["<node_internals>/**"],
      "program": "${workspaceFolder}/services/accounts-api/dist/index.js",
      "preLaunchTask": "npm: build",
      "outFiles": ["${workspaceFolder}/services/accounts-api/dist/**/*.js"],
      "env": {
        "NODE_ENV": "development"
      }
    }
  ]
}
```

### Console Debugging

```typescript
// Add debugging logs in your code
console.log('Query received:', { id });
console.log('Account found:', account);

// Or use a proper logger
import pino from 'pino';
const logger = pino();

logger.info({ id }, 'Fetching account');
logger.error({ error }, 'Failed to fetch account');
```

---

## 🔌 Connecting to Remote Services

### Port Forward to EKS Services

```bash
# Port forward accounts-api
kubectl port-forward -n default svc/accounts-api 4001:4000

# Port forward Apollo Router
kubectl port-forward -n default svc/apollo-router 8080:80

# Now you can access:
# Accounts API: http://localhost:4001
# Router: http://localhost:8080
```

### Test Federation Locally

```bash
# Start your local accounts-api
npm run dev  # Running on port 4000

# In another terminal, start Apollo Router pointing to local
# (You'll need rover CLI)
rover dev \
  --name accounts \
  --url http://localhost:4000/graphql
```

---

## 🧹 Cleanup

```bash
# Clean build artifacts
npm run clean

# Remove node_modules
rm -rf node_modules

# Fresh install
npm install

# Clean Docker
docker system prune -a

# Remove all accounts-api images
docker rmi $(docker images -q accounts-api)
```

---

## 🔥 Hot Tips

### Speed Up Development

```bash
# Use nodemon for auto-restart
npm run dev  # Already configured

# Keep TypeScript compiler running
npm run build:watch  # In separate terminal

# Use Docker BuildKit for faster builds
export DOCKER_BUILDKIT=1
docker build -t accounts-api:latest .
```

### Useful Aliases

Add to `~/.zshrc` or `~/.bash_profile`:

```bash
# Navigate to service
alias cda='cd ~/worldkinect/services/accounts-api'

# Quick test
alias atest='cd ~/worldkinect/services/accounts-api && npm test'

# Quick dev
alias adev='cd ~/worldkinect/services/accounts-api && npm run dev'

# Quick lint
alias alint='cd ~/worldkinect/services/accounts-api && npm run lint:fix'

# Check health
alias ahealth='curl -s http://localhost:4000/.well-known/apollo/server-health | jq'
```

---

## 📊 Performance Monitoring

### Local Performance Testing

```bash
# Install autocannon (HTTP benchmarking)
npm install -g autocannon

# Benchmark health endpoint
autocannon -c 100 -d 10 http://localhost:4000/.well-known/apollo/server-health

# Benchmark GraphQL query
autocannon -c 100 -d 10 -m POST \
  -H 'Content-Type: application/json' \
  -b '{"query":"{ accounts { nodes { id } } }"}' \
  http://localhost:4000/graphql
```

### Memory Profiling

```bash
# Run with memory profiling
node --inspect dist/index.js

# Open Chrome DevTools
# Navigate to: chrome://inspect
# Click "Open dedicated DevTools for Node"
```

---

## 🆘 Troubleshooting

### Port Already in Use

```bash
# Find process using port 4000
lsof -ti:4000

# Kill the process
kill -9 $(lsof -ti:4000)

# Or use a different port
PORT=4001 npm run dev
```

### TypeScript Errors

```bash
# Clear TypeScript cache
rm -rf dist
npm run build

# Check for type errors
npm run type-check
```

### npm Install Failures

```bash
# Clear npm cache
npm cache clean --force

# Remove node_modules and package-lock
rm -rf node_modules package-lock.json

# Fresh install
npm install
```

### Docker Build Failures

```bash
# Build without cache
docker build --no-cache -t accounts-api:latest .

# Check Docker daemon
docker ps

# Restart Docker Desktop if needed
```

---

## 📚 Additional Resources

- [Apollo Server Docs](https://www.apollographql.com/docs/apollo-server/)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/)
- [GraphQL Best Practices](https://graphql.org/learn/best-practices/)
- [Node.js Best Practices](https://github.com/goldbergyoni/nodebestpractices)

---

## ✅ Development Checklist

Before pushing code:

- [ ] Code compiles: `npm run build`
- [ ] Tests pass: `npm test`
- [ ] Types check: `npm run type-check`
- [ ] Linting passes: `npm run lint`
- [ ] Code formatted: `npm run format`
- [ ] Works in Docker: `npm run docker:build && npm run docker:run`
- [ ] Health endpoint responds
- [ ] GraphQL playground works

---

**Happy coding!** 🚀