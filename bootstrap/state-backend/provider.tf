terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  alias  = "shared_network"
  region = var.region

  assume_role {
    role_arn = "arn:aws:iam::${var.shared_network_account_id}:role/OrganizationAccountAccessRole"
  }
}

provider "aws" {
  alias  = "workload_dev"
  region = var.region

  assume_role {
    role_arn = "arn:aws:iam::${var.workload_dev_account_id}:role/OrganizationAccountAccessRole"
  }
}
