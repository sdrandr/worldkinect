# Accounts API - EKS Migration Guide

## Overview

This guide walks you through migrating your accounts-api from Lambda to EKS deployment, matching WorldKinect's production architecture.

---

## Step 1: Project Structure Changes

### Update your directory structure:

```
services/accounts-api/
├── src/
│   ├── index.ts           # ← NEW: EKS entry point (replaces handler.ts)
│   ├── schema.ts          # ← NEW: GraphQL schema definition
│   ├── resolvers.ts       # ← NEW: GraphQL resolvers
│   └── types.ts           # Updated: TypeScript types
├── kubernetes/            # ← NEW: K8s manifests
│   └── deployment.yaml
├── Dockerfile             # ← NEW: Container definition
├── .dockerignore          # ← NEW: Docker ignore file
├── package.json           # Updated for EKS
├── tsconfig.json
└── README.md
```

### Remove Lambda-specific files:
- ❌ Delete `handler.ts` (replaced by `index.ts`)
- ❌ Delete `webpack.config.js` (no longer needed for EKS)
- ❌ Remove `@as-integrations/aws-lambda` dependency

---

## Step 2: Install Dependencies

```bash
cd services/accounts-api

# Update package.json (use artifact above)
# Then install dependencies

npm install

# Verify dependencies installed correctly
npm list @apollo/server @apollo/subgraph graphql
```

---

## Step 3: Create Source Files

Create the following files in `src/`:

### 1. `src/index.ts`
(See artifact: "accounts-api - index.ts (EKS Entry Point)")

### 2. `src/schema.ts`
(See artifact: "accounts-api - schema.ts")

### 3. `src/resolvers.ts`
(See artifact: "accounts-api - resolvers.ts")

### 4. `src/types.ts`
(See artifact: "accounts-api - types.ts")

---

## Step 4: Update TypeScript Configuration

Update your `tsconfig.json`:

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ES2022",
    "lib": ["ES2022"],
    "moduleResolution": "node",
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "types": ["node"]
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

---

## Step 5: Test Locally

### Build and run locally:

```bash
# Build TypeScript
npm run build

# Start the server
npm start

# Or use dev mode with hot reload
npm run dev
```

### Test the GraphQL endpoint:

Open browser to `http://localhost:4000`

You should see Apollo Server playground.

### Test queries:

```graphql
# Query all accounts
query {
  accounts {
    nodes {
      id
      accountNumber
      companyName
      status
    }
    totalCount
    hasNextPage
  }
}

# Query single account
query {
  account(id: "1") {
    id
    accountNumber
    companyName
    billingAddress {
      city
      state
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

## Step 6: Dockerize the Application

### 1. Create Dockerfile
(See artifact: "Dockerfile - accounts-api")

### 2. Create .dockerignore
(See artifact: ".dockerignore")

### 3. Build Docker image:

```bash
# Build the image
npm run docker:build

# Or manually
docker build -t accounts-api:latest .

# Test locally
npm run docker:run

# Or manually
docker run -p 4000:4000 accounts-api:latest
```

### 4. Verify container:

```bash
# Check health
curl http://localhost:4000/.well-known/apollo/server-health

# Should return: {"status":"pass"}
```

---

## Step 7: Push to ECR (AWS Container Registry)

### 1. Create ECR repository:

```bash
aws ecr create-repository \
  --repository-name worldkinect/accounts-api \
  --region us-east-1
```

### 2. Authenticate Docker to ECR:

```bash
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  <YOUR_AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com
```

### 3. Tag and push:

```bash
# Tag the image
docker tag accounts-api:latest \
  <YOUR_AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/worldkinect/accounts-api:latest

# Push to ECR
docker push <YOUR_AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/worldkinect/accounts-api:latest
```

---

## Step 8: Deploy to EKS

### 1. Create Kubernetes manifests:

```bash
mkdir -p services/accounts-api/kubernetes
```

Copy the deployment.yaml artifact to `services/accounts-api/kubernetes/deployment.yaml`

### 2. Update the image in deployment.yaml:

Replace `<YOUR_ECR_REGISTRY>` with your actual ECR URL:
```yaml
image: <YOUR_AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/worldkinect/accounts-api:latest
```

### 3. Apply to EKS:

```bash
# Make sure you're connected to the right cluster
kubectl config current-context

# Apply the manifests
kubectl apply -f services/accounts-api/kubernetes/deployment.yaml

# Verify deployment
kubectl get pods -l app=accounts-api
kubectl get svc accounts-api
```

### 4. Check pod logs:

```bash
# Get pod name
kubectl get pods -l app=accounts-api

# View logs
kubectl logs <pod-name>

# Should see:
# 🚀 Accounts subgraph ready at http://0.0.0.0:4000
```

---

## Step 9: Configure Apollo Router

### Update your Apollo Router configuration:

Your router needs to know about the new subgraph endpoint.

**In `helm/charts/apollo-router/values.yaml`** (or wherever router config lives):

```yaml
supergraph:
  subgraphs:
    - name: accounts
      url: http://accounts-api.default.svc.cluster.local:4000/graphql
      # Or use service name directly
      # url: http://accounts-api:4000/graphql
```

### Generate supergraph schema:

```bash
# Using Rover CLI
rover supergraph compose --config supergraph.yaml > supergraph-schema.graphql

