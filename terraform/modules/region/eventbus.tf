module "event_bus" {
  source = "../event_bus"
  providers = {
    aws.region = aws
    aws.global = aws.global
  }
}
