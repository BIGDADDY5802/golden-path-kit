output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
}

output "shared_network_ci_deploy_role_arn" {
  value = aws_iam_role.shared_network_ci_deploy.arn
}

output "workload_dev_ci_deploy_role_arn" {
  value = aws_iam_role.workload_dev_ci_deploy.arn
}
