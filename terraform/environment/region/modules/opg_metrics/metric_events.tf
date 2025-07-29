resource "aws_cloudwatch_event_rule" "metric_events" {
  name           = "${data.aws_default_tags.current.tags.environment-name}-metric-events"
  description    = "forward events to opg-metrics service"
  event_bus_name = var.aws_cloudwatch_event_bus.name

  event_pattern = jsonencode({
    source      = ["opg.poas.lpauid"]
    detail-type = ["metric"]
  })
  provider = aws.region
}

resource "aws_iam_role_policy" "opg_metrics" {
  name     = "opg-metrics-${data.aws_region.current.region}"
  role     = var.opg_metrics_api_destination_role.name
  policy   = data.aws_iam_policy_document.opg_metrics.json
  provider = aws.region
}


data "aws_iam_policy_document" "opg_metrics" {
  statement {
    effect  = "Allow"
    actions = ["events:InvokeApiDestination"]
    resources = [
      "${aws_cloudwatch_event_api_destination.opg_metrics_put.arn}*"
    ]
  }
  provider = aws.global
}

resource "aws_cloudwatch_event_target" "opg_metrics" {
  arn            = aws_cloudwatch_event_api_destination.opg_metrics_put.arn
  event_bus_name = var.aws_cloudwatch_event_bus.name
  rule           = aws_cloudwatch_event_rule.metric_events.name
  role_arn       = var.opg_metrics_api_destination_role.arn
  http_target {
    header_parameters = {
      Content-Type = "application/json"
    }
    path_parameter_values   = []
    query_string_parameters = {}
  }
  input_path = "$.detail"
  provider   = aws.region
}
