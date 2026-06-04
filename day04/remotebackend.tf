terraform {
  backend "s3" {
    bucket = "tf-bkt-rmt-state-bknd"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}
