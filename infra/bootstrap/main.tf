resource "aws_s3_bucket" "tfstate" {
  bucket = "liken-benchmark-tfstate-eu-central-1"

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
  # job_workflow_ref pins the trust to this repo's workflows. The
  # sub/environment subject is not used: GitHub does not emit the
  # environment segment for all events, so assumes are denied.
  #
  # infra.yml@* covers apply/destroy and any branch. terraform-plan.yml
  # is the reusable plan workflow: callers reference it at @main, so
  # its job_workflow_ref carries that ref. A plan job running from a
  # caller branch still reports the reusable workflow's ref.
  github_workflow_refs = [
    "VictorAut/liken-databricks-benchmark/.github/workflows/infra.yml@*",
    "VictorAut/liken-databricks-benchmark/.github/workflows/terraform-plan.yml@*",
  ]
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
      values   = local.github_workflow_refs
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
  # Every bucket named liken-benchmark-* (tfstate, dbx root, data).
  statement {
    sid     = "S3Buckets"
    actions = ["s3:*"]
    resources = [
      "arn:aws:s3:::liken-benchmark-*",
      "arn:aws:s3:::liken-benchmark-*/*",
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

  # EC2 does not support resource-level permissions for most actions.
  statement {
    sid       = "EC2"
    actions   = ["ec2:*"]
    resources = ["*"]
  }

  # Roles, policies, and instance profiles created for the benchmark.
  # iam:PassRole is here because the Databricks provider passes the
  # cross-account role/instance profile on workspace setup.
  statement {
    actions = ["iam:*"]
    resources = [
      "arn:aws:iam::355162269108:role/liken-benchmark-*",
      "arn:aws:iam::355162269108:policy/liken-benchmark-*",
      "arn:aws:iam::355162269108:instance-profile/liken-benchmark-*",
    ]
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
