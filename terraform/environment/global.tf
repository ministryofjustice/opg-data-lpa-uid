module "global" {
  source = "./global"
  providers = {
    aws = aws.global
  }
}
