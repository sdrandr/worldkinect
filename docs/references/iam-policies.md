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

## Policy Best Practices

### Principle of Least Privilege

Only grant the minimum permissions required:

```json
{
  "Effect": "Allow",
  "Action": [
    "ecr:GetDownloadUrlForLayer",
    "ecr:BatchGetImage"
  ],
  "Resource": "arn:aws:ecr:us-east-1:*:repository/worldkinect/*"
}
```

### Use Resource-Specific ARNs

Avoid wildcards when possible:

```json
{
  "Resource": "arn:aws:eks:us-east-1:123456789012:cluster/worldkinect-*"
}
```

### Separate Policies by Purpose

- One policy for ECR access
- One policy for EKS access
- One policy for Secrets Manager

### Regular Audits

```bash
# Review attached policies
aws iam list-attached-user-policies --user-name terraform-admin

# Review policy versions
aws iam list-policy-versions --policy-arn <policy-arn>

# Get policy document
aws iam get-policy-version --policy-arn <arn> --version-id v1
```

---

## Resources

- [IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [IAM Policy Reference](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies.html)
- [EKS IAM Guide](https://docs.aws.amazon.com/eks/latest/userguide/security-iam.html)
