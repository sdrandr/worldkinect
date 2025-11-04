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

[Add more manual deployment details]
