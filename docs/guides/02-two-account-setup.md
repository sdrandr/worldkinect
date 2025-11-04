# Two-Account Setup Guide

Your IAM architecture with `sdrandrUser1` (admin) and `terraform-admin` (working user).

---

## 🎯 Your Account Strategy

```
┌──────────────────────────────────────────────────────────┐
│  sdrandrUser1 (Admin - DO NOT USE for daily work)       │
│  ├─ Purpose: Account management only                     │
│  ├─ Use for:                                             │
│  │  ├─ Creating terraform-admin user                     │
│  │  ├─ Granting permissions to terraform-admin           │
│  │  ├─ Emergency access                                  │
│  │  └─ Billing and account settings                      │
│  └─ DO NOT USE for: Terraform, EKS, ECR, deployments     │
└──────────────────────────────────────────────────────────┘
                            │
                            │ manages
                            ▼
┌──────────────────────────────────────────────────────────┐
│  terraform-admin (Working User - USE THIS)               │
│  ├─ Purpose: All infrastructure and deployments          │
│  ├─ Use for:                                             │
│  │  ├─ Terraform operations                              │
│  │  ├─ EKS cluster management                            │
│  │  ├─ ECR image pushes                                  │
│  │  ├─ Apollo/GraphQL deployments                        │
│  │  ├─ All scripts execution                             │
│  │  └─ Daily development work                            │
│  └─ Configured on your Mac as default AWS profile        │
└──────────────────────────────────────────────────────────┘
```

---

## ✅ **Step 1: Grant Permissions to terraform-admin (Use sdrandrUser1)**

### **Switch to Admin Account:**

```bash
# Configure sdrandrUser1 (one-time)
aws configure --profile admin
# Enter sdrandrUser1 credentials

# Use admin profile temporarily
export AWS_PROFILE=admin

# Verify
aws sts get-caller-identity
# Should show: sdrandrUser1
```

### **Attach Policy to terraform-admin:**

**Option A: Attach AWS Managed Policies (Quick):**

```bash
# Grant broad permissions (good for development)
aws iam attach-user-policy \
  --user-name terraform-admin \
  --policy-arn arn:aws:iam::aws:policy/PowerUserAccess

aws iam attach-user-policy \
  --user-name terraform-admin \
  --policy-arn arn:aws:iam::aws:policy/IAMFullAccess
```

**Option B: Create Custom Policy (Recommended for Production):**

```bash
# Save the policy JSON (see artifact: "Required IAM Policy for terraform-admin")
# to: terraform/bootstrap/policies/terraform-admin-policy.json

# Create the policy
aws iam create-policy \
  --policy-name TerraformAdmin-CustomPolicy \
  --policy-document file://terraform/bootstrap/policies/terraform-admin-policy.json

# Get your account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Attach to terraform-admin
aws iam attach-user-policy \
  --user-name terraform-admin \
  --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/TerraformAdmin-CustomPolicy
```

### **Verify Policies Attached:**

```bash
aws iam list-attached-user-policies --user-name terraform-admin
```

### **Switch Back to terraform-admin:**

```bash
# Done with admin account
unset AWS_PROFILE

# Or set to terraform-admin
export AWS_PROFILE=terraform-admin
```

---

## ✅ **Step 2: Configure Your Mac for terraform-admin**

### **Configure AWS CLI:**

```bash
# Set terraform-admin as default
aws configure

# Enter terraform-admin credentials:
# AWS Access Key ID: <terraform-admin-key>
# AWS Secret Access Key: <terraform-admin-secret>
# Default region: us-east-1
# Default output: json
```

### **Verify Configuration:**

```bash
# Check current user
aws sts get-caller-identity

# Should show:
# "Arn": "arn:aws:iam::<account>:user/terraform-admin"
# "UserId": "<userid>"
# "Account": "<account-id>"
```

### **Make it Permanent:**

Add to your shell profile (`~/.zshrc` or `~/.bash_profile`):

```bash
# Default to terraform-admin
export AWS_PROFILE=default  # or omit AWS_PROFILE to use default

# Keep admin profile for emergencies
alias aws-admin='export AWS_PROFILE=admin'
alias aws-terraform='export AWS_PROFILE=default'
```

---

## ✅ **Step 3: Verify terraform-admin Permissions**

### **Run Verification Script:**

```bash
# Make executable
chmod +x scripts/verify-terraform-admin.sh

# Run verification
./scripts/verify-terraform-admin.sh
```

**Expected output:**
```
✓ Correct user: terraform-admin
✓ ECR access: OK
✓ EKS access: OK
✓ S3 access: OK
✓ DynamoDB access: OK
...
```

**If any tests fail:**
- Switch back to `sdrandrUser1` (admin)
- Grant missing permissions
- Re-run verification

---

## 📝 **Updated Script Usage with terraform-admin**

All your scripts now automatically use terraform-admin:

### **Setup:**
```bash
./scripts/setup-accounts-api-eks.sh
```

### **Build & Deploy:**
```bash
./scripts/build-and-push.sh
./scripts/deploy-to-eks.sh
```

### **Full Pipeline:**
```bash
./scripts/ci-cd-pipeline.sh
```

**All scripts will use the AWS credentials configured with `aws configure`** (which should be terraform-admin).

---

## 🔐 **Managing Two Profiles**

### **Create Both Profiles:**

```bash
# Configure admin profile (use sparingly)
aws configure --profile admin
# Enter sdrandrUser1 credentials

# Configure default profile (daily use)
aws configure
# Enter terraform-admin credentials
```

### **View Configuration:**

