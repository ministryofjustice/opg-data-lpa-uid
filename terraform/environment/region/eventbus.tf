module "event_bus" {
  source = "./modules/event_bus"
  providers = {
    aws.region = aws
  }
}
