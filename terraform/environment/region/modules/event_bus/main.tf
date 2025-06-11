# Event bus for opg.poas events

resource "aws_cloudwatch_event_bus" "main" {
  name     = "${data.aws_default_tags.current.tags.application}-${data.aws_default_tags.current.tags.environment-name}"
  provider = aws.region
}

resource "aws_cloudwatch_event_archive" "main" {
  name             = "${data.aws_default_tags.current.tags.application}-${data.aws_default_tags.current.tags.environment-name}"
  event_source_arn = aws_cloudwatch_event_bus.main.arn
  provider         = aws.region
}
