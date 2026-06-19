resource "aws_db_subnet_group" "this" {
  name       = "${var.name_prefix}-db-subnets"
  subnet_ids = aws_subnet.private[*].id
  tags       = { Name = "${var.name_prefix}-db-subnets" }
}

resource "aws_db_instance" "mysql" {
  identifier     = "${var.name_prefix}-mysql"
  engine         = "mysql"
  engine_version = var.mysql_engine_version
  instance_class = var.db_instance_class

  allocated_storage = var.db_allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true
  kms_key_id        = aws_kms_key.this.arn

  db_name  = var.db_name
  username = var.db_master_username

  # --- Secrets Manager integration ---
  # RDS generates the master password, stores it in a Secrets Manager secret,
  # and manages rotation of that secret. Do NOT also set `password` here.
  manage_master_user_password   = true
  master_user_secret_kms_key_id = aws_kms_key.this.key_id

  # --- Single instance, fully private ---
  multi_az            = false
  publicly_accessible = false

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  # --- Demo-friendly settings: review before production ---
  skip_final_snapshot = true
  deletion_protection = false
  apply_immediately   = true

  tags = { Name = "${var.name_prefix}-mysql" }
}
