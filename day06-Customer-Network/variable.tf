variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "project_name" {
  description = "Prefix for naming resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/24"
}

variable "azs" {
  description = "Availability zones to use (at least 2)"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (2)"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (2)"
  type        = list(string)
}

variable "ec2_ami" {
  description = "AMI ID for EC2 instances"
  type        = string
}

variable "ec2_instance_type" {
  description = "Instance type for EC2 instances"
  type        = string
  default     = "t3.micro"
}
