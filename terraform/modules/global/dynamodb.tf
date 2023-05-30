resource "aws_dynamodb_table" "lpa_uid" {
  name                        = "lpa-uid-${var.environment_name}"
  billing_mode                = "PAY_PER_REQUEST"
  hash_key                    = "uid"
  stream_enabled              = true
  stream_view_type            = "NEW_AND_OLD_IMAGES"
  deletion_protection_enabled = true

  attribute {
    name = "uid"
    type = "S"
  }

  attribute {
    name = "source"
    type = "S"
  }

  point_in_time_recovery {
    enabled = var.is_local ? false : true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb.arn
  }

  global_secondary_index {
    name            = "source_index"
    hash_key        = "source"
    projection_type = "ALL"
  }

  lifecycle {
    ignore_changes = [
      replica
    ]
  }

  provider = aws.eu-west-1
}

resource "aws_dynamodb_table_replica" "lpa_uid_eu_west_2" {
  global_table_arn = aws_dynamodb_table.lpa_uid.arn
  kms_key_arn = var.is_local ? null : aws_kms_replica_key.dynamodb_eu_west_2[0].arn
  point_in_time_recovery = var.is_local ? false : true
  provider = aws.eu-west-2
}

resource "aws_kms_key" "dynamodb" {
  description             = "LPA UID Generation Service ${var.environment_name} DynamoDB"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  multi_region            = var.is_local ? false : true
  policy                  = data.aws_iam_policy_document.dynamodb.json
  provider                = aws.eu-west-1
}

resource "aws_kms_replica_key" "dynamodb_eu_west_2" {
  count = var.is_local ? 0 : 1
  description             = "LPA UID Generation Service ${var.environment_name} DynamoDB eu-west-2 replica key"
  deletion_window_in_days = 10
  primary_key_arn         = aws_kms_key.dynamodb.arn
  provider                = aws.eu-west-2
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_kms_alias" "dynamodb_alias_eu_west_1" {
  name          = "alias/lpa-uid-dynamodb-${var.environment_name}"
  target_key_id = aws_kms_key.dynamodb.key_id
  provider      = aws.eu-west-1
}

resource "aws_kms_alias" "dynamodb_alias_eu_west_2" {
  count         = var.is_local ? 0 : 1
  name          = "alias/lpa-uid-dynamodb-${var.environment_name}"
  target_key_id = aws_kms_replica_key.dynamodb_eu_west_2[0].key_id
  provider      = aws.eu-west-2
}

# See the following link for further information
# https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html
data "aws_iam_policy_document" "dynamodb" {
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
  provider = aws.eu-west-1
}
