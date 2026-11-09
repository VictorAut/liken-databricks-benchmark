# Shared Terragrunt configuration included by every unit under infra/.
#
# The bootstrap unit (infra/bootstrap) does NOT include this file: it
# runs on local state, and its bucket cannot hold the state of its own
# creation.
#
# Remote state (D003: S3 native lockfiles, no DynamoDB) is NOT declared
# here. Stacks copy units into generated paths, so a path-derived key
# here would split state between generated and canonical copies; instead
# every unit declares its own remote_state block with an explicit key
# (see the plan's structural decision on state keys). Units share only
# the bucket name below.

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
