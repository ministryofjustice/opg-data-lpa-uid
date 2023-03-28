module "local_setup" {
  source = "../modules/local"
  providers = {
    aws            = aws.eu-west-1
    aws.management = aws.management
  }
}
