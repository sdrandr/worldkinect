########################################
# Terraform Backend — dev-ingress
########################################

terraform {
  backend "s3" {
    bucket         = "kinect-terraform-state"
    key            = "env/dev-ingress/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    profile        = "terraform-admin"
  }
}
