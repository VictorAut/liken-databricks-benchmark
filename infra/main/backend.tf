terraform {
  backend "s3" {
    bucket       = "liken-benchmark-tfstate-eu-central-1"
    key          = "main/terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true
  }
}
