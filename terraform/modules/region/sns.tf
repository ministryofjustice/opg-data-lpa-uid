data "aws_sns_topic" "cloudwatch_api" {
  name = "CloudWatch-API-to-PagerDuty-${local.environment_name}-${data.aws_region.current.name}"
}