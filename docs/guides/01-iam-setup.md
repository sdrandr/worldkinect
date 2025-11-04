# IAM Setup Guide - Accounts API EKS Deployment

This guide covers all IAM requirements for deploying from your Mac and CI/CD pipelines.

---

## 🎯 IAM Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    Your Mac (Local)                     │
│  AWS CLI configured with your personal IAM user         │
│  - Deploys manually                                     │
│  - Runs scripts locally                                 │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│              GitHub Actions / Jenkins                   │
│  IAM User: accounts-api-cicd                            │
│  - Automated deployments                                │
│  - Build & push Docker images                           │
│  - Deploy to EKS                                        │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│                    AWS EKS Cluster                      │
│  IAM Role: AccountsAPI-EKS-ServiceAccount-Role          │
│  - Assumed by pods via IRSA                             │
│  - Access to AWS services (RDS, Secrets Manager, etc)   │
└─────────────────────────────────────────────────────────┘
```

---

## 📋 Prerequisites

### 1. Your Mac Setup

```bash
# Install AWS CLI
brew install awscli

# Configure AWS CLI with your credentials
aws configure

# Verify
aws sts get-caller-identity
```

### 2. Your IAM User Requirements

Your personal IAM user needs these permissions:
- **ECR:** Full access to push/pull images
- **EKS:** Describe cluster, update kubeconfig
- **IAM:** Create users, roles, policies (if running setup script)

**Minimum policy for your user:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:*",
        "eks:DescribeCluster",
        "eks:ListClusters",
        "iam:GetUser",
        "iam:CreateUser",
        "iam:CreatePolicy",
        "iam:AttachUserPolicy",
        "sts:GetCallerIdentity"
      ],
      "Resource": "*"
    }
  ]
}
```

---

## 🚀 Quick Setup

### Run the IAM Setup Script

```bash
# Make executable
chmod +x scripts/setup-iam-permissions.sh

# Run setup
./scripts/setup-iam-permissions.sh
```

This creates:
1. ✅ IAM Policy for CI/CD
2. ✅ IAM User for CI/CD (GitHub Actions/Jenkins)
3. ✅ Access keys for CI/CD user
4. ✅ IAM Role for EKS pods (IRSA)
5. ✅ Kubernetes ServiceAccount

---

## 🔑 IAM Resources Created

### 1. CI/CD IAM Policy

**Name:** `AccountsAPI-CICD-Policy`

**Permissions:**
- ECR: Push/pull images, create repositories
- EKS: Describe clusters, list clusters
- STS: Assume roles, get caller identity

**ARN:** `arn:aws:iam::<ACCOUNT_ID>:policy/AccountsAPI-CICD-Policy`

---

### 2. CI/CD IAM User

**Name:** `accounts-api-cicd`

**Purpose:** Used by GitHub Actions and Jenkins for automated deployments

**Attached Policies:**
- `AccountsAPI-CICD-Policy`

**Access Keys:** Saved to `.aws-credentials-accounts-api-cicd.txt`

---

### 3. EKS Service Account IAM Role (IRSA)

**Name:** `AccountsAPI-EKS-ServiceAccount-Role`

**Purpose:** Assumed by pods running in EKS

**Trust Relationship:** OIDC provider for EKS cluster

**Permissions:**
- Secrets Manager: Read secrets for accounts-api
- RDS: Describe database instances
- DynamoDB: Read/write to accounts tables

**ARN:** `arn:aws:iam::<ACCOUNT_ID>:role/AccountsAPI-EKS-ServiceAccount-Role`

---

## 🔐 Local Development (Your Mac)

### Option 1: Use Your Personal IAM User (Recommended)

```bash
# Already configured with aws configure
aws sts get-caller-identity

# Deploy using your credentials
./scripts/build-and-push.sh
./scripts/deploy-to-eks.sh
```

**Pros:**
- ✅ No additional setup needed
- ✅ Uses your existing permissions
- ✅ Audit trail tied to your user

**Cons:**
- ⚠️ Need sufficient IAM permissions
- ⚠️ Shared credentials with other projects

---

### Option 2: Use CI/CD User Locally (Not Recommended)

```bash
# Export the CI/CD user credentials
export AWS_ACCESS_KEY_ID=<from-credentials-file>
export AWS_SECRET_ACCESS_KEY=<from-credentials-file>

# Or configure a separate profile
aws configure --profile cicd

# Use the profile
AWS_PROFILE=cicd ./scripts/build-and-push.sh
```

