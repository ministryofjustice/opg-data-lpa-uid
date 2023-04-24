resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/lpa-uid-${local.environment_name}"
  kms_key_id        = aws_kms_key.cloudwatch_standard.arn
  retention_in_days = 400
}

resource "aws_kms_key" "cloudwatch_standard" {
  description             = "LPA UID Generation Service ${local.environment_name} Cloudwatch"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.cloudwatch_kms.json
}

resource "aws_kms_alias" "cloudwatch_standard_alias" {
  name          = "alias/lpa-uid-cloudwatch-${local.environment_name}"
  target_key_id = aws_kms_key.cloudwatch_standard.key_id
}

resource "aws_cloudwatch_log_metric_filter" "uid_service_400_errors" {
  name           = "${local.environment_name}-uid-service-400-errors"
  pattern        = "{ $.status = 400 }"
  log_group_name = aws_cloudwatch_log_group.lpa_uid.name

  metric_transformation {
    name      = "${local.environment_name}-uid-service-400-errors"
    namespace = "UID-Service/Monitoring"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "uid_service_401_errors" {
  name           = "${local.environment_name}-uid-service-401-errors"
  pattern        = "{ $.status = 401 }"
  log_group_name = aws_cloudwatch_log_group.lpa_uid.name

  metric_transformation {
    name      = "${local.environment_name}-uid-service-401-errors"
    namespace = "UID-Service/Monitoring"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "invalid_dob_errors" {
  name           = "${local.environment_name}-invalid-dob-errors"
  pattern        = "{$.problem.error_string = \"*/donor/dob must match format YYYY-MM-DD*\"}"
  log_group_name = aws_cloudwatch_log_group.lpa_uid.name

  metric_transformation {
    name      = "${local.environment_name}-invalid-dob-errors"
    namespace = "UID-Service/Monitoring"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "missing_dob_errors" {
  name           = "${local.environment_name}-missing-dob-errors"
  pattern        = "{$.problem.error_string = \"*/donor/dob required*\"}"
  log_group_name = aws_cloudwatch_log_group.lpa_uid.name

  metric_transformation {
    name      = "${local.environment_name}-missing-dob-errors"
    namespace = "UID-Service/Monitoring"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "missing_source_errors" {
  name           = "${local.environment_name}-missing-source-errors"
  pattern        = "{$.problem.error_string = \"*/source required*\"}"
  log_group_name = aws_cloudwatch_log_group.lpa_uid.name

  metric_transformation {
    name      = "${local.environment_name}-missing-source-errors"
    namespace = "UID-Service/Monitoring"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "invalid_source_errors" {
  name           = "${local.environment_name}-invalid-source-errors"
  pattern        = "{$.problem.error_string = \"*/source must be APPLICANT or PHONE*\"}"
  log_group_name = aws_cloudwatch_log_group.lpa_uid.name

  metric_transformation {
    name      = "${local.environment_name}-invalid-source-errors"
    namespace = "UID-Service/Monitoring"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "missing_type_errors" {
  name           = "${local.environment_name}-missing-type-errors"
  pattern        = "{$.problem.error_string = \"*/type required*\"}"
  log_group_name = aws_cloudwatch_log_group.lpa_uid.name

  metric_transformation {
    name      = "${local.environment_name}-missing-type-errors"
    namespace = "UID-Service/Monitoring"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "invalid_type_errors" {
  name           = "${local.environment_name}-invalid-type-errors"
  pattern        = "{$.problem.error_string = \"*/type must be hw or pfa*\"}"
  log_group_name = aws_cloudwatch_log_group.lpa_uid.name

  metric_transformation {
    name      = "${local.environment_name}-invalid-type-errors"
    namespace = "UID-Service/Monitoring"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "missing_postcode_errors" {
  name           = "${local.environment_name}-missing-postcode-errors"
  pattern        = "{$.problem.error_string = \"*/donor/postcode required*\"}"
  log_group_name = aws_cloudwatch_log_group.lpa_uid.name

  metric_transformation {
    name      = "${local.environment_name}-missing-postcode-errors"
    namespace = "UID-Service/Monitoring"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "invalid_postcode_errors" {
  name           = "${local.environment_name}-invalid-postcode-errors"
  pattern        = "{$.problem.error_string = \"*/donor/postcode must be a valid postcode*\"}"
  log_group_name = aws_cloudwatch_log_group.lpa_uid.name

  metric_transformation {
    name      = "${local.environment_name}-invalid-postcode-errors"
    namespace = "UID-Service/Monitoring"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "uid_service_5xx_errors" {
  actions_enabled           = true
  alarm_actions             = [data.aws_sns_topic.cloudwatch_api.arn]
  alarm_description         = "5xx errors occur in the ${local.environment_name} UID service."
  alarm_name                = "${local.environment_name}-uid-service-5xx-errors"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  datapoints_to_alarm       = 3
  evaluation_periods        = 3
  insufficient_data_actions = []
  metric_name               = "5XXError"
  namespace                 = "AWS/ApiGateway"
  ok_actions                = [data.aws_sns_topic.cloudwatch_api.arn]
  period                    = 60
  statistic                 = "Sum"
  threshold                 = 1
  treat_missing_data        = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "uid_service_4xx_error_anomaly" {
  actions_enabled           = true
  alarm_actions             = [data.aws_sns_topic.cloudwatch_api.arn]
  alarm_description         = "4xx errors anomaly occured in the ${local.environment_name} UID service."
  alarm_name                = "${local.environment_name}-uid-service-4xx-errors"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  datapoints_to_alarm       = 5
  evaluation_periods        = 5
  insufficient_data_actions = []
  ok_actions                = [data.aws_sns_topic.cloudwatch_api.arn]
  treat_missing_data        = "notBreaching"
  threshold_metric_id       = "e1"

  metric_query {
    id          = "e1"
    expression  = "ANOMALY_DETECTION_BAND(m1)"
    label       = "4xx error rate"
    return_data = true
  }

  metric_query {
    id          = "m1"
    return_data = true
    metric {
      dimensions  = {}
      metric_name = "4XXError"
      namespace   = "AWS/ApiGateway"
      period      = 60
      stat        = "Sum"
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "uid_service_high_request_rate" {
  actions_enabled           = true
  alarm_actions             = [data.aws_sns_topic.cloudwatch_api.arn]
  alarm_description         = "An abnormally high rate of requests detected in the ${local.environment_name} UID service."
  alarm_name                = "${local.environment_name}-uid-service-high-request-rate"
  comparison_operator       = "GreaterThanThreshold"
  datapoints_to_alarm       = 1
  evaluation_periods        = 1
  insufficient_data_actions = []
  metric_name               = "Count"
  namespace                 = "AWS/ApiGateway"
  ok_actions                = [data.aws_sns_topic.cloudwatch_api.arn]
  period                    = 60
  statistic                 = "Sum"
  threshold                 = 500
  treat_missing_data        = "notBreaching"
}

# See the following link for further information
# https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html
data "aws_iam_policy_document" "cloudwatch_kms" {
  statement {
    sid       = "Enable Root account permissions on Key"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
      ]
    }
  }

  statement {
    sid       = "Allow Key to be used for Encryption"
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]

    principals {
      type = "Service"
      identifiers = [
        "logs.${data.aws_region.current.name}.amazonaws.com",
        "events.amazonaws.com"
      ]
    }
  }

  statement {
    sid       = "Key Administrator"
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion"
    ]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/breakglass"]
    }
  }
}
