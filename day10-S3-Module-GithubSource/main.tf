module "s3_bucket" {
  source = "https://github.com/monik1422/terraform-aws-s3-bucket.git"

  bucket = var.bucket
  acl    = var.acl

  control_object_ownership = var.control_object_ownership
  object_ownership         = var.object_ownership

  versioning = {
    enabled = var.versioning["enabled"]
  }
}