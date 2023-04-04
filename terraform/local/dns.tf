data "aws_route53_zone" "service" {
  name     = "lpa-uid.api.opg.service.justice.gov.uk"
  provider = aws.management
}
