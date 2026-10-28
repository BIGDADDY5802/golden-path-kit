data "aws_caller_identity" "current" {}

# Cross-account state reference: reads the shared-network account's VPC CIDR directly out
# of its state file instead of hardcoding it here.
data "terraform_remote_state" "shared_network" {
  backend = "s3"

  config = {
    bucket = "golden-path-tf-state-400484420291"
    key    = "shared-network/terraform.tfstate"
    region = "us-east-1"

    assume_role = {
      role_arn = "arn:aws:iam::400484420291:role/golden-path-ci-deploy"
    }
  }
}

locals {
  common_tags = {
    Owner       = "jerome-hunter"
    Environment = "workload-dev"
    Project     = "golden-path-kit"
  }
}

module "network" {
  source     = "../../modules/vpc"
  name       = "workload-dev-vpc"
  cidr_block = "10.1.0.0/16"
  az_count   = 2
  tags       = local.common_tags
}

module "app_sg" {
  source = "../../modules/security-group"
  name   = "workload-dev-app"
  vpc_id = module.network.vpc_id
  tags   = local.common_tags

  ingress_rules = [
    {
      description = "Allow HTTPS from the shared-network account VPC"
      port        = 443
      protocol    = "tcp"
      cidr_blocks = [data.terraform_remote_state.shared_network.outputs.vpc_cidr_block]
    }
  ]
}

module "app_role" {
  source           = "../../modules/iam-role"
  role_name        = "workload-dev-app-role"
  trusted_services = ["ec2.amazonaws.com"]
  tags             = local.common_tags
}

module "app_bucket" {
  source      = "../../modules/s3-bucket"
  bucket_name = "golden-path-workload-dev-app-${data.aws_caller_identity.current.account_id}"
  tags        = local.common_tags
}
