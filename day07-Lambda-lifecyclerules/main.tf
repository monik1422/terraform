resource "aws_instance" "name" {
    ami           = "ami-00e801948462f718a"
    instance_type = "t2.micro"

    # lifecycle {
    #   create_before_destroy = true
    # }
    # lifecycle {
    #   ignore_changes = [ tags ]
    # }
    lifecycle {
      prevent_destroy = true
    }
    tags = {
        Name = "tf-lc-rule-instance"
    }
}