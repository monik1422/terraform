resource "aws_instance" "tf_instance" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  associate_public_ip_address = var.auto_assign_public_ip
}