# Foundation stack: the account-level units every workspace needs. The
# benchmark stack's units depend on these at their canonical paths
# (infra/units/...) because stacks cannot declare cross-stack
# dependencies; ordering across stacks is the workflow's job (CI runs
# foundation before benchmark).

unit "iam" {
  source = "../../units/iam"
  path   = "iam"
}

unit "storage" {
  source = "../../units/storage"
  path   = "storage"
}
