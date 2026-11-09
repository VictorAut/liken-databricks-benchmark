output "vpc_id" {
  description = "Id of the benchmark VPC."
  value       = aws_vpc.this.id
}

output "private_subnet_ids" {
  description = "Private subnet ids across two AZs, for the Databricks network."
  value       = aws_subnet.private[*].id
}

output "default_security_group_id" {
  description = "Id of the VPC's default security group."
  value       = aws_default_security_group.this.id
}

output "nat_gateway_id" {
  description = "Id of the NAT gateway (teardown check target)."
  value       = aws_nat_gateway.this.id
}

output "s3_endpoint_id" {
  description = "Id of the S3 gateway endpoint."
  value       = aws_vpc_endpoint.s3.id
}

output "sts_endpoint_id" {
  description = "Id of the STS interface endpoint."
  value       = aws_vpc_endpoint.sts.id
}
