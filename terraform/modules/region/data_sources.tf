data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.sirius.id]
  }

  filter {
    name   = "tag:Name"
    values = ["private-*"]
  }
}

data "aws_vpc" "sirius" {
  filter {
    name   = "tag:Name"
    values = ["vpc.${data.aws_region.current.name}.${var.environment.account_name}.sirius.opg.service.justice.gov.uk"]
  }
}