```bash
# View all profiles
cat ~/.aws/credentials

# Should show:
# [default]
# aws_access_key_id = <terraform-admin-key>
# aws_secret_access_key = <terraform-admin-secret>
#
# [admin]
# aws_access_key_id = <sdrandrUser1-key>
# aws_secret_access_key = <sdrandrUser1-secret>
```

### **Switch Between Profiles:**

```bash
# Use terraform-admin (default)
unset AWS_PROFILE
# or
export AWS_PROFILE=default

# Temporarily use admin
export AWS_PROFILE=admin

# Verify
aws sts get-caller-identity

# Switch back
unset AWS_PROFILE
```

---

## 🚨 **When to Use Each Account**

### **Use terraform-admin for:**
✅ All Terraform operations  
✅ All EKS deployments  
✅ All ECR operations  
✅ Running deployment scripts  
✅ Local development  
✅ 99% of your work  

### **Use sdrandrUser1 ONLY for:**
🔐 Creating new IAM users  
🔐 Modifying IAM policies  
🔐 Account-level settings  
🔐 Billing configuration  
🔐 Emergency access  

---

## 🛡️ **Security Best Practices**

### **1. Separate Credentials Files:**

```bash
# Store admin credentials separately (more secure)
mkdir -p ~/.aws-secure
chmod 700 ~/.aws-secure

# Move admin credentials
echo "[admin]
aws_access_key_id = <sdrandrUser1-key>
aws_secret_access_key = <sdrandrUser1-secret>" > ~/.aws-secure/admin-credentials

chmod 600 ~/.aws-secure/admin-credentials
```

### **2. Use MFA for Admin Account:**

```bash
# Enable MFA for sdrandrUser1
# AWS Console → IAM → Users → sdrandrUser1 → Security credentials → Enable MFA
```

### **3. Rotate terraform-admin Keys Regularly:**

```bash
# Every 90 days, using admin account:
export AWS_PROFILE=admin

# Create new key
aws iam create-access-key --user-name terraform-admin

# Update your ~/.aws/credentials with new key

# Delete old key
aws iam delete-access-key \
  --user-name terraform-admin \
  --access-key-id <OLD_KEY_ID>
```

### **4. Never Commit Credentials:**

```bash
# Add to .gitignore
cat >> .gitignore << EOF
.aws/
.aws-credentials-*
*.pem
*.key
.env.local
EOF
```

---

## 📊 **Checking Current Configuration**

### **Quick Status Check:**

```bash
# Who am I?
aws sts get-caller-identity

# What profile am I using?
echo $AWS_PROFILE

# What permissions do I have?
aws iam list-attached-user-policies --user-name terraform-admin

# What can I access?
aws eks list-clusters
aws ecr describe-repositories
```

---

## 🔧 **Troubleshooting**

### **Issue: "Access Denied" errors**

```bash
# Check current user
aws sts get-caller-identity

# If showing terraform-admin but still getting access denied:
# Switch to admin and grant permissions
export AWS_PROFILE=admin

# Grant missing permission
aws iam attach-user-policy \
  --user-name terraform-admin \
  --policy-arn arn:aws:iam::aws:policy/<PolicyName>

# Switch back
unset AWS_PROFILE
```

### **Issue: Scripts using wrong credentials**

```bash
# Check environment
env | grep AWS

# Clear any AWS environment variables
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN
unset AWS_PROFILE

# Or set explicitly
export AWS_PROFILE=default
```

### **Issue: Can't remember which account I'm using**

```bash
# Add to your shell prompt (zsh/bash)
# Add to ~/.zshrc or ~/.bashrc:

parse_aws_profile() {
  if [ -n "$AWS_PROFILE" ]; then
    echo " ☁️ $AWS_PROFILE"
  else
    echo " ☁️ default"
  fi
}

# Then in your prompt:
PS1='%n@%m $(parse_aws_profile) %~ $ '
```

---

## 📋 **Complete Setup Checklist**

Using **sdrandrUser1** (one-time):
- [ ] Grant permissions to terraform-admin
- [ ] Verify policies attached
- [ ] Enable MFA on sdrandrUser1

Using **terraform-admin** (daily):
- [ ] Configure as default AWS profile
- [ ] Run verification script
- [ ] Test ECR access
- [ ] Test EKS access
- [ ] Run deployment scripts

---

## 🎯 **Quick Reference**

```bash
# ============================================================
# Daily Commands (terraform-admin)
# ============================================================

# Verify identity
aws sts get-caller-identity

# Deploy
./scripts/ci-cd-pipeline.sh

# Build and push
./scripts/build-and-push.sh

# Deploy to EKS
./scripts/deploy-to-eks.sh

# ============================================================
# Admin Commands (sdrandrUser1 - USE SPARINGLY)
# ============================================================

# Switch to admin
export AWS_PROFILE=admin

# Grant permissions
aws iam attach-user-policy \
  --user-name terraform-admin \
  --policy-arn <policy-arn>

# Switch back
unset AWS_PROFILE
```

---

## ✅ **Summary**

**Your Setup:**
- 🔐 **sdrandrUser1**: Admin account (emergency only)
- 🛠️ **terraform-admin**: Working account (daily use)

**Your Mac:**
- Default AWS profile → terraform-admin
- Admin profile → sdrandrUser1 (when needed)

**Scripts:**
- All use default profile (terraform-admin)
- No changes needed to scripts

**Ready to deploy!** 🚀

```bash
# Verify you're using terraform-admin
./scripts/verify-terraform-admin.sh

# Then deploy
./scripts/ci-cd-pipeline.sh
```