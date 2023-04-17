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
  pattern        = "$.status = 400"
  log_group_name = aws_cloudwatch_log_group.lpa_uid.name

  metric_transformation {
    name      = "${local.environment_name}-uid-service-400-errors"
    namespace = "UID-Service/Monitoring"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "uid_service_401_errors" {
  name           = "${local.environment_name}-uid-service-401-errors"
  pattern        = "$.status = 401"
  log_group_name = aws_cloudwatch_log_group.lpa_uid.name

  metric_transformation {
    name      = "${local.environment_name}-uid-service-401-errors"
    namespace = "UID-Service/Monitoring"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "invalid_dob_errors" {
  name           = "${local.environment_name}-invalid-dob-errors"
  pattern        = "/donor/dob.*must match format YYYY-MM-DD"
  log_group_name = aws_cloudwatch_log_group.lpa_uid.name

  metric_transformation {
    name      = "${local.environment_name}-invalid-dob-errors"
    namespace = "UID-Service/Monitoring"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "missing_dob_errors" {
  name           = "${local.environment_name}-missing-dob-errors"
  pattern        = "/donor/dob.*required"
  log_group_name = aws_cloudwatch_log_group.lpa_uid.name

  metric_transformation {
    name      = "${local.environment_name}-missing-dob-errors"
    namespace = "UID-Service/Monitoring"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "missing_source_errors" {
  name           = "${local.environment_name}-missing-source-errors"
  pattern        = "/source.*required"
  log_group_name = aws_cloudwatch_log_group.lpa_uid.name

  metric_transformation {
    name      = "${local.environment_name}-missing-source-errors"
    namespace = "UID-Service/Monitoring"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "invalid_source_errors" {
  name           = "${local.environment_name}-invalid-source-errors"
  pattern        = "/source.*must be APPLICANT or PHONE"
  log_group_name = aws_cloudwatch_log_group.lpa_uid.name

  metric_transformation {
    name      = "${local.environment_name}-invalid-source-errors"
    namespace = "UID-Service/Monitoring"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "missing_type_errors" {
  name           = "${local.environment_name}-missing-type-errors"
  pattern        = "/type.*required"
  log_group_name = aws_cloudwatch_log_group.lpa_uid.name

  metric_transformation {
    name      = "${local.environment_name}-missing-type-errors"
    namespace = "UID-Service/Monitoring"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "invalid_type_errors" {
  name           = "${local.environment_name}-invalid-type-errors"
  pattern        = "/type.*must be hw or pfa"
  log_group_name = aws_cloudwatch_log_group.lpa_uid.name

  metric_transformation {
    name      = "${local.environment_name}-invalid-type-errors"
    namespace = "UID-Service/Monitoring"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "missing_postcode_errors" {
  name           = "${local.environment_name}-missing-postcode-errors"
  pattern        = "/donor/postcode.*required"
  log_group_name = aws_cloudwatch_log_group.lpa_uid.name

  metric_transformation {
    name      = "${local.environment_name}-missing-postcode-errors"
    namespace = "UID-Service/Monitoring"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "invalid_postcode_errors" {
  name           = "${local.environment_name}-invalid-postcode-errors"
  pattern        = "/donor/postcode.*must be a valid postcode"
  log_group_name = aws_cloudwatch_log_group.lpa_uid.name

  metric_transformation {
    name      = "${local.environment_name}-invalid-postcode-errors"
    namespace = "UID-Service/Monitoring"
    value     = "1"
  }
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
