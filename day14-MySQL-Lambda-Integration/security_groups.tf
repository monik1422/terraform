# ---------------------------------------------------------------------------
# Three SGs, wired with least privilege:
#   lambda -> rds        on 3306 (DB connection)
#   lambda -> endpoints  on 443  (Secrets Manager API call)
# ---------------------------------------------------------------------------

resource "aws_security_group" "lambda" {
  name        = "${var.name_prefix}-lambda-sg"
  description = "Lambda function ENIs"
  vpc_id      = aws_vpc.this.id
  tags        = { Name = "${var.name_prefix}-lambda-sg" }
}

resource "aws_security_group" "rds" {
  name        = "${var.name_prefix}-rds-sg"
  description = "RDS MySQL"
  vpc_id      = aws_vpc.this.id
  tags        = { Name = "${var.name_prefix}-rds-sg" }
}

resource "aws_security_group" "endpoints" {
  name        = "${var.name_prefix}-vpce-sg"
  description = "Interface VPC endpoints"
  vpc_id      = aws_vpc.this.id
  tags        = { Name = "${var.name_prefix}-vpce-sg" }
}

# --- Lambda <-> RDS (3306) ---
resource "aws_security_group_rule" "lambda_egress_rds" {
  type                     = "egress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.lambda.id
  source_security_group_id = aws_security_group.rds.id
  description              = "Lambda to MySQL"
}

resource "aws_security_group_rule" "rds_ingress_lambda" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = aws_security_group.lambda.id
  description              = "MySQL from Lambda"
}

# --- Lambda <-> Interface endpoints (443) ---
resource "aws_security_group_rule" "lambda_egress_vpce" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.lambda.id
  source_security_group_id = aws_security_group.endpoints.id
  description              = "Lambda to interface endpoints (HTTPS)"
}

resource "aws_security_group_rule" "vpce_ingress_lambda" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.endpoints.id
  source_security_group_id = aws_security_group.lambda.id
  description              = "HTTPS from Lambda"
}