**Only use this for testing CI/CD credentials!**

---

## 🤖 GitHub Actions Setup

### 1. Add Secrets to GitHub

Go to: **GitHub Repo → Settings → Secrets and variables → Actions**

Add these secrets:

```
AWS_ACCESS_KEY_ID=<from .aws-credentials-accounts-api-cicd.txt>
AWS_SECRET_ACCESS_KEY=<from .aws-credentials-accounts-api-cicd.txt>
AWS_REGION=us-east-1
```

### 2. Add Workflow File

File: `.github/workflows/deploy-accounts-api.yml`

(See artifact: "GitHub Actions Workflow - Deploy to EKS")

### 3. Configure Environments (Optional but Recommended)

Create environments in GitHub:
- **Settings → Environments → New environment**

Create three environments:
- `dev` - Auto-deploy on push to main
- `staging` - Auto-deploy on push to staging branch
- `prod` - Requires approval before deployment

**Environment protection rules:**
- `dev`: No restrictions
- `staging`: Require reviewers (optional)
- `prod`: Require reviewers (required)

### 4. Trigger Deployment

```bash
# Push to main → Auto-deploys to dev
git push origin main

# Push to staging → Auto-deploys to staging
git push origin staging

# Push to production → Auto-deploys to prod (with approval)
git push origin production

# Or trigger manually
# Go to: Actions → Deploy Accounts API to EKS → Run workflow
```

---

## 🏗️ Jenkins Setup

### 1. Add AWS Credentials to Jenkins

**Go to:** Jenkins → Credentials → System → Global credentials → Add Credentials

- **Kind:** AWS Credentials
- **ID:** `aws-credentials`
- **Access Key ID:** `<from .aws-credentials-accounts-api-cicd.txt>`
- **Secret Access Key:** `<from .aws-credentials-accounts-api-cicd.txt>`
- **Description:** AWS credentials for Accounts API deployments

### 2. Add Jenkinsfile

File: `jenkins/Jenkinsfile`

(See artifact: "Jenkinsfile - Jenkins Pipeline")

### 3. Create Jenkins Pipeline

1. **New Item → Pipeline**
2. **Name:** `accounts-api-deploy`
3. **Pipeline:**
   - Definition: Pipeline script from SCM
   - SCM: Git
   - Repository URL: `<your-github-repo>`
   - Script Path: `jenkins/Jenkinsfile`

### 4. Configure Build Parameters

The Jenkinsfile includes parameters:
- **ENVIRONMENT:** dev / staging / prod
- **SKIP_TESTS:** true / false
- **DRY_RUN:** true / false

### 5. Run Pipeline

Click **Build with Parameters** and select:
- Environment: `dev`
- Skip Tests: `false`
- Dry Run: `false`

---

## 🎭 IAM Roles for Services (IRSA)

### What is IRSA?

**IAM Roles for Service Accounts** - Allows Kubernetes pods to assume IAM roles without storing credentials.

### How It Works

```
Pod → ServiceAccount → IAM Role → AWS Services
```

1. Pod uses Kubernetes ServiceAccount
2. ServiceAccount has annotation with IAM Role ARN
3. EKS injects credentials via OIDC
4. Pod can call AWS APIs

### Setup IRSA

**1. Apply Kubernetes ServiceAccount:**

```bash
kubectl apply -f services/accounts-api/kubernetes/serviceaccount.yaml
```

**2. Update Deployment to use ServiceAccount:**

Add to `deployment.yaml` under `spec.template.spec`:

```yaml
spec:
  template:
    spec:
      serviceAccountName: accounts-api  # ← Add this
      containers:
      - name: accounts-api
        # ... rest of container spec
```

**3. Verify:**

```bash
# Check ServiceAccount
kubectl describe sa accounts-api

# Should show annotation:
# eks.amazonaws.com/role-arn: arn:aws:iam::<ACCOUNT>:role/AccountsAPI-EKS-ServiceAccount-Role

# Test from pod
kubectl exec -it <pod-name> -- env | grep AWS
```

---

## 🔍 Testing IAM Permissions

### Test CI/CD User Permissions

```bash
# Export credentials
export AWS_ACCESS_KEY_ID=<from-file>
export AWS_SECRET_ACCESS_KEY=<from-file>

# Test ECR access
aws ecr describe-repositories --repository-names worldkinect/accounts-api

# Test EKS access
aws eks describe-cluster --name worldkinect-dev

# Test STS
aws sts get-caller-identity
```

### Test IRSA from Pod

