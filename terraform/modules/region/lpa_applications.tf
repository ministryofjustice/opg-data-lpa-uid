# Event pipe to send events from dynamodb stream to event bus
resource "aws_pipes_pipe" "lpa_applications" {
  count         = var.is_primary && !var.is_local ? 1 : 0
  name          = "${var.environment_name}-lpa-applications"
  description   = "capture events from dynamodb stream and pass to event bus"
  desired_state = "RUNNING"
  enrichment    = null
  name_prefix   = null
  role_arn      = aws_iam_role.lpa_applications_pipe[0].arn
  source        = aws_dynamodb_table.lpa_uid[0].stream_arn
  target        = var.target_event_bus_arn

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

    filter_criteria {
      filter {
        pattern = jsonencode({
          eventName = ["INSERT"],
        })
      }
    }
  }

  target_parameters {
    input_template = <<EOT
    {
      "createdAt": "<$.dynamodb.NewImage.created_at.S>",
      "donor": {
        "dob": "<$.dynamodb.NewImage.donor.M.dob.S>",
        "name": "<$.dynamodb.NewImage.donor.M.name.S>",
        "postcode": "<$.dynamodb.NewImage.donor.M.postcode.S>"
      },
      "source": "<$.dynamodb.NewImage.source.S>",
      "type": "<$.dynamodb.NewImage.type.S>",
      "uid": "<$.dynamodb.NewImage.uid.S>"
    }
    EOT

    eventbridge_event_bus_parameters {
      source      = "opg.poas.uid"
      detail_type = "created"
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

resource "aws_iam_role_policy" "lpa_applications_policy" {
  count  = var.is_primary && !var.is_local ? 1 : 0
  name   = "${var.environment_name}-policy-${data.aws_region.current.name}"
  policy = data.aws_iam_policy_document.lpa_applications_policy[0].json
  role   = aws_iam_role.lpa_applications_pipe[0].id
}

data "aws_iam_policy_document" "lpa_applications_policy" {
  count = var.is_local ? 0 : 1

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

  statement {
    actions = [
      "events:PutEvents"
    ]
    effect    = "Allow"
    resources = [var.target_event_bus_arn]
  }

  statement {
    actions = [
      "kms:Decrypt"
    ]
    effect    = "Allow"
    resources = [var.is_primary ? aws_kms_key.dynamodb[0].arn : aws_kms_replica_key.dynamodb[0].arn]
  }
}
