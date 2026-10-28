variable "shared_network_name" {
  description = "Name of the shared-network member account"
  type        = string
  default     = "shared-network"
}

variable "shared_network_email" {
  description = "Root email for the shared-network member account"
  type        = string
  default     = "firstofmyname5802+shared-network@gmail.com"
}

variable "workload_dev_name" {
  description = "Name of the workload-dev member account"
  type        = string
  default     = "workload-dev"
}

variable "workload_dev_email" {
  description = "Root email for the workload-dev member account"
  type        = string
  default     = "firstofmyname5802+workload-dev@gmail.com"
}
