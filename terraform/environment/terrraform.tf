terraform {
  backend "s3" {
    assume_role = {
      role_arn = "arn:aws:iam::311462405659:role/opg-data-lpa-uid-terraform-state-access"
    }
    bucket       = "opg.terraform.state"
    encrypt      = true
    key          = "opg-data-lpa-uid/terraform.tfstate"
    region       = "eu-west-1"
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.8.0"
    }
  }
  required_version = ">= 1.11.0"
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

provider "aws" {
  alias  = "shared-eu-west-1"
  region = "eu-west-1"

  assume_role {
    role_arn     = "arn:aws:iam::${local.environment.shared_account_id}:role/${var.shared_role}"
    session_name = "terraform-session"
  }

  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  alias  = "shared-eu-west-2"
  region = "eu-west-2"

  assume_role {
    role_arn     = "arn:aws:iam::${local.environment.shared_account_id}:role/${var.shared_role}"
    session_name = "terraform-session"
  }

  default_tags {
    tags = local.default_tags
  }
}
