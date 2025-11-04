#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Create Documentation Structure
# Sets up docs/ folder with all guides and references
# ============================================================

echo "============================================================"
echo " Creating Documentation Structure"
echo "============================================================"
echo ""

# Get project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "Project root: ${PROJECT_ROOT}"
echo ""

# Create directory structure
echo "Creating directory structure..."
mkdir -p "${PROJECT_ROOT}/docs"/{guides,workflows,reference,diagrams}

# Create main README
echo "Creating docs/README.md..."
cat > "${PROJECT_ROOT}/docs/README.md" << 'EOF'
# WorldKinect Accounts API Documentation

Complete documentation for the Accounts API GraphQL subgraph service deployed on AWS EKS.

---

## 📚 Table of Contents

### Getting Started
1. [IAM Setup Guide](guides/01-iam-setup.md) - Configure IAM users, roles, and permissions
2. [Two-Account Setup](guides/02-two-account-setup.md) - Managing sdrandrUser1 and terraform-admin
3. [EKS Migration Guide](guides/03-eks-migration.md) - Migrate from Lambda to EKS deployment
4. [Local Development](guides/04-local-development.md) - Set up your development environment

### CI/CD
- [CI/CD Automation Guide](guides/05-cicd-automation.md) - Complete automation setup
- [GitHub Actions](workflows/github-actions.md) - GitHub Actions workflow setup
- [Jenkins Pipeline](workflows/jenkins-pipeline.md) - Jenkins pipeline configuration
- [Manual Deployment](workflows/manual-deployment.md) - Step-by-step manual deployment

### Reference
- [Scripts Reference](reference/scripts-reference.md) - All scripts explained in detail
- [IAM Policies Reference](reference/iam-policies.md) - IAM policy details
- [Kubernetes Resources](reference/kubernetes-resources.md) - K8s manifests explained
- [Quick Reference](reference/quick-reference.md) - Cheat sheet and common commands
- [Troubleshooting](reference/troubleshooting.md) - Common issues and solutions

### Learning Resources
- [Learning Roadmap](guides/learning-roadmap.md) - Path to WorldKinect tech stack proficiency

---

## 🚀 Quick Start

```bash
# 1. Verify IAM setup
./scripts/verify-terraform-admin.sh

# 2. Setup for EKS
./scripts/setup-accounts-api-eks.sh

# 3. Deploy
./scripts/ci-cd-pipeline.sh
```

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────┐
│      Users / React Applications      │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│    Apollo Router (EKS Gateway)      │
│    - Routes GraphQL queries         │
│    - Federation composition         │
└──────────────┬──────────────────────┘
               │
        ┌──────┴──────┐
        ▼             ▼
┌──────────────┐ ┌──────────────┐
│  Accounts    │ │   Other      │
│  Subgraph    │ │  Subgraphs   │
│   (EKS)      │ │   (EKS)      │
└──────────────┘ └──────────────┘
```

---

## 📖 Documentation Guide

### For New Team Members
1. Start with [IAM Setup](guides/01-iam-setup.md)
2. Read [Two-Account Setup](guides/02-two-account-setup.md)
3. Follow [EKS Migration](guides/03-eks-migration.md)
4. Set up [CI/CD](guides/05-cicd-automation.md)

### For Deploying
1. Check [Quick Reference](reference/quick-reference.md)
2. Use [Scripts Reference](reference/scripts-reference.md)
3. If issues, see [Troubleshooting](reference/troubleshooting.md)

### For Learning
1. Follow [Learning Roadmap](guides/learning-roadmap.md)
2. Build the portfolio project
3. Practice with different environments

---

## 🔗 Related Resources

- **Apollo Federation:** https://www.apollographql.com/docs/federation/
- **AWS EKS:** https://docs.aws.amazon.com/eks/
- **Kubernetes:** https://kubernetes.io/docs/
- **TypeScript:** https://www.typescriptlang.org/docs/

---

## 📝 Contributing to Docs

To add or update documentation:

1. Edit the relevant Markdown file in `docs/`
2. Follow the existing format and structure
3. Test any code examples
4. Commit with clear description: `docs: <description>`

---

## 🆘 Getting Help

- Check [Troubleshooting Guide](reference/troubleshooting.md)
- Review [Quick Reference](reference/quick-reference.md)
- Search issues in GitHub
- Ask in team Slack channel

---

**Last Updated:** $(date +"%Y-%m-%d")
EOF

echo "✓ Created docs/README.md"

# Create guides placeholder files
echo ""
echo "Creating guide files..."

cat > "${PROJECT_ROOT}/docs/guides/01-iam-setup.md" << 'EOF'
# IAM Setup Guide

> **Note:** Copy content from artifact "IAM Setup Guide - README"

[Content to be added]
EOF
echo "✓ Created docs/guides/01-iam-setup.md"

cat > "${PROJECT_ROOT}/docs/guides/02-two-account-setup.md" << 'EOF'
# Two-Account Setup Guide

> **Note:** Copy content from artifact "Two-Account Setup Guide"

[Content to be added]
EOF
echo "✓ Created docs/guides/02-two-account-setup.md"

cat > "${PROJECT_ROOT}/docs/guides/03-eks-migration.md" << 'EOF'
# EKS Migration Guide

> **Note:** Copy content from artifact "EKS Migration Guide"

[Content to be added]
EOF
echo "✓ Created docs/guides/03-eks-migration.md"

cat > "${PROJECT_ROOT}/docs/guides/04-local-development.md" << 'EOF'
# Local Development Guide

## Prerequisites

- Node.js 20+
- Docker Desktop
- AWS CLI configured
- kubectl configured

## Setup

```bash
cd services/accounts-api

