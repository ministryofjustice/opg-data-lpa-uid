module "eu-west-1" {
  source = "../modules/region"

  app_version          = var.app_version
  dynamodb_global_table_arn = null
  environment_name     = local.environment_name
  environment          = local.environment
  is_local             = false
  is_primary           = true
  lambda_iam_role      = module.global.lambda_iam_role

  providers = {
    aws            = aws.eu-west-1
    aws.management = aws.management
  }
}

module "eu-west-2" {
  source = "../modules/region"

  app_version          = var.app_version
  dynamodb_global_table_arn = module.eu-west-1.dynamodb_table.arn
  dynamodb_kms_key_arn = module.eu-west-1.dynamodb_table.server_side_encryption[0].kms_key_arn
  environment_name     = local.environment_name
  environment          = local.environment
  is_local             = false
  is_primary           = false
  lambda_iam_role      = module.global.lambda_iam_role

  providers = {
    aws            = aws.eu-west-2
    aws.management = aws.management
  }
}
