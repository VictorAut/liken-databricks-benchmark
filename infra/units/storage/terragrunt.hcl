# Storage unit: the DBFS root bucket. Its root_bucket_name feeds
# units/workspace (Task 5) via cross-stack dependency at this canonical
# path; the explicit state key is what makes that resolution work from
# remote state (R9).

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../modules/storage/"
}

remote_state {
  backend = "s3"

  config = {
    bucket       = "liken-benchmark-tfstate-eu-south-2"
    key          = "foundation/storage/terraform.tfstate"
    region       = "eu-south-2"
    use_lockfile = true
  }
}

inputs = {
  databricks_account_id = get_env("DATABRICKS_ACCOUNT_ID", "")
  databricks_client_id  = get_env("DATABRICKS_CLIENT_ID", "")
}
