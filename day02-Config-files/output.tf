output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.tf_instance.public_ip
}

output "instance_private_ip" {
  description = "Private IP of the EC2 instance"
  value       = aws_instance.tf_instance.private_ip
}

output "subnet_id" {
  description = "Subnet ID attached to the EC2 instance"
  value       = aws_instance.tf_instance.subnet_id
}
