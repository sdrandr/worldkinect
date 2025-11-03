output "db_identifier" {
  value       = aws_db_instance.this.identifier
  description = "Database identifier"
}

output "db_endpoint" {
  value       = aws_db_instance.this.endpoint
  description = "Database endpoint address"
}

output "db_name" {
  value       = aws_db_instance.this.db_name
  description = "Database name"
}

output "db_arn" {
  value       = aws_db_instance.this.arn
  description = "RDS instance ARN"
}