# Then update router with new schema
# (Your Helm chart should handle this)
```

---

## Step 10: Test End-to-End

### 1. Port-forward to test locally:

```bash
# Port-forward the accounts-api service
kubectl port-forward svc/accounts-api 4000:4000

# Test directly
curl http://localhost:4000/.well-known/apollo/server-health
```

### 2. Test through Apollo Router:

```bash
# Port-forward router (if not exposed externally)
kubectl port-forward svc/apollo-router 8080:80

# Query through router
curl -X POST http://localhost:8080/graphql \
  -H "Content-Type: application/json" \
  -d '{"query": "{ accounts { nodes { id companyName } } }"}'
```

---

## Step 11: Update CI/CD Pipeline

### Update your deployment script:

**In `scripts/deploy-accounts-api.sh`:**

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " Deploy Accounts API to EKS"
echo "============================================================"

# Variables
AWS_REGION="${AWS_REGION:-us-east-1}"
AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
ECR_REPO="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/worldkinect/accounts-api"
IMAGE_TAG="${IMAGE_TAG:-latest}"
K8S_NAMESPACE="${K8S_NAMESPACE:-default}"

# Build
echo ">>> [1/5] Building Docker image..."
cd services/accounts-api
docker build -t accounts-api:${IMAGE_TAG} .

# Tag
echo ">>> [2/5] Tagging image..."
docker tag accounts-api:${IMAGE_TAG} ${ECR_REPO}:${IMAGE_TAG}

# Push to ECR
echo ">>> [3/5] Pushing to ECR..."
aws ecr get-login-password --region ${AWS_REGION} | \
  docker login --username AWS --password-stdin ${ECR_REPO}
docker push ${ECR_REPO}:${IMAGE_TAG}

# Update K8s deployment
echo ">>> [4/5] Deploying to EKS..."
kubectl set image deployment/accounts-api \
  accounts-api=${ECR_REPO}:${IMAGE_TAG} \
  -n ${K8S_NAMESPACE}

# Wait for rollout
echo ">>> [5/5] Waiting for rollout..."
kubectl rollout status deployment/accounts-api -n ${K8S_NAMESPACE}

echo "✅ Deployment complete!"
kubectl get pods -l app=accounts-api -n ${K8S_NAMESPACE}
```

---

## Step 12: Add Monitoring & Observability

### 1. Add Prometheus metrics (optional but recommended):

```bash
npm install prom-client
```

Update `src/index.ts` to expose metrics endpoint.

### 2. Configure log aggregation:

Ensure logs are structured JSON for easy parsing:

```typescript
// In your resolvers or index.ts
console.log(JSON.stringify({
  level: 'info',
  message: 'Account fetched',
  accountId: id,
  timestamp: new Date().toISOString()
}));
```

### 3. Add distributed tracing (optional):

Consider adding OpenTelemetry for request tracing across subgraphs.

---

## Migration Checklist

- [ ] Project structure updated (index.ts, schema.ts, resolvers.ts)
- [ ] Lambda dependencies removed (@as-integrations/aws-lambda)
- [ ] EKS dependencies added (@apollo/server, @apollo/subgraph)
- [ ] Dockerfile created
- [ ] .dockerignore created
- [ ] Local testing passed (npm run dev)
- [ ] Docker build successful
- [ ] Docker container runs locally
- [ ] ECR repository created
- [ ] Image pushed to ECR
- [ ] Kubernetes manifests created
- [ ] Deployed to EKS
- [ ] Pods running successfully
- [ ] Health checks passing
- [ ] Apollo Router configured
- [ ] End-to-end testing through router
- [ ] CI/CD pipeline updated
- [ ] Monitoring configured

---

## Troubleshooting

### Pod won't start:

```bash
# Check pod status
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name>

# Common issues:
# - Image pull errors (check ECR permissions)
# - Port conflicts
# - Missing environment variables
```

### Health check failures:

```bash
# Test health endpoint directly
kubectl exec -it <pod-name> -- curl localhost:4000/.well-known/apollo/server-health

# Check if Apollo Server started
kubectl logs <pod-name> | grep "ready at"
```

### Router can't reach subgraph:

```bash
# Verify service exists
kubectl get svc accounts-api

# Test connectivity from router pod
kubectl exec -it <router-pod-name> -- curl http://accounts-api:4000/.well-known/apollo/server-health
```

---

## Next Steps

1. **Add database integration** - Replace mock data with real database (RDS, DynamoDB)
2. **Add authentication** - Implement JWT validation in context
3. **Add authorization** - Field-level permissions
4. **Optimize performance** - Add DataLoader for batching
5. **Add caching** - Response caching for frequently accessed data
6. **Setup staging environment** - Test changes before production
7. **Add integration tests** - Test federation with other subgraphs

---

## Resources

- **Apollo Federation Docs:** https://www.apollographql.com/docs/federation/
- **Apollo Subgraph Docs:** https://www.apollographql.com/docs/apollo-server/using-federation/apollo-subgraph-setup/
- **Kubernetes Best Practices:** https://kubernetes.io/docs/concepts/configuration/overview/

---

**You now have a production-ready GraphQL subgraph running on EKS!** 🚀