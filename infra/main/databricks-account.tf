
resource "databricks_mws_credentials" "this" {
  provider         = databricks.accounts
  account_id       = var.databricks_account_id
  credentials_name = "liken-benchmark-credentials"
  role_arn         = aws_iam_role.crossaccount.arn

  depends_on = [aws_iam_role_policy.crossaccount]
}


resource "databricks_mws_networks" "this" {
  provider = databricks.accounts

  account_id         = var.databricks_account_id
  network_name       = "${local.workspace_name}-network"
  security_group_ids = [aws_default_security_group.this.id]
  subnet_ids         = aws_subnet.private[*].id
  vpc_id             = aws_vpc.this.id
}

resource "databricks_mws_storage_configurations" "this" {
  provider = databricks.accounts

  account_id                 = var.databricks_account_id
  bucket_name                = aws_s3_bucket.root.bucket
  storage_configuration_name = "${local.workspace_name}-storage"

  depends_on = [
    aws_s3_bucket_versioning.root,
    aws_s3_bucket_server_side_encryption_configuration.root,
    aws_s3_bucket_public_access_block.root,
    aws_s3_bucket_policy.root,
  ]
}

resource "databricks_mws_workspaces" "this" {
  provider = databricks.accounts

  account_id               = var.databricks_account_id
  workspace_name           = local.workspace_name
  aws_region               = "eu-central-1"
  credentials_id           = databricks_mws_credentials.this.credentials_id
  storage_configuration_id = databricks_mws_storage_configurations.this.storage_configuration_id
  network_id               = databricks_mws_networks.this.network_id

  # The AWS provider's default_tags do not apply here.
  custom_tags = {
    Project   = "liken-databricks-benchmark"
    ManagedBy = "Terraform"
  }
}


