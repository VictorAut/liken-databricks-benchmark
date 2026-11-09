# Shared Terragrunt configuration included by every unit under infra/.
#
# The bootstrap unit (infra/bootstrap) does NOT include this file: its
# remote_state points at the very bucket this file names, and that
# bucket cannot hold the state of its own creation.

# Remote state in the bucket the bootstrap unit creates (D003: S3
# native lockfiles, no DynamoDB). The key derives from each unit's
# include path, so state never merges between units.
remote_state {
  backend = "s3"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    bucket       = "liken-benchmark-tfstate-eu-south-2"
    key          = "${path_relative_to_include()}/terraform.tfstate"
    region       = "eu-south-2"
    use_lockfile = true
  }
}

# Provider requirements generated into every unit. The Databricks
# provider is pinned in version only; modules that use it configure it
# themselves from variables.
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<EOF
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

provider "aws" {
  region = "eu-south-2"
}
EOF
}
