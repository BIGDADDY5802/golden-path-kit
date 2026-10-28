variable "region" {
  description = "AWS region for the state backend resources"
  type        = string
  default     = "us-east-1"
}

variable "shared_network_account_id" {
  description = "Account ID of the shared-network member account"
  type        = string
  default     = "400484420291"
}

variable "workload_dev_account_id" {
  description = "Account ID of the workload-dev member account"
  type        = string
  default     = "556166822095"
}

variable "state_bucket_prefix" {
  description = "Prefix for the per-account Terraform state bucket name"
  type        = string
  default     = "golden-path-tf-state"
}

variable "lock_table_name" {
  description = "Name of the per-account DynamoDB Terraform lock table"
  type        = string
  default     = "terraform-locks"
}
