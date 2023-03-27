resource "aws_lambda_function" "create_case" {
  function_name = "lpa-uid-create-case-${local.environment_name}"
  image_uri     = "311462405659.dkr.ecr.eu-west-1.amazonaws.com/lpa-uid/lambda/create-case:latest"
  package_type  = "Image"
  role          = var.lambda_iam_role.arn
  timeout       = 5
  memory_size   = 128

  vpc_config {
    subnet_ids         = data.aws_subnets.private.ids
    security_group_ids = []
  }
}
