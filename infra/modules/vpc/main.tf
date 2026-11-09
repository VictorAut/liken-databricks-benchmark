# Customer-managed VPC for the Databricks workspace (spec Option B):
# private subnets in two AZs, one NAT gateway, and the endpoints the
# clusters actually need — S3 gateway endpoint so cluster→S3 traffic
# never touches the NAT, STS interface endpoint so Databricks
# credentials flows stay off it either.

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "this" {
  cidr_block           = "10.20.0.0/20"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "liken-benchmark-vpc" }
}

# Two private /19s are impossible inside a /20. The plan's /19 requirement
# assumes a larger VPC; /20 with two /21s keeps the same shape (two AZs,
# one private + one public subnet each). Deviation ledgered as R11.
resource "aws_subnet" "private" {
  count = 2

  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(aws_vpc.this.cidr_block, 3, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = { Name = "liken-benchmark-private-${count.index}" }
}

resource "aws_subnet" "public" {
  count = 2

  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(aws_vpc.this.cidr_block, 3, count.index + 2)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = { Name = "liken-benchmark-public-${count.index}" }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = { Name = "liken-benchmark-igw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = { Name = "liken-benchmark-public-rt" }
}

resource "aws_route_table_association" "public" {
  count = 2

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  count = 2

  vpc_id = aws_vpc.this.id

  tags = { Name = "liken-benchmark-private-rt-${count.index}" }
}

resource "aws_route_table_association" "private" {
  count = 2

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# The default security group is what the Databricks workspace network
# config references.
resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
  }
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = { Name = "liken-benchmark-nat-eip" }
}

# The stack's one intentional idle-billing resource (D009): destroyed
# with the stack whenever the benchmark environment is idle.
resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = { Name = "liken-benchmark-nat" }

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route" "private_nat" {
  count = 2

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this.id
}

# S3 gateway endpoint: cluster→S3 traffic bypasses the NAT.
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = aws_route_table.private[*].id

  tags = { Name = "liken-benchmark-s3-endpoint" }
}

# STS interface endpoint: Databricks credentials flows stay off the NAT.
resource "aws_vpc_endpoint" "sts" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${var.region}.sts"
  vpc_endpoint_type = "Interface"

  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_default_security_group.this.id]
  private_dns_enabled = true

  tags = { Name = "liken-benchmark-sts-endpoint" }
}
