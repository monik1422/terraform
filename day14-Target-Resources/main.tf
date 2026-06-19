resource "aws_instance" "name1" {
  ami           = "ami-00e801948462f718a"
  instance_type = "t2.micro"
  tags = {
    Name = "tf-dev"
  }

}

resource "aws_s3_bucket" "name2" {
  bucket = "tf-bucket-1234567890-target-resource"

}

#terraform apply -target=aws_s3_bucket.name2 we can target specific resource to apply or delete 