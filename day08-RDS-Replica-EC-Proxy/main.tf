###############################################################################
# Providers
###############################################################################
provider "aws" {
  region = "us-east-1"
}

# Used to scope the KMS decrypt permission for the proxy's secret access.
data "aws_region" "current" {}

###############################################################################
# Networking (VPC + 2 subnets across AZs)
###############################################################################
resource "aws_vpc" "name" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "dev"
  }
}

resource "aws_subnet" "subnet-1" {
  vpc_id            = aws_vpc.name.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "subnet-2" {
  vpc_id            = aws_vpc.name.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_db_subnet_group" "sub-grp" {
  name       = "tf-db-subnet-group"
  subnet_ids = [aws_subnet.subnet-1.id, aws_subnet.subnet-2.id]
  tags = {
    Name = "My DB subnet group"
  }
}

###############################################################################
# Security groups
#   - rds_sg   : DB engine port (3306), reachable from the proxy + within VPC
#   - proxy_sg : RDS Proxy endpoint, reachable from app tier (here: VPC CIDR)
#   - redis_sg : ElastiCache Redis port (6379), reachable from within VPC
###############################################################################
resource "aws_security_group" "proxy_sg" {
  name        = "rds-proxy-sg"
  description = "Allow app traffic into the RDS Proxy"
  vpc_id      = aws_vpc.name.id

  ingress {
    description = "MySQL from app tier"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.name.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "rds-proxy-sg" }
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Allow MySQL from the proxy and within the VPC"
  vpc_id      = aws_vpc.name.id

  ingress {
    description     = "MySQL from RDS Proxy"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.proxy_sg.id]
  }

  ingress {
    description = "MySQL from within VPC (direct testing)"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.name.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "rds-sg" }
}

resource "aws_security_group" "redis_sg" {
  name        = "redis-sg"
  description = "Allow Redis from within the VPC"
  vpc_id      = aws_vpc.name.id

  ingress {
    description = "Redis from app tier"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.name.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "redis-sg" }
}

###############################################################################
# Master credentials (self-managed in Secrets Manager)
#   MySQL does NOT allow a read replica when the source uses
#   manage_master_user_password, so we manage the secret ourselves. RDS uses
#   the password, and the RDS Proxy reads this same secret. The secret MUST be
#   shaped as {"username","password"} for the proxy to accept it.
###############################################################################
resource "random_password" "db" {
  length  = 24
  special = true
  # Exclude characters RDS forbids in master passwords: / @ " and space.
  override_special = "!#$%^&*()-_=+[]{}"
}

resource "aws_secretsmanager_secret" "db" {
  name = "tf-rds-master-credentials"
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.db.result
  })
}

###############################################################################
# Primary RDS instance (MySQL 8.0)
#   NOTE: identifier uses hyphens — underscores are invalid for RDS identifiers.
#   Credentials come from the self-managed Secrets Manager secret above.
###############################################################################
resource "aws_db_instance" "default" {
  allocated_storage      = 10
  db_name                = "tf_db"
  identifier             = "tf-rds-instance"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  username               = "admin"
  password               = random_password.db.result
  db_subnet_group_name   = aws_db_subnet_group.sub-grp.name
  parameter_group_name   = "default.mysql8.0"
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  # backup_retention_period > 0 is REQUIRED to be able to create a read replica.
  backup_retention_period = 7
  backup_window           = "02:00-03:00"

  maintenance_window = "sun:04:00-sun:05:00"

  # Set true for production; false here so the stack can be destroyed cleanly.
  deletion_protection = false
  skip_final_snapshot = true
}

###############################################################################
# Read replica (same region)
#   Inherits storage / db_name / credentials / subnet group from the source,
#   so those are intentionally omitted. replicate_source_db = source identifier.
###############################################################################
resource "aws_db_instance" "read_replica" {
  identifier             = "tf-rds-replica"
  replicate_source_db    = aws_db_instance.default.identifier
  instance_class         = "db.t3.micro"
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  skip_final_snapshot = true
  deletion_protection = false
}

###############################################################################
# RDS Proxy
#   Pools and shares DB connections. Authenticates to RDS using the
#   self-managed Secrets Manager secret. Needs an IAM role that can read that
#   secret and decrypt it via the Secrets Manager KMS key.
###############################################################################
resource "aws_iam_role" "rds_proxy" {
  name = "rds-proxy-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "rds.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "rds_proxy" {
  name = "rds-proxy-secret-access"
  role = aws_iam_role.rds_proxy.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "GetSecret"
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = [aws_secretsmanager_secret.db.arn]
      },
      {
        Sid      = "DecryptSecret"
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "secretsmanager.${data.aws_region.current.region}.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_db_proxy" "default" {
  name                   = "tf-rds-proxy"
  engine_family          = "MYSQL"
  role_arn               = aws_iam_role.rds_proxy.arn
  vpc_subnet_ids         = [aws_subnet.subnet-1.id, aws_subnet.subnet-2.id]
  vpc_security_group_ids = [aws_security_group.proxy_sg.id]
  require_tls            = true
  idle_client_timeout    = 1800

  auth {
    auth_scheme = "SECRETS"
    iam_auth    = "DISABLED"
    secret_arn  = aws_secretsmanager_secret.db.arn
  }

  # Ensure the secret has a value (username/password) before the proxy validates it.
  depends_on = [aws_secretsmanager_secret_version.db]
}

resource "aws_db_proxy_default_target_group" "default" {
  db_proxy_name = aws_db_proxy.default.name

  connection_pool_config {
    connection_borrow_timeout    = 120
    max_connections_percent      = 100
    max_idle_connections_percent = 50
  }
}

# Routes the proxy to the primary instance (writer). Add another target or
# point the app at the replica's endpoint directly for read traffic.
resource "aws_db_proxy_target" "default" {
  db_instance_identifier = aws_db_instance.default.identifier
  db_proxy_name          = aws_db_proxy.default.name
  target_group_name      = aws_db_proxy_default_target_group.default.name
}

###############################################################################
# ElastiCache (Redis replication group: 1 primary + 1 replica, Multi-AZ)
###############################################################################
resource "aws_elasticache_subnet_group" "redis" {
  name       = "tf-redis-subnet-group"
  subnet_ids = [aws_subnet.subnet-1.id, aws_subnet.subnet-2.id]
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "tf-redis"
  description          = "Redis cache for the app tier"

  engine               = "redis"
  engine_version       = "7.1"
  node_type            = "cache.t3.micro"
  parameter_group_name = "default.redis7"
  port                 = 6379

  num_cache_clusters         = 2 # 1 primary + 1 read replica
  automatic_failover_enabled = true
  multi_az_enabled           = true

  subnet_group_name  = aws_elasticache_subnet_group.redis.name
  security_group_ids = [aws_security_group.redis_sg.id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  # auth_token = "..."   # optional: required only if you want Redis AUTH

  snapshot_retention_limit = 5
  snapshot_window          = "01:00-02:00"
  maintenance_window       = "sun:03:00-sun:04:00"
}

###############################################################################
# Useful endpoints
###############################################################################
output "rds_primary_endpoint" {
  value = aws_db_instance.default.endpoint
}

output "rds_replica_endpoint" {
  value = aws_db_instance.read_replica.endpoint
}

output "rds_proxy_endpoint" {
  value = aws_db_proxy.default.endpoint
}

output "redis_primary_endpoint" {
  value = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "redis_reader_endpoint" {
  value = aws_elasticache_replication_group.redis.reader_endpoint_address
}
