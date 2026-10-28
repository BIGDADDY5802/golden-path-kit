output "vpc_id" {
  value = module.network.vpc_id
}

output "app_role_arn" {
  value = module.app_role.role_arn
}

output "app_bucket_id" {
  value = module.app_bucket.bucket_id
}

output "app_security_group_id" {
  value = module.app_sg.security_group_id
}
