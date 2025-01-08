resource "aws_lambda_function" "create_case" {
  function_name = "lpa-uid-create-case-${local.environment_name}"
  package_type  = "Image"

  image_uri = "311462405659.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/integrations/lpa-uid-create-case-lambda:${var.app_version}"

  role        = var.lambda_iam_role.arn
  timeout     = 5
  memory_size = 128
  environment {
    variables = {
      AWS_DYNAMODB_TABLE_NAME = var.is_primary ? aws_dynamodb_table.lpa_uid[0].name : split(":", aws_dynamodb_table_replica.lpa_uid[0].id)[0]
    }
  }

  vpc_config {
    subnet_ids         = data.aws_subnets.private.ids
    security_group_ids = [aws_security_group.lambda.id]
  }
}

resource "aws_lambda_permission" "create_case" {
  statement_id  = "AllowLambdaAPIGatewayInvocation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_case.function_name
  principal     = "apigateway.amazonaws.com"
  # The /* part allows invocation from any stage, method and resource path
  # within API Gateway.
  source_arn = "${aws_api_gateway_rest_api.lpa_uid.execution_arn}/*"
}
