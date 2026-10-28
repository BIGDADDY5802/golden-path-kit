variable "name" {
  description = "Name prefix applied to all resources this module creates"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of public subnets (one per AZ) to create"
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 1 && var.az_count <= 3
    error_message = "az_count must be between 1 and 3 to keep this lab within free-tier-friendly limits."
  }
}

variable "tags" {
  description = "Resource tags; must include Owner and Environment for the golden-path tagging convention."
  type        = map(string)

  validation {
    condition     = contains(keys(var.tags), "Owner") && contains(keys(var.tags), "Environment")
    error_message = "tags must include both \"Owner\" and \"Environment\" keys."
  }
}
