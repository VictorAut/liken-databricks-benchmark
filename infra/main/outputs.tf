output "workspace_url" {
  description = "URL of the benchmark workspace."
  value       = databricks_mws_workspaces.this.workspace_url

  depends_on = [terraform_data.wait_for_workspace]
}

output "cluster_id" {
  description = "Id of the benchmark cluster."
  value       = databricks_cluster.benchmark.cluster_id
}

output "cluster_name" {
  description = "Name of the benchmark cluster."
  value       = databricks_cluster.benchmark.cluster_name
}

output "data_bucket_name" {
  description = "Name of the data S3 bucket."
  value       = aws_s3_bucket.data.bucket
}
