data "template_file" "_" {
  template = file("../../docs/openapi/openapi.yaml")
  vars = {
    allowed_roles                 = "\"\""
    create_case_lambda_invoke_arn = aws_lambda_function.create_case.invoke_arn
  }
}

resource "aws_api_gateway_rest_api" "lpa_uid" {
  name        = "lpa-uid-${terraform.workspace}"
  description = "API Gateway for LPA UID - ${local.environment_name}"
  body        = data.template_file._.rendered

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  lifecycle {
    replace_triggered_by = [null_resource.open_api]
  }
}

resource "null_resource" "open_api" {
  triggers = {
    open_api_sha = local.open_api_sha
  }
}

locals {
  open_api_sha = substr(replace(base64sha256(data.template_file._.rendered), "/[^0-9A-Za-z_]/", ""), 0, 5)
}


resource "aws_api_gateway_deployment" "lpa_uid" {
  rest_api_id = aws_api_gateway_rest_api.lpa_uid.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.lpa_uid.body))
  }

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  stage_name = "current"
}

resource "aws_api_gateway_stage" "current" {
  depends_on           = [aws_cloudwatch_log_group.lpa_uid]
  deployment_id        = aws_api_gateway_deployment.lpa_uid.id
  rest_api_id          = aws_api_gateway_rest_api.lpa_uid.id
  stage_name           = local.stage_name
  xray_tracing_enabled = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.lpa_uid.arn
    format = join("", [
      "{\"requestId\":\"$context.requestId\",",
      "\"ip\":\"$context.identity.sourceIp\"",
      "\"caller\":\"$context.identity.caller\"",
      "\"user\":\"$context.identity.user\"",
      "\"requestTime\":\"$context.requestTime\"",
      "\"httpMethod\":\"$context.httpMethod\"",
      "\"resourcePath\":\"$context.resourcePath\"",
      "\"status\":\"$context.status\"",
      "\"protocol\":\"$context.protocol\"",
      "\"responseLength\":\"$context.responseLength\"}"
    ])
  }
}

resource "aws_cloudwatch_log_group" "lpa_uid" {
  name              = "API-Gateway-Execution-Logs-${aws_api_gateway_rest_api.lpa_uid.name}-${local.stage_name}"
  kms_key_id        = aws_kms_key.cloudwatch_standard.arn
  retention_in_days = 400
}

output "api_stage_uri" {
  value = var.is_local ? "http://${aws_api_gateway_rest_api.lpa_uid.id}.execute-api.localhost.localstack.cloud:4566/${aws_api_gateway_stage.current.stage_name}/" : aws_api_gateway_stage.current.invoke_url
}

resource "aws_api_gateway_domain_name" "lpa_uid" {
  domain_name              = trimsuffix(local.a_record, ".")
  regional_certificate_arn = aws_acm_certificate.environment.arn
  security_policy          = "TLS_1_2"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_base_path_mapping" "mapping" {
  api_id      = aws_api_gateway_rest_api.lpa_uid.id
  stage_name  = aws_api_gateway_deployment.lpa_uid.stage_name
  domain_name = aws_api_gateway_domain_name.lpa_uid.domain_name
  base_path   = aws_api_gateway_deployment.lpa_uid.stage_name
}