# Install dependencies
npm install

# Run locally
npm run dev
```

## Testing

```bash
# Unit tests
npm test

# Type checking
npm run type-check

# Linting
npm run lint
```

## Docker Local Testing

```bash
# Build image
npm run docker:build

# Run container
npm run docker:run

# Test
curl http://localhost:4000/.well-known/apollo/server-health
```

---

[Add more local development details as needed]
EOF
echo "✓ Created docs/guides/04-local-development.md"

cat > "${PROJECT_ROOT}/docs/guides/05-cicd-automation.md" << 'EOF'
# CI/CD Automation Guide

> **Note:** Copy content from artifact "CI/CD Automation - README"

[Content to be added]
EOF
echo "✓ Created docs/guides/05-cicd-automation.md"

cat > "${PROJECT_ROOT}/docs/guides/learning-roadmap.md" << 'EOF'
# Learning Roadmap

> **Note:** Copy content from artifact "WorldKinect Tech Stack Learning Roadmap"

[Content to be added]
EOF
echo "✓ Created docs/guides/learning-roadmap.md"

# Create workflow files
echo ""
echo "Creating workflow documentation..."

cat > "${PROJECT_ROOT}/docs/workflows/github-actions.md" << 'EOF'
# GitHub Actions Workflow

## Setup

1. Add secrets to GitHub:
   - `Settings > Secrets and variables > Actions`
   - Add: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`

2. Copy workflow file:
   ```bash
   mkdir -p .github/workflows
   # Copy artifact: "GitHub Actions Workflow - Deploy to EKS"
   ```

3. Push to trigger:
   ```bash
   git push origin main  # deploys to dev
   ```

## Workflow Triggers

- `push` to `main` → deploys to dev
- `push` to `staging` → deploys to staging  
- `push` to `production` → deploys to prod
- Manual trigger via Actions UI

## Configuration

See `.github/workflows/deploy-accounts-api.yml` for full configuration.

---

[Add more GitHub Actions details]
EOF
echo "✓ Created docs/workflows/github-actions.md"

cat > "${PROJECT_ROOT}/docs/workflows/jenkins-pipeline.md" << 'EOF'
# Jenkins Pipeline

## Setup

1. Add AWS credentials to Jenkins
2. Create new Pipeline job
3. Point to `jenkins/Jenkinsfile`
4. Configure parameters

## Parameters

- **ENVIRONMENT:** dev / staging / prod
- **SKIP_TESTS:** Skip test stage
- **DRY_RUN:** Test without deploying

## Running

1. Click "Build with Parameters"
2. Select environment
3. Run build

---

[Add more Jenkins details]
EOF
echo "✓ Created docs/workflows/jenkins-pipeline.md"

cat > "${PROJECT_ROOT}/docs/workflows/manual-deployment.md" << 'EOF'
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
EOF
echo "✓ Created docs/workflows/manual-deployment.md"

# Create reference files
echo ""
echo "Creating reference documentation..."

cat > "${PROJECT_ROOT}/docs/reference/scripts-reference.md" << 'EOF'
# Scripts Reference

Complete reference for all deployment scripts.

---

## setup-accounts-api-eks.sh

**Purpose:** One-time migration from Lambda to EKS

**Usage:**
```bash
./scripts/setup-accounts-api-eks.sh
```

**What it does:**
- Backs up existing Lambda files
- Removes Lambda dependencies
- Installs EKS dependencies
- Creates directory structure
- Generates Dockerfile and K8s manifests

