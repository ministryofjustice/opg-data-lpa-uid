resource "aws_cloudwatch_event_connection" "opg_metrics" {
  name               = "lpa-uid-to-opg-metrics"
  description        = "A connection and auth for opg-metrics"
  authorization_type = "API_KEY"

  auth_parameters {
    api_key {
      key   = "x-api-key"
      value = data.aws_secretsmanager_secret_version.opg_metrics_api_key.secret_string
    }
  }
  lifecycle {
    ignore_changes = [auth_parameters[0].invocation_http_parameters]
  }
}

resource "aws_cloudwatch_event_api_destination" "opg_metrics_put" {
  name                             = "lpa-uid-to-opg-metrics-put"
  description                      = "an endpoint to push metrics to"
  invocation_endpoint              = "${var.opg_metrics_endpoint}/metrics"
  http_method                      = "PUT"
  invocation_rate_limit_per_second = 300
  connection_arn                   = aws_cloudwatch_event_connection.opg_metrics.arn
}

# resource "aws_ssm_parameter" "opg_metrics_arn" {
#   name     = "opg-metrics-api-destination-arn"
#   type     = "String"
#   value    = aws_cloudwatch_event_api_destination.opg_metrics_put.arn
#   provider = aws.region
# }

output "opg_metrics_api_destination_arn" {
  value = aws_cloudwatch_event_api_destination.opg_metrics_put.arn
}
