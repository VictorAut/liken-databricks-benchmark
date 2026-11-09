# Benchmark stack: the workspace-bearing units. Applied after the
# foundation stack (cross-stack ordering is the CI workflow's job, not
# HCL — see the plan's structural decision 2). Intra-stack ordering
# comes from each unit's own dependency blocks: cluster → workspace →
# vpc; data is independent.

unit "vpc" {
  source = "../../units/vpc"
  path   = "vpc"
}

unit "data" {
  source = "../../units/data"
  path   = "data"
}

unit "workspace" {
  source = "../../units/workspace"
  path   = "workspace"
}

unit "cluster" {
  source = "../../units/cluster"
  path   = "cluster"
}
