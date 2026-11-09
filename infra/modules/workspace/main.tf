# Databricks workspace on the customer-managed VPC: the provider guide's
# mws_networks + mws_storage_configurations + mws_workspaces graph, with
# the two wait guards the guide prescribes — a propagation guard before
# the workspace creation, and a RUNNING-wait before the URL is exported
# (Review-Focus 2 and 3).
#
# Account-level Databricks provider only: this module creates the
# workspace but touches nothing inside it. Provider requirements and the
# AWS provider config come from the including unit's root.hcl
# generation.

provider "databricks" {
  host       = "https://accounts.cloud.databricks.com"
  account_id = var.databricks_account_id
  client_id  = var.databricks_client_id
  auth_type  = "github-oidc"
}

resource "databricks_mws_networks" "this" {
  account_id         = var.databricks_account_id
  network_name       = "${var.workspace_name}-network"
  security_group_ids = [var.security_group_id]
  subnet_ids         = var.private_subnet_ids
  vpc_id             = var.vpc_id
}

resource "databricks_mws_storage_configurations" "this" {
  account_id                 = var.databricks_account_id
  bucket_name                = var.root_bucket_name
  storage_configuration_name = "${var.workspace_name}-storage"
}

# Propagation guard: the cross-account role policy may be younger than
# the credentials validation tolerates. The workspace unit depends on
# the iam unit (time from CI's two-stack order), but IAM propagation is
# not instant after apply either — the guide's guard is retained here.
resource "time_sleep" "propagation_guard" {
  create_duration = "15s"
}

# The workspace creation is the long pole; mws_workspaces blocks until
# the workspace is created, but the URL can 404 for a short window after
# creation completes.
resource "databricks_mws_workspaces" "this" {
  account_id               = var.databricks_account_id
  workspace_name           = var.workspace_name
  aws_region               = var.aws_region
  credentials_id           = var.credentials_id
  storage_configuration_id = databricks_mws_storage_configurations.this.storage_configuration_id
  network_id               = databricks_mws_networks.this.network_id

  depends_on = [time_sleep.propagation_guard]
}

# RUNNING-wait (Review-Focus 2): poll the workspace URL until it answers
# before the unit's outputs are exported, so the cluster unit (Task 6)
# never races a workspace that is not yet serving traffic.
resource "null_resource" "wait_for_workspace" {
  triggers = {
    workspace_id  = databricks_mws_workspaces.this.workspace_id
    workspace_url = databricks_mws_workspaces.this.workspace_url
  }

  provisioner "local-exec" {
    when    = create
    command = "for i in $(seq 1 30); do code=$(curl -s -o /dev/null -w '%%{http_code}' \"https://${databricks_mws_workspaces.this.workspace_url}\") && [ \"$code\" -ge 200 ] && [ \"$code\" -lt 500 ] && exit 0; sleep 10; done; echo workspace URL never became reachable; exit 1"
  }
}

output "workspace_url" {
  description = "URL of the created workspace."
  value       = databricks_mws_workspaces.this.workspace_url

  depends_on = [null_resource.wait_for_workspace]
}
