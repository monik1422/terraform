output "lambda_function_name" {
  description = "Name of the created Lambda function"
  value       = aws_lambda_function.tf_eventbus_lambda.function_name
}  
output "event_rule_name" {
  description = "Name of the created EventBridge rule"
  value       = aws_cloudwatch_event_rule.every_five_minutes.name
}
output "event_rule_arn" {
  description = "ARN of the created EventBridge rule"
  value       = aws_cloudwatch_event_rule.every_five_minutes.arn
}
output "lambda_execution_role_arn" {
  description = "ARN of the IAM role for Lambda execution"
  value       = aws_iam_role.lambda_exec.arn
}
