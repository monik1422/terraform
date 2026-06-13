output "lambda_function_name" {
  value       = aws_lambda_function.tf_lambda.function_name
  description = "Name of the deployed Lambda function."
}

output "lambda_function_arn" {
  value       = aws_lambda_function.tf_lambda.arn
  description = "ARN of the deployed Lambda function."
}

output "lambda_function_invoke_arn" {
  value       = aws_lambda_function.tf_lambda.invoke_arn
  description = "Invoke ARN for the Lambda function."
}
