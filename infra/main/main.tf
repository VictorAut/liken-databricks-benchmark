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
