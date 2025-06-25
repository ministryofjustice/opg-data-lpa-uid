
resource "aws_iam_role_policy" "lambda" {
  name   = "lpa-uid-lambda-${local.environment_name}"
  role   = var.lambda_iam_role.id
  policy = data.aws_iam_policy_document.lambda.json
}

data "aws_iam_policy_document" "lambda" {
  statement {
    sid       = "${local.policy_region_prefix}allowLogging"
    effect    = "Allow"
    resources = [aws_cloudwatch_log_group.lambda.arn]
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
  }
  statement {
    sid    = "${local.policy_region_prefix}allowDynamoAccess"
    effect = "Allow"
    resources = [
      var.is_primary ? aws_dynamodb_table.lpa_uid[0].arn : aws_dynamodb_table_replica.lpa_uid[0].arn,
      var.is_primary ? "${aws_dynamodb_table.lpa_uid[0].arn}/*" : "${aws_dynamodb_table_replica.lpa_uid[0].arn}/*",
    ]
    actions = [
      "dynamodb:BatchGetItem",
      "dynamodb:DeleteItem",
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:UpdateItem",
      "dynamodb:UpdateTable",
    ]
  }
  statement {
    effect    = "Allow"
    sid       = "${local.policy_region_prefix}ListTables"
    resources = ["*"]
    actions   = ["dynamodb:ListTables"]
  }

  statement {
    sid    = "${local.policy_region_prefix}DynamoDBEncryptionAccess"
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey",
    ]

    resources = [
      var.is_primary ? aws_kms_key.dynamodb[0].arn : aws_kms_replica_key.dynamodb[0].arn,
    ]
  }

  statement {
    sid    = "${local.policy_region_prefix}AllowEventBusAccess"
    effect = "Allow"
    actions = [
      "events:PutEvents",
    ]
    resources = [
      module.event_bus.event_bus.arn
    ]
  }
}
