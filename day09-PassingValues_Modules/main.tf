module "dev" {
  source        = "../day09-modules"
  instance_type = "t3.micro"
  name          = "tf-module-instance"
  ami_id        = "ami-00e801948462f718a"
}