# Classic compute cluster (D005: defined in code only; the UI observes,
# never creates). Workspace-level Databricks provider, OIDC-federated.
#
# Node type is resolved by data source (not hardcoded) so the plan stays
# valid if AWS inventory shifts; autoscale range and runtime selection
# are pinned in code.

provider "databricks" {
  # Workspace-level provider: authenticates against the workspace itself.
  host      = var.workspace_url
  client_id = var.databricks_client_id
  auth_type = "github-oidc"
}

# Latest LTS runtime carrying Spark 4.0 (Runtime 17.x, verified fact:
# Databricks Runtime 17.0 is Apache Spark 4.0.0).
data "databricks_spark_version" "lts" {
  spark_version     = "4"
  latest            = true
  long_term_support = true
}

# Smallest node type with local disk: the data source returns the
# smallest node matching the criteria by design (provider docs), so no
# sort attribute exists or is needed.
data "databricks_node_type" "smallest" {
  local_disk = true
}

resource "databricks_cluster" "benchmark" {
  cluster_name            = var.cluster_name
  spark_version           = data.databricks_spark_version.lts.id
  node_type_id            = data.databricks_node_type.smallest.id
  autotermination_minutes = 30
  data_security_mode      = "SINGLE_USER"

  autoscale {
    min_workers = 1
    max_workers = 2
  }

  library {
    pypi {
      package = "liken==0.16.0"
    }
  }
}

output "cluster_id" {
  description = "Id of the benchmark cluster."
  value       = databricks_cluster.benchmark.cluster_id
}

output "cluster_name" {
  description = "Name of the benchmark cluster."
  value       = databricks_cluster.benchmark.cluster_name
}
