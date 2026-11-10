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
  }
}

# Account-level Databricks provider, for standing auth configuration
# (federation policies). Bootstrap is applied once from the laptop and
# never destroyed, so what it manages survives teardown. Auth goes
# through the databricks CLI's browser login; no stored secret (D012).
provider "databricks" {
  host       = "https://accounts.cloud.databricks.com"
  account_id = "55a20437-0418-4752-b516-94ac43b973b3"
  client_id  = "feda187f-33bc-4bf3-981d-23237794be45"
  auth_type  = "databricks-cli"
}
