# --- GitHub OIDC entry point, management account ---

# Referenced, not created: an OIDC provider for this URL already exists in this account
# (owned by a separate "cloud-portfolio" Terraform project per its tags) — AWS allows only
# one per URL per account, and taking ownership here would risk that other project's state.
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

data "aws_iam_policy_document" "github_oidc_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Two patterns because GitHub now supports an "immutable IDs" sub-claim format
    # (repo:org@ORG_ID/repo@REPO_ID:...) alongside the classic repo:org/repo:... format,
    # depending on a per-repo opt-in setting — this trusts either.
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_org}/${var.github_repo}:*",
        "repo:${var.github_org}@*/${var.github_repo}@*:*",
      ]
    }
  }
}

# This role has no permissions of its own beyond assuming the two narrow per-account
# deploy roles below — it is only ever an entry point, never used to touch resources directly.
resource "aws_iam_role" "github_actions" {
  name               = "golden-path-github-actions"
  assume_role_policy = data.aws_iam_policy_document.github_oidc_trust.json
}

data "aws_iam_policy_document" "github_actions_assume" {
  statement {
    effect = "Allow"
    # TagSession must be granted on both sides of an assume-role call: the target's
    # trust policy (fixed separately) AND the caller's own identity-based policy here.
    actions = ["sts:AssumeRole", "sts:TagSession"]
    resources = [
      aws_iam_role.shared_network_ci_deploy.arn,
      aws_iam_role.workload_dev_ci_deploy.arn,
    ]
  }
}

resource "aws_iam_role_policy" "github_actions_assume" {
  name   = "assume-ci-deploy-roles"
  role   = aws_iam_role.github_actions.name
  policy = data.aws_iam_policy_document.github_actions_assume.json
}

# --- shared-network account: narrow deploy role, replaces OrganizationAccountAccessRole
#     for all routine Terraform runs (local and CI). Trusted by the OIDC entry role above
#     AND the local admin user, so both paths use the exact same identity. ---

data "aws_iam_policy_document" "shared_network_trust" {
  statement {
    effect = "Allow"
    # TagSession: aws-actions/configure-aws-credentials tags the assumed session with
    # GitHub run metadata by default for CloudTrail traceability, which needs this
    # in addition to AssumeRole itself.
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type = "AWS"
      identifiers = [
        aws_iam_role.github_actions.arn,
        var.local_admin_user_arn,
      ]
    }
  }
}

resource "aws_iam_role" "shared_network_ci_deploy" {
  provider           = aws.shared_network
  name               = "golden-path-ci-deploy"
  assume_role_policy = data.aws_iam_policy_document.shared_network_trust.json
}

data "aws_iam_policy_document" "shared_network_permissions" {
  statement {
    sid    = "Networking"
    effect = "Allow"
    actions = [
      "ec2:Describe*",
      "ec2:CreateVpc", "ec2:DeleteVpc", "ec2:ModifyVpcAttribute",
      "ec2:CreateSubnet", "ec2:DeleteSubnet",
      "ec2:CreateInternetGateway", "ec2:DeleteInternetGateway",
      "ec2:AttachInternetGateway", "ec2:DetachInternetGateway",
      "ec2:CreateRouteTable", "ec2:DeleteRouteTable",
      "ec2:CreateRoute", "ec2:DeleteRoute",
      "ec2:AssociateRouteTable", "ec2:DisassociateRouteTable",
      "ec2:CreateSecurityGroup", "ec2:DeleteSecurityGroup",
      "ec2:AuthorizeSecurityGroupIngress", "ec2:AuthorizeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress", "ec2:RevokeSecurityGroupEgress",
      "ec2:CreateTags", "ec2:DeleteTags",
    ]
    resources = ["*"]
  }

  statement {
    sid     = "StateBucket"
    effect  = "Allow"
    actions = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
    resources = [
      "arn:aws:s3:::golden-path-tf-state-${var.shared_network_account_id}",
      "arn:aws:s3:::golden-path-tf-state-${var.shared_network_account_id}/*",
    ]
  }

  statement {
    sid       = "LockTable"
    effect    = "Allow"
    actions   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem"]
    resources = ["arn:aws:dynamodb:*:${var.shared_network_account_id}:table/terraform-locks"]
  }
}

resource "aws_iam_role_policy" "shared_network_permissions" {
  provider = aws.shared_network
  name     = "golden-path-ci-permissions"
  role     = aws_iam_role.shared_network_ci_deploy.name
  policy   = data.aws_iam_policy_document.shared_network_permissions.json
}

# --- workload-dev account: same pattern, plus IAM/S3 actions scoped by naming
#     convention to exactly what this account's modules create. ---

data "aws_iam_policy_document" "workload_dev_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type = "AWS"
      identifiers = [
        aws_iam_role.github_actions.arn,
        var.local_admin_user_arn,
      ]
    }
  }
}

resource "aws_iam_role" "workload_dev_ci_deploy" {
  provider           = aws.workload_dev
  name               = "golden-path-ci-deploy"
  assume_role_policy = data.aws_iam_policy_document.workload_dev_trust.json
}

