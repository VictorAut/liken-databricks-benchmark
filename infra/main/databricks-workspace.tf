resource "terraform_data" "wait_for_workspace" {
  triggers_replace = [
    databricks_mws_workspaces.this.workspace_id,
    databricks_mws_workspaces.this.workspace_url,
  ]

  provisioner "local-exec" {
    command = "for i in $(seq 1 30); do code=$(curl -s -o /dev/null -w '%%{http_code}' \"${databricks_mws_workspaces.this.workspace_url}\") && [ \"$code\" -ge 200 ] && [ \"$code\" -lt 500 ] && exit 0; sleep 10; done; echo workspace URL never became reachable; exit 1"
  }
}

# The workspace is opened from the UI by the single user's identity, so
# its workspace assignment is defined here rather than as a console
# step that every destroy → apply cycle would lose.
data "databricks_user" "benchmark_admin" {
  provider  = databricks.accounts
  user_name = var.single_user_email
}

resource "databricks_mws_permission_assignment" "benchmark_admin" {
  provider     = databricks.accounts
  workspace_id = databricks_mws_workspaces.this.workspace_id
  principal_id = data.databricks_user.benchmark_admin.id
  permissions  = ["ADMIN"]

  depends_on = [terraform_data.wait_for_workspace]
}