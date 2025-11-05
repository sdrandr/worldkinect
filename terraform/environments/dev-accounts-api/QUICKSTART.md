# 🚀 Accounts API - Complete Setup Guide (Separate Environment)

## 📋 Overview

This guide sets up accounts-api in a **completely separate** Terraform environment from your existing `environments/dev` setup. Your EKS cluster and Apollo Router remain untouched.

---

## ⚡ Quick Start (5 Commands)

```bash
# 1. Run automated setup
cd ~/worldkinect
chmod +x setup-accounts-api-env.sh
./setup-accounts-api-env.sh

# 2. Install Docker (one-time)
chmod +x install-docker.sh
./install-docker.sh
# Log out and back in, then continue

# 3. Build and push image
./scripts/build-and-push.sh

# 4. Deploy to EKS
cd terraform/environments/dev-accounts-api
./scripts/deploy.sh

# 5. Check status
./scripts/status.sh
```

That's it! 🎉

---

## 📦 What You Downloaded

| File | Purpose |
|------|---------|
| `setup-accounts-api-env.sh` | **Run this first** - Creates all directories and copies files |
| `install-docker.sh` | Installs Docker on Ubuntu |
| `terraform-module-accounts-api.tf` | Reusable Terraform module |
| `dev-accounts-api-*.tf` | Terraform config files |
| `deploy.sh` / `destroy.sh` / `status.sh` | Deployment scripts |
| `README-SEPARATE-SETUP.md` | Detailed documentation |

---

## 📂 What Gets Created

```
~/worldkinect/
├── terraform/
│   ├── environments/
│   │   ├── dev/                    ← EXISTING (untouched)
│   │   │   └── main.tf             ← EKS + Apollo Router
│   │   │
│   │   └── dev-accounts-api/       ← NEW (separate)
│   │       ├── main.tf             ← References existing EKS
│   │       ├── variables.tf
│   │       ├── terraform.tfvars
│   │       ├── outputs.tf
│   │       ├── README.md
│   │       └── scripts/
│   │           ├── deploy.sh
│   │           ├── destroy.sh
│   │           └── status.sh
│   │
│   └── modules/
│       └── accounts_api/           ← NEW module
│           └── main.tf
```

---

## 🔧 Detailed Steps

### Step 1: Setup Environment (Automated)

```bash
cd ~/worldkinect

# Download all files to current directory first
# Then run:
chmod +x setup-accounts-api-env.sh
./setup-accounts-api-env.sh
```

**This script will:**
- ✅ Create `terraform/modules/accounts_api/`
- ✅ Create `terraform/environments/dev-accounts-api/`
- ✅ Copy all files to correct locations
- ✅ Make scripts executable

---

### Step 2: Install Docker (One-Time)

```bash
chmod +x install-docker.sh
./install-docker.sh
```

**Important:** After installation, **log out and log back in** (or run `newgrp docker`)

**Verify:**
```bash
docker --version
docker run hello-world
```

---

### Step 3: Build and Push Image

```bash
cd ~/worldkinect
./scripts/build-and-push.sh
```

**This creates:**
- ✅ ECR repository: `worldkinect/accounts-api`
- ✅ Docker image with tags: `latest` and timestamp
- ✅ Pushes to ECR

**Expected output:**
```
✓ Build and Push Complete!
Image Details:
  Repository:  worldkinect/accounts-api
  Tags:        latest, 20241104-153045
  Full URI:    891377181070.dkr.ecr.us-east-1.amazonaws.com/worldkinect/accounts-api:latest
```

---

### Step 4: Deploy to EKS

```bash
cd ~/worldkinect/terraform/environments/dev-accounts-api
./scripts/deploy.sh
```

**This will:**
1. Initialize Terraform
2. Show plan
3. Ask for confirmation
4. Create all resources:
   - ECR repository
   - IAM role (IRSA)
   - Kubernetes deployment (2 pods)
   - Kubernetes service
   - Service account

---

### Step 5: Verify Deployment

```bash
# Check status
./scripts/status.sh

# Or manually:
kubectl get pods -n apollo-system -l app=accounts-api

# View logs
kubectl logs -f deployment/accounts-api -n apollo-system

# Test locally
kubectl port-forward svc/accounts-api 4000:4000 -n apollo-system
curl http://localhost:4000/.well-known/apollo/server-health
```

---

