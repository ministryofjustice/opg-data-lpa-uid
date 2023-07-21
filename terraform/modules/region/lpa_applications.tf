# Send notification to event bridge when LPA application is made
resource "aws_cloudwatch_event_bus" "lpa_applications" {
  count = var.is_primary ? 1 : 0
  name  = "${var.environment_name}-lpa-applications"
}

resource "aws_cloudwatch_event_archive" "lpa_applications" {
  count            = var.is_primary ? 1 : 0
  name             = "${var.environment_name}-lpa-applications"
  event_source_arn = aws_cloudwatch_event_bus.lpa_applications[0].arn
}

# Event pipe to send events from dynamodb stream to event bus
resource "aws_pipes_pipe" "lpa_applications" {
  count         = var.is_primary ? 1 : 0
  name          = "${var.environment_name}-lpa-applications"
  description   = "capture events from dynamodb stream and pass to event bus"
  desired_state = "RUNNING"
  enrichment    = null
  name_prefix   = null
  role_arn      = aws_iam_role.lpa_applications_pipe[0].arn
  source        = aws_dynamodb_table.lpa_uid[0].stream_arn
  target        = aws_cloudwatch_event_bus.lpa_applications[0].arn
  source_parameters {
    dynamodb_stream_parameters {
      batch_size                         = 1
      maximum_batching_window_in_seconds = 0
      maximum_record_age_in_seconds      = -1
      maximum_retry_attempts             = 0
      on_partial_batch_item_failure      = null
      parallelization_factor             = 1
      starting_position                  = "LATEST"
    }
  }
}

resource "aws_iam_role" "lpa_applications_pipe" {
  count              = var.is_primary ? 1 : 0
  name               = "${var.environment_name}-lpa-applications-pipe"
  assume_role_policy = data.aws_iam_policy_document.lpa_applications_assume_role.json
  path               = "/service-role/"
}

data "aws_iam_policy_document" "lpa_applications_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["pipes.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:pipes:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:pipe/${var.environment_name}-lpa-applications"]
    }
  }
}

resource "aws_iam_role_policy" "lpa_applications_pipe_source" {
  count  = var.is_primary ? 1 : 0
  name   = "${var.environment_name}-DynamoDbPipeSource"
  policy = data.aws_iam_policy_document.lpa_applications_dynamodb_source.json
  role   = aws_iam_role.lpa_applications_pipe[0].id
}

data "aws_iam_policy_document" "lpa_applications_dynamodb_source" {
  statement {
    actions = [
      "dynamodb:DescribeStream",
      "dynamodb:GetRecords",
      "dynamodb:GetShardIterator",
      "dynamodb:ListStreams",
    ]
    effect    = "Allow"
    resources = aws_dynamodb_table.lpa_uid[*].stream_arn
  }
}

resource "aws_iam_role_policy" "lpa_applications_pipe_target" {
  count  = var.is_primary ? 1 : 0
  name   = "${var.environment_name}-EventBusPipeTarget"
  policy = data.aws_iam_policy_document.lpa_applications_eventbus_target.json
  role   = aws_iam_role.lpa_applications_pipe[0].id
}

data "aws_iam_policy_document" "lpa_applications_eventbus_target" {
  statement {
    actions = [
      "events:PutEvents"
    ]
    effect    = "Allow"
    resources = aws_cloudwatch_event_bus.lpa_applications[*].arn
  }
}

# Temporary SQS queue to enable debugging of events
resource "aws_cloudwatch_event_rule" "receive_insert" {
  count          = var.is_primary ? 1 : 0
  name           = "${var.environment_name}-receive-insert-lpa-applications"
  description    = "put insert events from event bus onto queue"
  event_bus_name = aws_cloudwatch_event_bus.lpa_applications[0].name

  event_pattern  = jsonencode({
    source      = ["lpa-applications"],
    detail-type = ["insert"]
  })
}

resource "aws_sqs_queue" "receive_insert" {
  count                       = var.is_primary ? 1 : 0
  name                        = "${var.environment_name}-receive-insert-lpa-applications"
  fifo_queue                  = false
  content_based_deduplication = false
}

resource "aws_cloudwatch_event_target" "receive_insert" {
  count          = var.is_primary ? 1 : 0
  target_id      = "${var.environment_name}-receive-insert-lpa-applications"
  arn            = aws_sqs_queue.receive_insert[0].arn
  event_bus_name = aws_cloudwatch_event_bus.lpa_applications[0].name
  rule           = aws_cloudwatch_event_rule.receive_insert[0].name
}