---

## verify-terraform-admin.sh

**Purpose:** Verify terraform-admin IAM permissions

**Usage:**
```bash
./scripts/verify-terraform-admin.sh
```

**What it does:**
- Confirms current AWS user
- Tests ECR, EKS, S3, DynamoDB access
- Lists attached IAM policies
- Shows any permission issues

---

## setup-iam-permissions.sh

**Purpose:** Create IAM resources for CI/CD

**Usage:**
```bash
./scripts/setup-iam-permissions.sh
```

**What it does:**
- Creates CI/CD IAM policy
- Creates CI/CD IAM user
- Generates access keys
- Creates EKS service account role
- Creates K8s ServiceAccount manifest

---

## build-and-push.sh

**Purpose:** Build Docker image and push to ECR

**Environment Variables:**
```bash
AWS_REGION=us-east-1
AWS_ACCOUNT_ID=<auto-detected>
ECR_REPOSITORY=worldkinect/accounts-api
IMAGE_TAG=latest
```

**Usage:**
```bash
# Default
./scripts/build-and-push.sh

# Custom tag
IMAGE_TAG=v1.2.3 ./scripts/build-and-push.sh
```

**What it does:**
1. Creates ECR repository (if needed)
2. Authenticates Docker to ECR
3. Builds TypeScript
4. Builds Docker image
5. Tests image locally
6. Pushes to ECR

---

## deploy-to-eks.sh

**Purpose:** Deploy to EKS cluster

**Environment Variables:**
```bash
AWS_REGION=us-east-1
K8S_NAMESPACE=default
EKS_CLUSTER_NAME=worldkinect-dev
IMAGE_TAG=latest
```

**Usage:**
```bash
# Default
./scripts/deploy-to-eks.sh

# Custom environment
K8S_NAMESPACE=staging \
EKS_CLUSTER_NAME=worldkinect-staging \
./scripts/deploy-to-eks.sh
```

**What it does:**
1. Configures kubectl
2. Creates namespace (if needed)
3. Updates K8s manifest with image
4. Applies manifest to cluster
5. Waits for rollout
6. Runs health checks

---

## ci-cd-pipeline.sh

**Purpose:** Complete CI/CD pipeline

**Options:**
```bash
--env [dev|staging|prod]  # Target environment
--skip-tests              # Skip test stage
--dry-run                 # Don't actually deploy
```

**Usage:**
```bash
# Development
./scripts/ci-cd-pipeline.sh

# Staging
./scripts/ci-cd-pipeline.sh --env staging

# Production (careful!)
./scripts/ci-cd-pipeline.sh --env prod

# Test pipeline
./scripts/ci-cd-pipeline.sh --dry-run
```

**Pipeline Stages:**
1. Lint
2. Type Check
3. Test
4. Build & Push
5. Deploy
6. Smoke Tests

---

[Add more script details as needed]
EOF
echo "✓ Created docs/reference/scripts-reference.md"

cat > "${PROJECT_ROOT}/docs/reference/iam-policies.md" << 'EOF'
# IAM Policies Reference

## terraform-admin User Policy

See: `terraform/bootstrap/policies/terraform-admin-policy.json`

**Permissions:**
- ECR: Full access
- EKS: Full access
- IAM: Role and policy management
- S3: Full access (for Terraform state)
- DynamoDB: Full access (for Terraform locking)
- Secrets Manager: Full access
- KMS: Encryption key management

---

## CI/CD User Policy

See: `terraform/bootstrap/policies/accounts-api-cicd-policy.json`

**Permissions:**
- ECR: Push/pull images
- EKS: Describe clusters
- STS: Assume role, get identity

---

## EKS Service Account Role

See: `terraform/bootstrap/policies/eks-service-account-permissions.json`

**Permissions:**
- Secrets Manager: Read secrets
- RDS: Describe instances
- DynamoDB: Read/write accounts tables

---

[Add more policy details]
EOF
echo "✓ Created docs/reference/iam-policies.md"

cat > "${PROJECT_ROOT}/docs/reference/kubernetes-resources.md" << 'EOF'
# Kubernetes Resources Reference

## Deployment

**File:** `services/accounts-api/kubernetes/deployment.yaml`

**Resources:**
- Deployment: 2 replicas, rolling update
- Service: ClusterIP on port 4000
- HorizontalPodAutoscaler: 2-10 replicas based on CPU/memory

**Configuration:**
```yaml
replicas: 2
resources:
  requests:
    memory: 256Mi
    cpu: 250m
  limits:
    memory: 512Mi
    cpu: 500m
```

