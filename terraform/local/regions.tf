module "eu-west-1" {
  source               = "../modules/region"
  depends_on           = [
    module.local_setup,
    module.global
    ]
  app_version          = "latest"
  dynamodb_arn         = module.global.dynamodb_table.arn
  dynamodb_kms_key_arn = module.global.dynamodb_table.server_side_encryption[0].kms_key_arn
  dynamodb_name        = module.global.dynamodb_table.name
  environment_name     = local.environment_name
  environment          = local.environment
  is_local             = local.is_local
  is_primary           = true
  lambda_iam_role      = module.global.lambda_iam_role

  providers = {
    aws            = aws.eu-west-1
    aws.management = aws.management
  }
}

module "eu-west-2" {
  source               = "../modules/region"
  depends_on           = [
    module.local_setup,
    module.global
    ]
  app_version          = "latest"
  dynamodb_arn         = module.global.dynamodb_table_replica.arn
  dynamodb_kms_key_arn = "*"
  dynamodb_name        = module.global.dynamodb_table.name
  environment_name     = local.environment_name
  environment          = local.environment
  is_local             = local.is_local
  lambda_iam_role      = module.global.lambda_iam_role

  providers = {
    aws            = aws.eu-west-2
    aws.management = aws.management
  }
}

