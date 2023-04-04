module "eu-west-1" {
  source = "./region"
  providers = {
    aws = aws.eu-west-1
  }
}

module "eu-west-2" {
  source = "./region"
  providers = {
    aws = aws.eu-west-2
  }
}
