# Accounts API - CI/CD Automation

Complete automation for deploying accounts-api to EKS using CI/CD pipelines.

---

## 📁 Script Files

All scripts should be placed in `scripts/` directory:

```
worldkinect/
├── scripts/
│   ├── setup-accounts-api.sh      # Initial setup/migration
│   ├── build-and-push.sh          # Build Docker & push to ECR
│   ├── deploy-to-eks.sh           # Deploy to EKS cluster
│   ├── ci-cd-pipeline.sh          # Complete pipeline (all stages)
│   └── notify.sh                  # Notifications (optional)
├── jenkins/
│   └── Jenkinsfile                # Jenkins pipeline definition
└── services/
    └── accounts-api/
        ├── src/
        ├── kubernetes/
        ├── Dockerfile
        └── package.json
```

---

## 🚀 Quick Start

### 1. Initial Setup (One-time)

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Run setup script (migrates from Lambda to EKS)
./scripts/setup-accounts-api.sh
```

This will:
- ✅ Backup existing Lambda files
- ✅ Remove Lambda dependencies
- ✅ Install EKS dependencies
- ✅ Create directory structure
- ✅ Generate placeholder files
- ✅ Create Dockerfile and K8s manifests

### 2. Complete Source Files

After setup, you need to populate the source files with actual implementation:

```bash
cd services/accounts-api/src

# Copy content from artifacts:
# - index.ts (EKS Entry Point)
# - schema.ts (GraphQL Schema)
# - resolvers.ts (GraphQL Resolvers)
# - types.ts (TypeScript Types)
```

### 3. Test Locally

```bash
cd services/accounts-api

# Install and build
npm install
npm run build

# Run locally
npm run dev

# Test
curl http://localhost:4000/.well-known/apollo/server-health
```

### 4. Deploy to EKS

#### Option A: Manual Deployment

```bash
# Build and push to ECR
./scripts/build-and-push.sh

# Deploy to EKS
./scripts/deploy-to-eks.sh
```

#### Option B: Complete Pipeline

```bash
# Run full CI/CD pipeline
./scripts/ci-cd-pipeline.sh

# With options
./scripts/ci-cd-pipeline.sh --env staging
./scripts/ci-cd-pipeline.sh --skip-tests
./scripts/ci-cd-pipeline.sh --dry-run
```

#### Option C: Jenkins Pipeline

1. Add `jenkins/Jenkinsfile` to your Jenkins
2. Configure pipeline parameters
3. Run build with desired environment

---

## 📜 Script Details

### `setup-accounts-api.sh`

**Purpose:** One-time migration from Lambda to EKS

**What it does:**
- Backs up existing files
- Removes Lambda dependencies and files
- Installs EKS dependencies
- Creates directory structure
- Generates template files

**Usage:**
```bash
./scripts/setup-accounts-api.sh
```

**Output:**
- Backup folder: `services/accounts-api/backup-TIMESTAMP/`
- Ready-to-use project structure

---

### `build-and-push.sh`

**Purpose:** Build Docker image and push to AWS ECR

**What it does:**
1. Validates environment
2. Creates ECR repository (if needed)
3. Authenticates Docker to ECR
4. Builds TypeScript
5. Builds Docker image
6. Tests image locally
7. Pushes to ECR

**Environment Variables:**
```bash
AWS_REGION=us-east-1           # AWS region
AWS_ACCOUNT_ID=123456789012    # Auto-detected if not set
ECR_REPOSITORY=worldkinect/accounts-api
IMAGE_TAG=latest               # Or custom tag
```

**Usage:**
```bash
# Default (uses latest tag)
./scripts/build-and-push.sh

# Custom tag
IMAGE_TAG=v1.2.3 ./scripts/build-and-push.sh

# Different region
AWS_REGION=us-west-2 ./scripts/build-and-push.sh
```

---

### `deploy-to-eks.sh`

**Purpose:** Deploy to EKS cluster

**What it does:**
1. Configures kubectl
2. Creates namespace (if needed)
3. Updates K8s manifest with image
4. Applies manifest
5. Waits for rollout
6. Runs health checks

**Environment Variables:**
```bash
AWS_REGION=us-east-1
K8S_NAMESPACE=default
EKS_CLUSTER_NAME=worldkinect-dev
IMAGE_TAG=latest
```

**Usage:**
```bash
# Default environment
./scripts/deploy-to-eks.sh

# Staging environment
K8S_NAMESPACE=staging \
EKS_CLUSTER_NAME=worldkinect-staging \
./scripts/deploy-to-eks.sh

