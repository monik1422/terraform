# ---------------------------------------------------------------------------
# Minimal, fully-private network. No Internet Gateway, no NAT Gateway.
# Egress to AWS APIs happens only through the interface VPC endpoint(s).
# To plug into an existing VPC instead, replace these resources with
# data sources and feed subnet/SG ids into the rest of the config.
# ---------------------------------------------------------------------------

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr

  # Required for private DNS on interface endpoints to resolve correctly.
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${var.name_prefix}-vpc" }
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = { Name = "${var.name_prefix}-private-${count.index + 1}" }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  # Only the implicit local route exists -> no path to the internet.
  tags = { Name = "${var.name_prefix}-private-rt" }
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
