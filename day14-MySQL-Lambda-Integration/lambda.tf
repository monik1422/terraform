data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_src"
  output_path = "${path.module}/build/lambda.zip"
}

resource "aws_iam_role" "lambda" {
  name = "${var.name_prefix}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Lets Lambda create/delete ENIs in the VPC and write CloudWatch Logs.
resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Read only this DB's secret, decrypt only with this CMK.
resource "aws_iam_role_policy" "lambda_secrets" {
  name = "${var.name_prefix}-lambda-secrets"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadDBSecret"
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = aws_db_instance.mysql.master_user_secret[0].secret_arn
      },
      {
        Sid      = "DecryptSecret"
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = aws_kms_key.this.arn
      }
    ]
  })
}

resource "aws_lambda_function" "db_client" {
  function_name = "${var.name_prefix}-db-client"
  role          = aws_iam_role.lambda.arn
  runtime       = "python3.12"
  handler       = "index.handler"

  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  timeout     = 30
  memory_size = 128

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      DB_SECRET_ARN = aws_db_instance.mysql.master_user_secret[0].secret_arn
      DB_HOST       = aws_db_instance.mysql.address
      DB_NAME       = var.db_name
      DB_PORT       = "3306"
    }
  }

  depends_on = [aws_iam_role_policy_attachment.lambda_vpc]
}
