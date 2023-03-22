terraform {
  #   backend "s3" {
  #     bucket         = "opg.terraform.state"
  #     key            = "opg-data-lpa-uid/terraform.tfstate"
  #     encrypt        = true
  #     region         = "eu-west-1"
  #     role_arn       = "arn:aws:iam::311462405659:role/sirius-ci"
  #     dynamodb_table = "remote_lock"
  #   }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.59.0"
    }
  }
  required_version = ">= 1.4.0"
}

provider "aws" {
  region = "eu-west-1"

  assume_role {
    role_arn     = "arn:aws:iam::${local.environment.account_id}:role/${var.default_role}"
    session_name = "terraform-session"
  }

  default_tags {
    tags = local.default_tags
  }
}
