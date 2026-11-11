data "databricks_spark_version" "lts" {
  provider          = databricks.workspace
  spark_version     = "4"
  latest            = true
  long_term_support = true

  depends_on = [databricks_mws_workspaces.this]
}

data "databricks_node_type" "smallest" {
  provider   = databricks.workspace
  local_disk = true

  depends_on = [databricks_mws_workspaces.this]
}

resource "databricks_cluster" "benchmark" {
  provider                = databricks.workspace
  cluster_name            = local.cluster_name
  spark_version           = data.databricks_spark_version.lts.id
  node_type_id            = data.databricks_node_type.smallest.id
  autotermination_minutes = 30
  data_security_mode      = "SINGLE_USER"
  # The single user is the person running benchmarks from the UI, not
  # the deployer service principal (the SP only deploys infra).
  single_user_name = var.single_user_email

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
