terraform {
  required_version = "~> 1.17.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.72"
    }
    databricks = {
      source  = "databricks/databricks"
      version = "= 1.141.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}

provider "aws" {
  region = "eu-central-1"

  # Tag every taggable AWS resource of this project.
  default_tags {
    tags = {
      Project   = "liken-databricks-benchmark"
      ManagedBy = "Terraform"
    }
  }
}

# Account-level Databricks provider. Cross-account IAM setup runs here,
# before any workspace exists.
provider "databricks" {
  alias      = "accounts"
  host       = "https://accounts.cloud.databricks.com"
  account_id = var.databricks_account_id
  client_id  = var.databricks_client_id
  auth_type  = "github-oidc"
}

provider "databricks" {
  alias     = "workspace"
  host      = databricks_mws_workspaces.this.workspace_url
  client_id = var.databricks_client_id
  auth_type = "github-oidc"
}
