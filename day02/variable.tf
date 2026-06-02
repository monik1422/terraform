variable "ami_id" {
  description = "AMI ID for the EC2 instance."
  type        = string
  default     = "ami-00e801948462f718a" # Example AMI ID, replace with your desired AMI ID
}

variable "instance_type" {
  description = "Instance type for the EC2 instance."
  type        = string
  default     = "t2.micro" # Example instance type, replace with your desired instance type
}

variable "auto_assign_public_ip" {
  description = "Whether to auto-assign a public IP address to the EC2 instance."
  type        = bool
  default     = true
}