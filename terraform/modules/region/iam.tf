
resource "aws_iam_role_policy" "lambda" {
  name   = "lpa-uid-lambda-${local.environment_name}"
  role   = var.lambda_iam_role.id
  policy = data.aws_iam_policy_document.lambda.json
}

data "aws_iam_policy_document" "lambda" {
  statement {
    sid       = "allowLogging"
    effect    = "Allow"
    resources = [aws_cloudwatch_log_group.lambda.arn]
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
  }
}
