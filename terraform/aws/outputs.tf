output "vpc_endpoint_dns" {
  value = [
    module.eu-west-1.vpc_endpoint_dns,
    module.eu-west-2.vpc_endpoint_dns
  ]
}

