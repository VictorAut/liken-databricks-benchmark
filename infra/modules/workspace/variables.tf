variable "databricks_account_id" {
  description = "Databricks account id."
  type        = string
}

variable "databricks_client_id" {
  description = "Client id (application id) of the Databricks service principal that authenticates via GitHub OIDC federation (D012)."
  type        = string
}

variable "credentials_id" {
  description = "Databricks credentials configuration id (from the iam unit)."
  type        = string
}

variable "root_bucket_name" {
  description = "DBFS root bucket name (from the storage unit)."
  type        = string
}

variable "vpc_id" {
  description = "Id of the customer-managed VPC (from the vpc unit)."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet ids in two AZs (from the vpc unit)."
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group id for the Databricks network (from the vpc unit)."
  type        = string
}

variable "workspace_name" {
  description = "Databricks workspace display name."
  type        = string
}

variable "aws_region" {
  description = "AWS region the workspace is created in."
  type        = string
}
