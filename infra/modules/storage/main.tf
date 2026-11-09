# DBFS root bucket for the Databricks workspace. Nothing in the cloud is
# precious (spec): force_destroy so teardown removes a non-empty bucket.
#
# Provider requirements and the AWS provider config come from the
# including unit's root.hcl generation; the databricks provider config
# lives here (R2: account-level host + OIDC auth differ per module).

# Account-level Databricks provider: the bucket policy data source
# generates a policy for the account's cross-account role, which it
# discovers through the account API.
provider "databricks" {
  alias      = "accounts"
  host       = "https://accounts.cloud.databricks.com"
  account_id = var.databricks_account_id
  client_id  = var.databricks_client_id
  auth_type  = "github-oidc"
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

# D013: all four public-access blocks on, from creation.
resource "aws_s3_bucket_public_access_block" "root" {
  bucket = aws_s3_bucket.root.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# The policy Databricks expects on the DBFS root bucket. Declared after
# the public-access block, per the provider guide's ordering.
data "databricks_aws_bucket_policy" "root" {
  bucket = aws_s3_bucket.root.bucket
}

resource "aws_s3_bucket_policy" "root" {
  bucket = aws_s3_bucket.root.id
  policy = data.databricks_aws_bucket_policy.root.json

  depends_on = [aws_s3_bucket_public_access_block.root]
}

output "root_bucket_name" {
  description = "Name of the DBFS root bucket."
  value       = aws_s3_bucket.root.bucket
}

output "root_bucket_id" {
  description = "Id of the DBFS root bucket."
  value       = aws_s3_bucket.root.id
}
