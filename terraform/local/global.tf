module "global" {
  source           = "../modules/global"
  environment_name = local.environment_name
  is_local         = true
  providers = {
    aws.global    = aws.global
    aws.eu-west-1 = aws.eu-west-1
    aws.eu-west-2 = aws.eu-west-2
  }
}