## 🎯 Key Points

### ✅ What This Does

- Creates **separate Terraform state** (`env/dev-accounts-api/terraform.tfstate`)
- References **existing EKS cluster** (doesn't create new one)
- Deploys **accounts-api** to same cluster as apollo-router
- Uses **same namespace** (`apollo-system`)
- Creates **own IAM role** and permissions

### ❌ What This Doesn't Touch

- Your existing `environments/dev/main.tf`
- Your EKS cluster configuration
- Your Apollo Router deployment
- Your VPC or networking

### 🔒 Safety

- Separate state = No risk to existing infrastructure
- Can destroy accounts-api without affecting anything else
- Can deploy/redeploy accounts-api independently

---

## 📊 Architecture

```
┌──────────────────────────────────────┐
│    environments/dev (UNTOUCHED)      │
│  ┌────────────────────────────────┐  │
│  │  EKS Cluster (wk-dev-eks)      │  │
│  │  VPC & Networking              │  │
│  │  Apollo Router                 │  │
│  └────────────────────────────────┘  │
└──────────────────┬───────────────────┘
                   │
        References │ (data source)
                   │
┌──────────────────▼───────────────────┐
│  environments/dev-accounts-api (NEW) │
│  ┌────────────────────────────────┐  │
│  │  ECR Repository                │  │
│  │  IAM Role (IRSA)               │  │
│  │  K8s Deployment                │  │
│  │  K8s Service                   │  │
│  └────────────────────────────────┘  │
└──────────────────┬───────────────────┘
                   │
        Deploys to │
                   │
┌──────────────────▼───────────────────┐
│  EKS Cluster: wk-dev-eks             │
│  Namespace: apollo-system            │
│  ┌────────────────────────────────┐  │
│  │  apollo-router (from dev)      │  │
│  │  accounts-api (from new env)   │  │
│  └────────────────────────────────┘  │
└──────────────────────────────────────┘
```

---

## 🔄 Common Operations

### Deploy New Version

```bash
# Build new image
cd ~/worldkinect
./scripts/build-and-push.sh

# Restart pods to pull new image
kubectl rollout restart deployment/accounts-api -n apollo-system
kubectl rollout status deployment/accounts-api -n apollo-system
```

### Check Logs

```bash
kubectl logs -f deployment/accounts-api -n apollo-system
```

### Update Configuration

```bash
cd ~/worldkinect/terraform/environments/dev-accounts-api

# Edit values
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

---

## 🐛 Troubleshooting

### Docker not found after install

```bash
# Log out and back in, or:
newgrp docker
docker --version
```

### "Cluster not found" error

Check cluster name in `terraform.tfvars`:
```bash
# Should be: eks_cluster_name = "wk-dev-eks"
aws eks list-clusters --region us-east-1
```

### ImagePullBackOff

```bash
# Check if image exists
aws ecr describe-images \
  --repository-name worldkinect/accounts-api \
  --region us-east-1

# If no images, build and push
cd ~/worldkinect
./scripts/build-and-push.sh
```

### Pods CrashLoopBackOff

```bash
# Check logs for errors
kubectl logs deployment/accounts-api -n apollo-system

# Common issues:
# - Missing environment variables
# - Port conflicts
# - Application errors
```

---

## 📚 Additional Resources

- **[README-SEPARATE-SETUP.md](README-SEPARATE-SETUP.md)** - Detailed documentation
- **Terraform docs:** https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- **Kubernetes docs:** https://kubernetes.io/docs/
- **Apollo Federation:** https://www.apollographql.com/docs/federation/

---

## ✅ Success Checklist

- [ ] Setup script ran successfully
- [ ] Docker installed and working
- [ ] Image built and pushed to ECR
- [ ] Terraform applied without errors
- [ ] 2 pods running in `apollo-system` namespace
- [ ] Health endpoint responding
- [ ] Logs show no errors

---

## 🎉 Next Steps

1. **Update Apollo Router** to include accounts-api in supergraph
2. **Test end-to-end** GraphQL queries through router
3. **Set up CI/CD** (GitHub Actions or CodeBuild)
4. **Create staging environment** (copy to `staging-accounts-api`)
5. **Add more subgraphs** following same pattern

---

**Need help?** Run `./scripts/status.sh` to see current state or check logs with `kubectl logs -f deployment/accounts-api -n apollo-system`
