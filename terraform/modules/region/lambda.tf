data "archive_file" "forwarder" {
  count       = var.is_local ? 1 : 0
  type        = "zip"
  source_file = "${path.module}/../../../scripts/lambda/forwarder.py"
  output_path = "${path.module}/../../../scripts/lambda/lambda.zip"
}

resource "aws_lambda_function" "create_case" {
  function_name = var.is_local ? "lambda-create-case" : "lpa-uid-create-case-${local.environment_name}"
  package_type  = var.is_local ? "Zip" : "Image"

  image_uri = var.is_local ? null : "311462405659.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/integrations/lpa-uid-create-case-lambda:${var.app_version}"

  filename = var.is_local ? data.archive_file.forwarder[0].output_path : null
  handler  = var.is_local ? "forwarder.handler" : null
  runtime  = var.is_local ? "python3.11" : null

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
