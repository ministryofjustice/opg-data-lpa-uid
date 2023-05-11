resource "aws_security_group" "lambda" {
  name_prefix = "lpa-uid-${local.environment_name}"
  vpc_id      = data.aws_vpc.sirius.id
  description = "LPA UID Lambda security group"

  lifecycle {
    create_before_destroy = true
  }
}
