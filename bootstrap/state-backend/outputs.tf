output "shared_network_state_bucket" {
  value = aws_s3_bucket.shared_network_state.id
}

output "shared_network_lock_table" {
  value = aws_dynamodb_table.shared_network_locks.name
}

output "workload_dev_state_bucket" {
  value = aws_s3_bucket.workload_dev_state.id
}

output "workload_dev_lock_table" {
  value = aws_dynamodb_table.workload_dev_locks.name
}