---

## ServiceAccount

**File:** `services/accounts-api/kubernetes/serviceaccount.yaml`

**Purpose:** IRSA (IAM Roles for Service Accounts)

**Resources:**
- ServiceAccount with IAM role annotation
- Role with configmap/secret permissions
- RoleBinding

---

[Add more K8s resource details]
EOF
echo "✓ Created docs/reference/kubernetes-resources.md"

cat > "${PROJECT_ROOT}/docs/reference/quick-reference.md" << 'EOF'
# Quick Reference

## Daily Commands

```bash
# Check AWS identity
aws sts get-caller-identity

# Deploy to dev
./scripts/ci-cd-pipeline.sh

# Build and push
./scripts/build-and-push.sh

# Deploy to EKS
./scripts/deploy-to-eks.sh
```

## Kubernetes Commands

```bash
# Get pods
kubectl get pods -l app=accounts-api

# View logs
kubectl logs -l app=accounts-api -f

# Describe pod
kubectl describe pod <pod-name>

# Port forward
kubectl port-forward svc/accounts-api 4000:4000

# Restart deployment
kubectl rollout restart deployment/accounts-api

# Rollback
kubectl rollout undo deployment/accounts-api
```

## Docker Commands

```bash
# Build image
docker build -t accounts-api:latest .

# Run locally
docker run -p 4000:4000 accounts-api:latest

# View images
docker images | grep accounts-api

# Remove old images
docker image prune
```

## AWS Commands

```bash
# List ECR images
aws ecr describe-images --repository-name worldkinect/accounts-api

# List EKS clusters
aws eks list-clusters

# Update kubeconfig
aws eks update-kubeconfig --name worldkinect-dev

# ECR login
aws ecr get-login-password | docker login --username AWS --password-stdin <ecr-uri>
```

## Environment Variables

```bash
# Set environment
export ENVIRONMENT=dev
export AWS_REGION=us-east-1
export K8S_NAMESPACE=default
export EKS_CLUSTER_NAME=worldkinect-dev

# For staging
export ENVIRONMENT=staging
export K8S_NAMESPACE=staging
export EKS_CLUSTER_NAME=worldkinect-staging

# For production
export ENVIRONMENT=prod
export K8S_NAMESPACE=production
export EKS_CLUSTER_NAME=worldkinect-prod
```

## Troubleshooting

```bash
# Check pod events
kubectl describe pod <pod-name>

# Get pod logs
kubectl logs <pod-name>

# Get previous pod logs (if crashed)
kubectl logs <pod-name> --previous

# Execute command in pod
kubectl exec -it <pod-name> -- /bin/sh

# Test from inside pod
kubectl exec -it <pod-name> -- curl http://localhost:4000/.well-known/apollo/server-health
```

---

[Add more quick reference commands]
EOF
echo "✓ Created docs/reference/quick-reference.md"

cat > "${PROJECT_ROOT}/docs/reference/troubleshooting.md" << 'EOF'
# Troubleshooting Guide

## Common Issues

### Issue: "Access Denied" Errors

**Symptom:** AWS CLI commands fail with access denied

**Solution:**
```bash
# Check current user
aws sts get-caller-identity

# Should show terraform-admin
# If not, switch profile:
export AWS_PROFILE=default

# Verify permissions
./scripts/verify-terraform-admin.sh
```

---

### Issue: Pod Won't Start

**Symptom:** Pods stuck in Pending or CrashLoopBackOff

**Diagnosis:**
```bash
# Check pod status
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name>

# Check events
kubectl get events --sort-by='.lastTimestamp'
```

**Common Causes:**
- Image pull errors (check ECR permissions)
- Resource limits too low
- Missing environment variables
- Health check failures

---

### Issue: Image Pull Errors

**Symptom:** `ErrImagePull` or `ImagePullBackOff`

**Solution:**
```bash
# Verify image exists
aws ecr describe-images --repository-name worldkinect/accounts-api

# Check image name in deployment
kubectl get deployment accounts-api -o yaml | grep image

# Verify ECR permissions for EKS nodes
```

---

### Issue: Health Check Failures

**Symptom:** Pods restarting, readiness probe failing

**Solution:**
```bash
# Test health endpoint from inside pod
kubectl exec -it <pod-name> -- curl http://localhost:4000/.well-known/apollo/server-health

# Check if Apollo Server started
kubectl logs <pod-name> | grep "ready at"

# Check application logs for errors
kubectl logs <pod-name>
```

---

### Issue: Can't Connect to EKS

