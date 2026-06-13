output "lambda_function_name" {
  value       = aws_lambda_function.tf_s3_lambda.function_name
  description = "Name of the deployed Lambda function." 
}
output "lambda_function_arn" {
  value       = aws_lambda_function.tf_s3_lambda.arn
  description = "ARN of the deployed Lambda function."
}
output "lambda_function_invoke_arn" {
  value       = aws_lambda_function.tf_s3_lambda.invoke_arn
  description = "Invoke ARN for the Lambda function."
}
output "s3_bucket_name" {
  value       = aws_s3_bucket.bucket.bucket
  description = "Name of the S3 bucket where Lambda code is stored."
}
output "s3_object_key" {
  value       = aws_s3_object.lambda_zip.key
  description = "S3 key for the Lambda code ZIP file."
}