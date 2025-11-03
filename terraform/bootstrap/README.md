# Terraform AWS Bootstrap Automation

A **secure, idempotent, and fully automated** bootstrap process for initializing Terraform state management in AWS.

This project provisions and configures:

- **S3 bucket** for remote state storage  
- **DynamoDB table** for state locking  
- **KMS key + alias** for encryption  
- **IAM user** (`terraform-admin`) with **least-privilege** access  
- **Temporary elevated permissions** (auto-cleaned)

---

## Project Structure

```bash
terraform/
├── bootstrap/
│   ├── bootstrap-full.sh                     # Main orchestrator
│   ├── add-temp-terraform-permissions.sh     # Grants temp IAM policy
│   ├── precheck-aws-resources-import.sh      # Validates & imports existing resources
│   ├── TerraformBootstrapTempAccess.json     # Temp policy template
│   └── *.log                                 # Auto-generated logs
├── main.tf
├── versions.tf
├── backend.tf
└── outputs.tf

Requirements





















ToolVersionAWS CLIv2.0+Terraformv1.5+Bash5.x+

Verify:
bashaws --version
terraform --version
bash --version

AWS Profiles Required

















ProfilePurpose--admin-profileFull IAM + S3 + DynamoDB + KMS permissions (e.g., sdrandrUser1)--target-userTerraform runtime user (e.g., terraform-admin)

Quick Start
bashgit clone <your-repo-url>
cd terraform/bootstrap

# Run bootstrap
DEBUG=1 ./bootstrap-full.sh \
  --admin-profile sdrandrUser1 \
  --target-user terraform-admin

Bootstrap Flow (ASCII Diagram)
text+------------------+     +---------------------+
|  Admin Profile   |     |  Target User        |
| (sdrandrUser1)   |     | (terraform-admin)   |
+--------+---------+     +--------+------------+
         |                        |
         | 1. Grant temp policy   |
         +------------------------+
                  |
                  v
+------------------+------------------+
| precheck-aws-resources-import.sh   |
| → Detects & imports existing:      |
|   • S3 bucket                     |
|   • DynamoDB table                |
|   • KMS key + alias               |
+-----------------------------------+
                  |
                  v
+------------------+------------------+
| terraform init + apply             |
| → Creates missing resources        |
| → Finalizes encryption & locking   |
+-----------------------------------+
                  |
                  v
         +--------v---------+
         | Remove temp policy |
         +--------------------+

Scripts Overview
bootstrap-full.sh
Orchestrator — runs all steps in sequence.
Features:

Centralized logging (bootstrap-full.*.log)
Step-by-step validation
Automatic cleanup on exit
DEBUG=1 for verbose output

bashUsage: ./bootstrap-full.sh --admin-profile <admin> --target-user <user>

add-temp-terraform-permissions.sh
Grants temporary god-mode to terraform-admin.
Actions:

Generates TerraformBootstrapTempAccess.json
Attaches inline policy
Logs to add_temp_perms.*.log
Idempotent (skips if exists)

Cleanup (auto or manual):
bashaws iam delete-user-policy \
  --user-name terraform-admin \
  --policy-name TerraformBootstrapTempAccess \
  --profile sdrandrUser1

precheck-aws-resources-import.sh
Pre-flight check — avoids duplicates.





















ResourceActionS3 kinect-terraform-stateImport if existsDynamoDB kinect-terraform-locksImport if existsKMS alias/terraformImport key + alias
Output: Summary table + detailed log

Logging & Debugging

All logs in bootstrap/ with timestamped prefixes
DEBUG=1 enables full command tracing
Unified log: bootstrap-full.*.log

Example:
log[2025-10-29 12:45:36] Step 3: Running Terraform in /Users/.../bootstrap
[2025-10-29 12:45:36] terraform apply -auto-approve
[2025-10-29 12:46:02] Apply complete! Resources: 1 added.

Cleanup (Post-Bootstrap)
bash# Remove temp policy (required)
aws iam delete-user-policy \
  --user-name terraform-admin \
  --policy-name TerraformBootstrapTempAccess \
  --profile sdrandrUser1

# Optional: remove logs
rm -f bootstrap/*.log bootstrap/*.json

Verification
1. Test Terraform State
bashcd ../..
terraform init
terraform state list
Expected:
textaws_s3_bucket.tf_state
aws_dynamodb_table.terraform_locks
aws_kms_key.terraform_key
aws_kms_alias.terraform_alias
2. Check AWS Console





















ServiceResourceS3kinect-terraform-state (versioning + encryption)DynamoDBkinect-terraform-locksKMSalias/terraform → key 95c3ed54-...

Permanent terraform-admin Policy (Least Privilege)
json{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::kinect-terraform-state",
        "arn:aws:s3:::kinect-terraform-state/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem",
        "dynamodb:DescribeTable"
      ],
      "Resource": "arn:aws:dynamodb:us-east-1:891377181070:table/kinect-terraform-locks"
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:GenerateDataKey"
      ],
      "Resource": "arn:aws:kms:us-east-1:891377181070:key/95c3ed54-e836-48a5-9bd6-5ea8fff56126"
    }
  ]
}

Update key ID from terraform output backend_kms_key_id


Final Backend Config (backend.tf)
hclterraform {
  backend "s3" {
    bucket         = "kinect-terraform-state"
    key            = "global/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "kinect-terraform-locks"
    encrypt        = true
    kms_key_id     = "alias/terraform"
    profile        = "terraform-admin"
  }
}

Next Steps

Create environment modules (env/dev, env/prod)
Migrate state to remote backend (if needed)
Apply first module using terraform-admin

bashterraform init -backend-config="key=env/dev.tfstate"
terraform apply

References

AWS IAM Best Practices
Terraform S3 Backend
KMS Key Rotation


You now have a production-grade, secure, and auditable Terraform bootstrap.

text---

**This README is now:**
- Clean & professional
- Actionable
- Visual (ASCII flow)
- Secure (least privilege)
- Ready for team onboarding