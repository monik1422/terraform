resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/24"
  tags = {
    Name = "tf-vpc-day05"
  }
}
resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.0.128/26"
  tags = {
    Name = "tf-vpc-day05"
  }
}
