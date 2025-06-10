terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.59.0"
      configuration_aliases = [
        aws.management,
        aws.shared,
        aws.global
      ]
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.4"
    }
  }
}
