//===== Reference Zones from management =====

data "aws_route53_zone" "service" {
  name     = "lpa-uid.api.opg.service.justice.gov.uk"
  provider = aws.management
}

//===== Create certificates for sub domains =====

resource "aws_acm_certificate" "environment" {
  domain_name               = "*.${data.aws_route53_zone.service.name}"
  validation_method         = "DNS"
  subject_alternative_names = [data.aws_route53_zone.service.name]
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "validation" {
  name     = sort(aws_acm_certificate.environment.domain_validation_options[*].resource_record_name)[0]
  type     = sort(aws_acm_certificate.environment.domain_validation_options[*].resource_record_type)[0]
  zone_id  = data.aws_route53_zone.service.id
  records  = [sort(aws_acm_certificate.environment.domain_validation_options[*].resource_record_value)[0]]
  ttl      = 60
  provider = aws.management
}

//===== Create A records =====

resource "aws_route53_record" "environment_record" {
  name     = local.a_record
  type     = "A"
  zone_id  = data.aws_route53_zone.service.id
  provider = aws.management

  alias {
    evaluate_target_health = true
    name                   = aws_api_gateway_domain_name.lpa_uid.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.lpa_uid.regional_zone_id
  }
}


locals {
  a_record = terraform.workspace == "production" ? data.aws_route53_zone.service.name : local.environment_name
}
