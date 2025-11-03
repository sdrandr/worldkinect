########################################
# terraform.tfvars
# Environment-specific configuration (Dev)
########################################

#################################################
# Core / Environment
#################################################
env_name   = "dev"
aws_region = "us-east-1"
account_id = "891377181070"

tags = {
  Environment = "dev"
}

#################################################
# Networking
#################################################
vpc_cidr        = "10.0.0.0/16"
private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

#################################################
# ECS Application Configuration
#################################################
ecs_container_port = 4000

#################################################
# Database Configuration
#################################################
db_name                = "energy_db"
db_user                = "energyadmin"
db_password_secret_arn = "arn:aws:secretsmanager:us-east-1:891377181070:secret:dev-db-password-LFBlh7"
db_instance            = "db.t3.micro"
db_storage             = 20
db_engine              = "postgres"
db_engine_version      = "15.4"

#################################################
# Backend / State Management (optional overrides)
#################################################
dynamodb_table = "terraform-locks"
kms_key_alias  = "alias/terraform"
kms_key_id     = "arn:aws:kms:us-east-1:891377181070:key/1234abcd-56ef-78gh-90ij-1234567890ab"

