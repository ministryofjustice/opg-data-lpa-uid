variable "environment_name" {}

variable "environment" {}

variable "is_local" {
}

variable "lambda_iam_role" {}

locals {
    environment_name = "${var.environment_name}-${data.aws_region.current.name}"
}
