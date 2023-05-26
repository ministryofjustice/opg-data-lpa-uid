resource "aws_security_group" "lambda" {
  name        = "lpa-uid-${local.environment_name}"
  vpc_id      = data.aws_vpc.sirius.id
  description = "LPA UID Lambda security group"

  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_security_group_rule" "lambda_egress" {
  description       = "Allow any egress from lambda"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"] #tfsec:ignore:aws-ec2-no-public-egress-sgr - open egress for load balancers
  security_group_id = aws_security_group.lambda.id
}
