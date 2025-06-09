module "opg_metrics" {
  count                = var.opg_metrics.enabled ? 1 : 0
  source               = "../opg_metrics"
  opg_metrics_endpoint = var.opg_metrics.endpoint
  providers = {
    aws.shared = aws.shared
    aws.region = aws
  }
}
