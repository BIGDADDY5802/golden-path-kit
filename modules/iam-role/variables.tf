variable "role_name" {
  description = "Name of the IAM role"
  type        = string
}

variable "trusted_services" {
  description = "AWS service principals (e.g. ec2.amazonaws.com) allowed to assume this role"
  type        = list(string)
  default     = []
}

variable "trusted_account_arns" {
  description = "AWS account or role ARNs allowed to assume this role"
  type        = list(string)
  default     = []
}

variable "managed_policy_arns" {
  description = "Managed policy ARNs to attach to the role"
  type        = list(string)
  default     = []
}

variable "inline_policy_json" {
  description = "Optional least-privilege inline policy JSON document"
  type        = string
  default     = null
}

variable "tags" {
  description = "Resource tags; must include Owner and Environment for the golden-path tagging convention."
  type        = map(string)

  validation {
    condition     = contains(keys(var.tags), "Owner") && contains(keys(var.tags), "Environment")
    error_message = "tags must include both \"Owner\" and \"Environment\" keys."
  }
}
