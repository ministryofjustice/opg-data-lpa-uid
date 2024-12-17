locals {
  template_file = templatefile("../../docs/openapi/openapi.yaml", {
    create_case_lambda_invoke_arn = aws_lambda_function.create_case.invoke_arn
  })
}

resource "aws_api_gateway_rest_api" "lpa_uid" {
  name        = "lpa-uid-${terraform.workspace}"
  description = "API Gateway for LPA UID - ${local.environment_name}"
  body        = local.template_file

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

locals {
  open_api_sha = substr(replace(base64sha256(local.template_file), "/[^0-9A-Za-z_]/", ""), 0, 5)
}

resource "aws_api_gateway_deployment" "lpa_uid" {
  rest_api_id = aws_api_gateway_rest_api.lpa_uid.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_rest_api.lpa_uid.body,
      var.environment.allowed_arns
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_rest_api.lpa_uid,
    aws_api_gateway_rest_api_policy.lpa_uid
  ]
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
      "\"ip\":\"$context.identity.sourceIp\",",
      "\"caller\":\"$context.identity.caller\",",
      "\"user\":\"$context.identity.user\",",
      "\"requestTime\":\"$context.requestTime\",",
      "\"httpMethod\":\"$context.httpMethod\",",
      "\"resourcePath\":\"$context.resourcePath\",",
      "\"status\":\"$context.status\",",
      "\"protocol\":\"$context.protocol\",",
      "\"responseLength\":\"$context.responseLength\"}"
    ])
  }
}

data "aws_wafv2_web_acl" "integrations" {
  name  = "integrations-${var.environment.account_name}-${data.aws_region.current.name}-web-acl"
  scope = "REGIONAL"
}

resource "aws_wafv2_web_acl_association" "api_gateway_stage" {
  resource_arn = aws_api_gateway_stage.current.arn
  web_acl_arn  = data.aws_wafv2_web_acl.integrations[0].arn
}

resource "aws_cloudwatch_log_group" "lpa_uid" {
  name              = "API-Gateway-Execution-Logs-${aws_api_gateway_rest_api.lpa_uid.name}-${local.stage_name}"
  kms_key_id        = aws_kms_key.cloudwatch_standard.arn
  retention_in_days = 400
}

output "api_stage_uri" {
  value = aws_api_gateway_stage.current.invoke_url
}

resource "aws_api_gateway_domain_name" "lpa_uid" {
  domain_name              = terraform.workspace == "production" ? data.aws_route53_zone.service.name : "${local.a_record}.${data.aws_route53_zone.service.name}"
  regional_certificate_arn = aws_acm_certificate.environment.arn
  security_policy          = "TLS_1_2"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_base_path_mapping" "mapping" {
  api_id      = aws_api_gateway_rest_api.lpa_uid.id
  stage_name  = aws_api_gateway_stage.current.stage_name
  domain_name = aws_api_gateway_domain_name.lpa_uid.domain_name

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_method_settings" "lpa_uid_gateway_settings" {
  rest_api_id = aws_api_gateway_rest_api.lpa_uid.id
  stage_name  = aws_api_gateway_stage.current.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled = true
    logging_level   = "INFO"
  }
}

data "aws_iam_policy_document" "lpa_uid" {
  policy_id = "lpa-uid-${terraform.workspace}-${data.aws_region.current.name}-resource-policy"

  statement {
    sid    = "${local.policy_region_prefix}AllowExecutionFromAllowedARNs"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = var.environment.allowed_arns
    }

    actions   = ["execute-api:Invoke"]
    resources = ["*"]
  }
}

resource "aws_api_gateway_rest_api_policy" "lpa_uid" {
  rest_api_id = aws_api_gateway_rest_api.lpa_uid.id
  policy      = data.aws_iam_policy_document.lpa_uid.json
}
