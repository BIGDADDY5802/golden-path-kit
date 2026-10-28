data "aws_iam_policy_document" "trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    dynamic "principals" {
      for_each = length(var.trusted_services) > 0 ? [1] : []
      content {
        type        = "Service"
        identifiers = var.trusted_services
      }
    }

    dynamic "principals" {
      for_each = length(var.trusted_account_arns) > 0 ? [1] : []
      content {
        type        = "AWS"
        identifiers = var.trusted_account_arns
      }
    }
  }
}

resource "aws_iam_role" "this" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.trust.json
  tags               = var.tags

  lifecycle {
    precondition {
      condition     = length(var.trusted_services) > 0 || length(var.trusted_account_arns) > 0
      error_message = "iam-role requires at least one trusted_service or trusted_account_arn so the role has a defined trust boundary."
    }
  }
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each   = toset(var.managed_policy_arns)
  role       = aws_iam_role.this.name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "inline" {
  count  = var.inline_policy_json == null ? 0 : 1
  name   = "${var.role_name}-inline"
  role   = aws_iam_role.this.name
  policy = var.inline_policy_json
}
