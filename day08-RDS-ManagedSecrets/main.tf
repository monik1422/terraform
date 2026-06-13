resource "aws_db_instance" "tf_rds_instance" {
  allocated_storage           = 10
  db_name                     = "tf_db"
  identifier                  = "tf-rds-instance"
  engine                      = "mysql"
  engine_version              = "8.0"
  instance_class              = "db.t3.micro"
  username                    = "admin"
  manage_master_user_password = true #rds and secret manager manage this password
  #   password                = "admin1234" # Not needed when manage_master_user_password is true
  db_subnet_group_name = aws_db_subnet_group.sub-grp.id
  parameter_group_name = "default.mysql8.0"

  # Enable backups and retention
  backup_retention_period = 7             # Retain backups for 7 days
  backup_window           = "02:00-03:00" # Daily backup window (UTC)

  # Enable deletion protection (to prevent accidental deletion)
  deletion_protection = false

  # Skip final snapshot
  skip_final_snapshot = true
  depends_on          = [aws_db_subnet_group.sub-grp] # Ensure subnet group is created before the DB instance

}

resource "aws_vpc" "name" {
  cidr_block = "10.0.0.0/24"
  tags = {
    Name = "tf-vpc-rds"
  }

}
resource "aws_subnet" "subnet-1" {
  vpc_id            = aws_vpc.name.id
  cidr_block        = "10.0.0.0/25"
  availability_zone = "us-east-1a"

}
resource "aws_subnet" "subnet-2" {
  vpc_id            = aws_vpc.name.id
  cidr_block        = "10.0.0.128/25"
  availability_zone = "us-east-1b"

}
resource "aws_db_subnet_group" "sub-grp" {
  name       = "tf-db-subnet-group"
  subnet_ids = [aws_subnet.subnet-1.id, aws_subnet.subnet-2.id]

  tags = {
    Name = "My DB subnet group"
  }
}
