variable "github_org" {
  description = "GitHub org/user that owns the repo allowed to assume the CI role"
  type        = string
  default     = "BIGDADDY5802"
}

variable "github_repo" {
  description = "GitHub repo allowed to assume the CI role"
  type        = string
  default     = "golden-path-kit"
}

variable "shared_network_account_id" {
  type    = string
  default = "400484420291"
}

variable "workload_dev_account_id" {
  type    = string
  default = "556166822095"
}

variable "local_admin_user_arn" {
  description = "Local human identity that may also assume the per-account CI deploy roles, for Terraform runs outside CI"
  type        = string
  default     = "arn:aws:iam::778185677715:user/awscli"
}
