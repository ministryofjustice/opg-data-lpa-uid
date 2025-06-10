module "event_bus" {
  source                           = "../event_bus"
  opg_metrics_api_destination_role = var.opg_metrics.iam_role
  opg_metrics_api_destination_arn  = module.opg_metrics[0].opg_metrics_api_destination_arn
  providers = {
    aws.region = aws
    aws.global = aws.global
  }
}
