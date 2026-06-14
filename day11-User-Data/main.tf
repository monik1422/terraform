resource "aws_instance" "name" {
  ami                   = "ami-00e801948462f718a"
  instance_type         = "t2.micro"
  user_data             = <<-EOF
                #!/bin/bash
                yum install -y httpd
                systemctl start httpd
                systemctl enable httpd
                echo "Welcome to Terraform!" > /var/www/html/index.html
                EOF
  associate_public_ip_address = true
  tags = {
    Name = "tf-ec2-nginx-Instance"
  }

}