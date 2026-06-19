# ---------------------------------------------------------------------------
# One CMK used for both RDS storage encryption and the RDS-managed master
# user secret. The "enable IAM" key policy lets IAM policies (e.g. the
# Lambda role's kms:Decrypt) take effect, while RDS/Secrets Manager use
# grants under the hood. This avoids the common "key policy gap" where the
# caller has IAM permission but the key never delegated to IAM.
# ---------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

resource "aws_kms_key" "this" {
  description             = "${var.name_prefix} CMK for RDS storage + master user secret"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnableIAMUserPermissions"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      }
    ]
  })

  tags = { Name = "${var.name_prefix}-cmk" }
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.name_prefix}-rds"
  target_key_id = aws_kms_key.this.key_id
}
