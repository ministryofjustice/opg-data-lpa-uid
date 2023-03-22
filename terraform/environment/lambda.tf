resource "aws_lambda_function" "lambda_function" {
  function_name = "lpa-uid-${local.environment_name}"
  image_uri     = "311462405659.dkr.ecr.eu-west-1.amazonaws.com/lpa-id:latest"
  package_type  = "Image"
  role          = aws_iam_role.lambda.arn
  timeout       = 300
  memory_size   = 2048

  vpc_config {
    subnet_ids         = data.aws_subnets.private.ids
    security_group_ids = []
  }
}
