aws configure --profile terraform-admin

aws secretsmanager create-secret \
  --profile terraform-admin \
  --name kinect-db-password \
  --description "Database password for kinect (managed outside Terraform)" \
  --secret-string "{\"password\":\"$DB_PASSWORD\"}" \
  --region us-east-1
