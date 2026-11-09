# VPC unit: the customer-managed network the workspace attaches to.
# No external dependencies; first unit of the benchmark stack.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../modules/vpc/"
}

remote_state {
  backend = "s3"

  config = {
    bucket       = "liken-benchmark-tfstate-eu-south-2"
    key          = "benchmark/vpc/terraform.tfstate"
    region       = "eu-south-2"
    use_lockfile = true
  }
}

inputs = {
  region = "eu-south-2"
}
