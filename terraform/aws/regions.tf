module "eu-west-1" {
  source = "../modules/region"

  app_version               = var.app_version
  dns_weighting             = 100
  dynamodb_global_table_arn = null
  environment_name          = local.environment_name
  environment               = local.environment
  is_primary                = true
  lambda_iam_role           = module.global.lambda_iam_role
  opg_metrics = {
    enabled  = local.environment.opg_metrics.enabled
    endpoint = local.environment.opg_metrics.endpoint
    iam_role = module.global.opg_metrics_iam_role
  }

  providers = {
    aws            = aws.eu-west-1
    aws.management = aws.management
    aws.shared     = aws.shared-eu-west-1
    aws.global     = aws.global
  }
}

module "eu-west-2" {
  source = "../modules/region"

  app_version               = var.app_version
  dns_weighting             = 0
  dynamodb_global_table_arn = module.eu-west-1.dynamodb_table.arn
  dynamodb_kms_key_arn      = module.eu-west-1.dynamodb_table.server_side_encryption[0].kms_key_arn
  environment_name          = local.environment_name
  environment               = local.environment
  is_primary                = false
  lambda_iam_role           = module.global.lambda_iam_role
  opg_metrics = {
    enabled  = false
    endpoint = local.environment.opg_metrics.endpoint
    iam_role = module.global.opg_metrics_iam_role
  }


  providers = {
    aws            = aws.eu-west-2
    aws.management = aws.management
    aws.shared     = aws.shared-eu-west-2
    aws.global     = aws.global
  }
}
