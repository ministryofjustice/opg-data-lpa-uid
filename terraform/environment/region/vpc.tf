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
  cidr_blocks       = [data.aws_ip_ranges.dynamodb.cidr_blocks]
  security_group_id = aws_security_group.lambda.id
}

resource "aws_security_group_rule" "lambda_egress_events" {
  description       = "Allow Lambda to reach EventBridge VPC endpoint"
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.sirius.cidr_block]
  security_group_id = aws_security_group.lambda.id
}

data "aws_ip_ranges" "dynamodb" {
  regions  = ["eu-west-1", "eu-west-2"]
  services = ["dynamodb"]
}
