# Cross-account role for Databricks workspace deployment (the provider
# guide's five-resource graph), and the mws credentials registration that
# binds the role to the Databricks account.
#
# Provider requirements and the AWS provider config come from the
# including unit's root.hcl generation; the databricks provider config
# lives here (R2: account-level host + OIDC auth differ per module).

# Account-level Databricks provider (R2): only the mws_* resources need
# it. Auth is the GitHub-OIDC-federated service principal (D012) — no
# stored secret.
provider "databricks" {
  alias      = "accounts"
  host       = "https://accounts.cloud.databricks.com"
  account_id = var.databricks_account_id
  client_id  = var.databricks_client_id
  auth_type  = "github-oidc"
}

# The trust policy Databricks expects for the cross-account role.
data "databricks_aws_assume_role_policy" "this" {
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
# validation (Review-Focus 3). Sleep after the role policy exists.
resource "time_sleep" "after_role_policy" {
  create_duration = "15s"

  triggers = {
    policy_json = data.databricks_aws_crossaccount_policy.this.json
  }
}

resource "databricks_mws_credentials" "this" {
  account_id       = var.databricks_account_id
  credentials_name = "liken-benchmark-credentials"
  role_arn         = aws_iam_role.crossaccount.arn
  depends_on       = [time_sleep.after_role_policy]
}

output "crossaccount_role_arn" {
  description = "ARN of the Databricks cross-account role."
  value       = aws_iam_role.crossaccount.arn
}

output "credentials_id" {
  description = "Databricks credentials configuration id."
  value       = databricks_mws_credentials.this.credentials_id
}