# Production
K8S_NAMESPACE=production \
EKS_CLUSTER_NAME=worldkinect-prod \
IMAGE_TAG=v1.2.3 \
./scripts/deploy-to-eks.sh
```

---

### `ci-cd-pipeline.sh`

**Purpose:** Complete CI/CD pipeline (all stages)

**Pipeline Stages:**
1. **Lint** - Code quality checks
2. **Type Check** - TypeScript validation
3. **Test** - Unit/integration tests
4. **Build & Push** - Docker image to ECR
5. **Deploy** - Deploy to EKS
6. **Smoke Tests** - Verify deployment

**Command Line Options:**
```bash
--env [dev|staging|prod]   # Target environment (default: dev)
--skip-tests               # Skip test stage
--dry-run                  # Don't actually deploy
```

**Usage:**
```bash
# Development deployment
./scripts/ci-cd-pipeline.sh

# Staging with tests
./scripts/ci-cd-pipeline.sh --env staging

# Production (careful!)
./scripts/ci-cd-pipeline.sh --env prod

# Dry run (test pipeline without deploying)
./scripts/ci-cd-pipeline.sh --dry-run
```

**Output:**
- Complete pipeline execution log
- Duration tracking
- Final status summary

---

## 🔧 Environment Configuration

### Development
```bash
export ENVIRONMENT=dev
export AWS_REGION=us-east-1
export K8S_NAMESPACE=default
export EKS_CLUSTER_NAME=worldkinect-dev
```

### Staging
```bash
export ENVIRONMENT=staging
export AWS_REGION=us-east-1
export K8S_NAMESPACE=staging
export EKS_CLUSTER_NAME=worldkinect-staging
```

### Production
```bash
export ENVIRONMENT=prod
export AWS_REGION=us-east-1
export K8S_NAMESPACE=production
export EKS_CLUSTER_NAME=worldkinect-prod
```

---

## 🔐 Prerequisites

### AWS Setup
```bash
# Configure AWS CLI
aws configure

# Verify credentials
aws sts get-caller-identity

# Verify EKS access
aws eks list-clusters --region us-east-1
```

### Kubernetes Setup
```bash
# Install kubectl
brew install kubectl  # macOS
# or apt-get install kubectl  # Linux

# Configure kubeconfig
aws eks update-kubeconfig \
  --region us-east-1 \
  --name worldkinect-dev

# Verify connection
kubectl cluster-info
kubectl get nodes
```

### Docker Setup
```bash
# Verify Docker is running
docker ps

# Test Docker build
cd services/accounts-api
docker build -t test .
```

---

## 🧪 Testing

### Local Testing
```bash
cd services/accounts-api

# Unit tests
npm test

# Type checking
npm run type-check

# Linting
npm run lint

# Run locally
npm run dev
```

### Docker Testing
```bash
# Build image
npm run docker:build

# Run container
npm run docker:run

# Test health endpoint
curl http://localhost:4000/.well-known/apollo/server-health
```

### EKS Testing
```bash
# Port forward service
kubectl port-forward svc/accounts-api 4000:4000

# Test endpoints
curl http://localhost:4000/.well-known/apollo/server-health
curl -X POST http://localhost:4000/graphql \
  -H "Content-Type: application/json" \
  -d '{"query":"{ __typename }"}'
```

---

## 📊 Monitoring

### Check Pod Status
```bash
# Get pods
kubectl get pods -l app=accounts-api

# Describe pod
kubectl describe pod <pod-name>

# View logs
kubectl logs -f <pod-name>

# Tail logs for all pods
kubectl logs -l app=accounts-api -f
```

### Check Service
```bash
# Get service
kubectl get svc accounts-api

# Describe service
kubectl describe svc accounts-api
```

### Check Deployment
```bash
# Get deployment
kubectl get deployment accounts-api

# Deployment details
kubectl describe deployment accounts-api

# Rollout status
kubectl rollout status deployment/accounts-api

# Rollout history
kubectl rollout history deployment/accounts-api
```

### Check HPA (Horizontal Pod Autoscaler)
```bash
# Get HPA
kubectl get hpa accounts-api-hpa

# HPA details
kubectl describe hpa accounts-api-hpa
```

---

## 🔄 Rollback

### Rollback Deployment
```bash
# View rollout history
kubectl rollout history deployment/accounts-api

# Rollback to previous version
kubectl rollout undo deployment/accounts-api

