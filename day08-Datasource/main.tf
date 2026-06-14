
data "aws_subnet" "selected" {
  filter {
    name   = "tag:Name"
    values = ["tf-subnet"] #fetch the subnet with the tag Name=tf-subnet
  }
}
data "aws_security_group" "selected" {
  filter {
    name   = "tag:Name"
    values = ["tf-security-group"] #fetch the security group with the tag Name=tf-security-group
  }
}
resource "aws_instance" "name" {
  ami                    = "ami-00e801948462f718a"
  instance_type          = "t2.micro"
  subnet_id              = data.aws_subnet.selected.id           #use the id of the fetched subnet
  vpc_security_group_ids = [data.aws_security_group.selected.id] #use the id of the fetched security group
  tags = {
    Name = "tf-ec2-instance"
  }

}
