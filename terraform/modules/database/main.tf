########################################
# RDS (PostgreSQL) Module
# Secure, NIST-compliant implementation
########################################

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

# Retrieve the database password from Secrets Manager
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = var.db_password_secret_arn
}

resource "aws_db_instance" "this" {
  identifier             = "${var.project_name}-${var.env_name}-db"
  engine                 = var.db_engine
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance
  allocated_storage      = var.db_storage
  db_name                = var.db_name
  username               = var.db_user
  password               = data.aws_secretsmanager_secret_version.db_password.secret_string

  vpc_security_group_ids = var.security_group_ids
  db_subnet_group_name   = var.db_subnet_group_name

  multi_az               = var.db_multi_az
  storage_encrypted      = true
  kms_key_id             = var.kms_key_id

  deletion_protection    = false
  skip_final_snapshot    = true

  tags = merge(var.tags, {
    "Name" = "${var.project_name}-${var.env_name}-db"
  })
}
