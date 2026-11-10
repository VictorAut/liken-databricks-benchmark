# Standing OIDC trust: the reusable terraform-plan workflow may
# authenticate as the CI service principal from any calling branch.
# The claim matched is job_workflow_ref, not sub, so the
# subject carries no repo: prefix.
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

# The apply/destroy subject: tokens minted in the protected GitHub
# environment "benchmark". Created manually before trust was
# code-managed; imported so all standing trust lives in code. It has
# no description in the account, so none is set here.
resource "databricks_service_principal_federation_policy" "benchmark_env" {
  service_principal_id = 76997434750825

  oidc_policy = {
    issuer    = "https://token.actions.githubusercontent.com"
    audiences = ["https://github.com/VictorAut"]
    subject   = "repo:VictorAut@51970549/liken-databricks-benchmark@1446713409:environment:benchmark"
  }
}
