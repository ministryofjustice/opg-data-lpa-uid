module "eu-west-1" {
  source     = "../modules/region"
  depends_on = [module.local_setup]

  environment_name = local.environment_name
  environment      = local.environment
  is_local         = local.is_local
  lambda_iam_role  = module.global.lambda_iam_role

  providers = {
    aws            = aws.eu-west-1
    aws.management = aws.management
  }
}