# Rollback to specific revision
kubectl rollout undo deployment/accounts-api --to-revision=2
```

### Redeploy Previous Image
```bash
# Find previous image tag in ECR
aws ecr describe-images \
  --repository-name worldkinect/accounts-api \
  --region us-east-1

# Deploy specific image
IMAGE_TAG=dev-abc1234-20241104120000 \
./scripts/deploy-to-eks.sh
```

---

## 🐛 Troubleshooting

### Build Failures

**Problem:** TypeScript compilation errors
```bash
# Check TypeScript config
cat tsconfig.json

# Run type check
npm run type-check

# Clean and rebuild
npm run clean
npm run build
```

**Problem:** Docker build fails
```bash
# Check Dockerfile syntax
docker build --no-cache -t accounts-api:test .

# View build output
docker build --progress=plain -t accounts-api:test .
```

### Deployment Failures

**Problem:** Image pull errors
```bash
# Verify image exists in ECR
aws ecr describe-images \
  --repository-name worldkinect/accounts-api

# Check ECR permissions
aws ecr get-login-password | docker login ...

# Verify K8s can pull from ECR (check IAM roles)
```

**Problem:** Pod crashes
```bash
# Get pod logs
kubectl logs <pod-name>

# Get previous pod logs
kubectl logs <pod-name> --previous

# Check pod events
kubectl describe pod <pod-name>
```

**Problem:** Health check failures
```bash
# Test health endpoint from inside pod
kubectl exec -it <pod-name> -- \
  curl http://localhost:4000/.well-known/apollo/server-health

# Check if Apollo Server started
kubectl logs <pod-name> | grep "ready at"
```

### Networking Issues

**Problem:** Can't reach service
```bash
# Verify service exists
kubectl get svc accounts-api

# Test from another pod
kubectl run curl-test --rm -it --image=curlimages/curl -- \
  curl http://accounts-api:4000/.well-known/apollo/server-health

# Check network policies
kubectl get networkpolicies
```

---

## 📈 Scaling

### Manual Scaling
```bash
# Scale up
kubectl scale deployment/accounts-api --replicas=5

# Scale down
kubectl scale deployment/accounts-api --replicas=2
```

### Auto-scaling (HPA already configured)
```bash
# View HPA
kubectl get hpa accounts-api-hpa

# Edit HPA
kubectl edit hpa accounts-api-hpa

# Current HPA config:
# - Min: 2 replicas
# - Max: 10 replicas
# - Target CPU: 70%
# - Target Memory: 80%
```

---

## 🔗 Integration with Apollo Router

### Update Router Configuration

Your Apollo Router needs to know about the accounts-api subgraph:

```yaml
# In apollo-router configuration
supergraph:
  subgraphs:
    - name: accounts
      url: http://accounts-api.default.svc.cluster.local:4000/graphql
      # or simply: http://accounts-api:4000/graphql
```

### Generate Supergraph Schema

```bash
# Using Rover CLI
rover supergraph compose \
  --config supergraph-config.yaml \
  > supergraph-schema.graphql

# Deploy updated schema to router
kubectl create configmap router-config \
  --from-file=supergraph-schema.graphql \
  --dry-run=client -o yaml | kubectl apply -f -
```

---

## 📝 Best Practices

1. **Always test locally first**
   ```bash
   npm run dev
   ```

2. **Use dry-run before production**
   ```bash
   ./scripts/ci-cd-pipeline.sh --env prod --dry-run
   ```

3. **Tag images with meaningful versions**
   ```bash
   IMAGE_TAG=v1.2.3 ./scripts/build-and-push.sh
   ```

4. **Monitor deployments**
   ```bash
   kubectl rollout status deployment/accounts-api -w
   ```

5. **Keep backups**
   - Setup script automatically creates backups
   - ECR keeps image history
   - K8s keeps rollout history

---

## 🎯 Next Steps

1. **Add database integration** (RDS/DynamoDB)
2. **Implement authentication** (JWT validation)
3. **Add monitoring** (Prometheus/Grafana)
4. **Setup alerts** (CloudWatch/PagerDuty)
5. **Add integration tests**
6. **Implement blue/green deployments**

---

## 📚 Resources

- **Apollo Federation:** https://www.apollographql.com/docs/federation/
- **Kubernetes Best Practices:** https://kubernetes.io/docs/concepts/
- **AWS EKS Guide:** https://docs.aws.amazon.com/eks/
- **Docker Best Practices:** https://docs.docker.com/develop/dev-best-practices/

---

**You now have complete CI/CD automation for your accounts-api EKS deployment!** 🚀