**Symptom:** `kubectl` commands fail with connection errors

**Solution:**
```bash
# Update kubeconfig
aws eks update-kubeconfig --name worldkinect-dev --region us-east-1

# Verify connection
kubectl cluster-info

# Check AWS permissions
aws eks describe-cluster --name worldkinect-dev
```

---

### Issue: GitHub Actions Deployment Fails

**Symptom:** GitHub Actions workflow fails

**Solution:**
1. Check GitHub Secrets are set correctly
2. Verify AWS credentials have required permissions
3. Check workflow logs for specific error
4. Test deployment locally first

---

[Add more troubleshooting scenarios]
EOF
echo "✓ Created docs/reference/troubleshooting.md"

# Create .gitignore entry for docs
echo ""
echo "Updating .gitignore..."

if ! grep -q "# Documentation build artifacts" "${PROJECT_ROOT}/.gitignore" 2>/dev/null; then
  cat >> "${PROJECT_ROOT}/.gitignore" << 'EOF'

# Documentation build artifacts
docs/site/
mkdocs.yml
EOF
  echo "✓ Updated .gitignore"
else
  echo "✓ .gitignore already configured"
fi

# Create instructions file
cat > "${PROJECT_ROOT}/docs/INSTRUCTIONS.md" << 'EOF'
# Documentation Instructions

## Filling in the Documentation

The documentation structure has been created with placeholder files. Now you need to copy the content from the Claude artifacts into each file.

### Files to Update

1. **docs/guides/01-iam-setup.md**
   - Copy from artifact: "IAM Setup Guide - README"

2. **docs/guides/02-two-account-setup.md**
   - Copy from artifact: "Two-Account Setup Guide"

3. **docs/guides/03-eks-migration.md**
   - Copy from artifact: "EKS Migration Guide"

4. **docs/guides/05-cicd-automation.md**
   - Copy from artifact: "CI/CD Automation - README"

5. **docs/guides/learning-roadmap.md**
   - Copy from artifact: "WorldKinect Tech Stack Learning Roadmap"

### How to Copy Content

1. Find the artifact in your conversation with Claude
2. Copy all the markdown content
3. Open the corresponding file in your editor
4. Replace the `[Content to be added]` section with the copied content
5. Save the file

### Updating Documentation

When you need to update the docs:

```bash
# Edit the relevant file
vim docs/guides/01-iam-setup.md

# Commit the changes
git add docs/
git commit -m "docs: Update IAM setup guide"
git push origin main
```

### Viewing Documentation

```bash
# View on GitHub
# Navigate to: https://github.com/<your-org>/<your-repo>/tree/main/docs

# Or view locally
# Open docs/README.md in your editor or browser
```

### Optional: Set up MkDocs

If you want a beautiful documentation website:

```bash
pip install mkdocs-material
mkdocs new .
# Edit mkdocs.yml to match docs structure
mkdocs serve
# Visit http://localhost:8000
```

---

Happy documenting! 📚
EOF

# Summary
echo ""
echo "============================================================"
echo "✓ Documentation Structure Created!"
echo "============================================================"
echo ""
echo "Created:"
echo "  docs/"
echo "  ├── README.md                      (Main index)"
echo "  ├── INSTRUCTIONS.md                (How to fill in content)"
echo "  ├── guides/"
echo "  │   ├── 01-iam-setup.md"
echo "  │   ├── 02-two-account-setup.md"
echo "  │   ├── 03-eks-migration.md"
echo "  │   ├── 04-local-development.md"
echo "  │   ├── 05-cicd-automation.md"
echo "  │   └── learning-roadmap.md"
echo "  ├── workflows/"
echo "  │   ├── github-actions.md"
echo "  │   ├── jenkins-pipeline.md"
echo "  │   └── manual-deployment.md"
echo "  └── reference/"
echo "      ├── scripts-reference.md"
echo "      ├── iam-policies.md"
echo "      ├── kubernetes-resources.md"
echo "      ├── quick-reference.md"
echo "      └── troubleshooting.md"
echo ""
echo "Next Steps:"
echo "  1. Read: docs/INSTRUCTIONS.md"
echo "  2. Copy artifact content into each guide file"
echo "  3. Review: docs/README.md"
echo "  4. Commit to git:"
echo "     git add docs/"
echo "     git commit -m 'docs: Add complete documentation structure'"
echo "     git push origin main"
echo ""
echo "View docs:"
echo "  - GitHub: https://github.com/<your-org>/<your-repo>/tree/main/docs"
echo "  - Local: open docs/README.md"
echo ""
echo "============================================================"