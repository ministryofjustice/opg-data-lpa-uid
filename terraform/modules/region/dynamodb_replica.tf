resource "aws_dynamodb_table_replica" "lpa_uid" {
  count                  = var.is_primary ? 0 : 1
  global_table_arn       = var.dynamodb_global_table_arn
  kms_key_arn            = var.is_local ? null : aws_kms_replica_key.dynamodb[0].arn
  point_in_time_recovery = var.is_local ? false : true
}

resource "aws_kms_replica_key" "dynamodb" {
  count                   = var.is_local || var.is_primary ? 0 : 1
  description             = "LPA UID Generation Service ${var.environment_name} DynamoDB eu-west-2 replica key"
  deletion_window_in_days = 10
  policy                  = data.aws_iam_policy_document.dynamodb_kms_replica.json
  primary_key_arn         = var.dynamodb_kms_key_arn
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_kms_alias" "dynamodb_alias" {
  count         = var.is_local || var.is_primary ? 0 : 1
  name          = "alias/lpa-uid-dynamodb-${var.environment_name}"
  target_key_id = aws_kms_replica_key.dynamodb[0].key_id
}

data "aws_iam_policy_document" "dynamodb_kms_replica" {
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
        "dynamodb.amazonaws.com"
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
