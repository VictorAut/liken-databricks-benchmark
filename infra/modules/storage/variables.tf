variable "databricks_account_id" {
  description = "Databricks account id, used by the account-level provider."
  type        = string
}

variable "databricks_client_id" {
  description = "Client id (application id) of the Databricks service principal that authenticates via GitHub OIDC federation (D012)."
  type        = string
}
