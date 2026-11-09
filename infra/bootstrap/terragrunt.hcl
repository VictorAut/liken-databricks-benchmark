# One-time bootstrap unit. Applied once from the laptop (D011). It does
# not include infra/root.hcl: root.hcl's remote_state points at the
# bucket this unit creates, and it runs on local state (throwaway — the
# bootstrap is never applied again).

terraform {
  source = "./"
}

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
  }
}

provider "aws" {
  region = "eu-south-2"
}
EOF
}
