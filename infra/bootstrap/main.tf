resource "aws_s3_bucket" "tfstate" {
  bucket = "liken-benchmark-tfstate-eu-south-2"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

locals {
  # job_workflow_ref pins the trust to this repo's infra.yml. The
  # sub/environment subject is not used: GitHub does not emit the
  # environment segment for all events, so assumes are denied.
  github_workflow_ref = "VictorAut/liken-databricks-benchmark/.github/workflows/infra.yml@*"
}

data "aws_iam_policy_document" "github_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:job_workflow_ref"
      values   = [local.github_workflow_ref]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "gha" {
  name               = "liken-benchmark-gha"
  assume_role_policy = data.aws_iam_policy_document.github_trust.json
}


data "aws_iam_policy_document" "gha_permissions" {
  statement {
    sid = "S3Lifecycle"
    actions = [
      "s3:CreateBucket",
      "s3:DeleteBucket",
      "s3:GetBucketLocation",
      "s3:GetBucketVersioning",
      "s3:ListBucket",
      "s3:ListBucketVersions",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:GetBucketPublicAccessBlock",
      "s3:PutBucketPublicAccessBlock",
      "s3:GetEncryptionConfiguration",
      "s3:PutEncryptionConfiguration",
      "s3:GetBucketPolicy",
      "s3:PutBucketPolicy",
      "s3:DeleteBucketPolicy",
      "s3:PutBucketVersioning",
      "s3:GetBucketTagging",
      "s3:PutBucketTagging",
      "s3:GetBucketOwnershipControls",
      "s3:PutBucketOwnershipControls",
    ]
    resources = [
      "arn:aws:s3:::liken-benchmark-tfstate-eu-south-2",
      "arn:aws:s3:::liken-benchmark-tfstate-eu-south-2/*",
      "arn:aws:s3:::liken-benchmark-dbx-root-eu-south-2",
      "arn:aws:s3:::liken-benchmark-dbx-root-eu-south-2/*",
      "arn:aws:s3:::liken-benchmark-data-eu-south-2",
      "arn:aws:s3:::liken-benchmark-data-eu-south-2/*",
    ]
  }

  statement {
    sid       = "S3List"
    actions   = ["s3:ListAllMyBuckets"]
    resources = ["*"]
  }

  statement {
    sid       = "STS"
    actions   = ["sts:GetCallerIdentity"]
    resources = ["*"]
  }

  # VPC/EC2: the benchmark VPC, subnets, NAT, endpoints, IGW.
  statement {
    sid = "EC2VPC"
    actions = [
      "ec2:CreateVpc",
      "ec2:DeleteVpc",
      "ec2:ModifyVpcAttribute",
      "ec2:DescribeVpcs",
      "ec2:DescribeVpcAttribute",
      "ec2:CreateSubnet",
      "ec2:DeleteSubnet",
      "ec2:DescribeSubnets",
      "ec2:CreateRouteTable",
      "ec2:DeleteRouteTable",
      "ec2:DescribeRouteTables",
      "ec2:CreateRoute",
      "ec2:DeleteRoute",
      "ec2:AssociateRouteTable",
      "ec2:DisassociateRouteTable",
      "ec2:CreateInternetGateway",
      "ec2:DeleteInternetGateway",
      "ec2:AttachInternetGateway",
      "ec2:DetachInternetGateway",
      "ec2:CreateNatGateway",
      "ec2:DeleteNatGateway",
      "ec2:DescribeNatGateways",
      "ec2:CreateEgressOnlyInternetGateway",
      "ec2:DeleteEgressOnlyInternetGateway",
      "ec2:AllocateAddress",
      "ec2:ReleaseAddress",
      "ec2:DescribeAddresses",
      "ec2:AssociateAddress",
      "ec2:CreateVpcEndpoint",
      "ec2:DeleteVpcEndpoints",
      "ec2:DescribeVpcEndpoints",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeSecurityGroups",
      "ec2:CreateSecurityGroup",
      "ec2:DeleteSecurityGroup",
      "ec2:CreateTags",
      "ec2:DeleteTags",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeNetworkAcls",
      "ec2:CreateNetworkAcl",
      "ec2:DeleteNetworkAcl",
      "ec2:CreateNetworkAclEntry",
      "ec2:DeleteNetworkAclEntry",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeSecurityGroupRules",
      "ec2:DescribeAddressesAttribute",
      "ec2:DescribePrefixLists",
    ]
    resources = ["*"]
  }

  # IAM: the cross-account role and its policy, name-scoped.
  statement {
    sid = "IAMLifecycle"
    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:GetRole",
      "iam:UpdateRole",
      "iam:PutRolePolicy",
      "iam:GetRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      "iam:TagRole",
      "iam:UntagRole",
    ]
    resources = ["arn:aws:iam::355162269108:role/liken-benchmark-*"]
  }

  # Databricks workspace creation reads the account id through STS; the
  # provider also calls iam:CreateServiceLinkedRole on first workspace.
  statement {
    sid       = "ServiceLinkedRole"
    actions   = ["iam:CreateServiceLinkedRole", "iam:GetServiceLinkedRoleDeletionStatus"]
    resources = ["arn:aws:iam::355162269108:role/aws-service-role/*"]
  }
}

resource "aws_iam_role_policy" "gha" {
  name   = "liken-benchmark-gha-permissions"
  role   = aws_iam_role.gha.id
  policy = data.aws_iam_policy_document.gha_permissions.json
}

output "state_bucket" {
  description = "Name of the Terraform state bucket."
  value       = aws_s3_bucket.tfstate.id
}

output "oidc_role_arn" {
  description = "ARN of the GitHub Actions deploy role."
  value       = aws_iam_role.gha.arn
}
