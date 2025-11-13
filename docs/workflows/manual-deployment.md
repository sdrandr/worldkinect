# Manual Deployment Guide

## Prerequisites

- AWS CLI configured with terraform-admin
- kubectl configured for EKS cluster
- Docker running locally

## Step-by-Step Deployment

### 1. Build and Push to ECR

```bash
./scripts/build-and-push.sh
```

### 2. Deploy to EKS

```bash
./scripts/deploy-to-eks.sh
```

### 3. Verify Deployment

```bash
# Check pods
kubectl get pods -l app=accounts-api

# Check logs
kubectl logs -l app=accounts-api -f

# Test health
kubectl port-forward svc/accounts-api 4000:4000
curl http://localhost:4000/.well-known/apollo/server-health
```

## Full Pipeline

```bash
# Run complete pipeline
./scripts/ci-cd-pipeline.sh

# With options
./scripts/ci-cd-pipeline.sh --env staging --skip-tests
```

---

## Step-by-Step Deployment

### 1. Prepare Environment

```bash
# Set environment variables
export ENVIRONMENT=dev
export AWS_REGION=us-east-1
export EKS_CLUSTER_NAME=worldkinect-dev

# Verify AWS credentials
aws sts get-caller-identity
```

### 2. Build Application

```bash
cd services/accounts-api

# Install dependencies
npm install

# Run tests
npm test

# Build TypeScript
npm run build
```

### 3. Build Docker Image

```bash
# Build image
docker build -t accounts-api:latest .

# Test locally
docker run -p 4000:4000 accounts-api:latest

# Test health endpoint
curl http://localhost:4000/.well-known/apollo/server-health
```

### 4. Push to ECR

```bash
# Use build-and-push script
cd ~/worldkinect
./scripts/build-and-push.sh

# Or manually:
# AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
# aws ecr get-login-password | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
# docker tag accounts-api:latest $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/worldkinect/accounts-api:latest
# docker push $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/worldkinect/accounts-api:latest
```

### 5. Deploy to EKS

```bash
# Use deploy script
./scripts/deploy-to-eks.sh

# Or manually:
# kubectl apply -f services/accounts-api/kubernetes/
# kubectl rollout status deployment/accounts-api
```

### 6. Verify Deployment

```bash
# Check pods
kubectl get pods -l app=accounts-api

# Check service
kubectl get svc accounts-api

# View logs
kubectl logs -l app=accounts-api -f

# Test health endpoint
kubectl port-forward svc/accounts-api 4000:4000
curl http://localhost:4000/.well-known/apollo/server-health
```

---

## Rollback Procedure

If deployment fails:

```bash
# Rollback to previous version
kubectl rollout undo deployment/accounts-api

# Check rollback status
kubectl rollout status deployment/accounts-api

# Verify pods are healthy
kubectl get pods -l app=accounts-api
```

---

## Deployment Checklist

Before deploying:

- [ ] Code reviewed and tested
- [ ] Tests passing locally
- [ ] Docker image builds successfully
- [ ] AWS credentials configured
- [ ] kubectl connected to correct cluster
- [ ] Verified in correct environment (dev/staging/prod)

After deploying:

- [ ] Pods are running
- [ ] Health checks passing
- [ ] No errors in logs
- [ ] Service is accessible
- [ ] Smoke tests pass

---

## Resources

- [Kubernetes Deployment Guide](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [CI/CD Automation Guide](../guides/05-cicd-automation.md)
