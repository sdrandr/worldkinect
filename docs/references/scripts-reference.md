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

## Script Best Practices

### Always Verify Environment

```bash
# Check AWS identity before running scripts
aws sts get-caller-identity

# Verify kubectl context
kubectl config current-context
```

### Use Environment Variables

```bash
# Set variables before running scripts
export ENVIRONMENT=dev
export AWS_REGION=us-east-1

./scripts/ci-cd-pipeline.sh
```

### Error Handling

All scripts use:
- `set -euo pipefail` - Exit on error
- Error messages with context
- Cleanup on failure

### Dry Run Mode

Use `--dry-run` to test without making changes:

```bash
./scripts/ci-cd-pipeline.sh --dry-run
```

---

## Troubleshooting Scripts

### Script Permission Denied

```bash
# Make scripts executable
chmod +x scripts/*.sh
```

### Script Not Found

```bash
# Run from project root
cd ~/worldkinect
./scripts/build-and-push.sh
```

### AWS Credentials Issues

```bash
# Verify AWS credentials
aws sts get-caller-identity

# Check AWS profile
echo $AWS_PROFILE
```

---

## Resources

- [Bash Scripting Guide](https://www.gnu.org/software/bash/manual/bash.html)
- [Shell Script Best Practices](https://google.github.io/styleguide/shellguide.html)
