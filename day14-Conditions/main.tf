########### first condition #############

# variable "dev" {
#     type = bool
#     default = true
# }

# resource "aws_instance" "name" {
#     ami           = "ami-00e801948462f718a"
#     instance_type = "t2.micro"
#     count = var.dev ? 1 : 0
#     #if dev is true then create 1 instance if false then create 0 instance

#     #true 1
#     #false 0 
#}

########### second condition #############

# variable "aws_region" {
#   description = "The region in which to create the infrastructure"
#   type        = string
#   nullable    = false
#   default     = "us-west-1" #here we need to define either us-west-1 or ca-central-1 if i give other region will get error 
#   validation {
#     condition = var.aws_region == "us-west-1" || var.aws_region == "ca-central-1"
#     error_message = "The variable 'aws_region' must be one of the following regions: us-west-1, ca-central-1"
#   }
# }
# provider "aws" {
#   region = var.aws_region   
#  }

#  resource "aws_s3_bucket" "dev" {
#     bucket = "statefile-configuresssdsfsff"



# }

########### third condition #############

variable "environment" {
  type    = string
  default = "prod"
}

resource "aws_instance" "example" {
  count         = var.environment == "prod" ? 3 : 1
  ami           = "ami-00e801948462f718a"
  instance_type = "t2.micro"

  tags = {
    Name = "example-${count.index}"
  }
}

# #In this case:
# #If var.environment == "prod" → count = 3
# #Else (like dev, qa, etc.) → count = 1
# #terraform apply -var="environment=dev"