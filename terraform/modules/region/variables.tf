variable "dynamodb_primary_arn" {
  default = ""
}

variable "dynamodb_primary_name" {
  default = ""
}

variable "environment_name" {}

variable "environment" {}

variable "is_local" {
}

variable "is_primary" {
  type    = bool
  default = false
}

variable "lambda_iam_role" {}

variable "app_version" {
  type = string
}

locals {
  environment_name = "${var.environment_name}-${data.aws_region.current.name}"
}
