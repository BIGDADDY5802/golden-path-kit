# close_on_deletion = false (the provider default) so a future `terraform destroy` here only
# forgets the account in state — it never closes the real AWS account, which has a 90-day
# email-reuse cooldown and can't be undone.
resource "aws_organizations_account" "shared_network" {
  name              = var.shared_network_name
  email             = var.shared_network_email
  close_on_deletion = false
}

resource "aws_organizations_account" "workload_dev" {
  name              = var.workload_dev_name
  email             = var.workload_dev_email
  close_on_deletion = false
}
