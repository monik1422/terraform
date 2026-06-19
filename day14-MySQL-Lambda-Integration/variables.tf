variable "region" {
  type        = string
  description = "AWS region"
  default     = "ca-central-1"
}

variable "name_prefix" {
  type        = string
  description = "Prefix applied to all resource names"
  default     = "demo"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.20.0.0/16"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private subnet CIDRs (need >= 2 AZs for the DB subnet group)"
  default     = ["10.20.1.0/24", "10.20.2.0/24"]
}

variable "db_name" {
  type        = string
  description = "Initial database name"
  default     = "appdb"
}

variable "db_master_username" {
  type        = string
  description = "Master username (the password is generated and stored in Secrets Manager)"
  default     = "admin"
}

variable "db_instance_class" {
  type        = string
  description = "RDS instance class"
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  type        = number
  description = "Allocated storage in GiB"
  default     = 20
}

variable "mysql_engine_version" {
  type        = string
  description = "MySQL engine version"
  default     = "8.0"
}
