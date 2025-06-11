data "aws_region" "current" {}

data "aws_default_tags" "current" {}

data "aws_secretsmanager_secret" "opg_metrics_api_key" {
  name     = "opg-metrics-api-key/lpa-uid-${data.aws_default_tags.current.tags.account}"
  provider = aws.shared
}

data "aws_secretsmanager_secret_version" "opg_metrics_api_key" {
  secret_id     = data.aws_secretsmanager_secret.opg_metrics_api_key.id
  version_stage = "AWSCURRENT"
  provider      = aws.shared
}
