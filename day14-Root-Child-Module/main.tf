provider "aws" {
  region = "us-east-1"
}

module "web_server" {
  source = "./modules"

  instance_name = "tf-web-server"
  ami_id        = "ami-00e801948462f718a" # Example AMI
  instance_type = "t2.micro"
}