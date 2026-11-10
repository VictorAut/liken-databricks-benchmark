# Standing OIDC trust: the reusable terraform-plan workflow may
# authenticate as the CI service principal from any calling branch.
# The claim matched is job_workflow_ref, not sub, so the
# subject carries no repo: prefix.
#
# This lives in bootstrap, not infra/main: infra/main is destroyed
# between sessions, and the dispatch plan that re-creates the stack
# needs this policy to authenticate first.
#
# The job_workflow_ref subject pins the reusable workflow at @main. Any
# repository that can invoke it could use this identity; the reusable
# workflow refuses callers from other repositories.
resource "databricks_service_principal_federation_policy" "plan" {
  service_principal_id = 76997434750825
  description          = "Reusable terraform-plan workflow, any calling branch"

  oidc_policy = {
    issuer        = "https://token.actions.githubusercontent.com"
    audiences     = ["https://github.com/VictorAut"]
    subject       = "VictorAut/liken-databricks-benchmark/.github/workflows/terraform-plan.yml@refs/heads/main"
    subject_claim = "job_workflow_ref"
  }
}
