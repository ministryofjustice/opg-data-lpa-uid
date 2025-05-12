locals {
  default_tags     = merge(local.mandatory_moj_tags, local.optional_tags)
  environment      = contains(keys(var.environments), terraform.workspace) ? var.environments[terraform.workspace] : var.environments["default"]
  environment_name = element(split("_", terraform.workspace), 0)
  mandatory_moj_tags = {
    business-unit    = "OPG"
    application      = "opg-data-lpa-uid"
    account          = local.environment.account_name
    environment-name = local.environment_name
    is-production    = terraform.workspace == "production" ? true : false
    owner            = "opgteam@digital.justice.gov.uk"
  }

  optional_tags = {
    source-code            = "https://github.com/ministryofjustice/opg-data-lpa-uid"
    infrastructure-support = "opgteam@digital.justice.gov.uk"
  }
}

variable "environments" {
  type = map(
    object({
      account_id   = string
      account_name = string
      allowed_arns = list(string)
    })
  )
}

variable "app_version" {
  default = "latest"
  type    = string
}

variable "default_role" {
  default = "integrations-ci"
  type    = string
}

variable "management_role" {
  default = "integrations-ci"
  type    = string
}
