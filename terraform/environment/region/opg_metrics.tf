module "opg_metrics" {
  count                            = var.opg_metrics.enabled ? 1 : 0
  source                           = "./modules/opg_metrics"
  opg_metrics_endpoint             = var.opg_metrics.endpoint
  opg_metrics_api_destination_role = var.opg_metrics.iam_role
  aws_cloudwatch_event_bus         = module.event_bus.event_bus
  providers = {
    aws.shared = aws.shared
    aws.region = aws
    aws.global = aws.global
  }
}
