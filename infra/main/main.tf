locals {
  workspace_name = "liken-benchmark"
  cluster_name   = "liken-benchmark"
}

# The trust policy Databricks expects for the cross-account role.
data "databricks_aws_assume_role_policy" "this" {
  provider    = databricks.accounts
  external_id = var.databricks_account_id
}

resource "aws_iam_role" "crossaccount" {
  name               = "liken-benchmark-databricks-crossaccount"
  assume_role_policy = data.databricks_aws_assume_role_policy.this.json
}

# The least-privilege policy Databricks expects on the cross-account role.
data "databricks_aws_crossaccount_policy" "this" {}

resource "aws_iam_role_policy" "crossaccount" {
  name   = "liken-benchmark-databricks-crossaccount-policy"
  role   = aws_iam_role.crossaccount.id
  policy = data.databricks_aws_crossaccount_policy.this.json
}

# Propagation guard: Databricks validates the cross-account role when
# registering credentials, and a policy younger than ~10s fails
# validation. Sleep after the role policy exists.
resource "time_sleep" "after_role_policy" {
  create_duration = "15s"

  triggers = {
    policy_json = data.databricks_aws_crossaccount_policy.this.json
  }
}

resource "databricks_mws_credentials" "this" {
  provider         = databricks.accounts
  account_id       = var.databricks_account_id
  credentials_name = "liken-benchmark-credentials"
  role_arn         = aws_iam_role.crossaccount.arn
  depends_on       = [time_sleep.after_role_policy]
}

resource "aws_s3_bucket" "root" {
  bucket        = "liken-benchmark-dbx-root-eu-south-2"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "root" {
  bucket = aws_s3_bucket.root.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "root" {
  bucket = aws_s3_bucket.root.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "root" {
  bucket = aws_s3_bucket.root.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "databricks_aws_bucket_policy" "root" {
  provider = databricks.accounts
  bucket   = aws_s3_bucket.root.bucket
}

resource "aws_s3_bucket_policy" "root" {
  bucket = aws_s3_bucket.root.id
  policy = data.databricks_aws_bucket_policy.root.json

  depends_on = [aws_s3_bucket_public_access_block.root]
}

resource "aws_s3_bucket" "data" {
  bucket        = "liken-benchmark-data-eu-south-2"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "data" {
  bucket = aws_s3_bucket.data.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  bucket = aws_s3_bucket.data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "data" {
  bucket = aws_s3_bucket.data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "this" {
  cidr_block           = "10.20.0.0/20"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "liken-benchmark-vpc" }
}

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
  service_name      = "com.amazonaws.eu-south-2.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = aws_route_table.private[*].id

  tags = { Name = "liken-benchmark-s3-endpoint" }
}

# STS interface endpoint: Databricks credentials flows stay off the NAT.
resource "aws_vpc_endpoint" "sts" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.eu-south-2.sts"
  vpc_endpoint_type = "Interface"

  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_default_security_group.this.id]
  private_dns_enabled = true

  tags = { Name = "liken-benchmark-sts-endpoint" }
}
