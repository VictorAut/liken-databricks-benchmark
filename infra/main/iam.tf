data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_iam_role" "crossaccount" {
  name               = "liken-benchmark-databricks-crossaccount"
  assume_role_policy = data.databricks_aws_assume_role_policy.this.json
}

data "databricks_aws_crossaccount_policy" "this" {
  provider = databricks.accounts
}

resource "aws_iam_role_policy" "crossaccount" {
  name   = "liken-benchmark-databricks-crossaccount-policy"
  role   = aws_iam_role.crossaccount.id
  policy = data.databricks_aws_crossaccount_policy.this.json
}

resource "time_sleep" "after_role_policy" {
  create_duration = "15s"

  triggers = {
    policy_json = data.databricks_aws_crossaccount_policy.this.json
  }

  depends_on = [aws_iam_role_policy.crossaccount]
}

# The trust policy Databricks expects for the cross-account role.
data "databricks_aws_assume_role_policy" "this" {
  provider    = databricks.accounts
  external_id = var.databricks_account_id
}