########################################
# locals.tf
# Enterprise/Federal shared local variables
########################################

locals {
  # Core identifiers
  project_name = "kinect"
  env_name     = terraform.workspace         # dev, staging, prod
  environment  = "env/${local.env_name}"

  # Common tags for all AWS resources
  common_tags = {
    Project     = local.project_name
    Environment = local.environment
    ManagedBy   = "Terraform"
    Compliance  = "NIST"
  }

  # Networking defaults
  vpc_cidr        = "10.0.0.0/16"
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  # ECS app configuration
  ecs_container_port = 4000

  # Database configuration
  db_name           = "energy_db"
  db_user           = "energyadmin"
  db_instance       = "db.t3.micro"
  db_storage        = 20
  db_engine         = "postgres"
  db_engine_version = "15.4"

  # Enterprise backend / state configuration
  region         = "us-east-1"
  s3_bucket_name = "${local.env_name}-${local.project_name}-tfstate"
  s3_key         = "terraform.tfstate"
  dynamodb_table = "terraform-locks"
  kms_key_alias  = "alias/terraform"   # optional friendly KMS alias
}