data "aws_iam_policy_document" "workload_dev_permissions" {
  statement {
    sid    = "Networking"
    effect = "Allow"
    actions = [
      "ec2:Describe*",
      "ec2:CreateVpc", "ec2:DeleteVpc", "ec2:ModifyVpcAttribute",
      "ec2:CreateSubnet", "ec2:DeleteSubnet",
      "ec2:CreateInternetGateway", "ec2:DeleteInternetGateway",
      "ec2:AttachInternetGateway", "ec2:DetachInternetGateway",
      "ec2:CreateRouteTable", "ec2:DeleteRouteTable",
      "ec2:CreateRoute", "ec2:DeleteRoute",
      "ec2:AssociateRouteTable", "ec2:DisassociateRouteTable",
      "ec2:CreateSecurityGroup", "ec2:DeleteSecurityGroup",
      "ec2:AuthorizeSecurityGroupIngress", "ec2:AuthorizeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress", "ec2:RevokeSecurityGroupEgress",
      "ec2:CreateTags", "ec2:DeleteTags",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ScopedIamRole"
    effect = "Allow"
    actions = [
      "iam:CreateRole", "iam:DeleteRole", "iam:GetRole",
      "iam:TagRole", "iam:UntagRole",
      "iam:AttachRolePolicy", "iam:DetachRolePolicy",
      "iam:PutRolePolicy", "iam:DeleteRolePolicy", "iam:GetRolePolicy",
      "iam:ListAttachedRolePolicies", "iam:ListRolePolicies",
      # The provider's role-delete path checks for attached instance profiles first,
      # even when none were ever created - found live, mid-teardown, when deleting
      # workload-dev-app-role failed without this.
      "iam:ListInstanceProfilesForRole",
    ]
    resources = ["arn:aws:iam::${var.workload_dev_account_id}:role/workload-dev-*"]
  }

  statement {
    sid    = "ScopedAppBucket"
    effect = "Allow"
    actions = [
      "s3:CreateBucket", "s3:DeleteBucket",
      "s3:PutBucketTagging",
      "s3:PutEncryptionConfiguration",
      "s3:PutBucketVersioning",
      "s3:PutBucketPublicAccessBlock",
      "s3:Get*",
      "s3:ListBucket",
    ]
    resources = ["arn:aws:s3:::golden-path-workload-dev-*"]
  }

  statement {
    sid     = "StateBucket"
    effect  = "Allow"
    actions = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
    resources = [
      "arn:aws:s3:::golden-path-tf-state-${var.workload_dev_account_id}",
      "arn:aws:s3:::golden-path-tf-state-${var.workload_dev_account_id}/*",
    ]
  }

  statement {
    sid       = "LockTable"
    effect    = "Allow"
    actions   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem"]
    resources = ["arn:aws:dynamodb:*:${var.workload_dev_account_id}:table/terraform-locks"]
  }
}

resource "aws_iam_role_policy" "workload_dev_permissions" {
  provider = aws.workload_dev
  name     = "golden-path-ci-permissions"
  role     = aws_iam_role.workload_dev_ci_deploy.name
  policy   = data.aws_iam_policy_document.workload_dev_permissions.json
}

# --- drift-detection alerting: one topic in the management account, both per-account
#     deploy roles can publish to it cross-account via the topic's own resource policy. ---

resource "aws_sns_topic" "drift_alerts" {
  name = "golden-path-drift-alerts"
}

resource "aws_sns_topic_subscription" "drift_alerts_email" {
  topic_arn = aws_sns_topic.drift_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

data "aws_iam_policy_document" "drift_alerts_topic_policy" {
  statement {
    sid    = "AllowCiDeployRolesToPublish"
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        aws_iam_role.shared_network_ci_deploy.arn,
        aws_iam_role.workload_dev_ci_deploy.arn,
      ]
    }

    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.drift_alerts.arn]
  }
}

resource "aws_sns_topic_policy" "drift_alerts" {
  arn    = aws_sns_topic.drift_alerts.arn
  policy = data.aws_iam_policy_document.drift_alerts_topic_policy.json
}

data "aws_iam_policy_document" "shared_network_sns_publish" {
  statement {
    sid       = "DriftAlertPublish"
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.drift_alerts.arn]
  }
}

resource "aws_iam_role_policy" "shared_network_sns_publish" {
  provider = aws.shared_network
  name     = "golden-path-drift-alert-publish"
  role     = aws_iam_role.shared_network_ci_deploy.name
  policy   = data.aws_iam_policy_document.shared_network_sns_publish.json
}

data "aws_iam_policy_document" "workload_dev_sns_publish" {
  statement {
    sid       = "DriftAlertPublish"
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.drift_alerts.arn]
  }
}

resource "aws_iam_role_policy" "workload_dev_sns_publish" {
  provider = aws.workload_dev
  name     = "golden-path-drift-alert-publish"
  role     = aws_iam_role.workload_dev_ci_deploy.name
  policy   = data.aws_iam_policy_document.workload_dev_sns_publish.json
}
