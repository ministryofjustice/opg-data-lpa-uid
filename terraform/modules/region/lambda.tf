resource "aws_lambda_function" "create_case" {
  function_name = "lpa-uid-create-case-${local.environment_name}"
  image_uri     = "311462405659.dkr.ecr.eu-west-1.amazonaws.com/integrations/lpa-uid-create-case-lambda:${var.app_version}"
  package_type  = "Image"
  role          = var.lambda_iam_role.arn
  timeout       = 5
  memory_size   = 128

  environment {
    variables = {
      AWS_DYNAMODB_TABLE_NAME = var.is_primary ? aws_dynamodb_table.lpa_uid[0].name : var.dynamodb_primary_name
    }
  }

  vpc_config {
    subnet_ids         = data.aws_subnets.private.ids
    security_group_ids = [aws_security_group.lambda.id]
  }
}
