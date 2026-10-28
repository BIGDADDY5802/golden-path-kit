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
  region = "us-east-1"
}

provider "aws" {
  alias  = "shared_network"
  region = "us-east-1"

  assume_role {
    role_arn = "arn:aws:iam::400484420291:role/OrganizationAccountAccessRole"
  }
}

provider "aws" {
  alias  = "workload_dev"
  region = "us-east-1"

  assume_role {
    role_arn = "arn:aws:iam::556166822095:role/OrganizationAccountAccessRole"
  }
}
