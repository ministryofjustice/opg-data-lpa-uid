resource "aws_vpc_endpoint" "execute_api" {
  vpc_id            = data.aws_vpc.sirius.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.execute-api"
  vpc_endpoint_type = "Interface"
  subnet_ids        = data.aws_subnet.private.*.id

  security_group_ids = [
    aws_security_group.execute_api.id,
  ]

  private_dns_enabled = true
}

resource "aws_security_group" "execute_api" {
  name        = "execute-api"
  description = "For execute-api vpc endpoint"
  vpc_id      = data.aws_vpc.sirius.id
}

# --------

data "aws_security_group" "execute_api" {
  name   = aws_security_group.execute_api.name
  vpc_id = data.aws_vpc.sirius.id
}

output "vpc_endpoint_dns" {
  value = aws_vpc_endpoint.execute_api.dns_entry[0].dns_name
}
