
variable "region" {
    default = "us-east-1"
}

locals {
  region        = var.region
  instance_type = "t2.micro"
  ami_id= "ami-00e801948462f718a"
}

resource "aws_instance" "name" {
  ami = local.ami_id
  instance_type = local.instance_type
  region = local.region
}