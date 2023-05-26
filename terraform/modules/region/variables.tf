variable "dynamodb_arn" {
  type = string
}

variable "dynamodb_name" {
  type = string
}

variable "dynamodb_kms_key_arn" {
  type = string
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

locals {
  policy_region_prefix = lower(replace(data.aws_region.current.name, "-", ""))
}
