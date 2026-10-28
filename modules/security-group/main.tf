resource "aws_security_group" "this" {
  name        = var.name
  description = "Managed by golden-path-kit security-group module"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = var.name })

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      description = ingress.value.description
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  dynamic "egress" {
    for_each = var.egress_rules
    content {
      description = egress.value.description
      from_port   = egress.value.port
      to_port     = egress.value.port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }

  # Governance guardrail baked into the module itself, not just caught later by a CI scanner.
  lifecycle {
    precondition {
      condition = var.allow_public_ingress || !anytrue([
        for rule in var.ingress_rules : contains(rule.cidr_blocks, "0.0.0.0/0")
      ])
      error_message = "An ingress rule allows 0.0.0.0/0 but allow_public_ingress is false. Set allow_public_ingress = true if this is intentional."
    }
  }
}
