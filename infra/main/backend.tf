terraform {
  backend "s3" {
    bucket       = "liken-benchmark-tfstate-eu-south-2"
    key          = "main/terraform.tfstate"
    region       = "eu-south-2"
    use_lockfile = true
  }
}
