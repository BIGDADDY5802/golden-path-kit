locals {
  common_tags = {
    Owner       = "jerome-hunter"
    Environment = "shared-network"
    Project     = "golden-path-kit"
  }
}

module "network" {
  source     = "../../modules/vpc"
  name       = "shared-network-vpc"
  cidr_block = "10.0.0.0/16"
  az_count   = 2
  tags       = local.common_tags
}

module "default_sg" {
  source = "../../modules/security-group"
  name   = "shared-network-internal"
  vpc_id = module.network.vpc_id
  tags   = local.common_tags

  ingress_rules = [
    {
      description = "Allow HTTPS from within the shared-network VPC"
      port        = 443
      protocol    = "tcp"
      cidr_blocks = [module.network.vpc_cidr_block]
    }
  ]
}
