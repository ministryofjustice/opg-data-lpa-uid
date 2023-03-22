resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = aws_vpc.main.cidr_block
  availability_zone = "${data.aws_region.current.name}a"

  tags = {
    Private = "true"
    Name    = "private-${data.aws_region.current.name}a"
  }
}
data "aws_region" "current" {}

resource "aws_vpc" "main" {
  cidr_block           = "10.162.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "vpc.${data.aws_region.current.name}.development.sirius.opg.service.justice.gov.uk" }
}
