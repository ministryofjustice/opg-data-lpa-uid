module "global" {
  source = "../modules/global"
  providers = {
    aws = aws.global
  }
}
