# Workspace unit: Databricks workspace on the customer-managed VPC.
# Consumes iam/storage outputs via cross-stack dependency at their
# canonical unit paths (resolved from remote state because those units
# pin explicit keys, R9), and vpc outputs intra-stack.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../modules/workspace/"
}

remote_state {
  backend = "s3"

  config = {
    bucket       = "liken-benchmark-tfstate-eu-south-2"
    key          = "benchmark/workspace/terraform.tfstate"
    region       = "eu-south-2"
    use_lockfile = true
  }
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id                    = "vpc-mock"
    private_subnet_ids        = ["subnet-mock1", "subnet-mock2"]
    default_security_group_id = "sg-mock"
  }

  mock_outputs_allowed_terraform_commands = ["validate"]
}

dependency "iam" {
  config_path = "../../units/iam"

  mock_outputs = {
    credentials_id = "mock-credentials-id"
  }

  mock_outputs_allowed_terraform_commands = ["validate"]
}

dependency "storage" {
  config_path = "../../units/storage"

  mock_outputs = {
    root_bucket_name = "mock-bucket"
  }

  mock_outputs_allowed_terraform_commands = ["validate"]
}

inputs = {
  databricks_account_id = get_env("DATABRICKS_ACCOUNT_ID", "")
  databricks_client_id  = get_env("DATABRICKS_CLIENT_ID", "")
  credentials_id        = dependency.iam.outputs.credentials_id
  root_bucket_name      = dependency.storage.outputs.root_bucket_name
  vpc_id                = dependency.vpc.outputs.vpc_id
  private_subnet_ids    = dependency.vpc.outputs.private_subnet_ids
  security_group_id     = dependency.vpc.outputs.default_security_group_id
  workspace_name        = "liken-benchmark"
  aws_region            = "eu-south-2"
}
