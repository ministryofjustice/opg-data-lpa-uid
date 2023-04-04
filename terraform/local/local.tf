module "local_setup" {
  source = "../modules/local"
  providers = {
    aws.eu-west-1  = aws.eu-west-1
    aws.eu-west-2  = aws.eu-west-2
    aws.management = aws.management
  }
}
