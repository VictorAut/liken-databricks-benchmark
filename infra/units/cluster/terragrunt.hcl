# Cluster unit: the classic cluster, created in code only (D005). Last
# unit of the benchmark stack; depends on the workspace unit and points
# its workspace-level Databricks provider at the workspace URL.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../modules/cluster/"
}

remote_state {
  backend = "s3"

  config = {
    bucket       = "liken-benchmark-tfstate-eu-south-2"
    key          = "benchmark/cluster/terraform.tfstate"
    region       = "eu-south-2"
    use_lockfile = true
  }
}

dependency "workspace" {
  config_path = "../workspace"

  mock_outputs = {
    workspace_url = "https://mock-workspace.cloud.databricks.com"
  }

  mock_outputs_allowed_terraform_commands = ["validate"]
}

inputs = {
  workspace_url        = dependency.workspace.outputs.workspace_url
  databricks_client_id = get_env("DATABRICKS_CLIENT_ID", "")
  cluster_name         = "liken-benchmark"
}
