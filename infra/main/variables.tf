variable "databricks_account_id" {
  description = "Databricks account id; used as the external id for the cross-account role, and as the account-level Databricks provider's account id."
  type        = string
}

variable "databricks_client_id" {
  description = "Client id (application id) of the Databricks service principal that authenticates via GitHub OIDC federation (D012)."
  type        = string
}
