locals {
  default_tags     = merge(local.mandatory_moj_tags, local.optional_tags)
  environment      = contains(keys(var.environments), terraform.workspace) ? var.environments[terraform.workspace] : var.environments["default"]
  environment_name = element(split("_", terraform.workspace), 0)
  is_local         = false
  mandatory_moj_tags = {
    business-unit    = "OPG"
    application      = "LPA UID Service"
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
    })
  )
}

variable "app_version" {
  default = "latest"
}

variable "default_role" {
  default = "operator"
}

variable "management_role" {
  default = "lpa-uid-ci"
}
