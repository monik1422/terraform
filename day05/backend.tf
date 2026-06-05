terraform {
  backend "s3" {
    bucket = "tf-bkt-rmt-state-bknd002"
    key    = "terraform.tfstate"
    use_lockfile = true 
    region = "us-east-1"
  }
}
