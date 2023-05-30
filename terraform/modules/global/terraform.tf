terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.59.0"
      configuration_aliases = [
        aws.global,
        aws.eu-west-1,
        aws.eu-west-2,
      ]
    }
  }
}

data "aws_caller_identity" "current" {
  provider = aws.global
}
