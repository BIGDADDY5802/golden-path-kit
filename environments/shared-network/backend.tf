terraform {
  backend "s3" {
    bucket         = "golden-path-tf-state-400484420291"
    key            = "shared-network/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true

    assume_role = {
      role_arn = "arn:aws:iam::400484420291:role/golden-path-ci-deploy"
    }
  }
}
