resource "aws_security_group" "lambda_egress" {
  name = "lpa-uid-${local.environment_name}"
}
