variable "dynamodb_global_table_arn" {
  type     = string
  nullable = true
}

variable "dynamodb_kms_key_arn" {
  type    = string
  default = "*"
}

variable "dns_weighting" {
  type    = number
  default = 50
}

variable "environment_name" {
  type = string
}

variable "environment" {
  type = object({
    account_id   = string
    account_name = string
    allowed_arns = list(string)
  })
}

variable "is_primary" {
  type    = bool
  default = false
}

variable "lambda_iam_role" {
  type = object({
    arn = string
    id  = string
  })
}

variable "app_version" {
  type = string
}

variable "opg_metrics_endpoint" {
  type = string
}

locals {
  environment_name     = "${var.environment_name}-${data.aws_region.current.name}"
  policy_region_prefix = lower(replace(data.aws_region.current.name, "-", ""))
}
