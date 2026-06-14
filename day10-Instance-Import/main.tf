resource "aws_instance" "name" {
  ami           = "ami-00e801948462f718a"
  instance_type = "t2.micro"
  tags = {
    Name = "ec2-instance"
  }

}
#importing the existing s3 bucket to terraform state file
resource "aws_s3_bucket" "name" {
  bucket = "tf-bucket-import-unique-name-12345"
}
resource "aws_s3_bucket_versioning" "name" {
  bucket = aws_s3_bucket.name.id
  versioning_configuration {
    status = "Suspended"
  }

}