variable "bucket_name" {
  description = "Globally-unique S3 bucket name"
  type        = string
}

variable "enable_versioning" {
  description = "Enable bucket versioning"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "KMS key ARN for SSE-KMS; leave null for SSE-S3 (AES256)"
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
