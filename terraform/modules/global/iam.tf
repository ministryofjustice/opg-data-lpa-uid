resource "aws_iam_role" "lambda" {
  name               = "lpa-uid-${local.environment_name}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  provider           = aws.global
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
  provider = aws.global
}

resource "aws_iam_role_policy_attachment" "vpc_execution_role" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  provider   = aws.global
}
