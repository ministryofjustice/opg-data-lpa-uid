module "global" {
  source           = "../modules/global"
  environment_name = local.environment_name
  providers = {
    aws.global    = aws.global
  }
}
