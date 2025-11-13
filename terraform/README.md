# Terraform Infrastructure

Infrastructure as Code for WorldKinect Accounts API deployment on AWS.

---

## 📁 Directory Structure

```
terraform/
├── bootstrap/              # Initial AWS infrastructure setup
│   ├── main.tf            # S3 bucket, DynamoDB, KMS for state
│   ├── outputs.tf         # Bootstrap outputs
│   └── README.md          # Bootstrap setup guide
├── common/                # Shared configurations
├── environments/          # Environment-specific configs
│   ├── dev/              # Development environment
│   ├── dev-accounts-api/ # Dev accounts-api specific
│   ├── dev-ingress/      # Dev ingress configuration
│   ├── staging/          # Staging environment
│   └── prod/             # Production environment
└── modules/              # Reusable Terraform modules
    └── irsa_apollo_router/  # IRSA for Apollo Router
```

---

## 🚀 Quick Start

### 1. Bootstrap (One-time Setup)

Create the S3 backend and DynamoDB table for Terraform state:

```bash
cd terraform/bootstrap

# Initialize Terraform
terraform init

# Plan the bootstrap
terraform plan

# Apply bootstrap resources
terraform apply
```

This creates:
- S3 bucket: `kinect-terraform-state`
- DynamoDB table: `terraform-locks`
- KMS key for encryption

### 2. Configure Backend

After bootstrap, other environments will use remote state:

```bash
cd terraform/environments/dev

# Backend is already configured in backend.tf
terraform init
```

---

## 🏗️ Infrastructure Components

### Bootstrap Infrastructure

**Purpose:** Set up Terraform state management

**Resources:**
- S3 bucket with versioning and encryption
- DynamoDB table for state locking
- KMS key for encryption

**Location:** `terraform/bootstrap/`

### Environment Infrastructure

Each environment (dev, staging, prod) provisions:
- EKS cluster configuration
- VPC and networking
- IAM roles and policies
- Security groups
- Load balancers

**Location:** `terraform/environments/{env}/`

### Modules

Reusable Terraform modules:

#### IRSA Apollo Router Module
**Purpose:** IAM Roles for Service Accounts for Apollo Router

**Location:** `terraform/modules/irsa_apollo_router/`

**Usage:**
```hcl
module "apollo_router_irsa" {
  source = "../../modules/irsa_apollo_router"

  cluster_name = "worldkinect-dev"
  namespace    = "default"
  # ... other variables
}
```

---

## 🔧 Managing Environments

### Development Environment

```bash
cd terraform/environments/dev

# Initialize
terraform init

# Plan changes
terraform plan

# Apply changes
terraform apply

# Destroy (careful!)
terraform destroy
```

### Staging Environment

```bash
cd terraform/environments/staging

terraform init
terraform plan
terraform apply
```

### Production Environment

```bash
cd terraform/environments/prod

# Always use plan first
terraform plan -out=prod.tfplan

# Review the plan carefully
# Then apply
terraform apply prod.tfplan
```

---

## 📝 Configuration Files

### backend.tf

Configures remote state storage:

```hcl
terraform {
  backend "s3" {
    bucket         = "kinect-terraform-state"
    key            = "env/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    profile        = "terraform-admin"
  }
}
```

### terraform.tfvars

Environment-specific variables (not committed to git):

```hcl
aws_region     = "us-east-1"
aws_account_id = "891377181070"
environment    = "dev"
project_name   = "worldkinect"
```

---

## 🔐 Security Best Practices

### State Management

- ✅ State stored in S3 with encryption
- ✅ State locking with DynamoDB
- ✅ Versioning enabled
- ✅ Access logging enabled

### Credentials

- ✅ Never commit `terraform.tfvars` with sensitive data
- ✅ Use AWS profiles (terraform-admin)
- ✅ Rotate access keys regularly
- ✅ Use IAM roles when possible

### Access Control

```bash
# Always verify who you are
aws sts get-caller-identity

# Should show: terraform-admin
```

---

## 🧪 Testing Infrastructure Changes

### Plan Before Apply

```bash
# Always run plan first
terraform plan

# Save plan for review
terraform plan -out=tfplan

# Apply the saved plan
terraform apply tfplan
```

### Validate Configuration

```bash
# Check syntax
terraform validate

# Format code
terraform fmt -recursive

# Check for issues
terraform validate
```

---

## 🔄 Common Operations

### View State

```bash
# List resources
terraform state list

# Show specific resource
terraform state show aws_eks_cluster.main

# Pull current state
terraform state pull > state.json
```

### Import Existing Resources

```bash
# Import existing resource
terraform import aws_s3_bucket.state kinect-terraform-state
```

### Refresh State

```bash
# Refresh state from AWS
terraform refresh
```

### Target Specific Resources

```bash
# Apply only specific resource
terraform apply -target=aws_eks_cluster.main

# Destroy specific resource
terraform destroy -target=aws_s3_bucket.logs
```

---

## 📊 Outputs

View outputs from Terraform:

```bash
# Show all outputs
terraform output

# Show specific output
terraform output eks_cluster_endpoint

# Output in JSON
terraform output -json
```

---

## 🐛 Troubleshooting

### State Lock Issues

```bash
# If state is locked, force unlock (use carefully!)
terraform force-unlock <lock-id>
```

### State Corruption

```bash
# Backup current state
terraform state pull > backup.tfstate

# Restore from backup
terraform state push backup.tfstate
```

### Permission Issues

```bash
# Check AWS credentials
aws sts get-caller-identity

# Verify terraform-admin has required permissions
./scripts/verify-terraform-admin.sh
```

---

## 📚 Resources

- **Terraform AWS Provider:** https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- **Terraform Best Practices:** https://www.terraform-best-practices.com/
- **AWS EKS Terraform:** https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest

---

## 🎯 Next Steps

1. Review bootstrap setup: `terraform/bootstrap/README.md`
2. Configure your environment in `terraform/environments/`
3. Customize modules as needed
4. Set up remote state
5. Plan and apply infrastructure

For detailed bootstrap instructions, see [terraform/bootstrap/README.md](bootstrap/README.md)
