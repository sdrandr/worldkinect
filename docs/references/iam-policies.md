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
