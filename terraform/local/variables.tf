locals {
  default_tags     = merge(local.mandatory_moj_tags, local.optional_tags)
  environment      = var.environments["local"]
  environment_name = "local"
  is_local         = true
  mandatory_moj_tags = {
    business-unit    = "OPG"
    application      = "LPA UID Service"
    account          = local.environment.account_name
    environment-name = local.environment_name
    is-production    = false
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

variable "default_role" {
  default = "operator"
}

variable "management_role" {
  default = "lpa-uid-ci"
}
