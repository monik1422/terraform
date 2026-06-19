output "rds_endpoint" {
  description = "RDS instance address (private)"
  value       = aws_db_instance.mysql.address
}

output "db_secret_arn" {
  description = "Secrets Manager ARN holding the master credentials"
  value       = aws_db_instance.mysql.master_user_secret[0].secret_arn
}

output "lambda_function_name" {
  value = aws_lambda_function.db_client.function_name
}

output "secretsmanager_vpc_endpoint_id" {
  value = aws_vpc_endpoint.secretsmanager.id
}

output "kms_key_arn" {
  value = aws_kms_key.this.arn
}
