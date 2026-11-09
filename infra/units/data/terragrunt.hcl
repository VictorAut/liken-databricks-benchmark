# Data unit: the benchmark data bucket. No dependencies; consumed by
# WI006's harness (bucket name), not by another unit.

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../modules/data/"
}

remote_state {
  backend = "s3"

  config = {
    bucket       = "liken-benchmark-tfstate-eu-south-2"
    key          = "benchmark/data/terraform.tfstate"
    region       = "eu-south-2"
    use_lockfile = true
  }
}
