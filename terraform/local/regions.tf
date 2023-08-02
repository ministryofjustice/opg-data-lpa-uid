module "eu-west-1" {
  source     = "../modules/region"
  depends_on = [module.local_setup]

  app_version               = "latest"
  dynamodb_global_table_arn = null
  environment_name          = local.environment_name
  environment               = local.environment
  is_local                  = true
  is_primary                = true
  lambda_iam_role           = module.global.lambda_iam_role
  target_event_bus_arn      = ""

  providers = {
    aws            = aws.eu-west-1
    aws.management = aws.management
  }
}

module "eu-west-2" {
  source     = "../modules/region"
  depends_on = [module.local_setup]

  app_version               = "latest"
  dynamodb_global_table_arn = module.eu-west-1.dynamodb_table.arn
  environment_name          = local.environment_name
  environment               = local.environment
  is_local                  = local.is_local
  is_primary                = false
  lambda_iam_role           = module.global.lambda_iam_role
  target_event_bus_arn      = ""

  providers = {
    aws            = aws.eu-west-2
    aws.management = aws.management
  }
}
