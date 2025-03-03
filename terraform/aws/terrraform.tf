terraform {
  backend "s3" {
    bucket         = "opg.terraform.state"
    key            = "opg-data-lpa-uid/terraform.tfstate"
    encrypt        = true
    region         = "eu-west-1"
    dynamodb_table = "remote_lock"
    assume_role = {
      role_arn = "arn:aws:iam::311462405659:role/integrations-ci"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.8.0"
    }
  }
  required_version = ">= 1.4.0"
}

provider "aws" {
  alias  = "global"
  region = "eu-west-1"

  assume_role {
    role_arn     = "arn:aws:iam::${local.environment.account_id}:role/${var.default_role}"
    session_name = "terraform-session"
  }

  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  alias  = "eu-west-1"
  region = "eu-west-1"

  assume_role {
    role_arn     = "arn:aws:iam::${local.environment.account_id}:role/${var.default_role}"
    session_name = "terraform-session"
  }

  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  alias  = "eu-west-2"
  region = "eu-west-2"

  assume_role {
    role_arn     = "arn:aws:iam::${local.environment.account_id}:role/${var.default_role}"
    session_name = "terraform-session"
  }

  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  alias  = "management"
  region = "eu-west-1"

  assume_role {
    role_arn     = "arn:aws:iam::311462405659:role/${var.management_role}"
    session_name = "terraform-session"
  }

  default_tags {
    tags = local.default_tags
  }
}
