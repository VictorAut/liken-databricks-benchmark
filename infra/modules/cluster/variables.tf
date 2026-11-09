variable "workspace_url" {
  description = "URL of the Databricks workspace the cluster lives in."
  type        = string
}

variable "databricks_client_id" {
  description = "Client id (application id) of the Databricks service principal that authenticates via GitHub OIDC federation (D012)."
  type        = string
}

variable "cluster_name" {
  description = "Cluster display name; WI006's harness targets it by name."
  type        = string
}