```bash
# Get a pod
POD_NAME=$(kubectl get pods -l app=accounts-api -o jsonpath='{.items[0].metadata.name}')

# Check AWS credentials are injected
kubectl exec -it $POD_NAME -- env | grep AWS

# Should see:
# AWS_ROLE_ARN=arn:aws:iam::<ACCOUNT>:role/AccountsAPI-EKS-ServiceAccount-Role
# AWS_WEB_IDENTITY_TOKEN_FILE=/var/run/secrets/eks.amazonaws.com/serviceaccount/token

# Test AWS API call from pod
kubectl exec -it $POD_NAME -- aws sts get-caller-identity

# Should show the IAM role, not the user
```

---

## 🛡️ Security Best Practices

### 1. Principle of Least Privilege

✅ **DO:**
- Grant only required permissions
- Use separate IAM users for CI/CD
- Rotate access keys regularly

❌ **DON'T:**
- Use root account credentials
- Grant Administrator access
- Share access keys

### 2. Access Key Rotation

```bash
# Create new access key
aws iam create-access-key --user-name accounts-api-cicd

# Update GitHub secrets with new key

# Delete old access key
aws iam delete-access-key \
  --user-name accounts-api-cicd \
  --access-key-id <OLD_KEY_ID>
```

**Schedule:** Rotate every 90 days

### 3. Audit and Monitoring

```bash
# List all access keys for user
aws iam list-access-keys --user-name accounts-api-cicd

# Check last used
aws iam get-access-key-last-used --access-key-id <KEY_ID>

# Enable CloudTrail for audit logs
```

### 4. Secure Credentials Storage

**Local Development:**
```bash
# Never commit credentials to Git!
echo ".aws-credentials-*" >> .gitignore

# Use AWS CLI profiles
aws configure --profile worldkinect

# Use temporary credentials (SSO)
aws sso login --profile worldkinect
```

**CI/CD:**
- ✅ Use GitHub Secrets (encrypted at rest)
- ✅ Use Jenkins Credentials (encrypted)
- ✅ Use AWS Secrets Manager for sensitive data
- ❌ Never hardcode in code or config files

---

## 🔧 Troubleshooting

### Issue: Access Denied Errors

```bash
# Check who you are
aws sts get-caller-identity

# Check user permissions
aws iam list-attached-user-policies --user-name <your-username>

# Check role permissions
aws iam get-role --role-name AccountsAPI-EKS-ServiceAccount-Role
```

### Issue: Pod Can't Access AWS Services

```bash
# Check ServiceAccount exists
kubectl get sa accounts-api

# Check ServiceAccount has IAM role annotation
kubectl describe sa accounts-api

# Check pod is using ServiceAccount
kubectl get pod <pod-name> -o yaml | grep serviceAccountName

# Check OIDC provider exists
aws iam list-open-id-connect-providers

# Check trust relationship on role
aws iam get-role --role-name AccountsAPI-EKS-ServiceAccount-Role
```

### Issue: Cannot Update Kubeconfig

```bash
# Check EKS permissions
aws eks describe-cluster --name worldkinect-dev

# Update kubeconfig
aws eks update-kubeconfig \
  --region us-east-1 \
  --name worldkinect-dev

# Verify kubectl works
kubectl get nodes
```

---

## 📚 IAM Policy Reference

### Minimum Policy for Local Development

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ECRAccess",
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ],
      "Resource": "*"
    },
    {
      "Sid": "EKSAccess",
      "Effect": "Allow",
      "Action": [
        "eks:DescribeCluster"
      ],
      "Resource": "arn:aws:eks:*:*:cluster/worldkinect-*"
    }
  ]
}
```

### Full CI/CD Policy

See: `terraform/bootstrap/policies/accounts-api-cicd-policy.json`

### Service Account Policy

See: `terraform/bootstrap/policies/eks-service-account-permissions.json`

---

## 🎓 Summary

**You need 3 types of IAM credentials:**

1. **Your Mac (Local):**
   - Use your personal IAM user
   - Configured with `aws configure`

2. **GitHub Actions / Jenkins (CI/CD):**
   - Use `accounts-api-cicd` IAM user
   - Access keys stored in GitHub Secrets / Jenkins Credentials

3. **EKS Pods (Runtime):**
   - Use `AccountsAPI-EKS-ServiceAccount-Role` IAM role
   - Assumed automatically via IRSA

**Quick Setup:**
```bash
./scripts/setup-iam-permissions.sh
```

Done! 🎉