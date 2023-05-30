variable "dynamodb_global_table_arn" {
  type     = string
  nullable = true
}

variable "dynamodb_kms_key_arn" {
  type    = string
  default = "*"
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
  environment_name     = "${var.environment_name}-${data.aws_region.current.name}"
  policy_region_prefix = lower(replace(data.aws_region.current.name, "-", ""))
}
