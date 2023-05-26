
resource "aws_iam_role_policy" "lambda" {
  name   = "lpa-uid-lambda-${local.environment_name}"
  role   = var.lambda_iam_role.name
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
    sid       = "${local.policy_region_prefix}allowDynamoAccess"
    effect    = "Allow"
    resources = [var.dynamodb_arn]
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
    sid       = "${local.policy_region_prefix}DynamoDBEncryptionAccess"
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey",
    ]

    resources = [
      var.dynamodb_kms_key_arn,
    ]
  }
}
