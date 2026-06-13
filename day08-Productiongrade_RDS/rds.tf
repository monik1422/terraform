# Self-managed master credentials.
# MySQL does NOT allow creating a read replica when the source uses
# manage_master_user_password (Secrets Manager-managed), so we manage the
# secret ourselves. RDS uses the password below; the secret is available for
# apps/rotation via the rds_master_user_secret_arn output.
resource "random_password" "db" {
  length  = 24
  special = true
  # Exclude characters RDS forbids in a master password: / @ " and space.
  override_special = "!#$%^&*()-_=+[]{}"
}

resource "aws_secretsmanager_secret" "db" {
  name                    = "${local.name_prefix}/rds/master"
  kms_key_id              = aws_kms_key.data.arn
  recovery_window_in_days = 30

  tags = {
    Name = "${local.name_prefix}-rds-master"
  }
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db.result
  })
}

resource "aws_db_parameter_group" "mysql" {
  name   = "${local.name_prefix}-mysql8"
  family = "mysql8.0"

  parameter {
    name  = "require_secure_transport"
    value = "ON"
  }

  tags = {
    Name = "${local.name_prefix}-mysql8"
  }
}

resource "aws_iam_role" "rds_monitoring" {
  name = "${local.name_prefix}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_db_instance" "primary" {
  identifier = "${local.name_prefix}-mysql-primary"

  engine         = "mysql"
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  db_name  = var.db_name
  username = var.db_username

  allocated_storage     = var.db_allocated_storage_gb
  max_allocated_storage = var.db_max_allocated_storage_gb
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.data.arn

  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  multi_az               = true

  manage_master_user_password = false
  password                    = random_password.db.result
  parameter_group_name        = aws_db_parameter_group.mysql.name

  backup_retention_period   = var.db_backup_retention_days
  backup_window             = "03:00-04:00"
  maintenance_window        = "sun:04:00-sun:05:00"
  copy_tags_to_snapshot     = true
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${local.name_prefix}-mysql-primary-final"

  enabled_cloudwatch_logs_exports = ["error", "slowquery"]
  monitoring_interval             = 60
  monitoring_role_arn             = aws_iam_role.rds_monitoring.arn
  performance_insights_enabled    = true
  performance_insights_kms_key_id = aws_kms_key.data.arn

  auto_minor_version_upgrade = true
  apply_immediately          = false

  tags = {
    Name = "${local.name_prefix}-mysql-primary"
    Role = "primary"
  }
}

resource "aws_db_instance" "read_replica" {
  identifier          = "${local.name_prefix}-mysql-replica-1"
  replicate_source_db = aws_db_instance.primary.identifier
  instance_class      = var.db_replica_instance_class

  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  backup_retention_period   = var.db_backup_retention_days
  backup_window             = "05:00-06:00"
  maintenance_window        = "sun:06:00-sun:07:00"
  copy_tags_to_snapshot     = true
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${local.name_prefix}-mysql-replica-final"

  enabled_cloudwatch_logs_exports = ["error", "slowquery"]
  monitoring_interval             = 60
  monitoring_role_arn             = aws_iam_role.rds_monitoring.arn
  performance_insights_enabled    = true
  performance_insights_kms_key_id = aws_kms_key.data.arn

  auto_minor_version_upgrade = true
  apply_immediately          = false

  tags = {
    Name = "${local.name_prefix}-mysql-replica-1"
    Role = "read-replica"
  }
}

