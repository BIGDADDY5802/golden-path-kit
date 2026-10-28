terraform {
  backend "s3" {
    bucket         = "golden-path-tf-state-556166822095"
    key            = "workload-dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true

    assume_role = {
      role_arn = "arn:aws:iam::556166822095:role/golden-path-ci-deploy"
    }
  }
}
