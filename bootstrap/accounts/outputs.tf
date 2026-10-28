output "shared_network_account_id" {
  value = aws_organizations_account.shared_network.id
}

output "workload_dev_account_id" {
  value = aws_organizations_account.workload_dev.id
}
