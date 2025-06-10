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

# data "aws_kms_alias" "sqs" {
#   name     = "alias/${data.aws_default_tags.current.tags.application}_sqs_secret_encryption_key"
#   provider = aws.region
# }

# resource "aws_sqs_queue" "event_bus_dead_letter_queue" {
#   name                              = "${data.aws_default_tags.current.tags.environment-name}-event-bus-dead-letter-queue"
#   kms_master_key_id                 = data.aws_kms_alias.sqs.target_key_id
#   kms_data_key_reuse_period_seconds = 300
#   provider                          = aws.region
# }

# resource "aws_sqs_queue_policy" "event_bus_dead_letter_queue_policy" {
#   queue_url = aws_sqs_queue.event_bus_dead_letter_queue.id
#   policy    = data.aws_iam_policy_document.event_bus_dead_letter_queue.json
#   provider  = aws.region
# }

# data "aws_iam_policy_document" "event_bus_dead_letter_queue" {
#   statement {
#     sid    = "DeadLetterQueueAccess"
#     effect = "Allow"
#     principals {
#       type        = "Service"
#       identifiers = ["events.amazonaws.com"]
#     }
#     resources = [aws_sqs_queue.event_bus_dead_letter_queue.arn]
#     actions   = ["sqs:SendMessage"]

#     condition {
#       test     = "ArnEquals"
#       variable = "aws:SourceArn"
#       values = [
#         aws_cloudwatch_event_rule.cross_account_put.arn, # metric forwarding rule
#       ]
#     }
#   }
#   provider = aws.region
# }

# resource "aws_sns_topic" "event_bus_dead_letter_queue" {
#   name                                     = "${data.aws_default_tags.current.tags.environment-name}-event-bus-dead-letter-queue-alarms"
#   kms_master_key_id                        = data.aws_kms_alias.sns_kms_key_alias.target_key_id
#   application_failure_feedback_role_arn    = data.aws_iam_role.sns_failure_feedback.arn
#   application_success_feedback_role_arn    = data.aws_iam_role.sns_success_feedback.arn
#   application_success_feedback_sample_rate = 100
#   firehose_failure_feedback_role_arn       = data.aws_iam_role.sns_failure_feedback.arn
#   firehose_success_feedback_role_arn       = data.aws_iam_role.sns_success_feedback.arn
#   firehose_success_feedback_sample_rate    = 100
#   http_failure_feedback_role_arn           = data.aws_iam_role.sns_failure_feedback.arn
#   http_success_feedback_role_arn           = data.aws_iam_role.sns_success_feedback.arn
#   http_success_feedback_sample_rate        = 100
#   lambda_failure_feedback_role_arn         = data.aws_iam_role.sns_failure_feedback.arn
#   lambda_success_feedback_role_arn         = data.aws_iam_role.sns_success_feedback.arn
#   lambda_success_feedback_sample_rate      = 100
#   sqs_failure_feedback_role_arn            = data.aws_iam_role.sns_failure_feedback.arn
#   sqs_success_feedback_role_arn            = data.aws_iam_role.sns_success_feedback.arn
#   sqs_success_feedback_sample_rate         = 100
#   provider                                 = aws.region
# }

# resource "aws_cloudwatch_metric_alarm" "event_bus_dead_letter_queue" {
#   alarm_name          = "${data.aws_default_tags.current.tags.environment-name}-event-bus-dead-letter-queue"
#   comparison_operator = "GreaterThanOrEqualToThreshold"
#   evaluation_periods  = 1
#   metric_name         = "ApproximateNumberOfMessagesVisible"
#   namespace           = "AWS/SQS"
#   period              = 60
#   statistic           = "Sum"
#   threshold           = 1
#   alarm_description   = "${data.aws_default_tags.current.tags.environment-name} event bus dead letter queue has messages"
#   alarm_actions       = [aws_sns_topic.event_bus_dead_letter_queue.arn]
#   dimensions = {
#     QueueName = aws_sqs_queue.event_bus_dead_letter_queue.name
#   }
#   provider = aws.region
# }
