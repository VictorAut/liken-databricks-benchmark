# Benchmark data bucket: where the WI006 generator writes Parquet and
# the harness reads from. Nothing in the cloud is precious: force_destroy
# so teardown removes a non-empty bucket (D010: even data buckets live in
# code). No databricks bucket policy — clusters reach it via workspace
# IAM (the cross-account role), not via a bucket policy of its own.

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

# D013: all four public-access blocks on, from creation.
resource "aws_s3_bucket_public_access_block" "data" {
  bucket = aws_s3_bucket.data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

output "data_bucket_name" {
  description = "Name of the benchmark data bucket."
  value       = aws_s3_bucket.data.bucket
}
