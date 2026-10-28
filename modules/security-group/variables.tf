variable "name" {
  description = "Security group name"
  type        = string
}

variable "vpc_id" {
  description = "VPC to attach the security group to"
  type        = string
}

variable "ingress_rules" {
  description = "List of ingress rules to allow"
  type = list(object({
    description = string
    port        = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = []
}

variable "egress_rules" {
  description = "List of egress rules to allow"
  type = list(object({
    description = string
    port        = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    {
      description = "Allow all outbound"
      port        = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

variable "allow_public_ingress" {
  description = "Must be explicitly true for any ingress_rules entry to use 0.0.0.0/0"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Resource tags; must include Owner and Environment for the golden-path tagging convention."
  type        = map(string)

  validation {
    condition     = contains(keys(var.tags), "Owner") && contains(keys(var.tags), "Environment")
    error_message = "tags must include both \"Owner\" and \"Environment\" keys."
  }
}
