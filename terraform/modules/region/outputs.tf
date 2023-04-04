output "dynamodb_arn" {
  value = var.is_primary ? aws_dynamodb_table.lpa_uid[0].arn : ""
}

output "dynamodb_name" {
  value = var.is_primary ? aws_dynamodb_table.lpa_uid[0].name : ""
}
