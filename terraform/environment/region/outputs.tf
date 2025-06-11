output "dynamodb_table" {
  value = var.is_primary ? aws_dynamodb_table.lpa_uid[0] : aws_dynamodb_table_replica.lpa_uid[0]
}
