# ---------------------------------------------------------------------------
# The single endpoint that is actually required for this design: the in-VPC
# Lambda calls secretsmanager:GetSecretValue through this interface endpoint,
# so no NAT gateway / internet access is needed.
#
# Notes:
# - private_dns_enabled = true makes secretsmanager.<region>.amazonaws.com
#   resolve to the endpoint's private IPs from inside the VPC.
# - You do NOT need a KMS endpoint: Secrets Manager decrypts the secret
#   server-side, so the KMS call is made by the service, not from the VPC.
# - You do NOT need an RDS endpoint to *connect* to the database; an RDS
#   interface endpoint is only for the RDS control-plane API (Describe*, etc.).
# - Lambda log delivery to CloudWatch Logs is handled by the Lambda service
#   itself (not via the function ENI), so no Logs endpoint is required.
# ---------------------------------------------------------------------------

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${var.region}.secretsmanager"
  vpc_endpoint_type = "Interface"

  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.endpoints.id]
  private_dns_enabled = true

  tags = { Name = "${var.name_prefix}-secretsmanager-vpce" }
}
