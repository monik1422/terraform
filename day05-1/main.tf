resource "aws_s3_bucket" "private_bucket" {
  bucket = var.private_s3_bucket_name
}

resource "aws_s3_bucket_versioning" "private_bucket_versioning" {
  bucket = aws_s3_bucket.private_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}
