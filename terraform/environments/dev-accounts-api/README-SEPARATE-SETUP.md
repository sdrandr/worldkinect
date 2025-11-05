# Accounts API - Separate Terraform Environment

This is a **standalone deployment** for the accounts-api GraphQL subgraph. It's completely separate from the `environments/dev` setup.

## Directory Structure

```
terraform/
├── environments/
│   ├── dev/                          # ← Existing EKS + Apollo Router (UNTOUCHED)
│   │   └── main.tf
│   │
│   └── dev-accounts-api/             # ← NEW: Separate accounts-api deployment
│       ├── main.tf                   # Main Terraform config
│       ├── variables.tf              # Variable definitions
│       ├── terraform.tfvars          # Variable values
│       ├── outputs.tf                # Output definitions
│       └── scripts/
│           ├── deploy.sh             # Deploy to EKS
│           ├── destroy.sh            # Remove from EKS
│           └── status.sh             # Check deployment status
│
└── modules/
    └── accounts_api/                 # ← NEW: Reusable module
        └── main.tf                   # Module logic
```

## What This Does

1. **References existing EKS cluster** from `environments/dev`
2. **Creates separate ECR repository** for accounts-api
3. **Deploys accounts-api** to the same EKS cluster (in `apollo-system` namespace)
4. **Creates IRSA role** with proper permissions
5. **Manages Kubernetes resources** (deployment, service, service account)

## Prerequisites

- ✅ EKS cluster already running (from `environments/dev`)
- ✅ Docker installed locally
- ✅ AWS CLI configured
- ✅ kubectl configured for your cluster

## Setup Instructions

### Step 1: Create Directory Structure

```bash
cd ~/worldkinect/terraform

# Create the new environment directory
mkdir -p environments/dev-accounts-api/scripts

# Create the module directory
mkdir -p modules/accounts_api
```

### Step 2: Copy Files

Copy the files to their locations:

```bash
# Copy module file
cp terraform-module-accounts-api.tf modules/accounts_api/main.tf

# Copy environment files
cp dev-accounts-api-main.tf environments/dev-accounts-api/main.tf
cp dev-accounts-api-variables.tf environments/dev-accounts-api/variables.tf
cp dev-accounts-api-terraform.tfvars environments/dev-accounts-api/terraform.tfvars
cp dev-accounts-api-outputs.tf environments/dev-accounts-api/outputs.tf

# Copy scripts
cp deploy.sh environments/dev-accounts-api/scripts/
cp destroy.sh environments/dev-accounts-api/scripts/
cp status.sh environments/dev-accounts-api/scripts/

# Make scripts executable
chmod +x environments/dev-accounts-api/scripts/*.sh
```

### Step 3: Build and Push Docker Image

```bash
cd ~/worldkinect

# Build and push to ECR
./scripts/build-and-push.sh
```

This creates the ECR repository and pushes your accounts-api image.

### Step 4: Deploy to EKS

```bash
cd ~/worldkinect/terraform/environments/dev-accounts-api

# Option A: Use the deploy script
./scripts/deploy.sh

# Option B: Manual deployment
terraform init
terraform plan
terraform apply
```

### Step 5: Verify Deployment

```bash
# Check status
./scripts/status.sh

# Or manually:
kubectl get pods -n apollo-system -l app=accounts-api
kubectl logs -f deployment/accounts-api -n apollo-system
```

## Configuration

### Key Variables (terraform.tfvars)

```hcl
# Reference existing EKS cluster
eks_cluster_name = "wk-dev-eks"  # Must match your existing cluster

# Kubernetes settings
namespace = "apollo-system"       # Same as apollo-router

# ECR settings
ecr_repository_name = "worldkinect/accounts-api"
image_tag = "latest"              # Or specific version

# Deployment settings
replicas = 2
```

### Customize as Needed

Edit `terraform.tfvars` to change:
- Number of replicas
- Image tag
- Resource limits
- Tags

## Common Operations

### Deploy New Version

```bash
# 1. Build and push new image
cd ~/worldkinect
./scripts/build-and-push.sh

# 2. Restart deployment
kubectl rollout restart deployment/accounts-api -n apollo-system

# 3. Watch rollout
kubectl rollout status deployment/accounts-api -n apollo-system
```

### Check Status

```bash
cd ~/worldkinect/terraform/environments/dev-accounts-api
./scripts/status.sh
```

### View Logs

```bash
kubectl logs -f deployment/accounts-api -n apollo-system
```

### Test Locally

```bash
# Port forward
kubectl port-forward svc/accounts-api 4000:4000 -n apollo-system

# Test health endpoint
curl http://localhost:4000/.well-known/apollo/server-health

# Test GraphQL
curl -X POST http://localhost:4000 \
  -H "Content-Type: application/json" \
  -d '{"query": "{ __typename }"}'
```

### Update Configuration

```bash
cd ~/worldkinect/terraform/environments/dev-accounts-api

# Modify terraform.tfvars
vim terraform.tfvars

# Apply changes
terraform plan
terraform apply
```

### Remove Deployment

```bash
cd ~/worldkinect/terraform/environments/dev-accounts-api
./scripts/destroy.sh
```

## Architecture

```
┌─────────────────────────────────────────────────────┐
│         terraform/environments/dev                  │
│         (Existing - UNTOUCHED)                      │
│                                                     │
│  ├─ EKS Cluster (wk-dev-eks)                       │
│  ├─ VPC & Networking                               │
│  └─ Apollo Router                                  │
└──────────────────┬──────────────────────────────────┘
                   │
                   │ References (data source)
                   ▼
┌─────────────────────────────────────────────────────┐
│      terraform/environments/dev-accounts-api        │
│      (New - Separate State)                         │
│                                                     │
│  ├─ ECR Repository (worldkinect/accounts-api)      │
│  ├─ IAM Role (IRSA)                                │
│  ├─ Kubernetes Deployment                          │
│  ├─ Kubernetes Service                             │
│  └─ Service Account                                │
└─────────────────────────────────────────────────────┘
                   │
                   │ Deployed to
                   ▼
┌─────────────────────────────────────────────────────┐
│              EKS Cluster: wk-dev-eks                │
│                                                     │
│  Namespace: apollo-system                           │
│  ├─ apollo-router (from dev env)                   │
│  └─ accounts-api (from dev-accounts-api env)       │
└─────────────────────────────────────────────────────┘
```

## Benefits of This Approach

✅ **Separate State** - Changes to accounts-api don't affect EKS/Router  
✅ **Independent Deployment** - Deploy accounts-api without touching dev environment  
✅ **Clear Separation** - Easy to understand what each environment manages  
✅ **Reusable Module** - Can create prod-accounts-api, staging-accounts-api easily  
✅ **Safe** - No risk of accidentally modifying core infrastructure  

## Terraform State

Each environment has its own state file:

- `env/dev/terraform.tfstate` - EKS cluster, networking, apollo-router
- `env/dev-accounts-api/terraform.tfstate` - accounts-api only

Both stored in the same S3 bucket but different keys.

## Adding More Subgraphs

To add another subgraph (e.g., `user-api`):

1. Copy `dev-accounts-api` to `dev-user-api`
2. Update `terraform.tfvars` with new values
3. Follow same deployment process

Each subgraph gets its own environment folder!

## Troubleshooting

### "Cluster not found"

Make sure `eks_cluster_name` in `terraform.tfvars` matches your existing cluster:

```bash
# Check cluster name
kubectl config current-context

# Or list all clusters
aws eks list-clusters --region us-east-1
```

### "OIDC provider not found"

Your EKS cluster must have OIDC enabled. Check in `environments/dev/main.tf`:

```hcl
enable_irsa = true  # Should be true
```

### "ImagePullBackOff"

```bash
# Check if image exists in ECR
aws ecr describe-images \
  --repository-name worldkinect/accounts-api \
  --region us-east-1

# If no images, build and push
cd ~/worldkinect
./scripts/build-and-push.sh
```

### State Lock Errors

```bash
# If terraform is stuck
terraform force-unlock <LOCK_ID>

# Or remove stale lock from DynamoDB
aws dynamodb delete-item \
  --table-name terraform-locks \
  --key '{"LockID":{"S":"kinect-terraform-state/env/dev-accounts-api/terraform.tfstate"}}'
```

## Next Steps

1. ✅ Deploy accounts-api (this guide)
2. Update Apollo Router supergraph config to include accounts-api
3. Test end-to-end GraphQL queries
4. Set up CI/CD for automated deployments
5. Create staging and production environments

## Support

- Check status: `./scripts/status.sh`
- View logs: `kubectl logs -f deployment/accounts-api -n apollo-system`
- Terraform docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- Kubernetes docs: https://kubernetes.io/docs/
